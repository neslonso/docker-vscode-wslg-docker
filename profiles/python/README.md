# Python Development Profile

Complete Python development environment with modern tooling, linting, testing, and GUI support.

## Overview

This profile provides a comprehensive Python development setup suitable for:
- **GUI Applications** (Tkinter, PySimpleGUI, matplotlib)
- **Web Development** (Django, Flask, FastAPI)
- **Data Science** (pandas, numpy, jupyter notebooks)
- **General Python Development** (CLI tools, automation, scripting)
- **Testing & Quality Assurance** (pytest, code coverage)

## Features

### Development Tools

- **Python 3.x** - Latest Python interpreter
- **Poetry** - Modern dependency management and packaging
- **pip, venv, virtualenv** - Traditional package and environment management
- **ipython** - Enhanced interactive Python shell

### Code Quality & Linting

- **black** - Opinionated code formatter (PEP 8 compliant)
- **flake8** - Style guide enforcement
- **mypy** - Static type checking
- **isort** - Import statement organizer
- **pylint** - Comprehensive code analysis
- **autopep8** - Automatic PEP 8 formatting
- **pydocstyle** - Docstring style checker

### Testing Framework

- **pytest** - Modern testing framework
- **pytest-mock** - Mocking plugin
- **pytest-cov** - Code coverage reporting

### GUI Development

- **Tkinter (tk-dev)** - Built-in GUI framework
- Compatible with:
  - PySimpleGUI
  - matplotlib (data visualization)
  - Pillow (image processing)
  - Custom Tkinter applications

### VSCode Extensions

**Python Core:**
- Python extension pack
- Pylance (IntelliSense)
- Python debugger
- Environment manager

**Linting & Formatting:**
- Black formatter
- Flake8
- isort
- MyPy type checker
- Pylint

**Additional Tools:**
- Jupyter notebook support
- Auto-docstring generator
- IntelliCode (AI-assisted completions)
- Python test adapter
- TOML support (pyproject.toml)

**Utilities:**
- Git Graph
- Docker support
- Markdown preview
- Code spell checker
- TODO tree
- Indent rainbow

## Quick Start

### Launch the Environment

```bash
# From your Python project directory
vsc-wslg up python

# Or with DooD mode (share host Docker)
vsc-wslg up python dood
```

### Project Structure Examples

#### Using Poetry (Recommended)

```bash
# Inside VSCode container terminal
poetry init
poetry add pysimplegui matplotlib
poetry add --group dev pytest black

# Run your application
poetry run python main.py

# Run tests
poetry run pytest
```

#### Using pip + requirements.txt

```bash
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run your application
python main.py
```

#### Using pip + pyproject.toml

```bash
# Install project dependencies
pip install -e .

# Or with development dependencies
pip install -e ".[dev]"
```

## Usage Examples

### GUI Application Development

Create a simple GUI app with Tkinter:

```python
# main.py
import tkinter as tk
from tkinter import ttk

def main():
    root = tk.Tk()
    root.title("My App")
    root.geometry("400x300")

    label = ttk.Label(root, text="Hello from Docker WSLg!")
    label.pack(pady=20)

    button = ttk.Button(root, text="Click Me", command=lambda: print("Clicked!"))
    button.pack(pady=10)

    root.mainloop()

if __name__ == "__main__":
    main()
```

Run it:
```bash
python main.py
# GUI window appears via WSLg!
```

### Web Development

```bash
# Flask example
poetry add flask
poetry run python app.py

# Django example
poetry add django
poetry run django-admin startproject mysite
cd mysite
poetry run python manage.py runserver
```

### Data Visualization

```python
# plot.py
import matplotlib.pyplot as plt

plt.plot([1, 2, 3, 4], [1, 4, 2, 3])
plt.ylabel('Some numbers')
plt.show()  # Opens in GUI window via WSLg
```

### Testing

```python
# test_calculator.py
def add(a, b):
    return a + b

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
```

Run tests:
```bash
pytest                    # Run all tests
pytest -v                 # Verbose output
pytest --cov              # With coverage
pytest tests/test_*.py    # Specific files
```

## Configuration

### Python Formatting (Black)

The profile is pre-configured with:
- **Line length:** 88 characters (Black default)
- **Format on save:** Enabled
- **Auto-organize imports:** Enabled (isort)

Customize in `.vscode/settings.json`:
```json
{
  "black-formatter.args": ["--line-length=100"],
  "isort.args": ["--profile=black", "--line-length=100"]
}
```

### Linting

Multiple linters are enabled by default:
- **Flake8:** Style enforcement
- **Pylint:** Code analysis
- **MyPy:** Type checking (strict mode)

Configure in your project's `pyproject.toml`:
```toml
[tool.black]
line-length = 88

[tool.isort]
profile = "black"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
```

### Type Checking

MyPy is configured in strict mode. To adjust:

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = true
```

## Common Workflows

### Starting a New Project

```bash
# Inside container
poetry new my-project
cd my-project

# Add dependencies
poetry add requests pysimplegui
poetry add --group dev pytest black mypy

# Install project
poetry install

# Start coding!
code .
```

### Working with Existing Projects

```bash
# Clone your project
git clone https://github.com/user/my-project.git
cd my-project

# Launch VSCode with Python profile
vsc-wslg up python

# Inside container:
poetry install              # If using Poetry
# or
pip install -r requirements.txt  # If using pip
```

### Jupyter Notebooks

The profile includes full Jupyter support:

```bash
# Install Jupyter
poetry add jupyter

# Create a notebook in VSCode
# File > New File > Jupyter Notebook

# Or run Jupyter server
poetry run jupyter notebook
```

## Installed Python Tools

### System Packages
- `python3` - Python interpreter
- `python3-pip` - Package installer
- `python3-venv` - Virtual environment support
- `python3-dev` - Development headers
- `python3-tk` - Tkinter GUI library
- `tk-dev` - Tk development files
- `build-essential` - Compilation tools (for C extensions)

### Python Packages (Global)
- `poetry` - Dependency management
- `black` - Code formatter
- `flake8` - Linter
- `mypy` - Type checker
- `isort` - Import organizer
- `pylint` - Code analyzer
- `pytest` - Testing framework
- `pytest-mock` - Mocking support
- `pytest-cov` - Coverage reporting
- `autopep8` - Auto-formatter
- `pydocstyle` - Docstring checker
- `ipython` - Interactive shell
- `virtualenv` - Virtual environments
- `pipenv` - Alternative package manager

## Tips & Best Practices

### Dependency Management

**Prefer Poetry for new projects:**
```bash
poetry init
poetry add <package>
poetry install
```

**Use virtual environments with pip:**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Code Quality

**Format before committing:**
```bash
black .
isort .
```

**Run linters:**
```bash
flake8 src/
pylint src/
mypy src/
```

**Run tests with coverage:**
```bash
pytest --cov=src --cov-report=html
```

### Performance

**For large projects:**
- Use `.vscode/settings.json` to exclude `__pycache__`, `.venv`, etc.
- Disable unused linters if they slow down the editor
- Use `"python.analysis.diagnosticMode": "openFilesOnly"` for faster analysis

## Troubleshooting

### GUI Applications Don't Display

**Ensure WSLg is working:**
```bash
echo $DISPLAY
# Should show something like :0
```

**Test with simple Tkinter:**
```python
import tkinter as tk
tk.Tk().mainloop()
```

### Poetry Not Found

**Restart the shell or update PATH:**
```bash
export PATH="/home/dev/.local/bin:$PATH"
source ~/.bashrc
```

### Import Errors in VSCode

**Select the correct Python interpreter:**
- Press `Ctrl+Shift+P`
- Type "Python: Select Interpreter"
- Choose your virtual environment or `/usr/bin/python3`

### Linters Not Working

**Verify installation:**
```bash
which black flake8 mypy pylint
python3 -m black --version
```

**Check VSCode settings:**
```json
{
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true
}
```

## Version Information

- **Python:** 3.x (Debian default, usually 3.11+)
- **Poetry:** Latest stable
- **Black:** Latest (PEP 8 compliant)
- **Pytest:** Latest stable

## Related Profiles

- **devops** - Shell scripting, Docker, YAML tools
- **rust** - Rust development with cargo and rust-analyzer
- **symfony** - PHP/Symfony development

## Resources

- [Python Official Docs](https://docs.python.org/)
- [Poetry Documentation](https://python-poetry.org/docs/)
- [Black Code Style](https://black.readthedocs.io/)
- [pytest Documentation](https://docs.pytest.org/)
- [Tkinter Tutorial](https://docs.python.org/3/library/tkinter.html)
- [PySimpleGUI](https://www.pysimplegui.org/)

## Contributing

To enhance this profile:
1. Add new extensions to `vscode/extensions.list`
2. Update settings in `vscode/settings.json`
3. Add system packages to `setup.sh`
4. Update this README with new features
