# ========================================
# RE/PWN CTF Setup для Windows (PowerShell)
# ========================================
# Автоматичне налаштування WSL2, Ubuntu та всіх необхідних інструментів
# Запуск: .\setup_windows.ps1
# Або: powershell -ExecutionPolicy Bypass -File setup_windows.ps1

#Requires -Version 5.1

# Кольори для виводу
function Write-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Перевірка прав адміністратора
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ========================================
# Головна функція
# ========================================

Write-Header "RE/PWN CTF Setup для Windows"
Write-Host ""

# Перевірка прав адміністратора
if (-not (Test-Administrator)) {
    Write-Warning "Цей скрипт потребує прав адміністратора"
    Write-Info "Клік правою кнопкою на PowerShell → 'Запустити від імені адміністратора'"
    Write-Info "Або запустіть: Start-Process powershell -ArgumentList '-File setup_windows.ps1' -Verb RunAs"
    Write-Host ""
    Read-Host "Натисніть Enter для виходу"
    exit 1
}

Write-Success "Запущено з правами адміністратора"
Write-Host ""

# ========================================
# Крок 1: Перевірка версії Windows
# ========================================
Write-Header "Крок 1/6: Перевірка системи"

$osVersion = [System.Environment]::OSVersion.Version
$buildNumber = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber

Write-Info "Windows версія: $($osVersion.ToString())"
Write-Info "Build: $buildNumber"

if ($buildNumber -lt 19041) {
    Write-Error "WSL2 потребує Windows 10 версії 2004 або новіше (build 19041+)"
    Write-Info "Оновіть Windows через Windows Update"
    Read-Host "Натисніть Enter для виходу"
    exit 1
}

Write-Success "Версія Windows підтримує WSL2"
Write-Host ""

# ========================================
# Крок 2: Встановлення WSL2
# ========================================
Write-Header "Крок 2/6: Встановлення WSL2"

# Перевірка чи WSL вже встановлено
$wslInstalled = $false
try {
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $wslInstalled = $true
        Write-Success "WSL вже встановлено"
        Write-Info $wslVersion[0]
    }
} catch {
    $wslInstalled = $false
}

if (-not $wslInstalled) {
    Write-Info "Встановлення WSL2..."
    Write-Info "Це може зайняти кілька хвилин..."

    # Встановлення WSL
    try {
        wsl --install --no-distribution
        Write-Success "WSL2 встановлено"
        Write-Warning "ВАЖЛИВО: Після завершення потрібен перезапуск системи"
        Write-Info "Після перезавантаження запустіть цей скрипт знову"

        $restart = Read-Host "Перезавантажити зараз? (Y/N)"
        if ($restart -eq 'Y' -or $restart -eq 'y') {
            Restart-Computer -Force
        }
        exit 0
    } catch {
        Write-Error "Помилка встановлення WSL: $_"
        Write-Info "Спробуйте встановити вручну: wsl --install"
        exit 1
    }
}

Write-Host ""

# ========================================
# Крок 3: Встановлення Ubuntu
# ========================================
Write-Header "Крок 3/6: Встановлення Ubuntu"

# Перевірка чи Ubuntu вже встановлено
$ubuntuInstalled = $false
try {
    $distributions = wsl --list --quiet 2>$null
    if ($distributions -match "Ubuntu") {
        $ubuntuInstalled = $true
        Write-Success "Ubuntu вже встановлено"
    }
} catch {
    $ubuntuInstalled = $false
}

if (-not $ubuntuInstalled) {
    Write-Info "Встановлення Ubuntu 22.04..."
    Write-Info "Відкриється Microsoft Store - завершіть встановлення там"

    try {
        # Спроба автоматичного встановлення
        wsl --install -d Ubuntu-22.04

        Write-Success "Ubuntu встановлюється"
        Write-Info "Після встановлення створіть користувача Ubuntu"
        Write-Host ""
        Read-Host "Натисніть Enter коли Ubuntu буде налаштовано"
    } catch {
        Write-Warning "Автоматичне встановлення не вдалося"
        Write-Info "Відкрийте Microsoft Store та встановіть 'Ubuntu 22.04 LTS' вручну"
        Write-Info "Потім запустіть цей скрипт знову"

        Start-Process "ms-windows-store://pdp/?ProductId=9PN20MSR04DW"
        exit 0
    }
}

Write-Host ""

# ========================================
# Крок 4: Встановлення Docker Desktop (опціонально)
# ========================================
Write-Header "Крок 4/6: Docker Desktop"

# Перевірка чи Docker встановлено
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue

if ($dockerInstalled) {
    Write-Success "Docker Desktop вже встановлено"
    Write-Info "Версія: $(docker --version)"
} else {
    Write-Info "Docker Desktop не знайдено"
    Write-Info "Docker потрібен для PWN завдань (віддалена експлуатація)"

    $installDocker = Read-Host "Встановити Docker Desktop? (Y/N)"

    if ($installDocker -eq 'Y' -or $installDocker -eq 'y') {
        Write-Info "Відкриваю сторінку завантаження Docker Desktop..."
        Start-Process "https://www.docker.com/products/docker-desktop"

        Write-Info "Після встановлення Docker Desktop:"
        Write-Info "1. Запустіть Docker Desktop"
        Write-Info "2. Увімкніть WSL2 backend в налаштуваннях"
        Write-Info "3. Запустіть цей скрипт знову"

        Read-Host "Натисніть Enter для продовження"
    } else {
        Write-Warning "Docker не буде встановлено - PWN завдання працюватимуть тільки локально"
    }
}

Write-Host ""

# ========================================
# Крок 5: Налаштування в WSL Ubuntu
# ========================================
Write-Header "Крок 5/6: Налаштування Ubuntu в WSL"

Write-Info "Запуск setup_linux.sh в WSL Ubuntu..."
Write-Host ""

# Конвертація Windows шляху до WSL
$scriptPath = $PSScriptRoot
$wslPath = $scriptPath -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/'
$wslPath = $wslPath.ToLower()

Write-Info "Шлях проєкту в WSL: $wslPath"

# Запуск setup скрипта
try {
    $setupScript = @"
cd '$wslPath'
chmod +x setup_linux.sh
./setup_linux.sh
"@

    wsl bash -c $setupScript

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Налаштування Ubuntu завершено"
    } else {
        Write-Error "Помилка під час виконання setup_linux.sh"
        Write-Info "Спробуйте запустити вручну в WSL:"
        Write-Info "  cd $wslPath"
        Write-Info "  ./setup_linux.sh"
    }
} catch {
    Write-Error "Не вдалося запустити WSL: $_"
    Write-Info "Переконайтеся що Ubuntu встановлено та налаштовано"
}

Write-Host ""

# ========================================
# Крок 6: Додаткові інструменти для Windows
# ========================================
Write-Header "Крок 6/6: Додаткові інструменти"

Write-Info "Рекомендовані інструменти для Windows:"
Write-Host ""

# Visual Studio Code
$vscodeInstalled = Get-Command code -ErrorAction SilentlyContinue
if ($vscodeInstalled) {
    Write-Success "Visual Studio Code встановлено"
    Write-Info "Встановіть розширення 'WSL' для роботи з Ubuntu"
} else {
    Write-Info "Visual Studio Code: https://code.visualstudio.com/"
    Write-Info "  - Розширення: Remote - WSL"
}

Write-Host ""

# Ghidra
Write-Info "Ghidra (для RE task 04):"
Write-Info "  - Завантажити: https://ghidra-sre.org/"
Write-Info "  - Або в WSL: sudo apt install openjdk-17-jdk"

Write-Host ""

# ========================================
# Завершення
# ========================================
Write-Header "Встановлення завершено!"

Write-Host ""
Write-Success "WSL2 та Ubuntu налаштовано"
Write-Success "Інструменти RE/PWN встановлено в Ubuntu"

Write-Host ""
Write-Info "Як користуватися:"
Write-Host ""

Write-Host "1. Відкрити WSL Ubuntu:" -ForegroundColor Cyan
Write-Host "   - Натисніть Win+R, введіть: wsl" -ForegroundColor White
Write-Host "   - Або: запустіть 'Ubuntu' з меню Start" -ForegroundColor White

Write-Host ""
Write-Host "2. Перейти до проєкту в WSL:" -ForegroundColor Cyan
Write-Host "   cd $wslPath" -ForegroundColor White

Write-Host ""
Write-Host "3. Запустити RE завдання:" -ForegroundColor Cyan
Write-Host "   cd re/task01_inventory" -ForegroundColor White
Write-Host "   make" -ForegroundColor White
Write-Host "   ./build/re101" -ForegroundColor White

Write-Host ""
Write-Host "4. Активувати Python venv:" -ForegroundColor Cyan
Write-Host "   source .venv/bin/activate" -ForegroundColor White

Write-Host ""
Write-Host "5. Запустити PWN завдання:" -ForegroundColor Cyan
Write-Host "   cd pwn" -ForegroundColor White
Write-Host "   docker compose up -d" -ForegroundColor White
Write-Host "   python3 solver/stage01_nc.py" -ForegroundColor White

Write-Host ""
Write-Host "6. VS Code з WSL:" -ForegroundColor Cyan
Write-Host "   code ." -ForegroundColor White
Write-Host "   (відкриє VS Code з підключенням до WSL)" -ForegroundColor White

Write-Host ""
Write-Host "7. Тестування:" -ForegroundColor Cyan
Write-Host "   ./test_all.sh" -ForegroundColor White

Write-Host ""
Write-Info "Python Virtual Environment (.venv):" -ForegroundColor Cyan
Write-Host "   - Вже створено setup_linux.sh" -ForegroundColor White
Write-Host "   - Активувати: source .venv/bin/activate" -ForegroundColor White
Write-Host "   - Деактивувати: deactivate" -ForegroundColor White

Write-Host ""
Write-Success "Готово! Приємного навчання! 🎓"
Write-Host ""

Read-Host "Натисніть Enter для виходу"
