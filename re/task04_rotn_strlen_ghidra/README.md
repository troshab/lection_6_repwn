# Task 04: ROT-N (strlen) + Ghidra

## 📋 Опис завдання

Зсув вже НЕ фіксований! Тепер `N = strlen(name) % 26`. Потрібен **Ghidra** для декомпіляції та статичного аналізу коду.

**Рівень:** ⭐⭐⭐ Середній | **Категорія:** Статична декомпіляція

## 🎯 Навчальна мета

- Використовувати Ghidra для декомп

іляції
- Аналізувати декомпільований C код
- Знаходити алгоритм генерації ключа
- Створювати кастомний кейген

## 📚 Що змінилося?

**Task 03:** `serial = ROT13(name)` - завжди зсув 13
**Task 04:** `serial = ROT-N(name)` де `N = strlen(name) % 26` - залежить від довжини!

**Приклади:**
- `Alice` (5 букв) → `ROT-5` → `Fqnhj`
- `Bob` (3 букви) → `ROT-3` → `Ere`

## 🛠️ Підготовка

### Встановлення Ghidra

```bash
# Скачати з офіційного сайту
https://ghidra-sre.org/

# Або через пакетний менеджер
# Ubuntu/Debian
sudo apt install ghidra

# Arch
yay -S ghidra
```

**Потрібно:** Java 17+

### Збірка бінарника

```bash
cd task04_rotn_strlen_ghidra
./build.sh
```

## 🔍 Покрокове рішення

### Крок 1: Спроба угадування (не спрацює)

```bash
./build/re104 Alice Nyvpr
# nope  (ROT13 вже не працює!)
```

### Крок 2: Аналіз через GDB (можна, але складно)

```gdb
gdb build/re104
(gdb) break strcmp
(gdb) run Alice TEST
(gdb) x/s $rdi
0x...: "Fqnhj"     # Не ROT13!
```

Бачимо інший результат - потрібно зрозуміти алгоритм!

### Крок 3: Відкрити у Ghidra

1. Запустіть Ghidra
2. Create New Project
3. Import File → виберіть `build/re104`
4. Double-click на файл → Auto-analyze (Yes)

### Крок 4: Знайти функцію main

У **Symbol Tree** зліва:
```
Functions → main
```

Double-click на `main`.

### Крок 5: Аналіз декомпільованого коду

**Decompile вікно** покаже щось подібне:

```c
undefined8 main(int argc, char **argv)
{
  int iVar1;
  size_t nameLen;
  char *name;
  char *serial;
  void *buffer;

  if (argc != 3) {
    fprintf(stderr, "usage: %s <name> <serial>\n", *argv);
    return 1;
  }

  name = argv[1];
  serial = argv[2];
  nameLen = strlen(name);        // ← ВАЖЛИВО!
  int N = (int)nameLen % 26;     // ← ЦЕ ФОРМУЛА ЗСУВУ!

  buffer = calloc(nameLen + 1, 1);
  rot_apply(buffer, name, N);     // ← ROT-N де N = strlen % 26

  iVar1 = strcmp(buffer, serial);
  if (iVar1 == 0) {
    printf("FLAG{task4_ok_%s}\n", name);
  } else {
    puts("nope");
  }
  free(buffer);
  return (iVar1 != 0) * 2;
}
```

### Крок 6: Зрозуміти алгоритм

```c
N = strlen(name) % 26
serial = ROT-N(name)
```

**Для "Alice":**
- `strlen("Alice") = 5`
- `N = 5 % 26 = 5`
- `serial = ROT-5("Alice")`

### Крок 7: Написати кейген

**Python:**
```python
def rot_n(text, n):
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr((ord(char) - ord('a') + n) % 26 + ord('a')))
        elif 'A' <= char <= 'Z':
            result.append(chr((ord(char) - ord('A') + n) % 26 + ord('A')))
        else:
            result.append(char)
    return ''.join(result)

name = "Alice"
n = len(name) % 26  # 5
serial = rot_n(name, n)
print(f"Name: {name}")
print(f"N: {n}")
print(f"Serial: {serial}")
```

**Вивід:**
```
Name: Alice
N: 5
Serial: Fqnhj
```

### Крок 8: Перевірка

```bash
./build/re104 Alice Fqnhj
# FLAG{task4_ok_Alice}
```

🎉 **Успіх!**

## 🎓 Ghidra Основи

### Інтерфейс Ghidra (детально для новачків)

Після відкриття файлу в Ghidra ви побачите **CodeBrowser** - головне вікно з трьома основними панелями:

```
┌─────────────────────────────────────────────────────────────┐
│ Меню: File Edit Navigation ... │ Tool │ Window │ Help     │
├──────────────┬──────────────────┬─────────────────────────────┤
│ Symbol Tree  │   Listing        │   Decompile                 │
│ (Functions)  │   (Assembly)     │   (C Code)                  │
│              │                  │                             │
│ 📁 Functions │  00400530  push  │  undefined8 main(int argc,  │
│  ├─ main     │  00400531  mov   │      char **argv)           │
│  ├─ rot_apply│  00400534  sub   │  {                          │
│  └─ strcmp   │  ...              │    if (argc != 3) {        │
│              │                  │      fprintf(...);          │
│ 📁 Imports   │                  │    }                        │
│  ├─ strlen   │                  │    ...                      │
│  └─ strcmp   │                  │  }                          │
└──────────────┴──────────────────┴─────────────────────────────┘
```

### Панелі інтерфейсу

#### Symbol Tree (ліва панель)

Це дерево символів - навігатор по всьому бінарнику.

**Основні розділи:**

1. **Functions** 📁 - всі функції у програмі
   - Розгорніть клацнувши на `▶ Functions`
   - Побачите список: `main`, `rot_apply`, `rot_shift` тощо
   - **Подвійний клік** на функції відкриє її в інших панелях

2. **Imports** 📁 - функції з зовнішніх бібліотек
   - Наприклад: `strlen`, `strcmp`, `printf` з libc
   - Це функції, які програма викликає, але їх код не в бінарнику

3. **Exports** 📁 - функції, які експортуються (рідко для простих програм)

4. **Data** 📁 - глобальні змінні та константи

**Як користуватись:**
- Розгортання папок: клік на `▶`
- Перехід до функції: **подвійний клік** на назві
- Пошук: `Ctrl+Shift+F` для пошуку тексту

#### Listing (центральна панель)

Показує **асемблерний код** - низькорівневі інструкції процесора.

**Формат:**
```
Адреса     Інструкція        Аргументи
00400530:  push              rbp
00400531:  mov               rbp, rsp
00400534:  sub               rsp, 0x20
```

**Колонки:**
- `00400530` - адреса в пам'яті (hex)
- `push` - інструкція асемблера
- `rbp` - регістр процесора

**Навігація:**
- Прокручуйте мишкою або клавішами `↑↓`
- Клік на адресу підсвітить пов'язаний C код
- **Зелений колір** - коментарі Ghidra

#### Decompile (права панель)

**Найважливіша панель!** Показує **декомпільований C код** - Ghidra намагається відновити оригінальний код.

**Що ви тут бачите:**
```c
undefined8 main(int argc, char **argv)
{
  int iVar1;
  size_t nameLen;
  ...
}
```

**Важливо розуміти:**
- Це **НЕ оригінальний код** - це реконструкція Ghidra
- Назви змінних автоматичні: `iVar1`, `local_38` (можна перейменувати)
- Типи можуть бути невизначені: `undefined8` означає "щось 8-байтне"

**Поліпшення читабельності:**
1. **Перейменування змінних:**
   - Правий клік на змінну → `Rename Variable`
   - Наприклад: `local_38` → `serial`

2. **Зміна типу:**
   - Правий клік → `Retype Variable`
   - Наприклад: `undefined8` → `char *`

### Навігація

**Symbol Tree** (ліворуч):
- `Functions` - всі функції
- `Imports` - імпортовані функції
- `Exports` - експортовані функції
- `Data` - глобальні дані

**Listing вікно** (центр):
- Асемблерний код
- Адреси та інструкції

**Decompile вікно** (праворуч):
- Декомпільований C код
- Найважливіше вікно!

### Корисні операції

**Перейменування змінних:**
- Right-click на змінну → Rename Variable
- Робить код читабельнішим

**Перегляд референсів:**
- Right-click → References → Show References to ...
- Де використовується функція/змінна

**Пошук рядків:**
- Search → For Strings
- Window → Defined Strings

**Cross-references:**
- `CTRL+SHIFT+F` - знайти текст
- `CTRL+SHIFT+E` - експорти/імпорти

### Ghidra-специфічні поняття для новачків

#### Що таке "undefined8"?

Ghidra не завжди знає точний тип даних. `undefined8` означає:
- `undefined` - невідомий тип
- `8` - розмір 8 байт (64 біти)

**Типові відповідності:**
- `undefined8` → часто `long`, `int64_t`, або `char *` (вказівник на 64-біт системі)
- `undefined4` → часто `int`, `int32_t`
- `undefined2` → часто `short`
- `undefined1` → часто `char`, `byte`

#### Що таке "iVar1", "local_38"?

Це автоматично згенеровані назви змінних:
- `iVar1` - **i**nteger **Var**iable 1 (ціле число)
- `uVar1` - **u**nsigned variable
- `local_38` - локальна змінна на стеку за offset 0x38
- `param_1` - перший параметр функції

**Ви можете їх перейменувати!** Правий клік → Rename Variable

#### Що означає "PTR" в коді?

`PTR` = Pointer (вказівник)

```c
*PTR_strlen_00600ff8  // Вказівник на функцію strlen
```

Це означає, що за адресою `0x600ff8` зберігається адреса функції `strlen`.

### Покрокова робота в Ghidra (для цього завдання)

**Крок за кроком що робити після відкриття файлу:**

1. **Запустіть Ghidra:**
   ```bash
   ghidra
   ```

2. **Створіть проєкт:**
   - File → New Project
   - Виберіть "Non-Shared Project"
   - Введіть назву: `re_task04`
   - Виберіть директорію
   - Натисніть `Finish`

3. **Імпортуйте файл:**
   - File → Import File
   - Виберіть `build/re104`
   - Натисніть `OK` (Ghidra автоматично розпізнає формат)

4. **Відкрийте файл:**
   - Подвійний клік на `re104` в списку
   - З'явиться питання "Would you like to analyze now?" → **Yes**

5. **Дочекайтесь аналізу:**
   - Буде видно прогрес-бар: "Auto Analysis"
   - Зачекайте завершення (5-30 секунд)

6. **Знайдіть main:**
   - У лівій панелі Symbol Tree
   - Розгорніть `Functions` (клік на `▶`)
   - Прокрутіть вниз до `main`
   - **Подвійний клік** на `main`

7. **Читайте декомпільований код:**
   - Права панель (Decompile) покаже C код
   - Шукайте виклики `strlen`, `calloc`, `rot_apply`
   - Знайдіть рядок: `int N = (int)nameLen % 26;`

8. **Проаналізуйте:**
   - Це і є формула обчислення зсуву!
   - `N = strlen(name) % 26`

## 💡 Альтернативні методи

### IDA Free

Безкоштовна версія IDA Pro також може декомпілювати.

### radare2 + Ghidra

```bash
r2 -A build/re104
[0x00400530]> pdf @ main   # Дизасемблювання main
[0x00400530]> pdg @ main   # Декомпіляція (потрібен r2ghidra plugin)
```

### objdump + читання асемблера

```bash
objdump -d -M intel build/re104 | grep -A 50 "<main>:"
```

Знайдемо виклик `strlen` та подальше використання результату.

## 🧮 ROT-N кейген (повна версія)

```python
#!/usr/bin/env python3

def rot_n(text, n):
    """Застосувати ROT-N шифрування"""
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            shifted = (ord(char) - ord('a') + n) % 26
            result.append(chr(shifted + ord('a')))
        elif 'A' <= char <= 'Z':
            shifted = (ord(char) - ord('A') + n) % 26
            result.append(chr(shifted + ord('A')))
        else:
            result.append(char)
    return ''.join(result)

def generate_serial(name):
    """Генерувати серійник для task04"""
    n = len(name) % 26
    serial = rot_n(name, n)
    return serial

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <name>")
        sys.exit(1)

    name = sys.argv[1]
    n = len(name) % 26
    serial = generate_serial(name)

    print(f"[+] Name: {name}")
    print(f"[+] Length: {len(name)}")
    print(f"[+] N (shift): {n}")
    print(f"[+] Serial: {serial}")
    print()
    print(f"[*] Run: ./build/re104 {name} {serial}")
```

**Використання:**
```bash
python3 keygen.py Alice
# [+] Serial: Fqnhj
```

## 🏁 Чеклист

- [ ] Встановив Ghidra
- [ ] Відкрив `build/re104` у Ghidra
- [ ] Проаналізував функцію `main`
- [ ] Знайшов формулу `N = strlen(name) % 26`
- [ ] Написав кейген
- [ ] Згенерував серійник
- [ ] Отримав FLAG

## 📖 Ресурси

- [Ghidra Official](https://ghidra-sre.org/)
- [Ghidra Cheat Sheet](https://ghidra-sre.org/CheatSheet.html)
- [Ghidra Book](https://nostarch.com/GhidraBook)
- [Ghidra Courses](https://hackaday.io/project/172292-introduction-to-reverse-engineering-with-ghidra)

## 🎯 Наступний крок

**Task 05** - `N = time() % 20`! Зсув змінюється кожної секунди!

---
**Складність:** ⭐⭐⭐ | **Час:** 45-60 хв | **FLAG:** `FLAG{task4_ok_<name>}`
