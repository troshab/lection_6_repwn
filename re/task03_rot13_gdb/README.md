# Task 03: ROT13 + GDB (Динамічний аналіз)

**[← Назад до головної](../README.md)** | [← Попереднє](../task02_hardcoded_strings/README.md) | [Наступне →](../task04_rotn_strlen_ghidra/README.md)

## 📋 Опис завдання

У цьому завданні серійний номер генерується через ROT13 шифрування вашого імені. Простий `strings` вже не допоможе - потрібно використовувати **динамічний аналіз** через GDB (GNU Debugger), щоб побачити як програма трансформує ваш ввід і порівнює його з очікуваним значенням.

**Рівень складності:** ⭐⭐ Початковий-Середній

**Категорія:** Динамічний аналіз, дебагінг, криптографія

## 🎯 Навчальна мета

Після виконання цього завдання ви навчитеся:
- Використовувати GDB для динамічного аналізу
- Встановлювати breakpoints (точки зупинки)
- Досліджувати пам'ять та регістри під час виконання
- Розуміти ROT13 шифрування
- Генерувати правильний серійник на основі алгоритму

## 📚 Що таке ROT13?

**ROT13** (Rotate by 13 places) - це простий шифр заміни, де кожна літера зсувається на 13 позицій в алфавіті.

```
Оригінал: A B C D E F G H I J K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
ROT13:    N O P Q R S T U V W X  Y  Z  A  B  C  D  E  F  G  H  I  J  K  L  M
```

**Приклади трансформації:**
- `HELLO` → `URYYB`
- `Alice` → `Nyvpr`
- `Bob` → `Obo`
- `World` → `Jbeyq`

**Цікава властивість:** ROT13(ROT13(x)) = x (застосувати двічі = повернутись до оригіналу)

## 🛠️ Підготовка

### Встановлення GDB

```bash
# Ubuntu/Debian
sudo apt install gdb

# Fedora
sudo dnf install gdb

# Arch
sudo pacman -S gdb
```

### Збірка бінарника

```bash
cd task03_rot13_gdb
./build.sh
# або
make clean && make
```

## 🔍 Покрокове рішення

### Крок 1: Розуміння програми

```bash
# Запуск без аргументів
./build/re103
```

**Вивід:**
```
usage: ./build/re103 <name> <serial>
```

Програма очікує ім'я та серійний номер.

### Крок 2: Спроба випадкового серійника

```bash
./build/re103 Alice TEST123
```

**Вивід:**
```
nope
```

Серійник неправильний. Потрібно зрозуміти як він генерується!

### Крок 3: Аналіз через strings (не спрацює!)

```bash
strings -a build/re103 | grep -i flag
```

**Вивід:**
```
FLAG{task3_ok_%s}
```

Ми знаємо формат FLAG, але не знаємо правильний серійник, бо він генерується **динамічно** під час виконання!

### Крок 4: Запуск через GDB

```bash
gdb build/re103
```

**Ви побачите:**
```
GNU gdb (Ubuntu 12.1-0ubuntu1) 12.1
...
Reading symbols from build/re103...
(No debugging symbols found in build/re103)
(gdb)
```

**В GDB промпті:**
```gdb
(gdb) info functions
```

Побачимо функції: `main`, `rot_shift`, `rot_apply`, `strcmp` тощо.

### Крок 5: Встановлення breakpoint перед strcmp

Ідея: програма порівнює наш серійник з чимось. Подивимось що саме!

```gdb
(gdb) break strcmp
Breakpoint 1 at 0x...

(gdb) run Alice TEST123
Starting program: /path/to/build/re103 Alice TEST123
```

Програма зупиниться перед викликом `strcmp`.

### Крок 6: Перегляд аргументів strcmp

#### Основи x86-64 архітектури для новачків

Перед тим як дивитись аргументи, потрібно зрозуміти як працює процесор.

**Що таке регістри?**
- Регістри - це найшвидша пам'ять всередині процесора
- Це як "кишені" процесора для зберігання даних
- На x86-64 є багато регістрів, кожен має своє призначення

**Основні регістри x86-64:**

```
┌─────────────┬──────────────────────────────────────┐
│ Регістр     │ Призначення                          │
├─────────────┼──────────────────────────────────────┤
│ rax         │ Return value (повернене значення)   │
│ rbx         │ Base (базовий регістр)               │
│ rcx         │ Counter (лічильник циклів)           │
│ rdx         │ Data (дані)                          │
│ rsi         │ Source Index (джерело даних)        │
│ rdi         │ Destination Index (призначення)      │
│ rbp         │ Base Pointer (вказівник на frame)   │
│ rsp         │ Stack Pointer (вершина стеку)       │
│ r8-r15      │ Додаткові регістри                   │
│ rip         │ Instruction Pointer (адреса команди) │
└─────────────┴──────────────────────────────────────┘
```

**Calling Convention (як передаються аргументи):**

На x86-64 Linux (System V AMD64 ABI) аргументи функцій передаються так:

```
Позиція аргументу → Регістр
────────────────────────────
1-й аргумент      → rdi
2-й аргумент      → rsi
3-й аргумент      → rdx
4-й аргумент      → rcx
5-й аргумент      → r8
6-й аргумент      → r9
7+ аргументи      → через стек
```

**Приклад:**
```c
strcmp(str1, str2)
       │     │
       │     └─→ 2-й аргумент → регістр rsi
       └────────→ 1-й аргумент → регістр rdi
```

**Повернене значення:**
- Функція повертає результат в регістрі `rax`

**Візуалізація виклику функції:**
```
До виклику strcmp:
rdi = адреса "Nyvpr"   ← перший параметр
rsi = адреса "TEST123" ← другий параметр

strcmp виконується...

Після виклику:
rax = -44              ← результат порівняння (не рівні)
```

**Як передаються аргументи в x86-64:**
- Перший аргумент: регістр `rdi`
- Другий аргумент: регістр `rsi`

**Дивимось що в регістрах:**
```gdb
(gdb) x/s $rdi
0x7fffffffe1a0: "Nyvpr"        ← ROT13 від "Alice"!

(gdb) x/s $rsi
0x7fffffffe1b0: "TEST123"      ← Наш введений серійник
```

**АГА!** Програма порівнює `"Nyvpr"` (ROT13 від Alice) з нашим введенням!

**Пояснення команди `x/s`:**
- `x` - examine (дослідити пам'ять)
- `/s` - формат string (рядок)
- `$rdi` - регістр rdi

### Крок 7: Генерація правильного серійника

Тепер ми знаємо алгоритм: `serial = ROT13(name)`

**Спосіб 1: Онлайн ROT13**
- Відкрийте https://rot13.com/
- Введіть "Alice"
- Отримаєте "Nyvpr"

**Спосіб 2: Python**
```python
import codecs
name = "Alice"
serial = codecs.encode(name, 'rot13')
print(serial)  # Nyvpr
```

**Спосіб 3: Bash**
```bash
echo "Alice" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
# Nyvpr
```

### Крок 8: Перевірка правильного серійника

```bash
./build/re103 Alice Nyvpr
```

**Вивід:**
```
FLAG{task3_ok_Alice}
```

🎉 **Успіх!** Ви отримали FLAG!

## 🎓 Детальний GDB туторіал

### Основні команди GDB

#### Запуск та керування

```gdb
# Запуск програми
run <args>                    # Запустити з аргументами
r Alice TEST                  # Скорочена форма

# Встановлення breakpoints
break main                    # Зупинитись на початку main
break strcmp                  # Зупинитись перед strcmp
break *0x401234               # Зупинитись на конкретній адресі
break rot_apply               # Зупинитись на функції

# Керування breakpoints
info breakpoints              # Показати всі breakpoints
delete 1                      # Видалити breakpoint #1
disable 2                     # Вимкнути breakpoint #2
enable 2                      # Увімкнути breakpoint #2
```

#### Виконання коду

```gdb
continue                      # Продовжити виконання (до наступного breakpoint)
c                            # Скорочена форма

step                         # Крок з входом у функції (step into)
s                           # Скорочена форма

next                         # Крок без входу у функції (step over)
n                           # Скорочена форма

finish                       # Виконати до повернення з поточної функції
```

#### Перегляд пам'яті та регістрів

```gdb
# Перегляд рядків
x/s $rdi                     # Показати рядок в rdi
x/s 0x7fffffffe1a0          # Показати рядок за адресою

# Перегляд hex значень
x/10x $rsp                   # 10 hex значень зі стеку
x/4xw $rsp                   # 4 words в hex

# Перегляд інструкцій
x/i $rip                     # Показати поточну інструкцію
x/10i $rip                   # Показати 10 інструкцій

# Змінні та вирази
print variable               # Вивести значення змінної
print $rax                   # Вивести значення регістра
print (char*)$rdi           # Cast та вивести

# Регістри
info registers               # Всі регістри
info registers rax rbx       # Конкретні регістри
```

#### Дизасемблювання

```gdb
disassemble main             # Дизасемблювати функцію main
disassemble                  # Дизасемблювати поточну функцію
```

### Розширений аналіз task03

#### Аналіз функції rot_apply

```gdb
(gdb) break rot_apply
Breakpoint 1 at 0x...

(gdb) run Alice TEST
Breakpoint 1, rot_apply ()

# Аргументи функції rot_apply(dst, src, n)
(gdb) print (char*)$rdi
$1 = 0x... ""                # dst (буфер результату - порожній)

(gdb) print (char*)$rsi
$2 = 0x... "Alice"           # src (вхідний рядок)

(gdb) print $rdx
$3 = 13                      # n (зсув = 13 для ROT13)

# Продовжуємо виконання
(gdb) finish
Run till exit from #0  rot_apply ()

# Перевіряємо результат в dst
(gdb) print (char*)$rdi
$4 = 0x... "Nyvpr"           # Трансформований рядок!
```

#### Покрокове виконання rot_shift

```gdb
(gdb) break rot_shift
(gdb) run Alice TEST

# При кожному виклику rot_shift (для кожної літери)
(gdb) print (char)$rdi       # Символ для трансформації (наприклад 'A')
$1 = 65 'A'

(gdb) print $rsi            # Значення зсуву (13)
$2 = 13

(gdb) finish                # Виконати функцію
Run till exit from #0  rot_shift ()

(gdb) print $rax            # Результат (трансформований символ 'N')
$3 = 78 'N'
```

## 💡 Альтернативні методи рішення

### Метод 1: Статичний аналіз коду (якщо є доступ)

Якщо відкрити `src/main.c`:

```c
rot_apply(tmp, name, 13);     // Застосувати ROT13
int ok = strcmp(tmp, serial)==0;
```

Одразу видно: `serial` має бути `ROT13(name)`.

### Метод 2: Через objdump (продвинутий)

```bash
objdump -d build/re103 | grep -A 20 "<main>:"
```

Знайдемо виклик `rot_apply` з константою `13` як третім аргументом:

```asm
4005f7:  ba 0d 00 00 00        mov    $0xd,%edx    ; n = 13
4005fc:  e8 XX XX XX XX        call   rot_apply
```

### Метод 3: Через ltrace (найпростіший!)

`ltrace` показує виклики **бібліотечних** функцій:

```bash
ltrace ./build/re103 Alice TEST123
```

**Вивід:**
```
strcmp("Nyvpr", "TEST123") = -44
puts("nope")
```

Бачимо що програма порівнює! Просто використайте "Nyvpr" як серійник.

## 🧮 ROT13 імплементації

### Python (повна версія)

```python
def rot13(text):
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            # Малі літери: зсув на 13 позицій
            result.append(chr((ord(char) - ord('a') + 13) % 26 + ord('a')))
        elif 'A' <= char <= 'Z':
            # Великі літери: зсув на 13 позицій
            result.append(chr((ord(char) - ord('A') + 13) % 26 + ord('A')))
        else:
            # Інші символи без змін
            result.append(char)
    return ''.join(result)

# Тестування
print(rot13("Alice"))  # Nyvpr
print(rot13("Hello World!"))  # Uryyb Jbeyq!
print(rot13(rot13("Alice")))  # Alice (повернення до оригіналу)
```

### Bash (з tr)

```bash
echo "Alice" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
```

**Пояснення tr:**
- `A-Za-z` - вхідні символи (A-Z та a-z)
- `N-ZA-Mn-za-m` - відповідні вихідні символи (зсув на 13)

### JavaScript

```javascript
function rot13(str) {
    return str.replace(/[A-Za-z]/g, function(c) {
        return String.fromCharCode(
            c <= 'Z' ? ((c.charCodeAt(0) - 65 + 13) % 26) + 65
                     : ((c.charCodeAt(0) - 97 + 13) % 26) + 97
        );
    });
}

console.log(rot13("Alice"));  // Nyvpr
```

### C (як у програмі)

```c
char rot_shift(char c, int n) {
    if ('a' <= c && c <= 'z')
        return 'a' + ((c - 'a') + n) % 26;
    if ('A' <= c && c <= 'Z')
        return 'A' + ((c - 'A') + n) % 26;
    return c;
}
```

## 🐛 Troubleshooting GDB

### Помилка: "No debugging symbols found"

**Вивід:**
```
Reading symbols from build/re103...
(No debugging symbols found in build/re103)
```

**Пояснення:**
- Це нормально! Бінарник зібраний без debug symbols (`-g` флаг)
- GDB все одно працюватиме, але не буде показувати вихідний код

**Рішення:**
- Для цього завдання не потрібно debug symbols
- Якщо потрібні: перекомпілюйте з `gcc -g`

### Помилка: Breakpoint не спрацьовує

**Проблема:** `break strcmp` не зупиняє виконання

**Діагностика:**
```gdb
(gdb) info breakpoints
# Перевірте чи breakpoint встановлений

(gdb) info functions
# Перевірте чи strcmp є в програмі
```

**Рішення:**
- Переконайтесь що запустили програму: `run Alice TEST`
- Спробуйте інший breakpoint: `break main`

### GDB зависає після `run`

**Причина:** Програма чекає на ввід або зациклилась

**Рішення:**
- `Ctrl+C` - перервати виконання
- `kill` - вбити процес в GDB
- `quit` - вийти з GDB

### Не можу побачити вміст регістрів

**Команди для перегляду:**
```gdb
# Подивитись конкретний регістр
(gdb) print $rdi
(gdb) print/x $rdi    # В hex форматі

# Подивитись як рядок
(gdb) x/s $rdi

# Усі регістри
(gdb) info registers
```

### "Cannot access memory at address 0x0"

**Причина:** Вказівник NULL або невалідна адреса

**Перевірка:**
```gdb
(gdb) print $rdi
$1 = 0x0              # NULL pointer!

(gdb) x/s $rsi        # Спробуйте інший регістр
```

## 🏁 Чеклист виконання

- [ ] Встановив GDB (`sudo apt install gdb`)
- [ ] Зібрав бінарник (`./build.sh`)
- [ ] Запустив програму та побачив usage
- [ ] Спробував неправильний серійник (nope)
- [ ] Запустив GDB (`gdb build/re103`)
- [ ] Встановив breakpoint на strcmp
- [ ] Побачив ROT13 трансформацію в пам'яті (Nyvpr)
- [ ] Згенерував ROT13 від свого імені
- [ ] Отримав FLAG: `FLAG{task3_ok_Alice}`
- [ ] Розумію як працює ROT13
- [ ] Розумію як працює GDB
- [ ] Розумію calling convention (rdi, rsi для аргументів)

## 📖 Корисні ресурси

- `man gdb` - документація GDB
- [GDB Tutorial](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [ROT13 на Wikipedia](https://en.wikipedia.org/wiki/ROT13)
- [GDB Cheat Sheet](https://darkdust.net/files/GDB%20Cheat%20Sheet.pdf)
- [pwndbg](https://github.com/pwndbg/pwndbg) - покращений GDB для CTF
- [gef](https://github.com/hugsy/gef) - альтернатива pwndbg

## 🎯 Наступний крок

Переходьте до **[Task 04: ROT-N + Ghidra](../task04_rotn_strlen_ghidra/README.md)**, де зсув вже не фіксований (13), а залежить від довжини імені! Потрібна декомпіляція через Ghidra.

---

**Автор:** CTF RE/PWN Training
**Складність:** ⭐⭐ Початковий-Середній
**Час виконання:** 30-45 хвилин
**FLAG формат:** `FLAG{task3_ok_<your_name>}`

**[← Назад до головної](../README.md)** | [← Попереднє](../task02_hardcoded_strings/README.md) | [Наступне →](../task04_rotn_strlen_ghidra/README.md)
