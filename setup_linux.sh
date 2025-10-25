#!/bin/bash
# Скрипт автоматичного встановлення середовища для RE/PWN CTF курсу
# Підтримка: Ubuntu 20.04+, Debian 11+, Kali Linux

set -e  # Зупинити при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функції для виводу
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Перевірка що скрипт запущено НЕ від root
if [ "$EUID" -eq 0 ]; then
    print_error "Не запускайте цей скрипт від root!"
    print_info "Використовуйте: ./setup_linux.sh"
    print_info "Скрипт сам попросить sudo коли потрібно"
    exit 1
fi

print_header "RE/PWN CTF Setup Script"
print_info "Цей скрипт встановить всі необхідні інструменти для курсу"
echo ""

# Запитати підтвердження
read -p "Продовжити встановлення? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Встановлення скасовано"
    exit 0
fi

# 1. Оновлення системи
print_header "Крок 1/7: Оновлення системи"
print_info "Оновлення списку пакетів..."
sudo apt update

# 2. Встановлення базових інструментів для RE
print_header "Крок 2/7: Встановлення RE інструментів"

PACKAGES=(
    "build-essential"  # gcc, make, g++
    "binutils"         # readelf, objdump, nm, strings
    "file"             # file утиліта
    "gdb"              # GNU Debugger
    "ltrace"           # library call tracer
    "strace"           # system call tracer
    "upx-ucl"          # UPX packer/unpacker
    "wget"             # для завантаження
    "curl"             # для HTTP завдань
    "netcat-openbsd"   # для PWN завдань
    "git"              # система контролю версій
)

print_info "Встановлення пакетів: ${PACKAGES[*]}"
sudo apt install -y "${PACKAGES[@]}"
print_success "RE інструменти встановлено"

# 3. Встановлення Python та Virtual Environment
print_header "Крок 3/7: Встановлення Python середовища"

if ! command -v python3 &> /dev/null; then
    print_info "Встановлення Python 3..."
    sudo apt install -y python3 python3-pip python3-dev python3-venv
else
    print_success "Python 3 вже встановлено: $(python3 --version)"

    # Переконатися що venv встановлено
    if ! dpkg -l | grep -q python3-venv; then
        print_info "Встановлення python3-venv..."
        sudo apt install -y python3-venv
    fi
fi

# Створення virtual environment
if [ ! -d ".venv" ]; then
    print_info "Створення Python virtual environment (.venv)..."
    python3 -m venv .venv
    print_success "Virtual environment створено"
else
    print_success "Virtual environment вже існує"
fi

# Активація venv та встановлення залежностей
if [ -f "requirements.txt" ]; then
    print_info "Встановлення Python пакетів в .venv..."

    # Активувати venv та встановити пакети
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate

    print_success "Python залежності встановлено в .venv"
    print_info "Для активації: source .venv/bin/activate"
else
    print_warning "requirements.txt не знайдено, пропускаємо"
fi

# 4. Встановлення Docker (для PWN завдань)
print_header "Крок 4/7: Встановлення Docker"

if ! command -v docker &> /dev/null; then
    print_info "Встановлення Docker..."

    # Встановлення Docker
    sudo apt install -y docker.io docker-compose

    # Додавання користувача до групи docker
    sudo usermod -aG docker $USER

    # Запуск Docker сервісу
    sudo systemctl enable docker
    sudo systemctl start docker

    print_success "Docker встановлено"
    print_warning "ВАЖЛИВО: Для використання Docker без sudo, вийдіть з системи та увійдіть знову"
    print_info "Або виконайте: newgrp docker"
else
    print_success "Docker вже встановлено: $(docker --version)"
fi

# 5. Встановлення checksec
print_header "Крок 5/7: Встановлення checksec"

if ! command -v checksec &> /dev/null; then
    print_info "Завантаження checksec..."
    wget https://raw.githubusercontent.com/slimm609/checksec.sh/master/checksec -O /tmp/checksec
    sudo install /tmp/checksec /usr/local/bin/checksec
    print_success "checksec встановлено"
else
    print_success "checksec вже встановлено"
fi

# 6. Перевірка Ghidra (опціонально)
print_header "Крок 6/7: Перевірка Ghidra"

if command -v ghidraRun &> /dev/null; then
    print_success "Ghidra знайдено: $(which ghidraRun)"
else
    print_warning "Ghidra не знайдено"
    print_info "Ghidra потрібен для Task 04 (ROT-N + Ghidra)"
    print_info "Завантажте з: https://ghidra-sre.org/"
    print_info "Або встановіть через flatpak: flatpak install flathub org.ghidra_sre.Ghidra"
fi

# 7. Збірка проєкту
print_header "Крок 7/7: Збірка PWN завдань"

if [ -d "pwn" ] && [ -f "pwn/Makefile" ]; then
    print_info "Компіляція PWN завдань..."
    cd pwn
    make clean
    make
    cd ..
    print_success "PWN завдання зібрано"
else
    print_warning "PWN директорія не знайдена, пропускаємо збірку"
fi

# Фінальна перевірка
print_header "Перевірка встановлення"

TOOLS=(
    "gcc:GCC Compiler"
    "make:Make"
    "gdb:GNU Debugger"
    "python3:Python 3"
    "docker:Docker"
    "checksec:Checksec"
    "file:File utility"
    "strings:Strings utility"
    "readelf:Readelf"
    "objdump:Objdump"
    "strace:Strace"
    "ltrace:Ltrace"
    "upx:UPX"
    "nc:Netcat"
)

print_info "Перевірка встановлених інструментів:"
echo ""

ALL_OK=true
for tool_desc in "${TOOLS[@]}"; do
    tool="${tool_desc%%:*}"
    desc="${tool_desc##*:}"
    if command -v "$tool" &> /dev/null; then
        print_success "$desc"
    else
        print_error "$desc не знайдено"
        ALL_OK=false
    fi
done

echo ""
print_header "Встановлення завершено!"

if [ "$ALL_OK" = true ]; then
    print_success "Всі необхідні інструменти встановлено"
else
    print_warning "Деякі інструменти не встановлено (див. вище)"
fi

echo ""
print_info "Наступні кроки:"
echo "  1. Активувати Python venv: source .venv/bin/activate"
echo "  2. Для RE завдань: cd re/task01_inventory && make"
echo "  3. Для PWN завдань: cd pwn && docker compose up -d"
echo "  4. Запустити тести: ./test_all.sh"
echo ""
print_info "Документація:"
echo "  - RE курс: re/README.md"
echo "  - PWN курс: pwn/README.md"
echo "  - Презентація: slides/README.md"
echo ""
print_info "Python Virtual Environment:"
echo "  - Активувати: source .venv/bin/activate"
echo "  - Деактивувати: deactivate"
echo "  - Встановити пакети: pip install <package>"
echo ""

if groups $USER | grep -q docker; then
    print_success "Ви вже в групі docker"
else
    print_warning "ВАЖЛИВО: Для використання Docker виконайте:"
    echo "  newgrp docker"
    echo "  або вийдіть з системи та увійдіть знову"
fi

print_success "Готово! Приємного навчання! 🎓"
