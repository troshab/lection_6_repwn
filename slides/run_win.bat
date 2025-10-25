@echo off
echo ========================================
echo   RE/PWN CTF Presentation
echo ========================================
echo.

REM Check if node_modules exists
if not exist "node_modules\" (
    echo [INFO] Installing dependencies...
    echo.
    npm install
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies!
        pause
        exit /b 1
    )
    echo.
)

echo Starting presentation server...
echo.
echo Open in browser: http://localhost:3030
echo Press Ctrl+C to stop
echo.

npm run dev
