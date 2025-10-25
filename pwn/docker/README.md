# Docker Directory

**[← Назад до головної](../README.md)**

## Опис

Ця директорія містить Docker конфігурації та security профілі для безпечного запуску PWN завдань у контейнерах. Безпека критично важлива для CTF інфраструктури, оскільки учасники можуть отримати RCE (Remote Code Execution).

## Файли

### Dockerfile

Базовий образ для всіх PWN завдань:

```dockerfile
FROM debian:12-slim
RUN useradd -u 10001 -m ctf && apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY build/ /app/
RUN mkdir -p /app/lib && \
    cp /lib/x86_64-linux-gnu/libc.so.6 /app/lib/ && \
    cp /lib64/ld-linux-x86-64.so.2 /app/lib/ || true
USER 10001:10001
ENTRYPOINT ["/bin/sh","-c","/app/stage$STAGE_BIN < /dev/stdin > /dev/stdout 2>&1"]
```

**Особливості:**
- **Базовий образ**: Debian 12 Slim - мінімальна атакуюча поверхня
- **Користувач**: ctf (UID 10001) - non-root для безпеки
- **Бінарники**: копіюються з директорії `build/`
- **Libc**: зберігається в `/app/lib/` для можливості екстракції учасниками
- **Entrypoint**: запускає відповідне завдання через змінну `$STAGE_BIN`

### seccomp-default.json

Мінімальний seccomp профіль, що дозволяє тільки базові системні виклики:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": ["read", "write", "exit", "exit_group", "sigreturn"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

**Дозволені syscalls:**
- `read`, `write` - введення/виведення
- `exit`, `exit_group` - завершення процесу
- `sigreturn` - обробка сигналів

**Призначення**: максимально обмежити можливості експлойту після успішного захоплення виконання. Навіть з RCE учасник не зможе виконати `execve`, `open`, тощо.

### seccomp-orw.json

Розширений seccomp профіль для ORW (Open-Read-Write) завдань:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "openat", "close",
        "fstat", "lseek", "mmap", "mprotect", "munmap",
        "brk", "access", "exit", "exit_group", "sigreturn"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

**Додатково дозволяє:**
- `open`, `openat`, `close` - робота з файлами
- `fstat`, `lseek` - операції з дескрипторами
- `mmap`, `mprotect`, `munmap`, `brk` - керування пам'яттю
- `access` - перевірка доступу до файлів

**Призначення**: дозволяє читати flag файл через ROP chain (open→read→write), але забороняє `execve` для запуску shell. Це типовий сценарій для просунутих PWN завдань.

### apparmor-profile

AppArmor профіль для додаткового рівня ізоляції (опційно).

---

## Docker Security Best Practices

### 1. Користувач та файлова система

```yaml
# docker-compose.yml
services:
  stage06:
    user: "10001:10001"           # НЕ root!
    read_only: true               # Read-only rootfs
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev
```

**Чому це важливо:**
- `user: 10001` - якщо учасник отримає shell, він не буде root
- `read_only: true` - неможливо модифікувати файли в контейнері
- `tmpfs` з `noexec` - навіть /tmp не дозволяє виконання коду

### 2. Обмеження capabilities та privileges

```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
pids_limit: 128
```

**Що це дає:**
- `no-new-privileges` - заборона підвищення привілеїв через setuid binaries
- `cap_drop: ALL` - видалення всіх Linux capabilities
- `pids_limit` - обмеження кількості процесів (захист від fork bomb)

### 3. Ресурсні обмеження

```yaml
mem_limit: 256m
cpus: 0.5
ulimits:
  nproc: 128                  # Максимум процесів
  nofile: 1024                # Максимум відкритих файлів
  core: 0                     # Без core dumps
  stack: 8388608              # 8MB стек
  as: 268435456               # 256MB address space
```

**Захист від:**
- Memory exhaustion attacks
- CPU-intensive attacks
- Fork bombs
- Resource leaks

### 4. Seccomp профілі

**Для простих стекових завдань (stage01-07):**
```yaml
security_opt:
  - seccomp=./docker/seccomp-default.json
```

Дозволяє тільки `read`, `write`, `exit`. Навіть з RCE учасник не може:
- Запустити shell (`execve` заблокований)
- Відкрити файли (`open` заблокований)
- Створити мережеві з'єднання (`socket` заблокований)

**Для ORW завдань (stage08):**
```yaml
security_opt:
  - seccomp=./docker/seccomp-orw.json
```

Дозволяє додатково `open`, `read` для читання `/flag`, але все ще блокує `execve`.

### 5. Мережева ізоляція

```yaml
networks:
  pwn_internal:
    driver: bridge
    internal: true              # Без доступу в Інтернет
```

**Чому це важливо:**
- Навіть з RCE учасник не може:
  - Завантажити додаткові інструменти
  - Атакувати інші сервери
  - Надіслати дані назовні (exfiltration)

### 6. Healthcheck та автоперезапуск

```yaml
healthcheck:
  test: ["CMD", "nc", "-z", "localhost", "7106"]
  interval: 30s
  timeout: 5s
  retries: 2

restart: unless-stopped
stop_grace_period: 2s
```

**Переваги:**
- Автоматичне виявлення crashed контейнерів
- Швидкий restart після падіння
- Graceful shutdown за 2 секунди

### 7. Rate Limiting

**Через iptables на хості:**
```bash
# Максимум 10 нових з'єднань за 60 секунд з одного IP
iptables -A INPUT -p tcp --dport 7106 -m state --state NEW \
  -m recent --set --name PWN

iptables -A INPUT -p tcp --dport 7106 -m state --state NEW \
  -m recent --update --seconds 60 --hitcount 10 --name PWN -j DROP
```

**Або через nginx reverse proxy:**
```nginx
http {
  limit_conn_zone $binary_remote_addr zone=pwn:10m;
  limit_req_zone $binary_remote_addr zone=pwn_req:10m rate=10r/s;

  server {
    location / {
      limit_conn pwn 5;              # Макс 5 одночасних з'єднань
      limit_req zone=pwn_req burst=10 nodelay;
      proxy_pass http://pwn_backend;
    }
  }
}
```

**Захист від:**
- DoS attacks
- Bruteforce attacks
- Resource exhaustion

---

## Повний приклад docker-compose.yml

```yaml
version: '3.8'

services:
  stage08_ret2libc:
    build:
      context: .
      dockerfile: docker/Dockerfile

    # Security: User and filesystem
    user: "10001:10001"
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=10m

    # Security: Capabilities
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
      - seccomp=./docker/seccomp-orw.json

    # Security: Resource limits
    mem_limit: 256m
    cpus: 0.5
    pids_limit: 128
    ulimits:
      nproc: 128
      nofile: 1024
      core: 0
      stack: 8388608
      as: 268435456

    # Networking
    ports:
      - "7108:7108"
    networks:
      - pwn_internal

    # Health and lifecycle
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "7108"]
      interval: 30s
      timeout: 5s
      retries: 2
    restart: unless-stopped
    stop_grace_period: 2s

    # Environment
    environment:
      - STAGE_BIN=08

networks:
  pwn_internal:
    driver: bridge
    internal: true
```

---

## Тестування безпеки

### Перевірка seccomp профілю

```bash
# Які syscalls дозволені?
docker run --rm \
  --security-opt seccomp=./docker/seccomp-default.json \
  debian:12-slim \
  strace -c /bin/true 2>&1 | grep -E "(read|write|open|execve)"
```

### Тест на fork bomb

```bash
# Має бути обмежений pids_limit
docker run --rm \
  --pids-limit 128 \
  debian:12-slim \
  bash -c ':(){ :|:& };:'
```

### Тест мережевої ізоляції

```bash
# Має провалитись (no internet)
docker run --rm \
  --network pwn_internal \
  debian:12-slim \
  ping -c 1 8.8.8.8
```

---

## Використання профілів

### У docker-compose.yml

```yaml
services:
  my_pwn_challenge:
    security_opt:
      - seccomp=./docker/seccomp-orw.json
      - apparmor=docker/apparmor-profile
```

### Прямий запуск Docker

```bash
docker run --rm \
  --security-opt seccomp=./docker/seccomp-default.json \
  --user 10001:10001 \
  --read-only \
  my-pwn-image
```

---

## Поширені питання

### Чому не просто відключити мережу?

Network isolation (internal: true) краще за повне відключення мережі, бо:
- Контейнери можуть комунікувати між собою (якщо потрібно)
- Healthchecks працюють
- Logging працює

### Чому ORW а не shell?

Seccomp-orw дозволяє створювати реалістичні PWN завдання де:
- Учасник має обійти NX + ASLR
- Потрібен ROP chain
- Але система все ще захищена від повного RCE

### Чи достатньо тільки seccomp?

Ні! Defense in depth:
1. Seccomp - обмежує syscalls
2. User 10001 - обмежує привілеї
3. Read-only FS - захищає файли
4. Resource limits - захищає від DoS
5. Network isolation - захищає від exfiltration

Всі рівні разом створюють надійний захист.

---

## Корисні посилання

- [Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Seccomp Security Profiles](https://docs.docker.com/engine/security/seccomp/)
- [Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

**[← Назад до головної](../README.md)**
