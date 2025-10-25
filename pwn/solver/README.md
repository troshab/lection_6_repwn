# Solver Directory

**[← Назад до головної](../README.md)** | [Всі етапи](../README.md#навчальна-прогресія)

## Опис

Ця директорія містить Python скрипти-рішення (exploits) для всіх PWN завдань. Кожен solver демонструє як вирішити відповідне завдання та отримати flag.

## Структура

```
solver/
├── stage01_nc.py              # Базове підключення через pwntools
├── stage03_pwntools.py        # Використання pwntools API
├── stage04_demo_no_offset.py  # Buffer overflow з bruteforce
├── stage05_demo_with_hint.py  # Buffer overflow з підказкою
├── stage06_ret2win.py         # Ret2win техніка
├── stage07_leak_demo.py       # Витік адрес пам'яті
└── stage08_ret2libc.py        # Ret2libc експлойт
```

## Вимоги

Всі solver'и використовують бібліотеку pwntools:

```bash
pip install pwntools
```

## Використання

### Локальний запуск

```bash
# Запустіть відповідний Docker контейнер
cd pwn/
docker compose up -d stage01_nc

# Запустіть solver
python3 solver/stage01_nc.py
```

### Віддалений запуск

Для підключення до віддаленого сервера відредагуйте в скрипті:

```python
# Замість
io = remote('127.0.0.1', 7101)

# Використайте
io = remote('ctf.example.com', 1337)
```

## Типи solver'ів

### 1. Базове підключення ([stage01](../stage01_nc/README.md))
- Демонструє просте TCP підключення
- Відправка/отримання даних
- Базовий API pwntools

### 2. Pwntools API ([stage03](../stage03_pwntools/README.md))
- Використання helper функцій
- Робота з форматованими даними
- Debugging можливості

### 3. Buffer Overflow ([stage04](../stage04_demo_no_offset/README.md), [stage05](../stage05_demo_with_hint/README.md))
- Визначення offset для перезапису RIP
- Bruteforce vs підказка з адресою
- Базовий ROP

### 4. Ret2win ([stage06](../stage06_ret2win/README.md))
- Виклик прихованої функції
- Простий ROP chain
- Контроль виконання

### 5. Memory Leak ([stage07](../stage07_leak_demo/README.md))
- Витік адрес через format string або інше
- Обхід PIE/ASLR
- Використання витоків для побудови експлойту

### 6. Ret2libc ([stage08](../stage08_ret2libc/README.md))
- Витік адреси libc
- Визначення libc version
- ROP chain до system/execve
- Отримання shell

## Debugging

Для детального логування додайте на початок скрипта:

```python
context.log_level = 'debug'
```

Для локального дебагу з GDB:

```python
io = gdb.debug('./build/stage06_ret2win/stage06', '''
    break main
    continue
''')
```

## Best Practices

1. **Перевірка з'єднання**: Завжди використовуйте timeout для remote()
2. **Читаємість**: Коментуйте кожен крок експлойту
3. **Універсальність**: Використовуйте змінні для адрес та offset'ів
4. **Тестування**: Перевіряйте solver локально перед атакою віддаленого сервера

## Структура типового solver'а

```python
#!/usr/bin/env python3
from pwn import *

# Налаштування
context.arch = 'amd64'
context.log_level = 'info'

# Підключення
io = remote('127.0.0.1', 7106)

# 1. Leak адрес
io.recvuntil(b'leak: ')
leak = int(io.recvline().strip(), 16)

# 2. Розрахунок адрес
base = leak - 0x1234
target = base + 0x5678

# 3. Побудова payload
payload = b'A' * 40        # Padding
payload += p64(target)      # RIP

# 4. Відправка та отримання результату
io.sendline(payload)
io.interactive()
```

## Автоматичне тестування

Можна створити скрипт для тестування всіх solver'ів:

```bash
for solver in solver/*.py; do
    echo "Testing $solver..."
    python3 "$solver" || echo "FAILED: $solver"
done
```

## Примітки

- Solver'и розраховані на локальний запуск проти Docker контейнерів
- Для віддалених серверів може знадобитись адаптація offset'ів
- Деякі exploit'и використовують специфічні версії libc
- Завжди перевіряйте чи запущений відповідний контейнер перед запуском solver'а

---

## Див. також

- [scripts/extract_libc.sh](../scripts/README.md) - Як витягти libc для ret2libc
- [docker/README.md](../docker/README.md) - Безпека та seccomp обмеження
- [Всі етапи](../README.md#навчальна-прогресія) - Повний список завдань
- [pwntools документація](https://docs.pwntools.com/) - Офіційна документація

**[← Назад до головної](../README.md)**
