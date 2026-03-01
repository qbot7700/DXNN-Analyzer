# DXNN Analyzer Web Interface

A modern Phoenix LiveView web interface for analyzing DXNN (Deep eXtended Neural Network) trading agents. Provides real-time interactive analysis through your browser with seamless Erlang-Elixir integration.

## Features

- **Dashboard**: Load and manage multiple Mnesia contexts from different experiments
- **Agent Browser**: View, filter, and search agents with real-time updates
- **Agent Inspector**: Detailed analysis of individual agents including fitness, topology, and evolution history
- **Topology Viewer**: Visualize neural network structure with sensors, neurons, and actuators
- **Comparator**: Compare multiple agents side-by-side with similarity analysis
- **Master Database**: Curate and manage elite agents across all experiments
  - Select agents from any loaded context
  - Save to centralized master database
  - View and manage your collection of best performers
  - Load master database as a context for analysis
  - Export for deployment to DXNN-Trader
- **Real-time Updates**: LiveView provides instant UI updates without page refreshes

## Quick Start with Docker

### Prerequisites

- Docker and Docker Compose
- Your DXNN-Trader Mnesia database folders

### Run with Docker Compose

1. **Clone or navigate to the project directory**

2. **Start the container:**
```bash
docker-compose up -d
```

3. **Access the interface:**
Open your browser to `http://localhost:4000`

4. **Load a context:**
   - Path: `/app/DXNN-Trader-V2/DXNN-Trader-v2/Mnesia.nonode@nohost`
   - Name: `exp1`

### Custom Mnesia Folder Location

Edit `docker-compose.yml` to mount your Mnesia folders:

```yaml
volumes:
  - /path/to/your/mnesia:/app/mnesia:ro
```

Then use path `/app/mnesia/Mnesia.nonode@nohost` in the interface.

### Stop the Container

```bash
docker-compose down
```

## Local Development Setup

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 26+
- Node.js 18+
- Rebar3

### Installation

1. **Install dependencies:**
```bash
cd dxnn_analyzer_web
mix deps.get
cd assets && npm install && cd ..
```

2. **Compile the Erlang analyzer:**
```bash
cd ../dxnn_analyzer
rebar3 compile
cd ../dxnn_analyzer_web
```

3. **Start the server:**
```bash
mix phx.server
```

4. **Access at:** `http://localhost:4000`

### Windows Quick Setup

Run the automated setup script:
```powershell
cd dxnn_analyzer_web
.\setup.ps1
.\start.ps1
```

## Usage Guide

### Loading Contexts

1. Navigate to the dashboard (`/`)
2. Enter your Mnesia folder path
3. Provide a context name (e.g., `exp1`, `experiment_2024`)
4. Click "Load Context"

The context will be loaded into memory and you can view its agents.

### Viewing Agents

1. Click "View Agents" on a loaded context
2. Use filters:
   - Show best N agents only
   - Sort by fitness or generation
3. Select agents using checkboxes
4. Click "Inspect" for detailed view or "Topology" for network structure

### Comparing Agents

1. Select multiple agents (2+) using checkboxes
2. Click "Compare Selected"
3. View side-by-side comparison with:
   - Fitness metrics
   - Topology statistics
   - Structural similarity
   - Evolution history

### Master Database

Build and manage your collection of elite agents:

1. **Save agents to master:**
   - Load a context and view agents
   - Select agents using checkboxes
   - Click "Save to Master Database"
   - Agents are copied (originals unchanged)

2. **View master database:**
   - Click "Master Database" in navigation
   - See all your curated agents sorted by fitness
   - Select and remove agents as needed

3. **Use master database:**
   - Load as context: Enter context name and click "Load as Context"
   - Deploy to DXNN-Trader: Copy `./data/MasterDatabase/Mnesia.nonode@nohost` to your DXNN-Trader folder
   - Analyze: Use all analyzer features (inspect, compare, topology)

4. **Best practices:**
   - Regularly curate after experiments
   - Keep only truly elite agents
   - Backup `./data/MasterDatabase/` folder
   - Use descriptive context names when loading

### Agent Inspection

View detailed information:
- Basic info (ID, fitness, generation, encoding type)
- Topology summary (sensors, neurons, actuators, layers)
- Evolution history
- Quick actions to view topology

### Topology Visualization

- Network statistics dashboard
- Complete list of sensors, neurons, and actuators
- Layer information
- Ready for interactive graph visualization (D3.js/Cytoscape.js)

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system architecture, data flow, and component interactions.

### High-Level Overview

```
Browser (LiveView) 
    ↓ WebSocket
Phoenix Server (Elixir)
    ↓ GenServer
AnalyzerBridge
    ↓ Erlang Interop
DXNN Analyzer (Erlang)
    ↓ ETS
Mnesia Database
```

## Docker Commands

### Production

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild after changes
docker-compose build
docker-compose up -d
```

### Development with Hot Reload

```bash
# Start development container
docker-compose --profile dev up dxnn_analyzer_dev

# This mounts your source code for live editing
```

### Custom Configuration

Set environment variables in `.env` file:

```bash
SECRET_KEY_BASE=your_secret_key_here
PHX_HOST=your-domain.com
PORT=4000
```

Then run:
```bash
docker-compose --env-file .env up -d
```

## Project Structure

```
.
├── dxnn_analyzer/              # Erlang analyzer (backend)
│   ├── src/                    # Erlang source files
│   ├── include/                # Header files
│   └── rebar.config            # Erlang build config
│
├── dxnn_analyzer_web/          # Phoenix web interface
│   ├── lib/
│   │   └── dxnn_analyzer_web/
│   │       ├── live/           # LiveView pages
│   │       ├── components/     # Reusable components
│   │       ├── analyzer_bridge.ex  # Erlang bridge
│   │       ├── endpoint.ex     # Phoenix endpoint
│   │       └── router.ex       # Routes
│   ├── assets/                 # Frontend assets
│   │   ├── js/                 # JavaScript
│   │   └── css/                # Tailwind CSS
│   ├── config/                 # Configuration
│   └── mix.exs                 # Elixir dependencies
│
├── Dockerfile                  # Production image
├── Dockerfile.dev              # Development image
├── docker-compose.yml          # Docker orchestration
├── README.md                   # This file
├── ARCHITECTURE.md             # Technical architecture
└── AI_README.md                # AI assistant guide
```

## Configuration

### Phoenix Configuration

Edit `dxnn_analyzer_web/config/dev.exs` or `config/prod.exs`:

```elixir
config :dxnn_analyzer_web, DxnnAnalyzerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "your-secret-key"
```

### Analyzer Bridge

The bridge automatically finds compiled Erlang modules in `../dxnn_analyzer/ebin`.

To use a different path, modify `lib/dxnn_analyzer_web/analyzer_bridge.ex`:

```elixir
analyzer_path = Path.expand("/custom/path/to/ebin")
```

## Troubleshooting

### Docker Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs dxnn_analyzer_web

# Rebuild
docker-compose build --no-cache
```

**Port already in use:**
```bash
# Change port in docker-compose.yml
ports:
  - "4001:4000"
```

**Can't access Mnesia files:**
```bash
# Check volume mount in docker-compose.yml
# Ensure path is correct and readable
```

### Local Development Issues

**"Analyzer module not found":**
```bash
cd dxnn_analyzer
rebar3 compile
# Verify ebin/*.beam files exist
```

**"Port 4000 already in use":**
```bash
# Change port in config/dev.exs
# Or kill process: lsof -ti:4000 | xargs kill
```

**Assets not loading:**
```bash
cd dxnn_analyzer_web/assets
npm install
npm run deploy
```

**Mix dependencies error:**
```bash
cd dxnn_analyzer_web
mix deps.clean --all
mix deps.get
```

### Runtime Issues

**Context fails to load:**
- Verify Mnesia path is correct
- Check file permissions
- Ensure Mnesia folder contains valid tables

**Slow performance with large populations:**
- Use "Show best agents only" filter
- Limit results to 50-100 agents
- Consider pagination for 1000+ agents

**WebSocket disconnects:**
- Check firewall settings
- Verify network stability
- Check browser console for errors

## Development

### Adding New Features

1. **New LiveView page:**
   - Create in `lib/dxnn_analyzer_web/live/`
   - Add route in `router.ex`
   - Implement `mount/3` and `render/1`

2. **New analyzer function:**
   - Add to `analyzer_bridge.ex`
   - Implement `handle_call/3`
   - Add data formatting function

3. **New component:**
   - Create in `lib/dxnn_analyzer_web/components/`
   - Use in templates with `<.component_name />`

### Testing

```bash
# Run tests
cd dxnn_analyzer_web
mix test

# Run with coverage
mix test --cover

# Run specific test
mix test test/dxnn_analyzer_web/live/dashboard_live_test.exs
```

### Code Formatting

```bash
# Format Elixir code
mix format

# Check formatting
mix format --check-formatted
```

## Production Deployment

### Generate Secret Key

```bash
mix phx.gen.secret
```

### Build Production Image

```bash
docker build -t dxnn_analyzer_web:latest .
```

### Run Production Container

```bash
docker run -d \
  -p 4000:4000 \
  -e SECRET_KEY_BASE="your-secret-key" \
  -e PHX_HOST="your-domain.com" \
  -v /path/to/mnesia:/app/mnesia:ro \
  --name dxnn_analyzer \
  dxnn_analyzer_web:latest
```

### Using Docker Compose (Recommended)

1. Create `.env` file:
```bash
SECRET_KEY_BASE=your_generated_secret_key_min_64_chars
PHX_HOST=your-domain.com
```

2. Start:
```bash
docker-compose up -d
```

### Reverse Proxy (Nginx)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Performance Considerations

### Recommended Limits

- **Agents per page:** 50-100
- **Concurrent contexts:** 5-10
- **Max agent selection:** 10 for comparison

### Optimization Tips

1. **Use filters** to reduce data transfer
2. **Unload unused contexts** to free memory
3. **Enable pagination** for large populations
4. **Cache frequently accessed data**
5. **Use "best agents only"** filter

### Memory Usage

- Each context: ~10-50 MB (depends on population size)
- Each LiveView connection: ~1-5 MB
- Erlang analyzer: ~50-200 MB base

## Security

### Production Checklist

- [ ] Generate secure `SECRET_KEY_BASE`
- [ ] Use HTTPS in production
- [ ] Set proper `PHX_HOST`
- [ ] Configure firewall rules
- [ ] Implement authentication (if needed)
- [ ] Set up monitoring and logging
- [ ] Regular security updates
- [ ] Backup Mnesia data

### Authentication (Optional)

For adding authentication, consider:
- [Pow](https://github.com/danschultzer/pow)
- [Guardian](https://github.com/ueberauth/guardian)
- [Phx.Gen.Auth](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html)

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Future Enhancements

- [ ] Interactive topology visualization (D3.js/Cytoscape.js)
- [ ] Real-time evolution monitoring
- [ ] Population builder wizard
- [ ] Export reports as PDF
- [ ] Multi-experiment comparison dashboard
- [ ] Advanced filtering and search
- [ ] Mutation timeline visualization
- [ ] REST API for external tools

## Resources

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
- [Elixir](https://elixir-lang.org/)
- [Erlang](https://www.erlang.org/)
- [Docker](https://www.docker.com/)

## License

Apache 2.0

## Support

For issues and questions:
- Check [Troubleshooting](#troubleshooting) section
- Review [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Check Docker logs: `docker-compose logs -f`
- Review Phoenix logs in the terminal

## Acknowledgments

Built for the DXNN-Trader-V2 project, providing a modern web interface for neuroevolution analysis and agent management.

cd C:\Users\qbot7\OneDrive\Documents\DXNN\dxnn_analyzer_web

mix phx.server