# Scripts Directory

**[← Назад до головної](../README.md)** | [Docker](../docker/README.md) | [Solvers](../solver/README.md)

## Опис

Ця директорія містить допоміжні скрипти для роботи з PWN завданнями. Основне призначення - автоматизація рутинних операцій під час розробки та тестування експлойтів.

## Скрипти

### extract_libc.sh

Скрипт для екстракції libc та ld бібліотек з Docker контейнерів.

#### Призначення

Для написання експлойтів типу ret2libc потрібно знати точну версію libc, що використовується на сервері. Цей скрипт дозволяє витягти бібліотеки з контейнера для локального аналізу.

#### Використання

```bash
# Екстракція libc для конкретного завдання
cd pwn/
./scripts/extract_libc.sh stage08_ret2libc

# За замовчуванням екстрагує для stage08
./scripts/extract_libc.sh
```

#### Що робить скрипт

1. Перевіряє чи запущений контейнер для вказаного завдання
2. Якщо не запущений - запускає через `docker compose up -d`
3. Копіює `/app/lib/libc.so.6` з контейнера
4. Копіює `/app/lib/ld-linux-x86-64.so.2` з контейнера
5. Зберігає файли в директорію `extracted/`

#### Вихідні файли

Після виконання в `pwn/extracted/` з'являються:
- `libc.so.6` - C standard library
- `ld-linux-x86-64.so.2` - dynamic linker/loader

#### Використання з pwntools

```python
from pwn import *

# Завантаження екстрагованої libc
libc = ELF('./extracted/libc.so.6')
ld = ELF('./extracted/ld-linux-x86-64.so.2')

# Використання для ret2libc
libc_base = leaked_addr - libc.symbols['puts']
system = libc_base + libc.symbols['system']
```

#### Використання для пошуку версії libc

```bash
# Визначення версії
./extracted/libc.so.6
# або
strings ./extracted/libc.so.6 | grep "GNU C Library"

# Пошук через libc database
libc-database/find <leak_info>
```

## Додавання нових скриптів

При додаванні нових скриптів дотримуйтесь конвенцій:
- Використовуйте `#!/usr/bin/env bash` або `#!/usr/bin/env python3`
- Додайте `set -euo pipefail` для bash скриптів
- Зробіть файл виконуваним: `chmod +x scripts/new_script.sh`
- Додайте документацію в цей README

## Примітки

- Скрипти розраховані на запуск з кореневої директорії `pwn/`
- Потрібен встановлений Docker та docker-compose
- Екстраговані файли не версіонуються в git (є в .gitignore)

---

## Див. також

- [docker/README.md](../docker/README.md) - Docker конфігурація та безпека
- [solver/README.md](../solver/README.md) - Як використовувати екстраговану libc
- [Stage 8 - ret2libc](../stage08_ret2libc/README.md) - Приклад використання

**[← Назад до головної](../README.md)**
