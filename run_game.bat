@echo off
echo ========================================
echo   Lexica Spire - Quick Launch
echo ========================================
echo.

set GODOT="%~dp0Godot_v4.3-stable_win64.exe"
set PROJECT="%~dp0godot\project.godot"

if not exist %GODOT% (
    echo ERROR: Godot 4.3 not found at %GODOT%
    echo Download it from https://godotengine.org/download/archive/4.3-stable/
    pause
    exit /b 1
)

if not exist %PROJECT% (
    echo ERROR: project.godot not found at %PROJECT%
    pause
    exit /b 1
)

echo Starting game...
start "" %GODOT% --path "%~dp0godot"
