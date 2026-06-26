DBT ?= dbt
SQLFLUFF ?= uvx --from sqlfluff sqlfluff
SQLFLUFF_PATHS ?= models tests macros
SQLFLUFF_TEMPLATER ?= jinja
SQLFLUFF_IGNORE ?= templating
DBT_SELECT ?=
STUDIO_LINT ?=

.PHONY: help lint-sql fix-sql lint-dbt lint-studio compile build check

help:
	@printf '%s\n' \
		'Available commands:' \
		'  make lint-sql      Run SQLFluff against dbt SQL paths' \
		'  make fix-sql       Auto-fix SQLFluff issues where possible' \
		'  make lint-dbt      Run dbt Core parser validation' \
		'  make lint-studio   Run Studio/Fusion lint command when configured' \
		'  make compile       Compile the project with dbt Core' \
		'  make build         Build the project with dbt Core' \
		'  make check         Run local SQL style, parse, and compile checks'

lint-sql:
	$(SQLFLUFF) lint --templater $(SQLFLUFF_TEMPLATER) --ignore $(SQLFLUFF_IGNORE) $(SQLFLUFF_PATHS)

fix-sql:
	$(SQLFLUFF) fix --templater $(SQLFLUFF_TEMPLATER) --ignore $(SQLFLUFF_IGNORE) $(SQLFLUFF_PATHS)

lint-dbt:
	$(DBT) parse

lint-studio:
	@if [ -z "$(STUDIO_LINT)" ]; then \
		echo "Set STUDIO_LINT to the local dbt Studio/Fusion lint command once installed."; \
		echo "Example: make lint-studio STUDIO_LINT='<studio lint command>'"; \
		exit 1; \
	fi
	$(STUDIO_LINT)

compile:
	$(DBT) compile $(if $(DBT_SELECT),--select $(DBT_SELECT),)

build:
	$(DBT) build $(if $(DBT_SELECT),--select $(DBT_SELECT),)

check: lint-sql lint-dbt compile
