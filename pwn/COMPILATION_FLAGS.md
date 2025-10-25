# Compilation Flags - Швидка довідка

## Таблиця прапорів компіляції по етапах

| Stage | Canary | NX | PIE | RELRO | Додаткові прапори | Призначення |
|-------|--------|----|----|-------|-------------------|-------------|
| 01_nc | Default | Default | Default | Default | `-I../common` | TCP сервіс, захисти не важливі |
| 02_checksec | **Varies** | **Varies** | **Varies** | **Varies** | 4 варіанти | Демонстрація різних захистів |
| 03_pwntools | Default | Default | Default | Default | `-I../common` | Те саме що 01, для pwntools |
| 04_demo_no_offset | Default | Default | OFF | Default | `-no-pie` | Пряме виконання за адресою |
| 05_demo_with_hint | **OFF** | **OFF** | **OFF** | Default | `-fno-stack-protector -z execstack -no-pie` | BOF з підказкою offset |
| 06_ret2win | **OFF** | **OFF** | **OFF** | **OFF** | `-fno-stack-protector -z execstack -no-pie -z norelro` | Класичний ret2win |
| 07_leak_demo | **OFF** | **ON** | **OFF** | Partial | `-fno-stack-protector -no-pie -z relro` | Leak адрес (ASLR bypass) |
| 08_ret2libc | **OFF** | **ON** | **OFF** | Partial | `-fno-stack-protector -no-pie -z relro -ldl` | Ret2libc + ROP |

## Розшифровка прапорів GCC

### Stack Canary (Stack Protector)
```bash
-fno-stack-protector           # Canary OFF
-fstack-protector              # Canary для функцій з буферами
-fstack-protector-all          # Canary для ВСІХ функцій
-fstack-protector-strong       # Canary для функцій з локальними масивами/адресами
```

### NX (No eXecute / DEP)
```bash
-z execstack                   # NX OFF - стек виконуваний
(без прапора)                  # NX ON - стек не виконуваний (default)
-z noexecstack                 # NX ON - явно заборонити (default в нових gcc)
```

### PIE (Position Independent Executable)
```bash
-no-pie                        # PIE OFF - фіксовані адреси
-pie -fPIE                     # PIE ON - рандомізація адрес бінарника
```

### RELRO (Relocation Read-Only)
```bash
-z norelro                     # RELRO OFF - GOT записуваний
-z relro                       # Partial RELRO - GOT після ініціалізації
-z now -z relro                # Full RELRO - GOT readonly з старту
```

### Інші корисні прапори
```bash
-ldl                           # Лінк з libdl (dlopen, dlsym)
-lpthread                      # Лінк з pthread
-static                        # Статична лінковка (great for CTF)
-m32                           # 32-bit binary (на 64-bit системі)
-m64                           # 64-bit binary (explicit)
-O0                            # Без оптимізацій (easier to reverse)
-O2                            # Оптимізація рівня 2
-O3                            # Агресивна оптимізація
-g                             # Debug symbols
-Wall -Wextra                  # Всі попередження
```

## Детальний розбір по етапах

### Stage 01-03: Базові TCP сервіси
```bash
gcc -Wall -Wextra -O2 -I../common server.c -o ../build/stage01_nc
```
- Стандартна компіляція
- `-I../common` для підключення net.h
- Захисти: default (залежить від системи)

### Stage 04: Demo без offset
```bash
gcc -Wall -Wextra -O2 -no-pie server.c -o ../build/stage04_demo_no_offset
```
- `-no-pie` - фіксовані адреси, легше знайти адресу win()
- Решта захистів default

### Stage 05: Demo з підказкою
```bash
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -z execstack \
    -no-pie \
    server.c -o ../build/stage05_demo_with_hint
```
- **ВСІ захисти OFF** крім RELRO
- Ідеально для навчання BOF
- Сервер підказує скільки байтів бракує

### Stage 06: ret2win (найпростіший BOF)
```bash
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -z execstack \
    -no-pie \
    -z norelro \
    server.c -o ../build/stage06_ret2win
```
- **ПОВНІСТЮ без захистів**
- Класичний навчальний ret2win
- Offset наданий у statement (72 байти)

### Stage 07: Leak demo (перехід до реальності)
```bash
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -no-pie \
    -z relro \
    server.c -o ../build/stage07_leak_demo
```
- **NX=ON** - стек не виконуваний
- Canary OFF, PIE OFF для простоти
- Команда LEAK віддає адресу з libc
- Вчимося рахувати базу libc

### Stage 08: ret2libc (повний реалізм)
```bash
gcc -Wall -Wextra -O2 \
    -fno-stack-protector \
    -no-pie \
    -z relro \
    -ldl \
    server.c -o ../build/stage08_ret2libc
```
- **NX=ON** - потрібен ROP
- **ASLR=ON** (системний) - потрібен leak
- `-ldl` для dlsym() у коді
- Повноцінний ret2libc: leak → база → ROP → system() або ORW

## Stage 02: Варіанти для checksec

### Варіант 1: Без захистів
```bash
gcc -fno-stack-protector -z execstack -no-pie -z norelro \
    dummy.c -o build/stage02_no_protections
```

### Варіант 2: Всі захисти
```bash
gcc -fstack-protector-all -D_FORTIFY_SOURCE=2 -pie -fPIE -z now -z relro \
    dummy.c -o build/stage02_all_protections
```

### Варіант 3: Тільки NX
```bash
gcc -fno-stack-protector -no-pie -z relro \
    dummy.c -o build/stage02_only_nx
```

### Варіант 4: NX + PIE
```bash
gcc -fno-stack-protector -pie -fPIE -z relro \
    dummy.c -o build/stage02_nx_pie
```

## Перевірка результату

### Використання checksec
```bash
checksec --file=build/stage06_ret2win
```

Очікуваний вивід:
```
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH
No RELRO        No canary found   NX disabled   No PIE (0x400000)   No RPATH   No RUNPATH
```

### Ручна перевірка

**Canary:**
```bash
objdump -d build/stage06_ret2win | grep -A20 '<vuln>' | grep '%fs:0x28'
# Якщо немає виводу → Canary OFF
```

**NX:**
```bash
readelf -l build/stage06_ret2win | grep GNU_STACK
# RWE → NX OFF (executable)
# RW  → NX ON (not executable)
```

**PIE:**
```bash
readelf -h build/stage06_ret2win | grep Type
# EXEC → PIE OFF
# DYN  → PIE ON (або shared lib)
```

**RELRO:**
```bash
readelf -l build/stage06_ret2win | grep GNU_RELRO
# Якщо є → Partial RELRO або Full
readelf -d build/stage06_ret2win | grep BIND_NOW
# Якщо є BIND_NOW → Full RELRO
```

## Практичні поради

### Для автора завдання

1. **Easy PWN** → всі захисти OFF (як stage06)
2. **Medium PWN** → NX ON, решта OFF (як stage07-08)
3. **Hard PWN** → NX + PIE + Canary, Full RELRO
4. **Реалістичний PWN** → як Hard + обмежений leak

### Тестування локально

Вимкніть ASLR для тестування:
```bash
# Вимкнути ASLR (потрібен root)
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

# Ваші тести...

# Увімкнути назад
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
```

### Статична збірка для distributable challenges
```bash
gcc -static -fno-stack-protector -z execstack -no-pie \
    server.c -o challenge
# Великий файл (~800KB+), але працює на будь-якому Linux
```

### 32-bit challenge на 64-bit системі
```bash
sudo apt install gcc-multilib
gcc -m32 -fno-stack-protector -z execstack -no-pie \
    server.c -o challenge32
```

## Типові помилки

### ❌ Забули вимкнути RELRO
```bash
gcc -fno-stack-protector -z execstack -no-pie server.c -o vuln
checksec --file=vuln
# RELRO: Partial RELRO ← не те що хотіли!
```

**Правильно:**
```bash
gcc -fno-stack-protector -z execstack -no-pie -Wl,-z,norelro server.c -o vuln
```

### ❌ NX все ще ON
```bash
gcc -fno-stack-protector server.c -o vuln
# NX: ON ← забули -z execstack
```

**Правильно:**
```bash
gcc -fno-stack-protector -z execstack server.c -o vuln
```

### ❌ PIE все ще ON (на нових gcc)
```bash
gcc server.c -o vuln
# PIE: ON ← default на Ubuntu 18.04+
```

**Правильно:**
```bash
gcc -no-pie server.c -o vuln
```

## Рекомендовані комбінації для CTF

### Beginner ret2win
```bash
-fno-stack-protector -z execstack -no-pie -Wl,-z,norelro
```

### Intermediate ret2libc
```bash
-fno-stack-protector -no-pie -Wl,-z,relro
# NX ON за замовчуванням
```

### Advanced ROP
```bash
-fno-stack-protector -pie -fPIE -Wl,-z,relro
# NX ON, PIE ON → потрібен leak
```

### Expert
```bash
-fstack-protector-all -pie -fPIE -Wl,-z,now,-z,relro
# Все ON → потрібен leak canary + leak PIE + bypass RELRO
```

## Додаткові ресурси

- [GCC Security Options](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)
- [checksec.sh GitHub](https://github.com/slimm609/checksec.sh)
- [Linux x86-64 ABI](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf)
- [RELRO Explained](https://www.redhat.com/en/blog/hardening-elf-binaries-using-relocation-read-only-relro)
