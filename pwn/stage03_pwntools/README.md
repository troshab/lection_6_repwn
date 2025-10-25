# Stage 03: pwntools - Автоматизація експлуатації

## 🎯 Мета завдання

Навчитися використовувати **pwntools** - найпопулярніший Python framework для написання exploit'ів. Це критичний інструмент для ефективної роботи з PWN завданнями.

## 📚 Що ви дізнаєтесь

- Що таке pwntools і навіщо він потрібен
- Як підключатися до віддалених сервісів через `remote()`
- Як надсилати та отримувати дані (`send`, `recv`, `sendline`, `recvline`)
- Як працювати з бінарними даними та пакуванням адрес
- Як обробляти таймаути та помилки
- Основи написання стабільних exploit скриптів

## 🔧 Необхідні інструменти

```bash
# Встановіть Python 3
sudo apt install python3 python3-pip

# Встановіть pwntools
pip3 install pwntools

# Або для користувача (без sudo)
pip3 install --user pwntools

# Перевірте встановлення
python3 -c "from pwn import *; print('pwntools OK!')"
```

## 📖 Теоретична основа

### Чому не просто nc?

**Проблеми з netcat:**
- ❌ Ручне введення даних (повільно, помилки)
- ❌ Важко відправляти бінарні дані (null bytes, спец символи)
- ❌ Немає автоматичного парсингу відповідей
- ❌ Важко debug при помилках
- ❌ Неможливо повторити спробу автоматично

**Переваги pwntools:**
- ✅ Повністю автоматизовано
- ✅ Легко працювати з бінарними даними
- ✅ Вбудовані функції для ROP, shellcode, packing
- ✅ Зручний debug та логування
- ✅ Стабільність та контроль таймаутів

### Анатомія exploit скрипта

```python
#!/usr/bin/env python3
from pwn import *

# 1. Підключення
io = remote('127.0.0.1', 7103)

# 2. Взаємодія
io.recvuntil(b'magic word')    # Чекаємо підказку
io.sendline(b'GIMME FLAG')     # Відправляємо команду

# 3. Отримання результату
flag = io.recvline()           # Читаємо прапор
print(flag.decode())

# 4. Закриття
io.close()
```

## 💻 Основні функції pwntools

### 1. Підключення

```python
# Віддалений сервіс
io = remote('host', port)
io = remote('127.0.0.1', 7103)

# Локальний процес
io = process('./binary')
io = process(['./binary', 'arg1', 'arg2'])

# SSH
shell = ssh('user', 'host', password='pass')
io = shell.process('./binary')
```

### 2. Відправка даних

```python
# Відправити дані без \n
io.send(b'data')

# Відправити дані з \n в кінці
io.sendline(b'data')

# Відправити після отримання конкретного тексту
io.sendafter(b'prompt: ', b'response')
io.sendlineafter(b'name: ', b'Alice')
```

### 3. Отримання даних

```python
# Прочитати N байт
data = io.recv(100)           # Читає до 100 байт

# Прочитати до \n
line = io.recvline()          # Включає \n в кінці

# Прочитати до конкретного рядка
io.recvuntil(b'Password: ')   # Зупиняється після 'Password: '

# Прочитати все (до закриття з'єднання)
all_data = io.recvall()       # Чекає поки сервер закриє з'єднання
```

### 4. Пакування даних

```python
# Пакування чисел в байти (Little Endian)
p64(0x401136)    # → b'\x36\x11\x40\x00\x00\x00\x00\x00'  (64-bit)
p32(0x401136)    # → b'\x36\x11\x40\x00'                  (32-bit)

# Розпакування
u64(b'\x36\x11\x40\x00\x00\x00\x00\x00')  # → 0x401136
u32(b'\x36\x11\x40\x00')                  # → 0x401136

# Hex перетворення
data = bytes.fromhex('41424344')  # → b'ABCD'
hexdata = data.hex()              # → '41424344'
```

### 5. Робота з ELF

```python
# Завантажити бінарник
elf = ELF('./binary')

# Отримати адреси символів
win_addr = elf.symbols['win']       # Адреса функції win()
main_addr = elf.symbols['main']

# Отримати адреси секцій
bss_addr = elf.bss()                # Адреса .bss
plt_puts = elf.plt['puts']          # Адреса puts@plt
got_puts = elf.got['puts']          # Адреса puts@got

# Встановити базову адресу (для PIE)
elf.address = 0x555555554000
```

### 6. Контроль виконання

```python
# Інтерактивний режим (передає керування вам)
io.interactive()

# Таймаути
io = remote('host', port, timeout=10)  # Таймаут 10 сек
io.recv(timeout=5)                     # Окремий таймаут для recv

# Закриття
io.close()
```

## 🚀 Покрокове рішення

### Крок 1: Збудуйте сервер

```bash
cd stage03_pwntools
./build.sh
```

### Крок 2: Запустіть сервер

```bash
cd ../build
./stage03_pwntools
```

### Крок 3: Створіть exploit скрипт

Створіть файл `exploit.py`:

```python
#!/usr/bin/env python3
from pwn import *

# Налаштування
HOST = '127.0.0.1'
PORT = 7103

# Підключення
io = remote(HOST, PORT)
print(f"[*] Підключено до {HOST}:{PORT}")

# Отримуємо банер
banner = io.recvline()
print(f"[*] Банер: {banner.decode().strip()}")

# Відправляємо магічне слово
print("[*] Відправляємо: GIMME FLAG")
io.sendline(b'GIMME FLAG')

# Отримуємо прапор
flag = io.recvline()
print(f"[+] Прапор: {flag.decode().strip()}")

# Закриваємо з'єднання
io.close()
print("[*] З'єднання закрито")
```

### Крок 4: Запустіть exploit

```bash
chmod +x exploit.py
python3 exploit.py
```

### Крок 5: Отримайте прапор

Вивід:
```
[*] Підключено до 127.0.0.1:7103
[*] Банер: say the magic word
[*] Відправляємо: GIMME FLAG
[+] Прапор: FLAG{STAGE3_AUTO}
[*] З'єднання закрито
```

## 🔍 Просунуті техніки

### 1. Логування та debug

```python
# Увімкнути debug вивід
context.log_level = 'debug'  # Показує всі send/recv

# Різні рівні
context.log_level = 'info'    # Базова інформація
context.log_level = 'warning' # Тільки попередження
context.log_level = 'error'   # Тільки помилки

# Ручне логування
log.info("Це інформація")
log.success("Успіх!")
log.warning("Попередження")
log.error("Помилка")
```

### 2. Обробка помилок

```python
try:
    io = remote('127.0.0.1', 7103, timeout=5)
    io.recvuntil(b'magic word')
    io.sendline(b'GIMME FLAG')
    flag = io.recvline(timeout=2)
    print(flag.decode())
except EOFError:
    log.error("З'єднання закрито передчасно")
except TimeoutError:
    log.error("Таймаут при очікуванні відповіді")
finally:
    try:
        io.close()
    except:
        pass
```

### 3. Перемикання між local/remote

```python
import sys

# Вибір цілі з командного рядка
if len(sys.argv) > 1 and sys.argv[1] == 'remote':
    io = remote('ctf.example.com', 1337)
else:
    io = process('./binary')

# Або через змінну середовища
if args.REMOTE:
    io = remote('host', port)
else:
    io = process('./binary')
```

### 4. Циклічний шаблон (для знаходження offset)

```python
# Генерація циклічного шаблону
pattern = cyclic(200)  # 200 байт унікального паттерну
io.send(pattern)

# Знаходження offset за адресою краша
# Наприклад, RIP = 0x6161616c ('laaa')
offset = cyclic_find(0x6161616c)  # → 44
print(f"Offset: {offset}")

# Або з core dump
core = io.corefile  # Якщо process() крашнувся
stack = core.rsp
info("RSP: %#x", stack)
pattern_offset = cyclic_find(core.read(stack, 4))
```

### 5. Shellcode генерація

```python
# Генерація shellcode
shellcode = asm(shellcraft.sh())  # Shell для поточної архітектури

# Для конкретної архітектури
context.arch = 'amd64'
shellcode = asm(shellcraft.amd64.linux.sh())

context.arch = 'i386'
shellcode = asm(shellcraft.i386.linux.sh())
```

## 🎓 Практичні завдання

### Завдання 1: Базовий скрипт з логуванням

```python
#!/usr/bin/env python3
from pwn import *

context.log_level = 'debug'  # Увімкніть debug

io = remote('127.0.0.1', 7103)
io.recvuntil(b'magic word')
io.sendline(b'GIMME FLAG')
print(io.recvline().decode())
io.close()
```

Запустіть і подивіться детальний вивід всіх операцій.

### Завдання 2: Обробка помилок

Додайте обробку ситуації коли сервер не відповідає:

```python
#!/usr/bin/env python3
from pwn import *

try:
    io = remote('127.0.0.1', 7103, timeout=3)
    io.recvuntil(b'magic word', timeout=2)
    io.sendline(b'GIMME FLAG')
    flag = io.recvline(timeout=2)
    log.success(f"Flag: {flag.decode().strip()}")
except TimeoutError as e:
    log.error(f"Timeout: {e}")
except Exception as e:
    log.error(f"Error: {e}")
finally:
    try:
        io.close()
    except:
        pass
```

### Завдання 3: Функція для повторних спроб

```python
#!/usr/bin/env python3
from pwn import *

def try_exploit(max_attempts=3):
    for attempt in range(1, max_attempts + 1):
        try:
            log.info(f"Спроба {attempt}/{max_attempts}")
            io = remote('127.0.0.1', 7103, timeout=5)
            io.recvuntil(b'magic word')
            io.sendline(b'GIMME FLAG')
            flag = io.recvline()
            io.close()
            return flag.decode().strip()
        except Exception as e:
            log.warning(f"Спроба {attempt} failed: {e}")
            if attempt < max_attempts:
                log.info("Повторюю...")
                time.sleep(1)
            else:
                log.error("Всі спроби вичерпано")
                return None

flag = try_exploit()
if flag:
    log.success(f"Прапор: {flag}")
```

### Завдання 4: Порівняння з чистим Python

Спробуйте те саме без pwntools:

```python
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('127.0.0.1', 7103))
data = s.recv(1024)
print(f"Received: {data}")
s.send(b'GIMME FLAG\n')
flag = s.recv(1024)
print(f"Flag: {flag.decode()}")
s.close()
```

Бачите різницю? З pwntools набагато зручніше!

## 💡 Порівняння: nc vs pwntools

| Завдання | netcat | pwntools |
|----------|--------|----------|
| Підключення | `nc host port` | `remote('host', port)` |
| Відправка | Ручне введення | `sendline(data)` |
| Очікування prompt | Ручне | `recvuntil(b'prompt')` |
| Бінарні дані | Складно | `p64(addr)` |
| Повторні спроби | Вручну | `while` loop легко |
| Debug | Немає | `context.log_level='debug'` |
| Таймаути | Обмежені | Повний контроль |

## 📚 Корисні snippets

### Шаблон для CTF

```python
#!/usr/bin/env python3
from pwn import *

# Налаштування
context.arch = 'amd64'
context.log_level = 'info'

HOST = '127.0.0.1'
PORT = 7103

def exploit():
    # Підключення
    io = remote(HOST, PORT)

    # Ваш код тут
    io.recvuntil(b'prompt')
    io.sendline(b'payload')

    # Результат
    result = io.recvline()
    log.success(f"Result: {result.decode()}")

    io.close()
    return result

if __name__ == '__main__':
    exploit()
```

### Конвертація hex в байти

```python
# Hex string → bytes
payload = bytes.fromhex('414243')  # → b'ABC'

# Integer → bytes (64-bit)
payload = p64(0x401136)

# Комбінація
payload = b'A' * 72 + p64(0x401136) + bytes.fromhex('909090')
```

## 🔗 Корисні посилання

- [pwntools документація](https://docs.pwntools.com/)
- [pwntools GitHub](https://github.com/Gallopsled/pwntools)
- [pwntools tutorial](https://github.com/Gallopsled/pwntools-tutorial)
- [CTF-wiki pwntools](https://ctf-wiki.org/pwn/linux/user-mode/mitigation/canary/)

## ✅ Чеклист виконання

- [ ] Встановлено pwntools (`pip3 install pwntools`)
- [ ] Зібрано сервер через `build.sh`
- [ ] Створено базовий exploit скрипт
- [ ] Запущено скрипт і отримано прапор
- [ ] Спробовано різні рівні логування
- [ ] Додано обробку помилок
- [ ] Зрозуміло переваги pwntools над netcat
- [ ] Знаю основні функції: remote, send, recv, p64, u64
- [ ] Готовий до Stage 04!

---

**Час виконання:** 10-15 хвилин
**Складність:** ⭐☆☆☆☆ (Тривіальна)
**Категорія:** PWN / Automation
**Залежності:** Python 3, pwntools
