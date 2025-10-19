@echo off
REM DeFi Admin Setup Script for Windows
REM This script sets up the development environment with virtual environment

echo ======================================
echo DeFi Admin Development Setup
echo ======================================
echo.

REM Check Python version
echo Checking Python version...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in PATH
    exit /b 1
)
python --version

REM Check Node.js
echo Checking Node.js version...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Node.js is not installed or not in PATH
    exit /b 1
)
node --version

REM Create virtual environment
echo.
echo Setting up Python virtual environment...
if not exist "backend\venv" (
    python -m venv backend\venv
    echo Virtual environment created at backend\venv
) else (
    echo Virtual environment already exists
)

REM Activate virtual environment
call backend\venv\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install Python dependencies
echo Installing Python dependencies...
pip install -r backend\requirements.txt
echo Python dependencies installed

REM Install development tools
echo Installing development tools...
pip install flake8 black pytest pytest-asyncio ipython
echo Development tools installed

REM Create .env file if it doesn't exist
if not exist "backend\.env" (
    echo.
    echo Creating .env file from template...
    copy backend\.env.example backend\.env
    echo Created backend\.env
    echo.
    echo Please edit backend\.env with your API keys and configuration
) else (
    echo backend\.env already exists
)

REM Install frontend dependencies
echo.
echo Installing frontend dependencies...
cd frontend
call npm install
cd ..
echo Frontend dependencies installed

REM Final instructions
echo.
echo ======================================
echo Setup Complete!
echo ======================================
echo.
echo Virtual environment location: backend\venv
echo.
echo To activate the virtual environment manually:
echo   backend\venv\Scripts\activate
echo.
echo To start the application:
echo   make run
echo.
echo Or start services individually:
echo   make run-backend  - Start backend server
echo   make run-frontend - Start frontend server
echo.
echo For more commands, run: make help
echo.

REM Check if .env needs configuration
findstr "your_openai_api_key_here" backend\.env >nul 2>&1
if %errorlevel% equ 0 (
    echo WARNING: Don't forget to configure backend\.env with your API keys!
)

pause