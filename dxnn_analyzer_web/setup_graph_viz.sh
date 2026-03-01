#!/bin/bash
# Setup script for Graph Visualization feature

echo "=== DXNN Analyzer - Graph Visualization Setup ==="
echo ""

# Check if we're in the right directory
if [ ! -f "mix.exs" ]; then
    echo "Error: Please run this script from the dxnn_analyzer_web directory"
    exit 1
fi

echo "Step 1: Installing Node.js dependencies (including D3.js)..."
cd assets
npm install
if [ $? -ne 0 ]; then
    echo "Error: npm install failed"
    exit 1
fi
echo "✓ Node.js dependencies installed"
echo ""

echo "Step 2: Compiling assets..."
npm run deploy
if [ $? -ne 0 ]; then
    echo "Error: Asset compilation failed"
    exit 1
fi
echo "✓ Assets compiled"
echo ""

cd ..

echo "Step 3: Installing Elixir dependencies..."
mix deps.get
if [ $? -ne 0 ]; then
    echo "Error: mix deps.get failed"
    exit 1
fi
echo "✓ Elixir dependencies installed"
echo ""

echo "Step 4: Compiling Erlang analyzer..."
cd ../dxnn_analyzer
if [ -f "rebar.config" ]; then
    rebar3 compile
    if [ $? -ne 0 ]; then
        echo "Warning: Erlang analyzer compilation had issues"
    else
        echo "✓ Erlang analyzer compiled"
    fi
else
    echo "Warning: dxnn_analyzer not found, skipping Erlang compilation"
fi
cd ../dxnn_analyzer_web
echo ""

echo "=== Setup Complete! ==="
echo ""
echo "To start the server:"
echo "  mix phx.server"
echo ""
echo "Then navigate to: http://localhost:4000"
echo ""
echo "New features:"
echo "  - Interactive Graph Visualization at /graph/:agent_id"
echo "  - Multiple layout algorithms (hierarchical, force-directed, circular)"
echo "  - Click nodes to see detailed information"
echo "  - Zoom and pan with mouse/trackpad"
echo ""
