# Створення завдань RE/PWN для CTF

Навчальні матеріали з реверс-інжинірингу (RE) та бінарної експлуатації (PWN) для організаторів CTF змагань.

## 📖 Про проєкт

Цей репозиторій містить:
- **Презентацію** з методології створення RE/PWN завдань
- **7 RE завдань** з прогресивною складністю
- **8 PWN завдань** від базових до просунутих

Усі матеріали призначені для навчання та створення власних CTF челенджів.

## ⚡ Quick Start

### Автоматичне встановлення

**Linux / WSL:**
```bash
./setup_linux.sh    # Встановити всі інструменти
./test_all.sh       # Протестувати все
```

**Windows:**
```powershell
.\setup_windows.ps1  # Встановити WSL2 + Ubuntu + інструменти
.\test_all.ps1       # Протестувати все
```

### Швидкий старт з завданнями

**RE завдання:**
```bash
cd re/task01_inventory
make
./build/re101 --hello
```

**PWN завдання:**
```bash
cd pwn
make                      # Компіляція
docker compose up -d      # Запуск серверів
python3 solver/stage01_nc.py
```

**Презентація:**
```bash
cd slides

# Windows (PowerShell)
.\run_win.ps1

# Linux/macOS
./run_nix.sh

# Або вручну
npm install && npm run dev

# Або відкрийте slides/slides.pdf
```

---

## 🎯 Структура проєкту

```
repwn/
├── slides/           # 📊 Презентація (Slidev)
├── re/               # 🔍 RE завдання (7 tasks)
└── pwn/              # 💥 PWN завдання (8 stages)
```

## 🚀 Швидкий старт

### 📊 Презентація

Презентація створена на базі [Slidev](https://sli.dev) - сучасного фреймворку для презентацій з Markdown.

```bash
cd slides
npm install
npm run dev
```

Детальніше: [slides/README.md](slides/README.md)

**Альтернатива:** Завантажте готовий PDF - `slides/slides.pdf`

---

### 🔍 RE (Reverse Engineering)

7 навчальних завдань з реверс-інжинірингу від базового до просунутого рівня.

#### Прогресія навчання:

| # | Завдання | Інструменти | Складність |
|---|----------|-------------|------------|
| 1 | [Інвентаризація ELF](re/task01_inventory/) | file, readelf, strings | ⭐ Trivial |
| 2 | [Hardcoded Strings](re/task02_hardcoded_strings/) | strings, grep | ⭐ Trivial |
| 3 | [ROT13 + GDB](re/task03_rot13_gdb/) | gdb, breakpoints | ⭐⭐ Easy |
| 4 | [ROT-N + Ghidra](re/task04_rotn_strlen_ghidra/) | Ghidra | ⭐⭐ Easy |
| 5 | [Time-based Keygen](re/task05_rotn_time_keygen/) | Python | ⭐⭐⭐ Medium |
| 6 | [UPX Packer](re/task06_upx_packer/) | UPX | ⭐⭐⭐ Medium |
| 7 | [Hidden HTTP](re/task07_hidden_http_strace/) | strace, curl | ⭐⭐⭐ Medium |

```bash
cd re
# Дивіться README.md для детальних інструкцій
```

Детальніше: [re/README.md](re/README.md)

---

### 💥 PWN (Binary Exploitation)

8 етапів навчання експлуатації бінарних вразливостей через мережу.

#### Прогресія навчання:

| # | Завдання | Навички | Складність |
|---|----------|---------|------------|
| 1 | [nc - TCP взаємодія](pwn/stage01_nc/) | netcat | ⭐ Trivial |
| 2 | [checksec](pwn/stage02_checksec/) | Аналіз захистів | ⭐ Trivial |
| 3 | [pwntools](pwn/stage03_pwntools/) | Автоматизація | ⭐ Trivial |
| 4 | [Прямий виклик](pwn/stage04_demo_no_offset/) | ELF parsing | ⭐⭐ Easy |
| 5 | [Buffer Overflow + hint](pwn/stage05_demo_with_hint/) | Stack layout | ⭐⭐ Easy |
| 6 | [ret2win](pwn/stage06_ret2win/) | Classic BOF | ⭐⭐ Easy |
| 7 | [Memory Leak](pwn/stage07_leak_demo/) | ASLR bypass | ⭐⭐⭐ Medium |
| 8 | [ret2libc](pwn/stage08_ret2libc/) | ROP chains | ⭐⭐⭐ Medium |

```bash
cd pwn
make                    # Компіляція
docker compose up -d    # Запуск сервісів
# Дивіться README.md для детальних інструкцій
```

Детальніше: [pwn/README.md](pwn/README.md)

---

## 🛠️ Технології

- **Презентація**: [Slidev](https://sli.dev) - Markdown-based презентації
- **RE завдання**: C, Makefile, UPX, obfuscation
- **PWN завдання**: C, Docker, Python, pwntools
- **Аналіз**: GDB, Ghidra, strace, checksec

## 📚 Для кого цей курс?

### Ви організатор CTF?
Використовуйте ці завдання як шаблон для створення власних челенджів.

### Ви викладач?
Презентація та завдання готові для використання в курсі з кібербезпеки.

### Ви вивчаєте RE/PWN?
Пройдіть усі завдання послідовно - від простих до складних.

## 🎓 Навчальна прогресія

### RE курс (7 завдань)
1. **Tasks 1-2**: Статичний аналіз (file, strings, readelf)
2. **Tasks 3-4**: Динамічний аналіз (GDB, Ghidra)
3. **Tasks 5-7**: Просунуті техніки (кейгени, пакери, трасування)

### PWN курс (8 етапів)
1. **Stages 1-3**: Основи (TCP, checksec, pwntools)
2. **Stages 4-6**: Buffer overflow (direct call, ret2win)
3. **Stages 7-8**: Обхід захистів (ASLR bypass, ret2libc)

## 📖 Додаткові ресурси

### Інструменти
- [Ghidra](https://ghidra-sre.org/) - Декомпілятор від NSA
- [pwntools](https://github.com/Gallopsled/pwntools) - Python фреймворк
- [pwndbg](https://github.com/pwndbg/pwndbg) - Покращений GDB

### Практика
- [pwn.college](https://pwn.college/) - Інтерактивне навчання
- [Crackmes.one](https://crackmes.one/) - RE челенджі
- [ROP Emporium](https://ropemporium.com/) - ROP практика

### Курси
- [Nightmare](https://guyinatuxedo.github.io/) - Детальний курс RE/PWN
- [Exploit Education](https://exploit.education/) - Практичні завдання

## 📋 Вимоги

### Для RE завдань:
```bash
# Linux (Ubuntu/Debian)
sudo apt install build-essential binutils gdb ltrace strace upx-ucl
# + Ghidra (завантажити окремо)
```

### Для PWN завдань:
```bash
# Linux (Ubuntu/Debian)
sudo apt install build-essential docker.io docker-compose
pip3 install pwntools
```

## 🗂️ Детальна структура

```
repwn/
│
├── slides/                         # Презентація
│   ├── slides.md                   # Контент презентації
│   ├── slides.pdf                  # PDF версія
│   ├── run_win.bat                 # Запуск на Windows
│   ├── run_nix.sh                  # Запуск на Linux/macOS
│   └── README.md                   # Інструкції
│
├── re/                             # RE завдання
│   ├── task01_inventory/           # Базовий аналіз
│   ├── task02_hardcoded_strings/   # Пошук рядків
│   ├── task03_rot13_gdb/           # GDB дебагінг
│   ├── task04_rotn_strlen_ghidra/  # Ghidra декомпіляція
│   ├── task05_rotn_time_keygen/    # Написання кейгена
│   ├── task06_upx_packer/          # Розпакування UPX
│   ├── task07_hidden_http_strace/  # Трасування syscalls
│   └── README.md                   # Головна документація RE
│
└── pwn/                            # PWN завдання
    ├── stage01_nc/                 # TCP взаємодія
    ├── stage02_checksec/           # Аналіз захистів
    ├── stage03_pwntools/           # Python автоматизація
    ├── stage04_demo_no_offset/     # Прямий виклик функції
    ├── stage05_demo_with_hint/     # Buffer overflow з підказкою
    ├── stage06_ret2win/            # Classic ret2win
    ├── stage07_leak_demo/          # Memory leak
    ├── stage08_ret2libc/           # ROP chains
    ├── docker/                     # Docker конфігурація
    ├── solver/                     # Готові рішення
    ├── scripts/                    # Допоміжні скрипти
    └── README.md                   # Головна документація PWN
```

## 🎯 Що далі?

Після завершення курсу ви зможете:
- ✅ Створювати власні RE/PWN завдання для CTF
- ✅ Розуміти методологію розробки челенджів
- ✅ Застосовувати прогресивну складність
- ✅ Використовувати сучасні інструменти аналізу
- ✅ Організовувати навчальні CTF події

---

**Навчальний проєкт** | Створено для освітніх цілей
