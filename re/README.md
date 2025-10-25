# RE Challenges - Навчальний курс Reverse Engineering

**[⬅️ Назад до головної](../README.md)** | **[📊 Презентація](../slides/)** | **[💥 PWN завдання](../pwn/)**

---

## Про курс

Цей курс складається з **7 прогресивних завдань** з реверс-інжинірингу. Кожне завдання демонструє конкретні техніки аналізу бінарних файлів та методи захисту/обфускації.

## Швидкий старт

```bash
# 1. Перейти в директорію завдання
cd task01_inventory

# 2. Зібрати бінарник
make

# 3. Аналізувати бінарник
file build/re101
strings -a build/re101
./build/re101
```

## Навчальна прогресія

### Базовий рівень - Статичний аналіз

| Task | Назва | Інструменти | Складність | Документація |
|------|-------|-------------|------------|--------------|
| 1 | [Інвентаризація ELF](task01_inventory/README.md) | file, readelf, objdump, strings | ⭐ Trivial | [Детальніше →](task01_inventory/README.md) |
| 2 | [Hardcoded Strings](task02_hardcoded_strings/README.md) | strings, grep | ⭐ Trivial | [Детальніше →](task02_hardcoded_strings/README.md) |

### Середній рівень - Динамічний аналіз

| Task | Назва | Інструменти | Складність | Документація |
|------|-------|-------------|------------|--------------|
| 3 | [ROT13 + GDB](task03_rot13_gdb/README.md) | gdb, breakpoints | ⭐⭐ Easy | [Детальніше →](task03_rot13_gdb/README.md) |
| 4 | [ROT-N + Ghidra](task04_rotn_strlen_ghidra/README.md) | Ghidra, декомпіляція | ⭐⭐ Easy | [Детальніше →](task04_rotn_strlen_ghidra/README.md) |

### Просунутий рівень - Кейгени та обфускація

| Task | Назва | Інструменти | Складність | Документація |
|------|-------|-------------|------------|--------------|
| 5 | [Time-based Keygen](task05_rotn_time_keygen/README.md) | Python, алгоритми | ⭐⭐⭐ Medium | [Детальніше →](task05_rotn_time_keygen/README.md) |
| 6 | [UPX Packer](task06_upx_packer/README.md) | UPX, розпакування | ⭐⭐⭐ Medium | [Детальніше →](task06_upx_packer/README.md) |
| 7 | [Hidden HTTP Server](task07_hidden_http_strace/README.md) | strace, curl, мережа | ⭐⭐⭐ Medium | [Детальніше →](task07_hidden_http_strace/README.md) |

## Структура проєкту

```
re/
├── README.md                          # 📖 Ви тут - головна документація
│
├── task01_inventory/                  # 🎯 Базовий аналіз ELF
│   ├── README.md                      # Детальний туторіал
│   ├── Makefile
│   ├── src/
│   └── build/
│
├── task02_hardcoded_strings/          # 🎯 Пошук жорстко вшитих рядків
├── task03_rot13_gdb/                  # 🎯 Динамічний аналіз з GDB
├── task04_rotn_strlen_ghidra/         # 🎯 Декомпіляція з Ghidra
├── task05_rotn_time_keygen/           # 🎯 Написання кейгена
├── task06_upx_packer/                 # 🎯 Робота з пакувальниками
└── task07_hidden_http_strace/         # 🎯 Трасування системних викликів
```

## Основні концепції по рівнях

### Tasks 1-2: Статичний аналіз
- Визначення типу файлу
- Аналіз структури ELF
- Витягування рядків
- Пошук hardcoded secrets

### Tasks 3-4: Динамічний аналіз та декомпіляція
- Використання GDB для дебагінгу
- Встановлення breakpoints
- Дослідження пам'яті
- Декомпіляція через Ghidra

### Tasks 5-7: Просунуті техніки
- Написання кейгенів
- Розуміння алгоритмів шифрування
- Робота з пакувальниками
- Трасування системних викликів
- Аналіз мережевої активності

## Корисні команди

### Базові утиліти

```bash
# Визначення типу файлу
file build/re101

# Витягування рядків
strings -a build/re101
strings -a build/re101 | grep -i flag

# Аналіз ELF
readelf -h build/re101        # ELF заголовок
readelf -l build/re101        # Program headers
readelf -S build/re101        # Section headers

# Символи
objdump -T build/re101        # Динамічні символи
nm build/re101                # Всі символи

# Дизасемблювання
objdump -d build/re101        # Весь код
objdump -d build/re101 | grep -A 20 "<main>:"
```

### Debugging з GDB

```bash
# Запуск GDB
gdb build/re103

# В GDB:
(gdb) info functions          # Список функцій
(gdb) break strcmp            # Breakpoint перед strcmp
(gdb) run Alice TEST          # Запуск з аргументами
(gdb) x/s $rdi               # Подивитись рядок в rdi
(gdb) info registers         # Всі регістри
(gdb) continue               # Продовжити виконання
```

### Трасування

```bash
# Трасування системних викликів
strace -f -e trace=%network ./build/re107 Alice

# Трасування бібліотечних викликів
ltrace ./build/re103 Alice TEST
```

### Ghidra

1. Відкрити Ghidra
2. File → Import File → вибрати бінарник
3. Analysis → Auto Analyze
4. Знайти main функцію в Symbol Tree
5. Подивитись декомпільований код

## Встановлення інструментів

### Ubuntu/Debian

```bash
# Базові інструменти
sudo apt update
sudo apt install build-essential binutils gdb

# Додаткові інструменти
sudo apt install ltrace strace curl upx-ucl

# Ghidra (завантажити з https://ghidra-sre.org/)
# Або через snap:
sudo snap install ghidra

# Покращений GDB
pip3 install pwntools
git clone https://github.com/pwndbg/pwndbg
cd pwndbg && ./setup.sh
```

## Навчальні ресурси

### Інструменти
- [Ghidra](https://ghidra-sre.org/) - Безкоштовний декомпілятор від NSA
- [GDB](https://sourceware.org/gdb/) - GNU Debugger
- [pwndbg](https://github.com/pwndbg/pwndbg) - Покращений GDB для RE/PWN
- [radare2](https://github.com/radareorg/radare2) - CLI фреймворк для RE
- [IDA Free](https://hex-rays.com/ida-free/) - Популярний дизасемблер

### Курси та практика
- [Exploit Education: Phoenix](https://exploit.education/phoenix/) - Практичні завдання
- [Nightmare](https://guyinatuxedo.github.io/) - Детальний курс по RE та PWN
- [Crackmes.one](https://crackmes.one/) - Колекція RE челенджів
- [Reverse Engineering for Beginners](https://beginners.re/) - Книга Dennis Yurichev

### Документація
- [ELF Format Specification](https://refspecs.linuxfoundation.org/elf/elf.pdf)
- [x86-64 Calling Convention](https://en.wikipedia.org/wiki/X86_calling_conventions)
- `man gdb`, `man readelf`, `man objdump` - Локальна документація

## Найчастіші питання

### Як почати якщо я новачок?
Починайте з Task 1 - там є детальні пояснення для абсолютних новачків, включаючи базову роботу з терміналом.

### Які інструменти обов'язкові?
Для базових завдань (1-3): `file`, `strings`, `readelf`, `objdump`, `gdb`
Для просунутих (4-7): Ghidra, strace, Python, upx

### Як встановити Ghidra?
1. Завантажити з https://ghidra-sre.org/
2. Розпакувати архів
3. Запустити `./ghidraRun` (потрібна Java 11+)

Або через snap: `sudo snap install ghidra`

### Мій GDB виглядає інакше
Це нормально! GDB має різні фронтенди:
- Стандартний GDB - базовий інтерфейс
- pwndbg - покращений для CTF
- gef - альтернатива pwndbg

### Що таке "stripped" binary?
- **Not stripped** - містить назви функцій → легко аналізувати
- **Stripped** - назви функцій видалені → важче аналізувати
- Команда `strip` видаляє символи для зменшення розміру

### Як знайти FLAG в завданні?
Кожне завдання має свій підхід - читайте README кожного task. Загалом:
- Task 1-2: статичний аналіз (strings)
- Task 3-4: динамічний аналіз (gdb/ghidra)
- Task 5-7: розуміння алгоритму та написання solver'а

## Прогресія навичок

Після завершення курсу ви вмітимете:

1. **Базовий аналіз** (Tasks 1-2)
   - Інвентаризація невідомих бінарників
   - Витягування корисної інформації
   - Статичний аналіз

2. **Динамічний аналіз** (Tasks 3-4)
   - Використання GDB для дебагінгу
   - Декомпіляція через Ghidra
   - Розуміння calling conventions

3. **Просунуті техніки** (Tasks 5-7)
   - Написання кейгенів
   - Робота з обфускацією
   - Трасування системних викликів
   - Аналіз мережевої активності

## Що далі?

Після завершення всіх 7 завдань ви матимете базу для:
- Участі в CTF змаганнях (категорія RE)
- Аналізу malware (з етичними цілями!)
- Пошуку вразливостей в бінарниках
- Вивчення антивірусних обходів
- Створення власних RE завдань

### Рекомендовані напрямки:
1. **Malware Analysis** - аналіз зловмисного ПЗ
2. **Mobile RE** - Android/iOS reverse engineering
3. **Game Hacking** - модифікація ігор
4. **Firmware Analysis** - аналіз прошивок IoT
5. **Kernel RE** - реверс-інжиніринг ядра ОС

---

Приємного навчання!
