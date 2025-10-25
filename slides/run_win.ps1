# PowerShell скрипт для запуску презентації на Windows
# Використання: .\run_win.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RE/PWN CTF Презентація" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Перевірка наявності Node.js
$nodeExists = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeExists) {
    Write-Host "[ПОМИЛКА] Node.js не встановлений!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Завантажте та встановіть Node.js з:" -ForegroundColor Yellow
    Write-Host "https://nodejs.org/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Рекомендована версія: LTS (Long Term Support)" -ForegroundColor Yellow
    Read-Host "Натисніть Enter для виходу"
    exit 1
}

# Перевірка наявності npm
$npmExists = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmExists) {
    Write-Host "[ПОМИЛКА] npm не знайдено!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Переустановіть Node.js з офіційного сайту." -ForegroundColor Yellow
    Read-Host "Натисніть Enter для виходу"
    exit 1
}

Write-Host "[OK] Node.js та npm встановлені" -ForegroundColor Green
node --version
npm --version
Write-Host ""

# Перевірка наявності node_modules
if (-not (Test-Path "node_modules")) {
    Write-Host "[INFO] Встановлення залежностей..." -ForegroundColor Yellow
    Write-Host "Це може зайняти кілька хвилин при першому запуску." -ForegroundColor Yellow
    Write-Host ""

    npm install

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ПОМИЛКА] Не вдалося встановити залежності!" -ForegroundColor Red
        Read-Host "Натисніть Enter для виходу"
        exit 1
    }

    Write-Host ""
    Write-Host "[OK] Залежності встановлено успішно!" -ForegroundColor Green
} else {
    Write-Host "[OK] Залежності вже встановлені" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Запуск презентації..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Презентація буде доступна за адресою:" -ForegroundColor Green
Write-Host "  http://localhost:3030" -ForegroundColor Cyan
Write-Host ""
Write-Host "Натисніть Ctrl+C для зупинки сервера" -ForegroundColor Yellow
Write-Host ""

# Запуск dev сервера
npm run dev

# Якщо сервер зупинився
Write-Host ""
Write-Host "Презентація зупинена." -ForegroundColor Yellow
