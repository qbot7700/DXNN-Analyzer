#!/bin/bash

# DXNN Analyzer Installation Verification Script

echo "=========================================="
echo "DXNN Analyzer - Installation Verification"
echo "=========================================="
echo ""

# Check Erlang installation
echo "Checking Erlang installation..."
if command -v erl &> /dev/null; then
    ERL_VERSION=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>&1)
    echo "✓ Erlang found: OTP $ERL_VERSION"
    
    # Check version (need OTP 26+)
    if [ "$ERL_VERSION" -ge 26 ]; then
        echo "✓ Erlang version is sufficient (26+)"
    else
        echo "✗ Erlang version is too old (need 26+, have $ERL_VERSION)"
        echo "  Please upgrade Erlang"
    fi
else
    echo "✗ Erlang not found"
    echo "  Please install Erlang/OTP 26 or later"
    exit 1
fi

echo ""

# Check Rebar3 installation
echo "Checking Rebar3 installation..."
if command -v rebar3 &> /dev/null; then
    REBAR_VERSION=$(rebar3 version 2>&1 | head -n 1)
    echo "✓ Rebar3 found: $REBAR_VERSION"
else
    echo "✗ Rebar3 not found"
    echo "  Please install Rebar3"
    exit 1
fi

echo ""

# Check project structure
echo "Checking project structure..."

REQUIRED_DIRS=("src" "include" "priv/examples")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ Directory exists: $dir"
    else
        echo "✗ Directory missing: $dir"
    fi
done

echo ""

REQUIRED_FILES=(
    "rebar.config"
    "Makefile"
    "README.md"
    "include/records.hrl"
    "include/analyzer_records.hrl"
    "src/dxnn_analyzer.app.src"
    "src/analyzer.erl"
    "src/mnesia_loader.erl"
    "src/agent_inspector.erl"
    "src/topology_mapper.erl"
    "src/mutation_analyzer.erl"
    "src/population_builder.erl"
    "src/comparator.erl"
    "src/stats_collector.erl"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ File exists: $file"
    else
        echo "✗ File missing: $file"
    fi
done

echo ""

# Try to compile
echo "Attempting to compile..."
if make compile > /tmp/dxnn_compile.log 2>&1; then
    echo "✓ Compilation successful"
else
    echo "✗ Compilation failed"
    echo "  Check /tmp/dxnn_compile.log for details"
    cat /tmp/dxnn_compile.log
    exit 1
fi

echo ""

# Check compiled modules
echo "Checking compiled modules..."
MODULES=(
    "analyzer"
    "mnesia_loader"
    "agent_inspector"
    "topology_mapper"
    "mutation_analyzer"
    "population_builder"
    "comparator"
    "stats_collector"
)

BEAM_DIR="_build/default/lib/dxnn_analyzer/ebin"
if [ -d "$BEAM_DIR" ]; then
    for module in "${MODULES[@]}"; do
        if [ -f "$BEAM_DIR/$module.beam" ]; then
            echo "✓ Module compiled: $module"
        else
            echo "✗ Module not compiled: $module"
        fi
    done
else
    echo "✗ Build directory not found: $BEAM_DIR"
fi

echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo ""
echo "If all checks passed, you can start using DXNN Analyzer:"
echo ""
echo "  1. Start the shell:"
echo "     make shell"
echo ""
echo "  2. In the Erlang shell:"
echo "     analyzer:start()."
echo ""
echo "  3. Load a Mnesia folder:"
echo "     analyzer:load(\"path/to/Mnesia.nonode@nohost\", exp1)."
echo ""
echo "  4. Find best agents:"
echo "     analyzer:find_best(5, [{context, exp1}])."
echo ""
echo "For more information, see:"
echo "  - README.md"
echo "  - GETTING_STARTED.md"
echo "  - QUICK_REFERENCE.md"
echo ""
echo "=========================================="
