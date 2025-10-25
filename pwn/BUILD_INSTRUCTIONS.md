# Build Instructions для PWN завдань

## Огляд

Кожен етап має власний `build.sh` скрипт для компіляції бінарника з правильними параметрами захисту.

## Способи збірки

### Варіант 1: Використання Makefile (рекомендовано)

Зібрати всі етапи одразу:
```bash
make all
```

Зібрати конкретний етап:
```bash
make build/stage06_ret2win
```

Очистити зібрані файли:
```bash
make clean
```

### Варіант 2: Індивідуальні build.sh скрипти

Для збірки окремого етапу:
```bash
cd stage06_ret2win
./build.sh
```

Або з будь-якої директорії:
```bash
./stage06_ret2win/build.sh
```

## Деталі кожного етапу

### Stage 01: nc
```bash
./stage01_nc/build.sh
```
**Параметри:** базова компіляція без спеціальних прапорів

### Stage 02: checksec
```bash
./stage02_checksec/build.sh
```
**Особливість:** створює 4 варіанти бінарників з різними захистами:
- `stage02_no_protections` - всі захисти OFF
- `stage02_all_protections` - всі захисти ON
- `stage02_only_nx` - тільки NX
- `stage02_nx_pie` - NX + PIE

### Stage 03: pwntools
```bash
./stage03_pwntools/build.sh
```
**Параметри:** те саме що stage01

### Stage 04: demo_no_offset
```bash
./stage04_demo_no_offset/build.sh
```
**Параметри:**
- `-no-pie` - фіксовані адреси

### Stage 05: demo_with_hint
```bash
./stage05_demo_with_hint/build.sh
```
**Параметри:**
- `-fno-stack-protector` - вимкнути canary
- `-z execstack` - дозволити виконання в стеку (NX=Off)
- `-no-pie` - вимкнути PIE

### Stage 06: ret2win
```bash
./stage06_ret2win/build.sh
```
**Параметри:**
- `-fno-stack-protector` - Canary OFF
- `-z execstack` - NX OFF
- `-no-pie` - PIE OFF
- `-z norelro` - RELRO OFF

Повністю без захистів для навчання базового BOF.

### Stage 07: leak_demo
```bash
./stage07_leak_demo/build.sh
```
**Параметри:**
- `-fno-stack-protector` - Canary OFF
- `-no-pie` - PIE OFF
- `-z relro` - Partial RELRO
- **NX=On** (без `-z execstack`)

Демонструє leak адрес для обходу ASLR.

### Stage 08: ret2libc
```bash
./stage08_ret2libc/build.sh
```
**Параметри:**
- `-fno-stack-protector` - Canary OFF
- `-no-pie` - PIE OFF
- `-z relro` - Partial RELRO
- `-ldl` - лінк з libdl для dlsym()
- **NX=On** (без `-z execstack`)

Повноцінний ret2libc з leak + ROP.

## Перевірка захистів

Після збірки перевірте захисти:
```bash
checksec --file=build/stage06_ret2win
```

Очікуваний вивід для stage06:
```
Canary:        No canary found
NX:            NX disabled
PIE:           No PIE (0x400000)
RELRO:         No RELRO
```

## Директорія збірки

Всі бінарники збираються в `build/`:
```
pwn/
├── build/
│   ├── stage01_nc
│   ├── stage02_no_protections
│   ├── stage02_all_protections
│   ├── stage02_only_nx
│   ├── stage02_nx_pie
│   ├── stage03_pwntools
│   ├── stage04_demo_no_offset
│   ├── stage05_demo_with_hint
│   ├── stage06_ret2win
│   ├── stage07_leak_demo
│   └── stage08_ret2libc
```

## Вимоги

### Linux/WSL
```bash
sudo apt update
sudo apt install build-essential gcc make
```

### Для checksec
```bash
sudo apt install checksec
# або
wget https://github.com/slimm609/checksec.sh/raw/master/checksec
chmod +x checksec
```

## Запуск після збірки

### Локально (для тестування)
```bash
./build/stage06_ret2win
```

### Через Docker (production)
```bash
docker compose up -d
# Бінарники будуть скопійовані в контейнери
```

## Параметри компіляції - довідка

| Прапор | Що робить |
|--------|-----------|
| `-fno-stack-protector` | Вимикає canary (stack cookies) |
| `-fstack-protector-all` | Вмикає canary для всіх функцій |
| `-z execstack` | NX OFF - дозволяє виконання коду в стеку |
| (без `-z execstack`) | NX ON - заборона виконання в стеку |
| `-no-pie` | PIE OFF - фіксовані адреси |
| `-pie -fPIE` | PIE ON - рандомізація адрес |
| `-z norelro` | RELRO OFF - дозволяє запис у GOT |
| `-z relro` | Partial RELRO |
| `-z now -z relro` | Full RELRO - заборона запису у GOT |
| `-ldl` | Лінк з libdl (для dlsym, dlopen) |

## Troubleshooting

### "gcc: command not found"
Встановіть gcc:
```bash
sudo apt install gcc make
```

### "cannot find -ldl"
Встановіть glibc development files:
```bash
sudo apt install libc6-dev
```

### Бінарник не запускається
Перевірте архітектуру:
```bash
file build/stage06_ret2win
# Має бути: ELF 64-bit LSB executable, x86-64
```

### Захисти не ті що очікуються
Перевірте версію gcc та перекомпілюйте:
```bash
gcc --version
# Рекомендовано: gcc 9.x або новіший
```

## Для розробників завдань

### Додавання нового етапу

1. Створіть директорію `stageXX_name/`
2. Додайте `server.c` з вразливістю
3. Створіть `build.sh`:
```bash
#!/bin/bash
set -e
echo "[*] Building stageXX_name..."
mkdir -p ../build
gcc [YOUR_FLAGS] server.c -o ../build/stageXX_name
echo "[+] Built: ../build/stageXX_name"
```
4. Зробіть виконуваним: `chmod +x build.sh`
5. Оновіть `Makefile` додавши новий target
6. Створіть solver у `../solver/stageXX_name.py`

## Автоматична збірка всіх етапів

```bash
# З директорії pwn/
for stage in stage*/build.sh; do
    echo "Building $stage..."
    (cd $(dirname "$stage") && ./build.sh)
done
```

Або простіше:
```bash
make all
```
