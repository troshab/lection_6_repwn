# Task 05: ROT-N (time-based) + Keygen

## 📋 Опис завдання

Зсув змінюється КОЖНОЇ СЕКУНДИ! `N = time() % 20`. Потрібен **кейген**, який генерує правильний серійник в реальному часі.

**Рівень:** ⭐⭐⭐⭐ Складний | **Категорія:** Time-based algorithms, Keygen development

## 🎯 Навчальна мета

- Розуміти time-based алгоритми
- Писати кейгени (генератори ключів)
- Синхронізувати час між кейгеном та програмою
- Аналізувати залежність від системного часу

## 📚 Що змінилося?

**Task 04:** `N = strlen(name) % 26` - залежить від імені
**Task 05:** `N = time() % 20` - залежить від ЧАСУ!

**Проблема:** Серійник дійсний лише 1 секунду!

```
13:37:00 → time()=1698160620 → N=0  → serial="Alice"
13:37:01 → time()=1698160621 → N=1  → serial="Bmjdf"
13:37:02 → time()=1698160622 → N=2  → serial="Cnkeg"
```

## 🛠️ Підготовка

```bash
cd task05_rotn_time_keygen
./build.sh
```

## 🔍 Покрокове рішення

### Крок 1: Спроба статичного серійника (FAIL)

```bash
./build/re105 Alice Fqnhj
# nope (працювало б якби N=5, але зараз інший час!)
```

### Крок 2: Аналіз через Ghidra

Відкриваємо `build/re105` у Ghidra та знаходимо в `main`:

```c
time_t t = time(NULL);        // ← Поточний час (Unix timestamp)
int N = (int)(t % 20);         // ← Зсув від 0 до 19
rot_apply(buffer, name, N);
```

**Ага!** Зсув змінюється кожної секунди!

### Крок 3: Написання кейгена

#### Основи Python для новачків

Якщо ви вперше бачите Python код, ось базові поняття:

**Що таке Python?**
- Мова програмування високого рівня
- Простий синтаксис, читабельний код
- Не потрібна компіляція - скрипти запускаються напряму

**Як запустити Python скрипт:**
```bash
python3 script.py          # Запустити скрипт
python3 script.py Alice    # Запустити з аргументом "Alice"
```

**Базовий синтаксис Python:**
```python
# Це коментар (ігнорується)

x = 5                      # Змінна (не потрібен тип!)
text = "Hello"             # Рядок в лапках

def my_function(param):    # Оголошення функції
    result = param + 1     # Відступи ВАЖЛИВІ (4 пробіли)
    return result          # Повернути значення

if x > 3:                  # Умова
    print("Більше 3")      # Вивід на екран
else:
    print("Менше або 3")

for char in text:          # Цикл по символах
    print(char)            # H, e, l, l, o

# Робота з символами
ord('A')                   # → 65 (ASCII код букви A)
chr(65)                    # → 'A' (буква з ASCII кода)
```

**Списки (lists):**
```python
my_list = []               # Порожній список
my_list.append('A')        # Додати елемент
my_list.append('B')        # my_list тепер ['A', 'B']
''.join(my_list)           # → 'AB' (об'єднати в рядок)
```

**Модулі (import):**
```python
import time                # Імпортувати модуль time
t = time.time()            # Викликати функцію з модуля
```

Створюємо `solver/keygen.py`:

```python
#!/usr/bin/env python3
import time

def rot_n(text, n):
    """ROT-N шифрування"""
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr((ord(char) - ord('a') + n) % 26 + ord('a')))
        elif 'A' <= char <= 'Z':
            result.append(chr((ord(char) - ord('A') + n) % 26 + ord('A')))
        else:
            result.append(char)
    return ''.join(result)

def generate_serial(name):
    """Генерувати серійник на основі поточного часу"""
    t = int(time.time())      # Поточний Unix timestamp
    n = t % 20                 # Зсув від 0 до 19
    serial = rot_n(name, n)
    return serial, n, t

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <name>")
        sys.exit(1)

    name = sys.argv[1]
    serial, n, t = generate_serial(name)

    print(f"[*] Current time: {t}")
    print(f"[*] N (shift): {n}")
    print(f"[+] Serial: {serial}")
    print()
    print(f"[!] Quick! Run immediately:")
    print(f"    ./build/re105 {name} {serial}")
```

#### Пояснення коду построково

Розберемо кейген детально для тих, хто не знайомий з Python:

```python
#!/usr/bin/env python3
# ↑ "shebang" - каже системі використати python3 для запуску

import time
# ↑ Імпортуємо модуль для роботи з часом

def rot_n(text, n):
# ↑ Оголошуємо функцію rot_n, яка приймає текст і зсув n

    result = []
    # ↑ Створюємо порожній список для результату

    for char in text:
    # ↑ Цикл: проходимо по кожному символу в тексті

        if 'a' <= char <= 'z':
        # ↑ Якщо символ - маленька літера (a-z)

            result.append(chr((ord(char) - ord('a') + n) % 26 + ord('a')))
            # Розбір виразу:
            # ord(char) - отримати ASCII код символу (наприклад, 'a' → 97)
            # ord('a') - ASCII код 'a' (97)
            # ord(char) - ord('a') - позиція в алфавіті (0-25)
            # + n - додати зсув
            # % 26 - якщо вийшли за межі, повернутись на початок
            # + ord('a') - перетворити назад в ASCII код
            # chr(...) - перетворити ASCII код назад в символ
            # result.append(...) - додати символ до результату

        elif 'A' <= char <= 'Z':
        # ↑ Якщо символ - велика літера (A-Z)
            result.append(chr((ord(char) - ord('A') + n) % 26 + ord('A')))
            # Те саме, але для великих літер

        else:
        # ↑ Якщо НЕ літера (цифра, пробіл, тощо)
            result.append(char)
            # Залишаємо символ без змін

    return ''.join(result)
    # ↑ Об'єднуємо список символів у рядок і повертаємо

def generate_serial(name):
# ↑ Функція для генерації серійника

    t = int(time.time())
    # ↑ Отримати поточний Unix timestamp (секунди з 1 січня 1970)

    n = t % 20
    # ↑ Обчислити зсув: залишок від ділення на 20 (результат 0-19)

    serial = rot_n(name, n)
    # ↑ Застосувати ROT-N шифрування до імені

    return serial, n, t
    # ↑ Повернути серійник, зсув, та час (три значення одразу!)

if __name__ == "__main__":
# ↑ Якщо скрипт запускається напряму (не імпортується)

    import sys
    # ↑ Імпортуємо модуль для роботи з аргументами командного рядка

    if len(sys.argv) != 2:
    # ↑ Якщо кількість аргументів НЕ 2 (скрипт + ім'я)
        print(f"Usage: {sys.argv[0]} <name>")
        # sys.argv[0] - назва скрипту
        sys.exit(1)
        # Вийти з кодом помилки 1

    name = sys.argv[1]
    # ↑ Отримати перший аргумент (ім'я)

    serial, n, t = generate_serial(name)
    # ↑ Викликати функцію, розпакувати три повернені значення

    print(f"[*] Current time: {t}")
    # ↑ f"..." - f-string для підстановки змінних
```

**Приклад виконання:**
```python
# Якщо час = 1698160622, name = "Alice"
t = 1698160622
n = t % 20              # n = 2
serial = rot_n("Alice", 2)

# ROT-2 для "Alice":
# A → C, l → n, i → k, c → e, e → g
# Результат: "Cnkeg"
```

### Крок 4: Запуск кейгена та програми ШВИДКО

```bash
# Генеруємо серійник
python3 solver/keygen.py Alice
# [+] Serial: Doljh

# ШВИДКО копіюємо та запускаємо (в тій же секунді!)
./build/re105 Alice Doljh
# FLAG{task5_ok_Alice}
```

**Важливо:** Між генерацією та запуском має пройти <1 секунди!

### Крок 5: Автоматизація (bash one-liner)

```bash
name="Alice" && ./build/re105 "$name" "$(python3 solver/keygen.py "$name" | grep Serial | awk '{print $3}')"
```

Або повністю в Python:

```python
#!/usr/bin/env python3
import subprocess, time, sys

def rot_n(text, n):
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr((ord(char) - ord('a') + n) % 26 + ord('a')))
        elif 'A' <= char <= 'Z':
            result.append(chr((ord(char) - ord('A') + n) % 26 + ord('A')))
        else:
            result.append(char)
    return ''.join(result)

name = sys.argv[1] if len(sys.argv) > 1 else "Alice"
n = int(time.time()) % 20
serial = rot_n(name, n)

# Запускаємо програму одразу
result = subprocess.run(
    ['./build/re105', name, serial],
    capture_output=True, text=True
)
print(result.stdout)
```

## 🎓 Time-based Security

### Чому це цікаво?

**Real-world аналоги:**
- TOTP (Time-based One-Time Password) - Google Authenticator
- Ліцензійні ключі з терміном дії
- Anti-replay захист

### Атака "Time Manipulation"

Можна "заморозити" час системи:

```bash
# Linux: встановити фіксований час (потрібен root)
sudo date -s "2024-01-01 12:00:00"

# Або використати libfaketime
LD_PRELOAD=/usr/lib/faketime/libfaketime.so.1 FAKETIME="2024-01-01 12:00:00" ./build/re105 Alice <serial>
```

### Знаходження "хорошого" часу

Можна перебрати всі можливі N (0-19):

```python
#!/usr/bin/env python3
import subprocess

def rot_n(text, n):
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr((ord(char) - ord('a') + n) % 26 + ord('a')))
        elif 'A' <= char <= 'Z':
            result.append(chr((ord(char) - ord('A') + n) % 26 + ord('A')))
        else:
            result.append(char)
    return ''.join(result)

name = "Alice"

# Пробуємо всі можливі зсуви
for n in range(20):
    serial = rot_n(name, n)
    result = subprocess.run(
        ['./build/re105', name, serial],
        capture_output=True, text=True
    )
    if "FLAG" in result.stdout:
        print(f"[+] Found! N={n}, Serial={serial}")
        print(result.stdout)
        break
    else:
        print(f"[-] N={n}, Serial={serial} - nope")
```

Один з 20 варіантів ЗАВЖДИ спрацює!

## 💡 Поради

### Швидкий workflow

```bash
# Створюємо alias
alias solve='name="Alice"; serial=$(python3 solver/keygen.py "$name" 2>/dev/null | tail -1); ./build/re105 "$name" "$serial"'

# Просто викликаємо
solve
```

### Bash функція з виводом

```bash
function solve_task05() {
    local name="${1:-Alice}"
    local t=$(date +%s)
    local n=$((t % 20))

    echo "[*] Time: $t"
    echo "[*] N: $n"

    # ROT-N в bash (спрощено, працює тільки для ASCII)
    # Для повноцінного рішення краще Python

    python3 -c "
import time
def rot_n(s, n):
    r = ''
    for c in s:
        if 'a' <= c <= 'z':
            r += chr((ord(c) - ord('a') + n) % 26 + ord('a'))
        elif 'A' <= c <= 'Z':
            r += chr((ord(c) - ord('A') + n) % 26 + ord('A'))
        else:
            r += c
    return r

n = int(time.time()) % 20
serial = rot_n('$name', n)
print(f'[+] Serial: {serial}')
import subprocess
subprocess.run(['./build/re105', '$name', serial])
"
}

solve_task05 Alice
```

## 🏁 Чеклист

- [ ] Зібрав `build/re105`
- [ ] Проаналізував через Ghidra (знайшов `time()`)
- [ ] Написав кейген який використовує `time()`
- [ ] Згенерував та одразу використав серійник
- [ ] Отримав FLAG
- [ ] (Бонус) Автоматизував через скрипт

## 📖 Ресурси

- [Unix Time](https://en.wikipedia.org/wiki/Unix_time)
- [TOTP (RFC 6238)](https://tools.ietf.org/html/rfc6238)
- [libfaketime](https://github.com/wolfcw/libfaketime)
- [Caesar Cipher](https://en.wikipedia.org/wiki/Caesar_cipher)

## 🎯 Наступний крок

**Task 06** - UPX пакування! Як аналізувати запаковані бінарники?

---
**Складність:** ⭐⭐⭐⭐ | **Час:** 45-60 хв | **FLAG:** `FLAG{task5_ok_<name>}`
