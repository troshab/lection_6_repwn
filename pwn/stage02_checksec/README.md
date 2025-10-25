# Stage 02: checksec - Аналіз захистів бінарників

## 🎯 Мета завдання

Навчитися **розпізнавати** та **розуміти** захисні механізми у бінарних файлах. Це критично важливо для вибору правильної стратегії експлуатації.

## 📚 Що ви дізнаєтесь

- Що таке Canary (Stack Protector) і як він працює
- Що таке NX (No eXecute) і чому він блокує shellcode
- Що таке PIE (Position Independent Executable) і ASLR
- Що таке RELRO (Relocation Read-Only) і захист GOT
- Як використовувати інструмент `checksec`
- Як захисти впливають на вибір техніки експлуатації

## 🔧 Необхідні інструменти

```bash
# Встановіть checksec
sudo apt install checksec

# Альтернатива - скачати скрипт
wget https://github.com/slimm609/checksec.sh/raw/master/checksec
chmod +x checksec
sudo mv checksec /usr/local/bin/
```

## 📖 Теоретична основа

### 1. Stack Canary (Stack Protector)

**Що це?** "Канарейка" - спеціальне значення між локальними змінними та збереженим RIP.

```
┌────────────────┐  Вища адреса
│   Saved RIP    │  ← Куди повернеться функція
├────────────────┤
│   Saved RBP    │
├────────────────┤
│   ** CANARY ** │  ← Секретне значення!
├────────────────┤
│   Local vars   │  ← Ваші дані
│   char buf[64] │
└────────────────┘  Нижча адреса
```

**Як працює?**

1. **При вході в функцію**: canary зберігається зі спеціального регістру `fs:0x28`
2. **При виході з функції**: перевіряється чи canary не змінилась
3. **Якщо змінилась**: програма аварійно завершується з `*** stack smashing detected ***`

**Приклад коду з canary:**

```c
void vulnerable() {
    char buf[64];
    // Canary додана компілятором автоматично!
    gets(buf);  // BOF
    // Перевірка canary перед return
}
```

**Скомпільовано з `-fstack-protector-all`:**

```asm
vulnerable:
    ; Зберегти canary зі fs:0x28
    mov    rax, QWORD PTR fs:0x28
    mov    QWORD PTR [rbp-0x8], rax

    ; Ваш код тут...

    ; Перевірка перед поверненням
    mov    rax, QWORD PTR [rbp-0x8]
    xor    rax, QWORD PTR fs:0x28
    je     .L_ok            ; Якщо рівні - ОК
    call   __stack_chk_fail ; Інакше - PANIC!
.L_ok:
    ret
```

**Як експлуатувати з canary?**

- ❌ Просто перезаписати RIP не вийде
- ✅ Потрібен **leak canary** (витік значення)
- ✅ Або знайти **інший баг** (не BOF)

### 2. NX (No eXecute / DEP)

**Що це?** Заборона **виконання коду** в певних областях пам'яті (стек, heap).

```
┌──────────────────┐
│   Code (.text)   │  ✅ Виконуваний, ❌ Не записуваний
├──────────────────┤
│   Data (.data)   │  ❌ Не виконуваний, ✅ Записуваний
├──────────────────┤
│   Stack          │  ❌ Не виконуваний (NX ON)
│                  │  ✅ Виконуваний (NX OFF)
└──────────────────┘
```

**Як працює NX?**

На рівні процесора кожна сторінка пам'яті має біт **NX** (або **XD** у Intel):
- Якщо `NX=1` → процесор **заборонить** виконання коду з цієї сторінки
- Спроба виконати → `Segmentation fault`

**У Linux це називається:**
- **NX bit** (No eXecute)
- **W^X** (Write XOR Execute) - або записуваний, або виконуваний

**Перевірка через readelf:**

```bash
readelf -l binary | grep GNU_STACK
# GNU_STACK  0x000000 0x0000 0x0000 0x00000 0x00000 RW  0x10  ← NX ON (Read-Write)
# GNU_STACK  0x000000 0x0000 0x0000 0x00000 0x00000 RWE 0x10  ← NX OFF (Read-Write-Execute)
```

**Вплив на експлуатацію:**

- **NX OFF**: можна закинути shellcode в стек і виконати
  ```
  payload = shellcode + padding + p64(address_of_shellcode)
  ```

- **NX ON**: shellcode в стеку не виконається, потрібен **ROP** (Return Oriented Programming)
  ```
  payload = padding + rop_chain
  ```

### 3. PIE (Position Independent Executable) + ASLR

**PIE** - бінарник може бути завантажений за **будь-якою адресою**.
**ASLR** - ядро Linux **рандомізує** адреси при кожному запуску.

```
Без PIE (завжди 0x400000):
./binary    →  0x400000 (базова адреса)
./binary    →  0x400000 (та сама!)
./binary    →  0x400000 (та сама!)

З PIE + ASLR (випадкові адреси):
./binary    →  0x5555555 54000
./binary    →  0x5555557 8a000
./binary    →  0x5555559 2f000
```

**Ефект на адреси функцій:**

```bash
# PIE OFF - адреси стабільні
objdump -d binary | grep '<win>'
0000000000401136 <win>:   # Завжди 0x401136

# PIE ON - адреси відносні
objdump -d binary | grep '<win>'
0000000000001136 <win>:   # Базова адреса + 0x1136
```

**Як експлуатувати з PIE?**

- ❌ Hardcode адреси не працює
- ✅ Потрібен **leak адреси** з процесу
- ✅ Розрахувати базову адресу: `base = leaked_addr - known_offset`

**ASLR на системному рівні:**

```bash
# Перевірити статус ASLR
cat /proc/sys/kernel/randomize_va_space
# 0 = OFF (все фіксовано)
# 1 = Conservative (heap/stack/libraries, але не main executable якщо не PIE)
# 2 = Full (все включно з PIE)

# Вимкнути (для тестування, потрібен root)
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

# Увімкнути назад
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
```

### 4. RELRO (Relocation Read-Only)

**Що це?** Захист таблиць **GOT** (Global Offset Table) та **PLT** (Procedure Linkage Table).

**Три режими:**

**No RELRO:**
```
┌─────────────┐
│  GOT/PLT    │  ✅ Записуваний завжди
└─────────────┘
```
- Можна перезаписати адреси в GOT → виклик довільної функції
- Техніка: **GOT overwrite**

**Partial RELRO:**
```
┌─────────────┐
│  .got.plt   │  ✅ Записуваний до першого виклику
└─────────────┘
```
- GOT захищена, але `.got.plt` все ще можна змінити
- Lazy binding працює
- **Більшість програм** мають Partial RELRO

**Full RELRO:**
```
┌─────────────┐
│  GOT/PLT    │  ❌ Тільки читання (read-only)
└─────────────┘
```
- **Всі адреси** резолвяться при старті (`-z now`)
- GOT стає read-only → **неможливо перезаписати**
- Повільніший старт програми

**Перевірка:**

```bash
readelf -l binary | grep GNU_RELRO
# Якщо є → Partial або Full

readelf -d binary | grep BIND_NOW
# Якщо є BIND_NOW → Full RELRO
```

## 🚀 Покрокове рішення

### Крок 1: Збудуйте бінарники

```bash
cd stage02_checksec
./build.sh
```

Це створить **4 варіанти** з різними захистами:
- `stage02_no_protections` - всі OFF
- `stage02_all_protections` - всі ON
- `stage02_only_nx` - тільки NX
- `stage02_nx_pie` - NX + PIE

### Крок 2: Перевірте захисти

```bash
checksec --file=../build/stage02_no_protections
checksec --file=../build/stage02_all_protections
checksec --file=../build/stage02_only_nx
checksec --file=../build/stage02_nx_pie
```

### Крок 3: Порівняйте результати

**Варіант 1: Без захистів**
```
RELRO           STACK CANARY      NX            PIE
No RELRO        No canary found   NX disabled   No PIE (0x400000)
```

**Варіант 2: Всі захисти**
```
RELRO           STACK CANARY      NX            PIE
Full RELRO      Canary found      NX enabled    PIE enabled
```

**Варіант 3: Тільки NX**
```
RELRO           STACK CANARY      NX            PIE
Partial RELRO   No canary found   NX enabled    No PIE (0x400000)
```

**Варіант 4: NX + PIE**
```
RELRO           STACK CANARY      NX            PIE
Partial RELRO   No canary found   NX enabled    PIE enabled
```

## 🔍 Детальний аналіз

### Ручна перевірка без checksec

#### 1. Перевірка Canary

```bash
objdump -d binary | grep -A20 '<main>' | grep fs:0x28
# Якщо знайдено fs:0x28 → Canary ON
```

#### 2. Перевірка NX

```bash
readelf -l binary | grep GNU_STACK
# RW  → NX ON
# RWE → NX OFF
```

#### 3. Перевірка PIE

```bash
readelf -h binary | grep Type
# EXEC (Executable file) → PIE OFF
# DYN (Shared object file) → PIE ON (або просто .so)

file binary
# ELF 64-bit LSB executable → PIE OFF
# ELF 64-bit LSB pie executable → PIE ON
```

#### 4. Перевірка RELRO

```bash
readelf -l binary | grep GNU_RELRO
# Немає → No RELRO
# Є → Partial або Full

readelf -d binary | grep BIND_NOW
# Є → Full RELRO
# Немає → Partial RELRO
```

## 💡 Стратегії експлуатації

### Матриця: Захисти → Техніка

| Canary | NX | PIE | RELRO | Техніка експлуатації |
|--------|----|----|-------|---------------------|
| OFF | OFF | OFF | OFF | Shellcode в стеку + ret до нього |
| OFF | ON | OFF | OFF | ROP chain (ret2libc) |
| OFF | ON | OFF | Partial | ROP + можливий GOT overwrite |
| OFF | ON | ON | Partial | Leak PIE → ROP chain |
| OFF | ON | ON | Full | Leak PIE → ROP chain (без GOT overwrite) |
| ON | - | - | - | Потрібен leak canary + вище |

### Приклади

**Сценарій 1: Все вимкнено (stage06_ret2win)**

```python
# Простіший exploit на світі
payload = b'A' * offset + p64(addr_of_win)
```

**Сценарій 2: Тільки NX увімкнений**

```python
# Не можна shellcode, але можна ret2libc
payload = b'A' * offset + rop_chain
```

**Сценарій 3: NX + PIE**

```python
# 1. Leak адреси
io.recvuntil(b'Address: ')
leaked = int(io.recvline(), 16)
base = leaked - known_offset

# 2. Розрахувати адреси
win_addr = base + 0x1234

# 3. Експлойт
payload = b'A' * offset + p64(win_addr)
```

**Сценарій 4: Всі захисти (реальні програми)**

```python
# 1. Leak canary
# 2. Leak PIE base
# 3. Leak libc base
# 4. ROP chain з урахуванням Full RELRO
```

## 🎓 Практичні завдання

### Завдання 1: Зберіть власний бінарник

```bash
cat > test.c <<EOF
#include <stdio.h>
int main() {
    char buf[64];
    gets(buf);
    return 0;
}
EOF

# Без захистів
gcc -fno-stack-protector -z execstack -no-pie test.c -o test_noprotect

# Всі захисти
gcc -fstack-protector-all -pie -fPIE -z now -z relro test.c -o test_fullprotect

# Перевірте
checksec --file=test_noprotect
checksec --file=test_fullprotect
```

### Завдання 2: Експеримент з canary

```bash
# Зберіть з canary
gcc -fstack-protector-all test.c -o test_canary

# Спробуйте BOF
echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" | ./test_canary
# Результат: *** stack smashing detected ***
```

### Завдання 3: ASLR експеримент

```bash
cat > aslr_test.c <<EOF
#include <stdio.h>
int main() {
    printf("main() at: %p\n", main);
    return 0;
}
EOF

gcc -pie -fPIE aslr_test.c -o aslr_test

# Запустіть 5 разів
for i in {1..5}; do ./aslr_test; done
# Адреси різні кожен раз!
```

### Завдання 4: Порівняння розмірів

```bash
# Full RELRO збільшує розмір
gcc test.c -o test_partial -z relro
gcc test.c -o test_full -z now -z relro

ls -lh test_partial test_full
# test_full буде трохи більший
```

## 🔗 Таблиця прапорів компіляції

| Захист | Увімкнути | Вимкнути |
|--------|-----------|----------|
| Canary | `-fstack-protector-all` | `-fno-stack-protector` |
| NX | (default) | `-z execstack` |
| PIE | `-pie -fPIE` | `-no-pie` |
| RELRO Partial | `-z relro` | `-z norelro` |
| RELRO Full | `-z now -z relro` | `-z norelro` |

## 📚 Корисні команди

```bash
# Швидка перевірка
checksec --file=binary

# Детальна інфо про ELF
readelf -a binary | less

# Дизасемблювання
objdump -d binary | less

# Strings (шукаємо підказки)
strings binary

# Файловий тип
file binary

# Hex dump
xxd binary | less

# strace (системні виклики)
strace ./binary

# ltrace (бібліотечні виклики)
ltrace ./binary
```

## ✅ Чеклист виконання

- [ ] Встановлено checksec
- [ ] Зібрано всі 4 варіанти бінарників
- [ ] Перевірено захисти через checksec
- [ ] Зрозуміло що таке Canary і як він працює
- [ ] Зрозуміло що таке NX і чому блокує shellcode
- [ ] Зрозуміло що таке PIE/ASLR і навіщо leak
- [ ] Зрозуміло що таке RELRO і захист GOT
- [ ] Можу вибрати стратегію експлуатації за захистами
- [ ] Готовий до Stage 03!

---

**Час виконання:** 15-20 хвилин
**Складність:** ⭐⭐☆☆☆ (Легка)
**Категорія:** PWN / Binary Analysis
