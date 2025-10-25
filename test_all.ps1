# ========================================
# RE/PWN CTF - Тестування (PowerShell wrapper)
# ========================================
# Запускає test_all.sh в WSL Ubuntu та показує результати

param(
    [switch]$Verbose
)

# Кольори
function Write-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ========================================
# Початок
# ========================================

Write-Header "RE/PWN CTF - Запуск тестування"
Write-Host ""

# ========================================
# Перевірка WSL
# ========================================

Write-Info "Перевірка WSL..."

try {
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "WSL не знайдено"
        Write-Host ""
        Write-Info "Спочатку встановіть WSL:"
        Write-Info "  1. Запустіть setup_windows.ps1"
        Write-Info "  2. Або вручну: wsl --install"
        Write-Host ""
        Read-Host "Натисніть Enter для виходу"
        exit 1
    }
    Write-Success "WSL знайдено"
} catch {
    Write-Error "Помилка перевірки WSL: $_"
    exit 1
}

Write-Host ""

# ========================================
# Перевірка Ubuntu
# ========================================

Write-Info "Перевірка Ubuntu..."

try {
    $distributions = wsl --list --quiet 2>$null
    if ($distributions -match "Ubuntu") {
        Write-Success "Ubuntu знайдено"
    } else {
        Write-Error "Ubuntu не знайдено в WSL"
        Write-Host ""
        Write-Info "Встановіть Ubuntu через:"
        Write-Info "  1. setup_windows.ps1"
        Write-Info "  2. Microsoft Store: Ubuntu 22.04"
        Write-Host ""
        Read-Host "Натисніть Enter для виходу"
        exit 1
    }
} catch {
    Write-Error "Помилка перевірки Ubuntu: $_"
    exit 1
}

Write-Host ""

# ========================================
# Підготовка шляху
# ========================================

$scriptPath = $PSScriptRoot
$wslPath = $scriptPath -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/'
$wslPath = $wslPath.ToLower()

Write-Info "Шлях проєкту: $scriptPath"
Write-Info "WSL шлях: $wslPath"
Write-Host ""

# ========================================
# Запуск тестування
# ========================================

Write-Header "Запуск test_all.sh в WSL"
Write-Host ""

# Підготовка команди
$testCommand = @"
cd '$wslPath'
chmod +x test_all.sh
./test_all.sh
"@

if ($Verbose) {
    Write-Info "Команда:"
    Write-Host $testCommand -ForegroundColor DarkGray
    Write-Host ""
}

# Запуск
try {
    wsl bash -c $testCommand
    $testResult = $LASTEXITCODE

    Write-Host ""
    Write-Header "Результат"

    if ($testResult -eq 0) {
        Write-Success "Всі тести пройдено успішно! 🎉"
        Write-Host ""
        Write-Info "Проєкт повністю готовий до використання"
    } elseif ($testResult -eq 1) {
        Write-Host "[WARNING] Деякі тести провалено" -ForegroundColor Yellow
        Write-Host ""
        Write-Info "Більшість компонентів працює, але є деякі проблеми"
        Write-Info "Перегляньте вивід вище для деталей"
    } else {
        Write-Error "Багато тестів провалено"
        Write-Host ""
        Write-Info "Рекомендується:"
        Write-Info "  1. Запустити setup_windows.ps1 знову"
        Write-Info "  2. Або в WSL: ./setup_linux.sh"
    }

    Write-Host ""

    if ($testResult -eq 0) {
        Write-Info "Наступні кроки:"
        Write-Host "  1. RE завдання: wsl" -ForegroundColor White
        Write-Host "     cd $wslPath/re/task01_inventory" -ForegroundColor DarkGray
        Write-Host "     make && ./build/re101" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  2. PWN завдання: wsl" -ForegroundColor White
        Write-Host "     cd $wslPath/pwn" -ForegroundColor DarkGray
        Write-Host "     docker compose up -d" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  3. VS Code: code ." -ForegroundColor White
        Write-Host "     (відкриє в WSL режимі)" -ForegroundColor DarkGray
    }

    Write-Host ""
    exit $testResult

} catch {
    Write-Error "Помилка під час тестування: $_"
    Write-Host ""
    Write-Info "Спробуйте запустити вручну:"
    Write-Info "  wsl"
    Write-Info "  cd $wslPath"
    Write-Info "  ./test_all.sh"
    Write-Host ""
    exit 1
}
