.PHONY: all compile clean test shell help

all: compile

compile:
	@echo "Compiling DXNN Analyzer..."
	rebar3 compile

clean:
	@echo "Cleaning build artifacts..."
	rebar3 clean
	rm -rf _build

test:
	@echo "Running tests..."
	rebar3 eunit

shell:
	@echo "Starting Erlang shell with DXNN Analyzer..."
	rebar3 shell

help:
	@echo "DXNN Analyzer - Makefile targets:"
	@echo "  make compile  - Compile the project"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make test     - Run unit tests"
	@echo "  make shell    - Start Erlang shell"
	@echo "  make help     - Show this help message"
