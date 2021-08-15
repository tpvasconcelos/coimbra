# ==============================================================
# ---  Help (default goal)
# ==============================================================

.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT


.PHONY: help
help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)


# ==============================================================
# ---  Variables
# ==============================================================

# Adjustable through export
BASE_PYTHON	?= python3.7

# Virtual environment
VENV_PATH	= .venv
VENV_BIN	= $(VENV_PATH)/bin
VENV_PYTHON	= $(VENV_BIN)/python


# ==============================================================
# ---  Setup development environment
# ==============================================================

.PHONY: init
GIT_INITIALISED = "$((git rev-parse --is-inside-work-tree > /dev/null 2>&1 && echo true) || false)"
ifeq ($(GIT_INITIALISED), true)
init: init-dev ## [if inside git working tree] initialise development environment
else
init:  git-init init-dev ## [if not inside git working tree] initialise git repository and development environment
endif


.PHONY: git-init
git-init: ## initialize git repository
	git init
	git add --all
	git commit -m "Generate initial project structured (cookiecutter gh:tpvasconcelos/python-library-template)"
	git remote add origin git@github.com:tpvasconcelos/coimbra.git
	git branch -M master
	git push -u origin master


.PHONY: init-dev
init-dev: clean-all init-venv install ## initialise development environment


.PHONY: init-venv
init-venv: clean-venv ## create a virtual environment
	$(BASE_PYTHON) -m pip install --upgrade pip
	$(BASE_PYTHON) -m venv "$(VENV_PATH)"


.PHONY: install
install: ## install the package in editable mode and install all pre-commit hooks
	$(VENV_PYTHON) -m pip install --upgrade pip setuptools wheel
	$(VENV_PYTHON) -m pip install -e ".[dev]"
	$(VENV_PYTHON) -m pre_commit install --install-hooks --overwrite


.PHONY: init-jupyter
init-jupyter: ## initialise a jupyterlab environment and install extensions
	$(VENV_PYTHON) -m pip install -e ".[notebook]"
	$(VENV_PYTHON) -m ipykernel install --user --name="coimbra"
	$(VENV_PYTHON) -m jupyter lab build


.PHONY: jupyter-plotly
jupyter-plotly: ## setup jupyterlab's plotly extensions
	$(VENV_PYTHON) -m jupyter labextension install @jupyter-widgets/jupyterlab-manager \
                                              jupyterlab-plotly \
                                              plotlywidget
	$(VENV_PYTHON) -m jupyter lab build


# ==============================================================
# ---  Building and releasing
# ==============================================================

.PHONY: docs
docs: ## generate Sphinx HTML documentation, including API docs
	#rm -f docs/coimbra.rst
	#rm -f docs/modules.rst
	#sphinx-apidoc -o docs/ coimbra
	$(MAKE) --directory=docs clean
	$(MAKE) --directory=docs html
	$(VENV_PYTHON) "scripts/open_in_browser.py" "docs/build/html/index.html"


.PHONY: servedocs
servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) --directory=docs html' -R -D .


.PHONY: dist
dist: clean-build ## builds source and wheel package
	$(VENV_PYTHON) setup.py sdist bdist_wheel
	$(VENV_PYTHON) -m twine check --strict dist/*


.PHONY: release-test
release-test: dist ## package and upload a release to test pypi
	$(VENV_PYTHON) -m twine upload --verbose --repository testpypi dist/*


.PHONY: release-prod
release-prod: dist ## package and upload a release prod pypi
	$(VENV_PYTHON) -m twine upload --verbose dist/*


# ==============================================================
# ---  Cleaning
# ==============================================================

.PHONY: clean-all
clean-all: clean-ci clean-venv clean-build clean-pyc ## remove all artifacts


.PHONY: clean-build
clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +


.PHONY: clean-pyc
clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +


.PHONY: clean-ci
clean-ci: ## remove linting, testing, and coverage artifacts
	rm -fr .tox/
	rm -fr .pytest_cache
	rm -fr .mypy_cache/
	find . -name 'coverage.xml' -exec rm -f {} +
	find . -name '.coverage' -exec rm -f {} +


.PHONY: clean-venv
clean-venv: ## remove venv artifacts
	rm -fr .venv
