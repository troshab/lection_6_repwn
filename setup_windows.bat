@echo off
REM ========================================
REM RE/PWN CTF Setup для Windows
REM ========================================
REM Цей скрипт містить інструкції для налаштування середовища на Windows
REM Для RE/PWN завдань рекомендується використовувати WSL2 (Windows Subsystem for Linux)

setlocal enabledelayedexpansion

color 0A
echo ========================================
echo   RE/PWN CTF Setup для Windows
echo ========================================
echo.

echo [INFO] Цей проєкт оптимізований для Linux середовища
echo [INFO] На Windows рекомендується використовувати WSL2
echo.

REM Перевірка чи запущено WSL
wsl --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] WSL вже встановлено
    goto :WSL_INSTALLED
) else (
    echo [WARNING] WSL не знайдено
    goto :WSL_INSTALL_GUIDE
)

:WSL_INSTALL_GUIDE
echo.
echo ========================================
echo   Інструкція встановлення WSL2
echo ========================================
echo.
echo Крок 1: Встановити WSL2
echo ----------------------
echo Відкрийте PowerShell від імені адміністратора та виконайте:
echo.
echo   wsl --install
echo.
echo Після встановлення перезавантажте комп'ютер.
echo.
echo Крок 2: Встановити Ubuntu
echo ----------------------
echo Після перезавантаження відкрийте Microsoft Store і встановіть:
echo   - Ubuntu 22.04 LTS (рекомендовано)
echo   або
echo   - Kali Linux (для pentest інструментів)
echo.
echo Крок 3: Налаштувати Ubuntu
echo ----------------------
echo Запустіть Ubuntu з меню Start, створіть користувача
echo.
echo Крок 4: Встановити Docker Desktop (опціонально)
echo ----------------------
echo Завантажте з: https://www.docker.com/products/docker-desktop
echo Після встановлення увімкніть WSL2 backend в налаштуваннях
echo.
pause
goto :SETUP_IN_WSL

:WSL_INSTALLED
echo.
echo ========================================
echo   WSL встановлено - налаштування
echo ========================================
echo.

REM Перевірка чи є Ubuntu
wsl --list --quiet | findstr /i "Ubuntu" >nul
if %errorlevel% equ 0 (
    echo [OK] Ubuntu знайдено
) else (
    echo [WARNING] Ubuntu не знайдено
    echo [INFO] Встановіть Ubuntu через Microsoft Store
    pause
    exit /b 1
)

:SETUP_IN_WSL
echo.
echo ========================================
echo   Запуск setup в WSL
echo ========================================
echo.

REM Конвертація Windows шляху до WSL шляху
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
set "WSL_PATH=/mnt/%SCRIPT_DIR::=%"
set "WSL_PATH=%WSL_PATH:\=/%"

echo [INFO] Запуск setup_linux.sh в WSL...
echo.

REM Запуск setup скрипта в WSL
wsl bash -c "cd '%WSL_PATH%' && chmod +x setup_linux.sh && ./setup_linux.sh"

if %errorlevel% equ 0 (
    echo.
    echo [OK] Встановлення завершено успішно!
    goto :SUCCESS
) else (
    echo.
    echo [ERROR] Помилка під час встановлення
    goto :ERROR
)

:SUCCESS
echo.
echo ========================================
echo   Наступні кроки
echo ========================================
echo.
echo 1. Відкрийте WSL Ubuntu:
echo    - Натисніть Win+R та введіть: wsl
echo.
echo 2. Перейдіть до проєкту:
echo    - cd %WSL_PATH%
echo.
echo 3. Запустіть RE завдання:
echo    - cd re/task01_inventory
echo    - make
echo    - ./build/re101
echo.
echo 4. Запустіть PWN завдання:
echo    - cd pwn
echo    - docker compose up -d
echo    - python3 solver/stage01_nc.py
echo.
echo 5. Перегляньте документацію:
echo    - cat README.md
echo.
echo ========================================
echo   Додаткова інформація
echo ========================================
echo.
echo - Ghidra для Windows: https://ghidra-sre.org/
echo - Visual Studio Code з WSL: https://code.visualstudio.com/docs/remote/wsl
echo - Docker Desktop: https://www.docker.com/products/docker-desktop
echo.
echo [SUCCESS] Готово! Приємного навчання! 🎓
echo.
pause
exit /b 0

:ERROR
echo.
echo [ERROR] Щось пішло не так
echo.
echo Можливі причини:
echo - WSL не встановлено правильно
echo - Ubuntu не встановлено
echo - Відсутній доступ до інтернету
echo.
echo Спробуйте:
echo 1. Перевірити WSL: wsl --version
echo 2. Перевірити Ubuntu: wsl --list
echo 3. Оновити WSL: wsl --update
echo 4. Запустити setup_linux.sh вручну в WSL
echo.
pause
exit /b 1
