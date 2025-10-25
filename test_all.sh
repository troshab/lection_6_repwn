#!/bin/bash
# Скрипт тестування всіх RE/PWN завдань
# Перевіряє компіляцію, наявність бінарників та роботу Docker

set -e  # Зупинити при помилці (але ми будемо ловити помилки вручну)

# Кольори
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Лічильники
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

print_fail() {
    echo -e "${RED}  ✗ $1${NC}"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

print_info() {
    echo -e "${BLUE}  ℹ $1${NC}"
}

# Функція для тестування команди
test_command() {
    local cmd=$1
    local desc=$2

    ((TOTAL_TESTS++))
    if command -v "$cmd" &> /dev/null; then
        print_success "$desc знайдено: $(which $cmd)"
        return 0
    else
        print_fail "$desc не знайдено"
        return 1
    fi
}

# Функція для компіляції RE завдання
test_re_task() {
    local task_dir=$1
    local task_name=$(basename "$task_dir")

    print_test "RE: $task_name"

    if [ ! -d "$task_dir" ]; then
        print_fail "Директорія не знайдена: $task_dir"
        return 1
    fi

    cd "$task_dir"

    # Очистка
    if make clean &> /dev/null; then
        print_info "Очистка попередніх файлів"
    fi

    # Компіляція
    if make &> /dev/null; then
        print_success "Компіляція успішна"

        # Перевірка що бінарник створено
        if [ -f "build/"* ] 2>/dev/null; then
            local binary=$(find build -type f -executable 2>/dev/null | head -n 1)
            if [ -n "$binary" ]; then
                print_success "Бінарник створено: $binary"
            else
                print_fail "Виконуваний файл не знайдено в build/"
            fi
        else
            print_fail "Директорія build/ порожня"
        fi
    else
        print_fail "Помилка компіляції"
    fi

    cd - > /dev/null
}

# Функція для компіляції PWN завдання
test_pwn_stage() {
    local stage_name=$1
    ((TOTAL_TESTS++))

    if [ -f "pwn/build/$stage_name/"* ] 2>/dev/null; then
        print_success "PWN: $stage_name - бінарник знайдено"
        return 0
    else
        print_fail "PWN: $stage_name - бінарник не знайдено"
        return 1
    fi
}

# ========================================
# Початок тестування
# ========================================

print_header "RE/PWN CTF - Тестування проєкту"
echo ""

# Перевірка та активація .venv якщо існує
if [ -d ".venv" ]; then
    print_info "Використання Python venv (.venv)..."
    source .venv/bin/activate
else
    print_warning "Python venv (.venv) не знайдено - використовую системний Python"
    print_info "Рекомендується запустити: ./setup_linux.sh"
fi

echo ""

# ========================================
# 1. Тест базових інструментів
# ========================================
print_header "1. Перевірка базових інструментів"

test_command "gcc" "GCC компілятор"
test_command "make" "Make"
test_command "file" "file утиліта"
test_command "strings" "strings"
test_command "readelf" "readelf"
test_command "objdump" "objdump"
test_command "gdb" "GDB debugger"
test_command "python3" "Python 3"

echo ""

# ========================================
# 2. Тест RE інструментів
# ========================================
print_header "2. Перевірка RE інструментів"

test_command "strace" "strace"
test_command "ltrace" "ltrace"
test_command "upx" "UPX packer"

# Ghidra (опціонально)
((TOTAL_TESTS++))
if command -v ghidraRun &> /dev/null; then
    print_success "Ghidra знайдено (опціонально)"
else
    print_info "Ghidra не знайдено (опціонально, потрібен для task04)"
    ((TOTAL_TESTS--))  # Не рахуємо як тест
fi

echo ""

# ========================================
# 3. Тест PWN інструментів
# ========================================
print_header "3. Перевірка PWN інструментів"

test_command "docker" "Docker"
test_command "nc" "netcat"
test_command "checksec" "checksec"

# Python venv
print_test "Python Virtual Environment (.venv)"
((TOTAL_TESTS++))
if [ -d ".venv" ]; then
    print_success ".venv існує"
else
    print_fail ".venv не знайдено (запустіть ./setup_linux.sh)"
fi

# pwntools
print_test "pwntools (Python пакет)"
((TOTAL_TESTS++))
if python3 -c "import pwn" 2>/dev/null; then
    print_success "pwntools встановлено"

    # Перевірка чи в venv
    if [[ "$VIRTUAL_ENV" != "" ]]; then
        print_info "Використовується з .venv"
    else
        print_warning "Використовується системний Python (краще використовувати .venv)"
    fi
else
    print_fail "pwntools не встановлено"
    if [ -d ".venv" ]; then
        print_info "Спробуйте: source .venv/bin/activate && pip install pwntools"
    else
        print_info "Запустіть: ./setup_linux.sh"
    fi
fi

echo ""

# ========================================
# 4. Компіляція RE завдань
# ========================================
print_header "4. Компіляція RE завдань"

RE_TASKS=(
    "re/task01_inventory"
    "re/task02_hardcoded_strings"
    "re/task03_rot13_gdb"
    "re/task04_rotn_strlen_ghidra"
    "re/task05_rotn_time_keygen"
    "re/task06_upx_packer"
    "re/task07_hidden_http_strace"
)

for task in "${RE_TASKS[@]}"; do
    if [ -d "$task" ]; then
        test_re_task "$task"
    else
        print_fail "RE завдання не знайдено: $task"
        ((FAILED_TESTS++))
        ((TOTAL_TESTS++))
    fi
    echo ""
done

# ========================================
# 5. Компіляція PWN завдань
# ========================================
print_header "5. Компіляція PWN завдань"

if [ -d "pwn" ] && [ -f "pwn/Makefile" ]; then
    print_info "Компіляція всіх PWN завдань..."

    cd pwn
    if make clean &> /dev/null && make &> /dev/null; then
        print_success "PWN Makefile: компіляція успішна"

        # Перевірка окремих етапів
        PWN_STAGES=(
            "stage01_nc/stage01"
            "stage02_checksec/dummy"
            "stage03_pwntools/stage03"
            "stage04_demo_no_offset/stage04"
            "stage05_demo_with_hint/stage05"
            "stage06_ret2win/stage06"
            "stage07_leak_demo/stage07"
            "stage08_ret2libc/stage08"
        )

        for stage in "${PWN_STAGES[@]}"; do
            test_pwn_stage "$stage"
        done
    else
        print_fail "PWN Makefile: помилка компіляції"
        ((FAILED_TESTS++))
        ((TOTAL_TESTS++))
    fi
    cd - > /dev/null
else
    print_fail "PWN директорія або Makefile не знайдено"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
fi

echo ""

# ========================================
# 6. Тест Docker
# ========================================
print_header "6. Перевірка Docker"

print_test "Docker сервіс"
((TOTAL_TESTS++))
if systemctl is-active --quiet docker 2>/dev/null || docker info &> /dev/null; then
    print_success "Docker сервіс запущено"
else
    print_fail "Docker сервіс не запущено (sudo systemctl start docker)"
fi

print_test "Docker Compose конфігурація"
((TOTAL_TESTS++))
if [ -f "pwn/docker-compose.yml" ]; then
    print_success "docker-compose.yml знайдено"

    # Спробувати запустити (без фактичного запуску)
    cd pwn
    if docker compose config &> /dev/null; then
        print_success "docker-compose.yml валідний"
        ((TOTAL_TESTS++))
    else
        print_fail "docker-compose.yml має помилки"
        ((TOTAL_TESTS++))
        ((FAILED_TESTS++))
    fi
    cd - > /dev/null
else
    print_fail "docker-compose.yml не знайдено"
fi

echo ""

# ========================================
# 7. Тест документації
# ========================================
print_header "7. Перевірка документації"

DOCS=(
    "README.md:Головний README"
    "re/README.md:RE документація"
    "pwn/README.md:PWN документація"
    "slides/slides.md:Презентація"
)

for doc_desc in "${DOCS[@]}"; do
    doc="${doc_desc%%:*}"
    desc="${doc_desc##*:}"

    print_test "$desc"
    ((TOTAL_TESTS++))
    if [ -f "$doc" ]; then
        print_success "Знайдено: $doc"
    else
        print_fail "Не знайдено: $doc"
    fi
done

echo ""

# ========================================
# Фінальний звіт
# ========================================
print_header "Результати тестування"

echo ""
echo -e "Всього тестів:    ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Успішно:          ${GREEN}$PASSED_TESTS${NC}"
echo -e "Провалено:        ${RED}$FAILED_TESTS${NC}"
echo ""

# Обчислення відсотку успішності
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Успішність:       ${BLUE}${SUCCESS_RATE}%${NC}"
else
    SUCCESS_RATE=0
fi

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    print_header "🎉 Всі тести пройдено успішно! 🎉"
    echo ""
    print_info "Проєкт повністю готовий до використання"
    echo ""
    print_info "Наступні кроки:"
    echo "  - Почніть з RE: cd re/task01_inventory && make && ./build/re101"
    echo "  - Або PWN: cd pwn && docker compose up -d"
    echo "  - Презентація: cd slides && npm run dev"
    exit 0
elif [ $SUCCESS_RATE -ge 80 ]; then
    echo -e "${YELLOW}⚠ Більшість тестів пройдено, але є деякі проблеми${NC}"
    echo ""
    print_info "Деякі інструменти або завдання не працюють"
    print_info "Перегляньте повідомлення вище для деталей"
    exit 1
else
    echo -e "${RED}✗ Багато тестів провалено${NC}"
    echo ""
    print_info "Рекомендується запустити setup_linux.sh"
    print_info "або встановити відсутні інструменти вручну"
    exit 1
fi
