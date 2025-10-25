# PWN Challenges - Навчальний курс Binary Exploitation

**[⬅️ Назад до головної](../README.md)** | **[📊 Презентація](../slides/)** | **[🔍 RE завдання](../re/)**

---

## Про курс

Цей курс складається з **8 прогресивних етапів** навчання віддаленій експлуатації (remote PWN) бінарних вразливостей. Кожен етап будує знання на попередньому, від базової TCP взаємодії до повноцінного ret2libc експлойту.

## Швидкий старт

```bash
# 1. Скомпілювати всі завдання
make

# 2. Запустити Docker контейнери
docker compose up -d

# 3. Запустити solver для першого завдання
python3 solver/stage01_nc.py

# 4. Витягти libc для останнього етапу (опціонально)
./scripts/extract_libc.sh stage08
```

## Навчальна прогресія

### Початковий рівень

| Етап | Назва | Навички | Складність | Документація |
|------|-------|---------|------------|--------------|
| 1 | [nc - TCP взаємодія](stage01_nc/README.md) | Робота з netcat, TCP/IP | ⭐ Trivial | [Детальніше →](stage01_nc/README.md) |
| 2 | [checksec - Аналіз захистів](stage02_checksec/README.md) | NX, PIE, Canary, RELRO | ⭐ Trivial | [Детальніше →](stage02_checksec/README.md) |
| 3 | [pwntools - Автоматизація](stage03_pwntools/README.md) | Python, pwntools API | ⭐ Trivial | [Детальніше →](stage03_pwntools/README.md) |

### Базові експлойти

| Етап | Назва | Навички | Складність | Документація |
|------|-------|---------|------------|--------------|
| 4 | [Прямий виклик функції](stage04_demo_no_offset/README.md) | Адреси функцій, ELF parsing | ⭐⭐ Easy | [Детальніше →](stage04_demo_no_offset/README.md) |
| 5 | [Buffer Overflow з підказкою](stage05_demo_with_hint/README.md) | Stack layout, offset calculation | ⭐⭐ Easy | [Детальніше →](stage05_demo_with_hint/README.md) |
| 6 | [ret2win](stage06_ret2win/README.md) | Classic buffer overflow | ⭐⭐ Easy | [Детальніше →](stage06_ret2win/README.md) |

### Просунуті техніки

| Етап | Назва | Навички | Складність | Документація |
|------|-------|---------|------------|--------------|
| 7 | [Memory Leak](stage07_leak_demo/README.md) | ASLR bypass, address leaks | ⭐⭐⭐ Medium | [Детальніше →](stage07_leak_demo/README.md) |
| 8 | [ret2libc](stage08_ret2libc/README.md) | ROP chains, libc exploitation | ⭐⭐⭐ Medium | [Детальніше →](stage08_ret2libc/README.md) |

## Структура проєкту

```
pwn/
├── README.md                      # 📖 Ви тут - головна документація
│
├── stage01_nc/                    # 🎯 Завдання етапу 1
│   ├── README.md                  # Детальний опис та рішення
│   ├── stage01.c                  # Вихідний код
│   └── Makefile
├── stage02_checksec/              # 🎯 Завдання етапу 2
├── ...
├── stage08_ret2libc/              # 🎯 Завдання етапу 8
│
├── build/                         # 🔨 Скомпільовані бінарники
│   └── README.md                  # Про процес збірки
├── common/                        # 🔧 Спільний код (net.h)
│   └── README.md                  # API документація
├── docker/                        # 🐳 Docker та безпека
│   └── README.md                  # Security best practices
├── scripts/                       # 🛠️ Допоміжні скрипти
│   └── README.md                  # Використання скриптів
└── solver/                        # ✅ Готові рішення
    └── README.md                  # Як писати exploits

```

## Документація

### Для початківців
1. **Почніть тут:** [Stage 1 - TCP взаємодія](stage01_nc/README.md)
2. **Розуміння захистів:** [Stage 2 - Checksec](stage02_checksec/README.md)
3. **Перший експлойт:** [Stage 6 - ret2win](stage06_ret2win/README.md)

### Технічна документація
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - Детальні інструкції компіляції
- [COMPILATION_FLAGS.md](COMPILATION_FLAGS.md) - Пояснення прапорців компілятора
- [docker/README.md](docker/README.md) - Docker security та seccomp профілі
- [solver/README.md](solver/README.md) - Як писати exploits з pwntools

### Допоміжні ресурси
- [build/README.md](build/README.md) - Структура скомпільованих файлів
- [common/README.md](common/README.md) - Спільний код для мережі
- [scripts/README.md](scripts/README.md) - Скрипти (extract_libc.sh та інші)

## Основні концепції по етапах

### Етапи 1-3: Основи
- Підключення до TCP сервісів
- Розуміння binary protections
- Автоматизація з pwntools

### Етапи 4-6: Buffer Overflow
- Перезапис return address
- Контроль flow виконання
- Виклик функцій

### Етапи 7-8: Обхід захистів
- Витік адрес (ASLR bypass)
- ROP chains
- Ret2libc техніка

## Корисні команди

### Компіляція та запуск

```bash
# Компіляція
make                              # Всі завдання
make stage06_ret2win              # Конкретне завдання
make clean                        # Очистити build/

# Docker
docker compose up -d              # Запустити всі
docker compose up -d stage06      # Запустити одне
docker compose logs stage06       # Подивитись логи
docker compose down               # Зупинити всі
```

### Тестування

```bash
# Ручна взаємодія
nc 127.0.0.1 7101

# Автоматичні solver'и
python3 solver/stage01_nc.py
python3 solver/stage06_ret2win.py
python3 solver/stage08_ret2libc.py

# Аналіз бінарників
checksec build/stage06_ret2win/stage06
file build/stage06_ret2win/stage06
objdump -d build/stage06_ret2win/stage06
```

### Debugging

```bash
# GDB з pwndbg
gdb build/stage06_ret2win/stage06

# З pwntools
python3 -c "from pwn import *; gdb.debug('./build/stage06_ret2win/stage06', 'break main')"
```

## Порти сервісів

| Етап | Порт | Сервіс |
|------|------|--------|
| Stage 1 | 7101 | nc demo |
| Stage 3 | 7103 | pwntools demo |
| Stage 4 | 7104 | demo_no_offset |
| Stage 5 | 7105 | demo_with_hint |
| Stage 6 | 7106 | ret2win |
| Stage 7 | 7107 | leak_demo |
| Stage 8 | 7108 | ret2libc |

## Найчастіші питання

### Мій експлойт не працює
1. Перевірте чи запущений контейнер: `docker compose ps`
2. Перевірте offset - скористайтеся stage 5 для навчання
3. Переконайтесь що використовуєте правильну libc для stage 8

### Як знайти offset до RIP?
```python
# Спосіб 1: Stage 5 підкаже автоматично
# Спосіб 2: Використати cyclic pattern
from pwn import *
pattern = cyclic(200)
# Відправити pattern, знайти crash offset
cyclic_find(0x6161616161616162)  # Знайде позицію
```

### Як дізнатись версію libc?
```bash
# Витягти з контейнера
./scripts/extract_libc.sh stage08

# Перевірити версію
./extracted/libc.so.6
strings ./extracted/libc.so.6 | grep "GNU C Library"
```

## Навчальні ресурси

### Інструменти
- [pwntools](https://github.com/Gallopsled/pwntools) - Python фреймворк для exploits
- [pwndbg](https://github.com/pwndbg/pwndbg) - GDB плагін для PWN
- [ROPgadget](https://github.com/JonathanSalwan/ROPgadget) - Пошук ROP gadgets
- [checksec](https://github.com/slimm609/checksec.sh) - Аналіз захистів

### Курси та практика
- [pwn.college](https://pwn.college/) - Інтерактивне навчання
- [Exploit Education: Phoenix](https://exploit.education/phoenix/) - Практичні завдання по бінарній експлуатації
- [ROP Emporium](https://ropemporium.com/) - ROP челенджі
- [Nightmare](https://guyinatuxedo.github.io/) - Детальний курс

### Документація
- [pwntools docs](https://docs.pwntools.com/) - Офіційна документація
- [Linux syscalls](https://filippo.io/linux-syscall-table/) - Таблиця syscall

## Що далі?

Після завершення всіх 8 етапів ви матимете базу для:
- Участі в CTF змаганнях (категорія PWN)
- Створення власних PWN завдань
- Вивчення kernel exploitation
- Дослідження heap exploitation

Рекомендовані напрямки для подальшого вивчення:
1. **Heap exploitation** - use-after-free, heap overflow
2. **Format string** - витік та запис через format strings
3. **Kernel PWN** - експлуатація вразливостей ядра
4. **ARM/MIPS** - інші архітектури
