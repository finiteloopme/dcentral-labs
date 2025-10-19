.PHONY: help venv install install-backend install-frontend run run-backend run-frontend build test clean docker-build docker-run

# Detect OS for virtual environment activation
ifeq ($(OS),Windows_NT)
    VENV_ACTIVATE = backend\venv\Scripts\activate
    PYTHON = backend\venv\Scripts\python
    PIP = backend\venv\Scripts\pip
else
    VENV_ACTIVATE = backend/venv/bin/activate
    PYTHON = backend/venv/bin/python
    PIP = backend/venv/bin/pip
endif

help:
	@echo "DeFi Admin - Makefile Commands"
	@echo "==============================="
	@echo "venv             - Create Python virtual environment"
	@echo "install          - Install all dependencies (backend + frontend)"
	@echo "install-backend  - Install Python backend dependencies in venv"
	@echo "install-frontend - Install TypeScript frontend dependencies"
	@echo "run             - Run both backend and frontend"
	@echo "run-backend     - Run Python backend server"
	@echo "run-frontend    - Run React frontend dev server"
	@echo "build           - Build production version"
	@echo "test            - Run all tests"
	@echo "clean           - Clean up generated files and venv"
	@echo "clean-venv      - Remove virtual environment"
	@echo "docker-build    - Build Docker containers"
	@echo "docker-run      - Run application in Docker"
	@echo "freeze          - Update requirements.txt with current packages"

venv:
	@echo "Creating Python virtual environment..."
	@if [ ! -d "backend/venv" ]; then \
		python3 -m venv backend/venv || { echo "Error creating virtual environment"; exit 1; }; \
		echo "Virtual environment created at backend/venv"; \
		echo "Python version: $$(backend/venv/bin/python --version)"; \
	else \
		echo "Virtual environment already exists"; \
		echo "Python version: $$(backend/venv/bin/python --version 2>/dev/null || echo 'Unable to detect')"; \
	fi

install: venv install-backend install-frontend

install-backend: venv
	@echo "Installing Python backend dependencies in virtual environment..."
	@$(PIP) install --upgrade pip setuptools wheel || { echo "Error upgrading pip"; exit 1; }
	@echo "Installing requirements..."
	@$(PIP) install -r backend/requirements.txt || { \
		echo ""; \
		echo "Error installing dependencies. Trying with --no-cache-dir..."; \
		$(PIP) install --no-cache-dir -r backend/requirements.txt || { \
			echo ""; \
			echo "Installation failed. Common solutions:"; \
			echo "1. Try: make install-backend-compat (for compatibility mode)"; \
			echo "2. Check Python version: python3 --version (3.8-3.11 recommended)"; \
			echo "3. Clear cache: make clean-cache"; \
			exit 1; \
		}; \
	}
	@echo "Backend dependencies installed successfully"

install-frontend:
	@echo "Installing TypeScript frontend dependencies..."
	cd frontend && npm install
	@echo "Frontend dependencies installed successfully"

run:
	@echo "Starting DeFi Admin application..."
	@make -j 2 run-backend run-frontend

run-backend: venv
	@echo "Starting backend server on http://localhost:8000..."
	@cd backend && $(PYTHON) main.py

run-frontend:
	@echo "Starting frontend dev server on http://localhost:3000..."
	cd frontend && npm start

build: build-backend build-frontend

build-backend: venv
	@echo "Building backend..."
	@$(PYTHON) -m compileall backend/

build-frontend:
	@echo "Building frontend production bundle..."
	cd frontend && npm run build

test: test-backend test-frontend

test-backend: venv
	@echo "Running backend tests..."
	@cd backend && $(PYTHON) -m pytest tests/ -v

test-frontend:
	@echo "Running frontend tests..."
	cd frontend && npm test -- --watchAll=false

lint: lint-backend lint-frontend

lint-backend: venv
	@echo "Linting Python code..."
	@$(PYTHON) -m flake8 backend/ --max-line-length=120 --exclude=venv

lint-frontend:
	@echo "Linting TypeScript code..."
	cd frontend && npm run lint

format: format-backend format-frontend

format-backend: venv
	@echo "Formatting Python code..."
	@$(PYTHON) -m black backend/ --exclude=venv

format-frontend:
	@echo "Formatting TypeScript code..."
	cd frontend && npm run format

freeze: venv
	@echo "Updating requirements.txt with current packages..."
	@$(PIP) freeze > backend/requirements.txt
	@echo "requirements.txt updated"

clean:
	@echo "Cleaning up..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf backend/.pytest_cache
	rm -rf frontend/node_modules
	rm -rf frontend/build
	rm -rf backend/defi_admin.db
	@echo "Cleanup complete"

clean-venv:
	@echo "Removing virtual environment..."
	rm -rf backend/venv
	@echo "Virtual environment removed"

clean-all: clean clean-venv
	@echo "Full cleanup complete"

clean-cache:
	@echo "Clearing pip cache..."
	@$(PIP) cache purge 2>/dev/null || pip cache purge 2>/dev/null || echo "Cache cleared"
	@rm -rf ~/.cache/pip
	@echo "Cache cleared"

install-backend-compat: venv
	@echo "Installing backend with compatibility mode..."
	@$(PIP) install --upgrade pip setuptools wheel
	@echo "Installing core dependencies first..."
	@$(PIP) install fastapi uvicorn pydantic python-dotenv
	@echo "Installing remaining dependencies..."
	@for req in $$(cat backend/requirements.txt | grep -v '^#' | grep -v '^$$'); do \
		echo "Installing $$req..."; \
		$(PIP) install "$$req" || echo "Warning: Failed to install $$req"; \
	done
	@echo "Compatibility installation complete"

diagnose: venv
	@echo "System Diagnostics"
	@echo "=================="
	@echo "OS: $$(uname -s)"
	@echo "Python: $$(python3 --version)"
	@echo "Pip: $$($(PIP) --version 2>/dev/null || echo 'Not found')"
	@echo "Venv Python: $$($(PYTHON) --version 2>/dev/null || echo 'Not found')"
	@echo "Venv location: backend/venv"
	@echo ""
	@echo "Testing imports..."
	@$(PYTHON) -c "import sys; print(f'Python path: {sys.executable}')" 2>/dev/null || echo "Error: Cannot run Python"
	@$(PYTHON) -c "import fastapi; print('✓ FastAPI imported')" 2>/dev/null || echo "✗ FastAPI not available"
	@$(PYTHON) -c "import uvicorn; print('✓ Uvicorn imported')" 2>/dev/null || echo "✗ Uvicorn not available"
	@$(PYTHON) -c "import pydantic; print('✓ Pydantic imported')" 2>/dev/null || echo "✗ Pydantic not available"

docker-build:
	@echo "Building Docker containers..."
	docker-compose build

docker-run:
	@echo "Running application in Docker..."
	docker-compose up

docker-stop:
	@echo "Stopping Docker containers..."
	docker-compose down

setup-env: venv
	@echo "Setting up environment..."
	@if [ ! -f "backend/.env" ]; then \
		cp backend/.env.example backend/.env; \
		echo "Created backend/.env from template"; \
		echo "Please edit backend/.env with your API keys and configuration"; \
	else \
		echo "backend/.env already exists"; \
	fi

dev-setup: venv install setup-env
	@echo "Development environment setup complete!"
	@echo "Virtual environment: backend/venv"
	@echo "Edit backend/.env with your configuration"
	@echo "Run 'make run' to start the application"

# Development helpers
shell: venv
	@echo "Activating Python shell with virtual environment..."
	@cd backend && $(PYTHON)

ipython: venv
	@echo "Starting IPython shell..."
	@$(PIP) install ipython 2>/dev/null || true
	@cd backend && $(PYTHON) -m IPython

check-deps: venv
	@echo "Checking for outdated packages..."
	@$(PIP) list --outdated

upgrade-deps: venv
	@echo "Upgrading all packages..."
	@$(PIP) list --outdated --format=json | $(PYTHON) -c "import json, sys; packages = json.load(sys.stdin); [print(f'Upgrading {p[\"name\"]}') or sys.stdout.flush() or __import__('subprocess').run(['$(PIP)', 'install', '--upgrade', p['name']]) for p in packages]"
	@make freeze

# Backend-specific commands with venv
backend-shell: venv
	@echo "Starting backend shell with environment loaded..."
	@cd backend && $(PYTHON) -c "import os; os.system('bash')"

backend-migrate: venv
	@echo "Running database migrations..."
	@cd backend && $(PYTHON) -m alembic upgrade head

backend-makemigrations: venv
	@echo "Creating new migration..."
	@cd backend && $(PYTHON) -m alembic revision --autogenerate -m "$(MSG)"

# Quick development commands
dev: venv
	@echo "Starting development servers..."
	@make -j 2 run-backend run-frontend

dev-backend: venv
	@echo "Starting backend in development mode..."
	@cd backend && $(PYTHON) -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

dev-frontend:
	@echo "Starting frontend in development mode..."
	cd frontend && npm start

# Installation verification
verify: venv
	@echo "Verifying installation..."
	@echo "Python version:"
	@$(PYTHON) --version
	@echo ""
	@echo "Installed packages:"
	@$(PIP) list
	@echo ""
	@echo "Node version:"
	@node --version
	@echo ""
	@echo "NPM version:"
	@npm --version
	@echo ""
	@echo "Verification complete!"

# Help for virtual environment
venv-help:
	@echo "Virtual Environment Information"
	@echo "==============================="
	@echo "Location: backend/venv"
	@echo ""
	@echo "To activate manually:"
	@echo "  Linux/Mac: source backend/venv/bin/activate"
	@echo "  Windows: backend\\venv\\Scripts\\activate"
	@echo ""
	@echo "To deactivate: deactivate"
	@echo ""
	@echo "All make commands automatically use the virtual environment"