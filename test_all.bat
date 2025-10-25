@echo off
REM ========================================
REM RE/PWN CTF - Тестування (Windows wrapper)
REM ========================================
REM Цей скрипт запускає test_all.sh в WSL Ubuntu

setlocal enabledelayedexpansion

color 0B
echo ========================================
echo   RE/PWN CTF - Запуск тестування
echo ========================================
echo.

REM Перевірка WSL
wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] WSL не знайдено
    echo.
    echo Спочатку встановіть WSL:
    echo   1. Запустіть setup_windows.bat
    echo   2. Або встановіть вручну: wsl --install
    echo.
    pause
    exit /b 1
)

echo [INFO] WSL знайдено
echo.

REM Перевірка Ubuntu
wsl --list --quiet | findstr /i "Ubuntu" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Ubuntu не знайдено в WSL
    echo.
    echo Встановіть Ubuntu через:
    echo   1. setup_windows.bat
    echo   2. Microsoft Store: Ubuntu 22.04
    echo.
    pause
    exit /b 1
)

echo [INFO] Ubuntu знайдено
echo.

REM Конвертація шляху до WSL формату
for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
set "WSL_PATH=/mnt/%SCRIPT_DIR::=%"
set "WSL_PATH=%WSL_PATH:\=/%"

echo [INFO] Проєкт: %WSL_PATH%
echo.
echo ========================================
echo   Запуск test_all.sh в WSL
echo ========================================
echo.

REM Запуск тестування в WSL
wsl bash -c "cd '%WSL_PATH%' && chmod +x test_all.sh && ./test_all.sh"

set TEST_RESULT=%errorlevel%

echo.
echo ========================================

if %TEST_RESULT% equ 0 (
    echo [SUCCESS] Всі тести пройдено успішно!
    color 0A
) else (
    echo [WARNING] Деякі тести провалено
    echo [INFO] Перегляньте вивід вище для деталей
    color 0E
)

echo ========================================
echo.
pause
exit /b %TEST_RESULT%
