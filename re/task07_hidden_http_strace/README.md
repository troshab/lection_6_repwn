# Task 07: Hidden HTTP Server + strace

## 📋 Опис завдання

Програма **таємно запускає HTTP сервер** на localhost! Статичний та навіть динамічний аналіз через GDB не допоможе - потрібен **strace** для трасування системних викликів.

**Рівень:** ⭐⭐⭐⭐⭐ Експертний | **Категорія:** System calls tracing, Network analysis

## 🎯 Навчальна мета

- Використовувати strace для трасування системних викликів
- Аналізувати мережеву активність програми
- Виявляти приховану функціональність
- Працювати з fork() та дочірніми процесами
- Використовувати curl для HTTP запитів

## 📚 Що таке strace?

**strace** - інструмент для трасування системних викликів Linux програми.

**Що він показує:**
- Виклики функцій ядра (open, read, write, socket, bind, etc.)
- Аргументи цих функцій
- Повернені значення
- Сигнали та помилки

**Чому корисний:**
- Виявлення прихованої поведінки
- Debugging без вихідного коду
- Аналіз малвару
- Оптимізація продуктивності

## 🛠️ Підготовка

### Встановлення strace

```bash
# Ubuntu/Debian
sudo apt install strace

# Fedora
sudo dnf install strace

# Arch
sudo pacman -S strace
```

### Збірка

```bash
cd task07_hidden_http_strace
./build.sh
```

## 🔍 Покрокове рішення

### Крок 1: Звичайний запуск

```bash
./build/re107 Alice
```

**Вивід:**
```
(програма запускається і просто завершується через секунду)
```

Нічого цікавого... Або ні?

### Крок 2: Аналіз через strings

```bash
strings -a build/re107 | grep -i flag
```

**Вивід:**
```
FLAG{task7_ok_%s}
```

Бачимо формат FLAG, але як його отримати?

### Крок 3: Аналіз через GDB

```gdb
gdb build/re107
(gdb) break main
(gdb) run Alice
(gdb) continue
```

Програма просто завершується... Можливо fork()?

### Крок 4: strace - базовий запуск

```bash
strace ./build/re107 Alice
```

**Частина виводу (багато тексту!):**
```
execve("./build/re107", ["./build/re107", "Alice"], ...) = 0
...
fork()                                  = 12345  ← AHA! Fork!
...
```

Бачимо `fork()` - програма створює дочірній процес!

#### Що таке fork() для новачків?

**fork()** - це системний виклик Linux, який створює копію поточного процесу.

**Як це працює:**

```
До fork():
┌──────────────────┐
│   Процес (PID)   │
│   ./re107        │
└──────────────────┘

fork() викликається...

Після fork():
┌──────────────────┐       ┌──────────────────┐
│ Батьківський     │       │ Дочірній         │
│ процес (PID)     │       │ процес (новий    │
│                  │       │ PID)             │
└──────────────────┘       └──────────────────┘
```

**Що отримує кожен процес після fork():**

```c
pid_t pid = fork();

// Після виклику є ДВА процеси, обидва виконують наступний код!

if (pid == 0) {
    // Це дочірній процес
    // pid = 0 означає "я дитина"
    printf("Я дочірній процес!\n");
} else if (pid > 0) {
    // Це батьківський процес
    // pid = PID дочірнього процесу
    printf("Я батько, мій син має PID %d\n", pid);
} else {
    // pid < 0 означає помилку
    perror("fork failed");
}
```

**Навіщо fork() в цьому завданні?**

```
Батьківський процес:
- Швидко завершується
- Здається що програма нічого не робить

Дочірній процес:
- Запускає HTTP сервер
- Працює у фоні
- Приховується від поверхневого аналізу!
```

**Візуалізація:**
```
$ ./build/re107 Alice
                ↓
          fork() виклик
          ↙           ↘
   Батько              Дитина
     ↓                   ↓
  exit(0)         Запуск HTTP сервера
     ↓              на порті 31337
  Завершився           ↓
                  listen() → accept()
                       ↓
                  Очікує підключення
```

**Чому strace -f потрібен:**

Без `-f`:
- strace стежить тільки за батьківським процесом
- Батько швидко завершується
- Не бачимо що робить дитина!

З `-f`:
- strace стежить за батьком **і дітьми**
- Бачимо всі системні виклики дочірнього процесу
- Виявляємо прихований HTTP сервер!

### Крок 5: strace з трасуванням форків

```bash
strace -f ./build/re107 Alice
```

**Опція `-f`** - стежити за дочірніми процесами!

**Вивід (знайдемо в трасі дочірнього процесу):**
```
[pid 12345] socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) = 3
[pid 12345] setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
[pid 12345] bind(3, {sa_family=AF_INET, sin_port=htons(31337),
                       sin_addr=inet_addr("127.0.0.1")}, 16) = 0
[pid 12345] listen(3, 8) = 0
[pid 12345] accept(3, NULL, NULL
```

**JACKPOT!** Бачимо:
- `socket()` - створення сокета
- `bind()` - прив'язка до **порту 31337** на **127.0.0.1**
- `listen()` - очікування з'єднань
- `accept()` - прийом підключення

### Крок 6: Фільтрація тільки мережевих викликів

```bash
strace -f -e trace=%network -s 200 ./build/re107 Alice
```

**Опції:**
- `-f` - стежити за форками
- `-e trace=%network` - тільки мережеві системні виклики
- `-s 200` - показувати до 200 символів рядкових аргументів

**Вивід (чистіший):**
```
socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) = 3
setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
bind(3, {sa_family=AF_INET, sin_port=htons(31337),
         sin_addr=inet_addr("127.0.0.1")}, 16) = 0
listen(3, 8) = 0
accept(3, NULL, NULL) = 4
recv(4, "GET / HTTP/1.1\r\nHost: 127.0.0.1:31337\r\n...", 1023, 0) = ...
send(4, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n...", ..., 0) = ...
send(4, "FLAG{task7_ok_Alice}\n", 21, 0) = 21
```

**Тепер все зрозуміло:**
1. Програма стартує HTTP сервер на `127.0.0.1:31337`
2. Очікує підключення
3. Повертає FLAG в HTTP відповіді!

### Крок 7: Підключення через curl

**У НОВОМУ ТЕРМІНАЛІ** (поки strace працює):

```bash
curl http://127.0.0.1:31337/?name=Alice
```

**Вивід:**
```
FLAG{task7_ok_Alice}
```

🎉 **Успіх!**

### Крок 8: Автоматизація (background process)

```bash
# Запускаємо у фоні
./build/re107 Alice &
PID=$!

# Даємо час стартувати
sleep 0.5

# Підключаємось
curl http://127.0.0.1:31337/?name=Alice

# Вбиваємо процес
kill $PID
```

Або в одну команду:

```bash
./build/re107 Alice & sleep 0.5 && curl http://127.0.0.1:31337/?name=Alice && kill $!
```

## 🎓 strace Поглиблений аналіз

### Важливі опції strace

```bash
# Базове використання
strace ./program

# Стежити за форками
strace -f ./program

# Фільтрувати виклики
strace -e trace=open,read ./program       # Тільки open та read
strace -e trace=%file ./program           # Файлові операції
strace -e trace=%network ./program        # Мережеві операції
strace -e trace=%process ./program        # Process management
strace -e trace=%signal ./program         # Сигнали

# Показувати більше даних
strace -s 1000 ./program                  # Рядки до 1000 символів

# Писати у файл
strace -o output.txt ./program

# Окремі файли для кожного процесу
strace -ff -o trace ./program
# Створить trace.PID файли

# Показувати час
strace -t ./program                       # HH:MM:SS
strace -tt ./program                      # HH:MM:SS.microseconds
strace -T ./program                       # Час виконання кожного виклику
```

### Типи системних викликів

#### %network (мережеві)
- `socket()` - створення сокета
- `bind()` - прив'язка до адреси/порту
- `listen()` - очікування з'єднань
- `accept()` - прийом підключення
- `connect()` - підключення до сервера
- `send()/recv()` - відправка/отримання даних
- `sendto()/recvfrom()` - UDP операції

#### %file (файлові)
- `open()` - відкрити файл
- `read()` - читати
- `write()` - писати
- `close()` - закрити
- `stat()` - інформація про файл

#### %process (процеси)
- `fork()` - створити дочірній процес
- `execve()` - виконати програму
- `wait()` - чекати завершення дочірнього
- `kill()` - надіслати сигнал

### Приклад детальної траси

```bash
strace -ff -o trace -s 10000 ./build/re107 Alice
```

Створить файли:
- `trace.12345` - батьківський процес
- `trace.12346` - дочірній процес (HTTP сервер)

**Аналіз дочірнього:**
```bash
cat trace.12346 | grep -E "socket|bind|listen|accept|send"
```

## 💡 Real-World застосування

### Виявлення малвару

```bash
# Що робить підозріла програма?
strace -f -e trace=%network,% file ./suspicious_binary

# Шукаємо:
# - Підключення до C&C серверів
# - Створення файлів у системних директоріях
# - Модифікацію конфігів
```

### Debugging без вихідного коду

```bash
# Чому програма не може відкрити файл?
strace -e trace=open ./program 2>&1 | grep ENOENT

# Які бібліотеки завантажуються?
strace -e trace=open ./program 2>&1 | grep "\.so"
```

### Аналіз продуктивності

```bash
# Які виклики найповільніші?
strace -T -c ./program

# Вивід статистики:
# % time  seconds  usecs/call  calls  errors  syscall
# ------ --------- ----------- ------ ------- --------
#  99.99  0.123456        1234    100       0 read
```

## 🏁 Чеклист

- [ ] Встановив strace
- [ ] Зібрав `build/re107`
- [ ] Запустив `strace -f ./build/re107 Alice`
- [ ] Побачив `fork()` у трасі
- [ ] Використав `-e trace=%network` для фільтрації
- [ ] Знайшов порт **31337** у `bind()`
- [ ] Підключився через `curl`
- [ ] Отримав FLAG

## 📖 Ресурси

- `man strace` - документація
- [strace.io](https://strace.io/) - офіційний сайт
- [Brendan Gregg's Blog](http://www.brendangregg.com/blog/2014-05-11/strace-wow-much-syscall.html)
- [ltrace](https://man7.org/linux/man-pages/man1/ltrace.1.html) - альтернатива для library calls

## 🎯 Підсумок курсу

**Вітаємо!** Ви пройшли всі 7 завдань з RE:

1. ⭐ **Inventory** - file, readelf, objdump, strings
2. ⭐ **Hardcoded** - strings, grep
3. ⭐⭐ **ROT13** - GDB, динамічний аналіз
4. ⭐⭐⭐ **ROT-N(strlen)** - Ghidra, декомпіляція
5. ⭐⭐⭐⭐ **ROT-N(time)** - кейгени, time-based
6. ⭐⭐⭐ **UPX** - пакування/розпакування
7. ⭐⭐⭐⭐⭐ **HTTP** - strace, system calls

**Набуті навички:**
- Статичний аналіз (strings, readelf, objdump, Ghidra)
- Динамічний аналіз (GDB, breakpoints, memory inspection)
- Трасування (strace, ltrace)
- Розпакування (UPX)
- Написання кейгенів (Python, криптографія)
- Мережевий аналіз (curl, HTTP)

**Наступні кроки:**
- PWN завдання (buffer overflow, ROP)
- Більш складна обфускація (anti-debug, VM)
- Reverse engineering real malware (у controlled environment!)

---
**Складність:** ⭐⭐⭐⭐⭐ | **Час:** 60-90 хв | **FLAG:** `FLAG{task7_ok_<name>}`
