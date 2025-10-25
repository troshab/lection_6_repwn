# Task 06: UPX Packer (Пакування бінарників)

## 📋 Опис завдання

Бінарник **запакований** за допомогою UPX! Звичайні методи аналізу не спрацюють. Навчіться розпізнавати та розпаковувати упаковані файли.

**Рівень:** ⭐⭐⭐ Середній | **Категорія:** Packing, Unpacking, Obfuscation

## 🎯 Навчальна мета

- Розпізнавати запаковані бінарники
- Використовувати UPX для розпакування
- Розуміти чому пакування ускладнює аналіз
- Аналізувати розпаковані файли

## 📚 Що таке UPX?

**UPX (Ultimate Packer for eXecutables)** - безкоштовний пакувальник виконуваних файлів.

**Що робить:**
- Стискає бінарник (50-70% зменшення розміру)
- Додає розпаковувач (stub)
- При запуску: розпаковує в пам'ять → виконує

**Чому використовується:**
- ✅ Законно: зменшення розміру файлів
- ❌ Малвар: приховування від антивірусів
- ❌ Крекінг: ускладнення реверсу

## 🛠️ Підготовка

### Встановлення UPX

```bash
# Ubuntu/Debian
sudo apt install upx-ucl

# Fedora
sudo dnf install upx

# Arch
sudo pacman -S upx

# Manual download
https://github.com/upx/upx/releases
```

### Збірка та пакування

```bash
cd task06_upx_packer
./build.sh
# Скрипт запропонує запакувати через UPX

# Або вручну:
make clean && make
upx -9 build/re106 -o build/re106_packed
```

## 🔍 Покрокове рішення

### Крок 1: Розпізнавання упакованого файлу

```bash
file build/re106_packed
```

**Вивід:**
```
build/re106_packed: ELF 64-bit LSB executable, x86-64, version 1 (SYSV),
dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, stripped
```

Hmm, виглядає нормально... Але спробуємо `strings`:

```bash
strings -a build/re106_packed | head -n 20
```

**Вивід:**
```
UPX!
$Info: This file is packed with the UPX executable packer http://upx.sf.net $
...
```

**Ага!** Бачимо `UPX!` - файл упакований!

### Крок 2: Порівняння розмірів

```bash
ls -lh build/re106 build/re106_packed
```

**Вивід:**
```
-rwxr-xr-x 1 user user 16K build/re106
-rwxr-xr-x 1 user user 7.2K build/re106_packed
```

Упакований файл на 55% менший!

### Крок 3: Спроба аналізу БЕЗ розпакування (FAIL)

```bash
# Strings не покаже корисного
strings -a build/re106_packed | grep -i serial
# Майже нічого корисного...

# Ghidra показує stub код, не оригінальний
# IDA показує розпаковувач, не логіку програми
```

### Крок 4: Розпакування через UPX

```bash
upx -d build/re106_packed -o build/re106_unpacked
```

**Вивід:**
```
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2023
UPX 4.2.1       Markus Oberhumer, Laszlo Molnar & John Reiser    Nov 1st 2023

        File size         Ratio      Format      Name
   --------------------   ------   -----------   ---------------------
     16384 <-      7368   44.97%   linux/amd64   re106_unpacked

Unpacked 1 file.
```

### Крок 5: Аналіз розпакованого файлу

Тепер файл розпакований - можна аналізувати як звичайно!

```bash
strings -a build/re106_unpacked | grep -i "KEY\|SERIAL"
```

**Вивід:**
```
PACKED-KEY-9000
```

**Знайшли ключ!**

### Крок 6: Перевірка

```bash
./build/re106_unpacked Alice PACKED-KEY-9000
# FLAG{task6_ok_Alice}
```

🎉 **Успіх!**

**Важливо:** Упакований файл (`re106_packed`) також працює:

```bash
./build/re106_packed Alice PACKED-KEY-9000
# FLAG{task6_ok_Alice}
```

Але аналізувати потрібно **розпакований**!

## 🎓 Детальний аналіз UPX

### Як працює UPX

```
Оригінальний файл → Стискання → Додавання stub → Упакований файл
     (re106)                                        (re106_packed)

При запуску:
1. Stub розпаковує в пам'ять
2. Передає управління оригінальному коду
3. Програма працює нормально
```

### Виявлення UPX

#### Метод 1: strings

```bash
strings -a binary | grep -i upx
```

#### Метод 2: Секції з назвою UPX

```bash
readelf -S binary | grep UPX
```

**Вивід:**
```
[13] UPX0            PROGBITS  ...
[14] UPX1            PROGBITS  ...
```

#### Метод 3: Entropy аналіз

Упаковані файли мають високу ентропію (виглядають як випадкові дані).

```bash
# З використанням binwalk
binwalk -E binary

# З використанням detect-it-easy
die binary
```

### UPX опції

```bash
# Пакування з максимальним стисненням
upx -9 binary

# Пакування з найкращим stisненням (повільніше)
upx --best --ultra-brute binary

# Розпакування
upx -d packed_binary

# Тестування (не змінює файл)
upx -t binary

# Інформація про упакований файл
upx -l packed_binary
```

### Захист від розпакування

UPX підтримує опцію `--no-backup` та модифікацію заголовків:

```bash
# Пакування з модифікованим заголовком
upx -9 --no-backup binary
# Потім hex-редактором змінити "UPX!" сигнатуру

# Тепер upx -d не спрацює автоматично!
```

**Обхід:** Вручну відновити сигнатуру або розпакувати в пам'яті через дебагер.

## 💡 Інші пакувальники

### Popular packers:

1. **UPX** (open-source, найпопулярніший)
2. **Themida** (комерційний, дуже складний)
3. **VMProtect** (віртуалізація коду)
4. **ASPack** (для Windows)
5. **PECompact** (для Windows)

### Універсальні розпаковувачі:

- **Detect It Easy (DiE)** - визначення пакувальника
- **PE Explorer** - аналіз PE файлів
- **CFF Explorer** - детальний аналіз структур

## 🐛 Advanced Troubleshooting (Просунуте)

### UPX видалив сигнатуру (modified UPX)

Іноді малвар автори модифікують UPX, видаляючи сигнатуру "UPX!".

**Виявлення:**
```bash
# Strings не показує "UPX"
strings -a binary | grep -i upx
# (порожній вивід)

# Але ентропія висока (стиснений файл)
# Секції мають підозрілі назви
readelf -S binary
```

**Рішення 1: Спроба розпакування все одно:**
```bash
upx -d binary
# Може спрацювати якщо змінена тільки сигнатура
```

**Рішення 2: Відновлення сигнатури:**
```bash
# Знайти offset де має бути "UPX!"
xxd binary | grep -i "00.*00.*00"

# Відредагувати hex редактором (ghex, hexedit)
# Додати байти: 55 50 58 21 (hex для "UPX!")

# Спробувати розпакувати
upx -d binary
```

**Рішення 3: Розпакування в пам'яті:**
```bash
# Запустити через GDB
gdb binary

# Встановити breakpoint після розпакування
# (шукати виклик jmp до оригінального entry point)
break *0x400000  # Приблизний entry point

# Дампнути розпакований код з пам'яті
dump memory unpacked.bin 0x400000 0x500000
```

### Помилка: "NotPackedException: not packed by UPX"

**Причина:**
- Файл не упакований UPX
- Або сигнатура пошкоджена
- Або використана нестандартна версія UPX

**Діагностика:**
```bash
# Перевірка entropy
binwalk -E binary
# Упакований файл має високу ентропію (близько 7-8)

# Перевірка секцій
readelf -S binary | head -20
# Шукаємо секції UPX0, UPX1, тощо
```

**Рішення:**
- Якщо є секції UPXn - спробуйте старішу версію UPX
- Спробуйте різні флаги: `upx -d --force binary`

### UPX розпакував, але бінарник не запускається

**Причина:** UPX іноді псує бінарник при розпакуванні

**Діагностика:**
```bash
# Перевірка валідності ELF
file unpacked_binary

# Перевірка integrity
readelf -h unpacked_binary

# Запуск через strace для деталей
strace ./unpacked_binary
```

**Рішення:**
```bash
# Спробувати -k (keep broken output)
upx -d --keep-broken binary -o unpacked

# Або -f (force overwrite)
upx -d -f binary
```

### Визначення модифікованого UPX

**Інструменти для виявлення:**

1. **Detect It Easy (DiE):**
```bash
die binary
# Покаже: "UPX (modified)" якщо модифікований
```

2. **PEiD signatures (для Windows, але концепція та сама):**
- Створити кастомну сигнатуру
- Порівняти з known good UPX

3. **Manual analysis:**
```bash
# Порівняти структуру з оригінальним UPX
hexdump -C original_upx.packed > orig.hex
hexdump -C modified_upx.packed > modi.hex
diff orig.hex modi.hex
```

### Альтернативи якщо UPX не працює

**Якщо UPX розпакування не спрацьовує:**

1. **Generic unpacker:**
```bash
# Використати PIN (dynamic instrumentation)
# Дампнути пам'ять після розпакування
```

2. **Ручне розпакування через GDB:**
```bash
gdb binary
break _start
run
# Прокрутити до оригінального коду
# Дампнути memory
```

3. **Automated unpackers:**
- **unipacker** (Python tool for automatic unpacking)
- **de4dot** (для .NET)
- **RDG Packer Detector**

## 🏁 Чеклист

- [ ] Встановив UPX
- [ ] Зібрав `build/re106`
- [ ] Запакував через `upx -9`
- [ ] Розпізнав упакований файл (`strings | grep UPX`)
- [ ] Розпакував через `upx -d`
- [ ] Проаналізував розпакований файл
- [ ] Знайшов ключ `PACKED-KEY-9000`
- [ ] Отримав FLAG
- [ ] (Бонус) Зрозумів як виявити modified UPX

## 📖 Ресурси

- [UPX Official](https://upx.github.io/)
- [UPX GitHub](https://github.com/upx/upx)
- [Detect It Easy](https://github.com/horsicq/Detect-It-Easy)
- [Unpacking Tutorial](https://www.youtube.com/watch?v=X3giMAGMf8E)

## 🎯 Наступний крок

**Task 07** - Прихований HTTP сервер! Потрібен `strace` для виявлення мережевої активності!

---
**Складність:** ⭐⭐⭐ | **Час:** 30-45 хв | **FLAG:** `FLAG{task6_ok_<name>}`
