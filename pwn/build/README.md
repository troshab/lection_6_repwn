# Build Directory

**[← Назад до головної](../README.md)** | [Інструкції компіляції](../BUILD_INSTRUCTIONS.md) | [Прапорці компілятора](../COMPILATION_FLAGS.md)

## Опис

Ця директорія містить скомпільовані бінарні файли для всіх PWN завдань. Бінарники створюються автоматично при виконанні команди `make` з кореневої директорії `pwn/`.

## Структура

```
build/
├── stage01_nc/                    # Базове netcat завдання
├── stage02_all_protections/       # Всі захисти увімкнені
├── stage02_no_protections/        # Всі захисти вимкнені
├── stage02_nx_pie/                # NX + PIE захисти
├── stage02_only_nx/               # Тільки NX захист
├── stage03_pwntools/              # Завдання для pwntools
├── stage04_demo_no_offset/        # Buffer overflow без підказки
├── stage05_demo_with_hint/        # Buffer overflow з підказкою
├── stage06_ret2win/               # Ret2win техніка
├── stage07_leak_demo/             # Витік адрес
└── stage08_ret2libc/              # Ret2libc експлойт
```

## Компіляція

Бінарники компілюються з кореневого Makefile:

```bash
# З директорії pwn/
make                    # Компілює всі завдання
make clean              # Очищує build директорію
make stage01_nc         # Компілює конкретне завдання
```

## Прапорці компіляції

Різні завдання компілюються з різними захистами:

- **NX (No-eXecute)**: `-z noexecstack` - забороняє виконання коду в стеку
- **PIE (Position Independent Executable)**: `-pie` - випадкова адреса завантаження
- **Stack Canary**: `-fstack-protector-all` - захист від buffer overflow
- **RELRO**: `-z relro -z now` - захист таблиці релокацій

Детальну інформацію дивіться в `COMPILATION_FLAGS.md`

## Використання

Ці бінарники використовуються:
1. **Docker контейнерами** - копіюються в образи для запуску завдань
2. **Локальним тестуванням** - можна запускати напряму для дебагу
3. **Автоматичними тестами** - для перевірки solver скриптів

## Примітки

- Бінарники компілюються для архітектури x86-64 Linux
- Всі файли в цій директорії є generated - не редагуйте їх вручну
- Після зміни вихідного коду треба перекомпілювати через `make`

---

## Див. також

- [BUILD_INSTRUCTIONS.md](../BUILD_INSTRUCTIONS.md) - Детальні інструкції компіляції
- [COMPILATION_FLAGS.md](../COMPILATION_FLAGS.md) - Пояснення прапорців та захистів
- [docker/README.md](../docker/README.md) - Як використовуються бінарники в Docker

**[← Назад до головної](../README.md)**
