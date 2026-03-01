# DXNN Analyzer Web Interface

Phoenix LiveView web interface for the DXNN Analyzer.

## Documentation

Please see the main project documentation:

- **[README.md](../README.md)** - Complete user guide, installation, and usage
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Technical architecture and design
- **[AI_README.md](../AI_README.md)** - Guide for AI assistants and developers

## Quick Start

### With Docker (Recommended)

```bash
cd ..
docker-compose up -d
```

Access at `http://localhost:4000`

### Local Development

```bash
# Install dependencies
mix deps.get
cd assets && npm install && cd ..

# Compile Erlang analyzer
cd ../dxnn_analyzer && rebar3 compile && cd ../dxnn_analyzer_web

# Start server
mix phx.server
```

Access at `http://localhost:4000`

### Windows Quick Setup

```powershell
.\setup.ps1
.\start.ps1
```

## Project Structure

```
lib/
├── dxnn_analyzer_web/
│   ├── live/              # LiveView pages
│   ├── components/        # Reusable components
│   ├── analyzer_bridge.ex # Erlang ↔ Elixir bridge
│   ├── endpoint.ex        # Phoenix endpoint
│   └── router.ex          # Routes
assets/
├── js/                    # JavaScript
└── css/                   # Tailwind CSS
config/                    # Configuration files
```

## Features

- Dashboard for loading and managing Mnesia contexts
- Agent browser with filtering and search
- Detailed agent inspection
- **Interactive Graph Visualization** - D3.js powered neural network visualization with:
  - Multiple layout algorithms (hierarchical, force-directed, circular)
  - Interactive node selection and details
  - Real-time zoom and pan
  - Connection weight visualization
  - Layer structure analysis
- Neural network topology viewer (raw data)
- Multi-agent comparison
- **Master Database** - Curate and manage elite agents across experiments:
  - Select agents from any loaded context
  - Save to centralized master database
  - View and manage your collection
  - Load master database as a context for analysis
  - Export for deployment to DXNN-Trader
- Real-time updates via LiveView

## Development

```bash
# Start server with IEx
iex -S mix phx.server

# Run tests
mix test

# Format code
mix format

# Compile assets
cd assets && npm run deploy
```

## Configuration

Edit `config/dev.exs` or `config/prod.exs` to change settings:

```elixir
config :dxnn_analyzer_web, DxnnAnalyzerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000]
```

## License

Apache 2.0
