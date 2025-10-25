#!/usr/bin/env bash
# Скрипт для запуску презентації на Linux/macOS
# Автоматично встановлює залежності та запускає dev сервер

set -e  # Зупинитися при помилці

echo "========================================"
echo "  RE/PWN CTF Презентація"
echo "========================================"
echo

# Функція для перевірки наявності команди
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Перевірка наявності Node.js
if ! command_exists node; then
    echo "[ПОМИЛКА] Node.js не встановлений!"
    echo
    echo "Встановіть Node.js одним з наступних способів:"
    echo
    echo "Ubuntu/Debian:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
    echo "  sudo apt-get install -y nodejs"
    echo
    echo "macOS (Homebrew):"
    echo "  brew install node"
    echo
    echo "Fedora:"
    echo "  sudo dnf install nodejs"
    echo
    echo "Arch Linux:"
    echo "  sudo pacman -S nodejs npm"
    echo
    echo "Або завантажте з офіційного сайту:"
    echo "  https://nodejs.org/"
    exit 1
fi

# Перевірка наявності npm
if ! command_exists npm; then
    echo "[ПОМИЛКА] npm не знайдено!"
    echo
    echo "Переустановіть Node.js з офіційного сайту."
    exit 1
fi

echo "[OK] Node.js та npm встановлені"
node --version
npm --version
echo

# Перевірка наявності node_modules
if [ ! -d "node_modules" ]; then
    echo "[INFO] Встановлення залежностей..."
    echo "Це може зайняти кілька хвилин при першому запуску."
    echo
    npm install
    echo
    echo "[OK] Залежності встановлено успішно!"
else
    echo "[OK] Залежності вже встановлені"
fi

echo
echo "========================================"
echo "  Запуск презентації..."
echo "========================================"
echo
echo "Презентація буде доступна за адресою:"
echo "  http://localhost:3030"
echo
echo "Натисніть Ctrl+C для зупинки сервера"
echo

# Запуск dev сервера
npm run dev

# Якщо сервер зупинився
echo
echo "Презентація зупинена."
