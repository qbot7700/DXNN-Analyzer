# DXNN Analyzer Web Interface - AI Assistant Guide

This document provides context for AI assistants working with the DXNN Analyzer Web Interface codebase.

## Project Overview

A Phoenix LiveView web application that provides a modern browser-based UI for the DXNN (Deep eXtended Neural Network) Analyzer, an Erlang-based tool for analyzing neuroevolution trading agents.

**Key Technologies:**
- Phoenix LiveView (Elixir) - Real-time web interface
- Erlang/OTP - Backend analyzer
- Mnesia - Database
- Docker - Deployment
- Tailwind CSS - Styling

## Project Structure

```
.
├── dxnn_analyzer/                  # Erlang analyzer (backend)
│   ├── src/                        # Erlang source files
│   │   ├── analyzer.erl            # Main API
│   │   ├── mnesia_loader.erl       # Load Mnesia into ETS
│   │   ├── agent_inspector.erl     # Agent analysis
│   │   ├── topology_mapper.erl     # Network mapping
│   │   ├── mutation_analyzer.erl   # Evolution tracking
│   │   ├── comparator.erl          # Agent comparison
│   │   ├── stats_collector.erl     # Statistics
│   │   └── population_builder.erl  # Population creation
│   ├── include/                    # Header files
│   │   ├── records.hrl             # Mnesia record definitions
│   │   └── analyzer_records.hrl    # Analyzer-specific records
│   └── rebar.config                # Erlang build config
│
├── dxnn_analyzer_web/              # Phoenix web interface
│   ├── lib/
│   │   └── dxnn_analyzer_web/
│   │       ├── live/               # LiveView pages
│   │       │   ├── dashboard_live.ex       # Main dashboard
│   │       │   ├── agent_list_live.ex      # Agent listing
│   │       │   ├── agent_inspector_live.ex # Agent details
│   │       │   ├── topology_viewer_live.ex # Network topology
│   │       │   └── comparator_live.ex      # Agent comparison
│   │       ├── components/         # Reusable UI components
│   │       │   ├── core_components.ex      # Base components
│   │       │   ├── error_html.ex           # Error pages
│   │       │   ├── layouts.ex              # Layout module
│   │       │   └── layouts/
│   │       │       ├── root.html.heex      # Root HTML
│   │       │       └── app.html.heex       # App layout
│   │       ├── analyzer_bridge.ex  # Erlang ↔ Elixir bridge
│   │       ├── application.ex      # Application supervisor
│   │       ├── endpoint.ex         # Phoenix endpoint
│   │       ├── router.ex           # Route definitions
│   │       └── telemetry.ex        # Metrics
│   ├── assets/                     # Frontend assets
│   │   ├── js/
│   │   │   └── app.js              # LiveView JavaScript
│   │   ├── css/
│   │   │   └── app.css             # Tailwind CSS
│   │   ├── vendor/
│   │   │   └── topbar.js           # Progress bar
│   │   ├── package.json            # Node dependencies
│   │   └── tailwind.config.js      # Tailwind config
│   ├── config/                     # Configuration
│   │   ├── config.exs              # Base config
│   │   ├── dev.exs                 # Development
│   │   ├── test.exs                # Test
│   │   ├── prod.exs                # Production
│   │   └── runtime.exs             # Runtime
│   └── mix.exs                     # Elixir dependencies
│
├── Dockerfile                      # Production image
├── Dockerfile.dev                  # Development image
├── docker-compose.yml              # Docker orchestration
├── .dockerignore                   # Docker ignore patterns
├── README.md                       # User documentation
├── ARCHITECTURE.md                 # Technical architecture
└── AI_README.md                    # This file
```

## Key Concepts

### 1. Phoenix LiveView

LiveView provides real-time, server-rendered HTML over WebSockets:

- **No JavaScript needed** for most interactions
- **Real-time updates** without page refreshes
- **One process per client** maintains state
- **Automatic DOM diffing** minimizes data transfer

**Example LiveView:**
```elixir
defmodule DxnnAnalyzerWeb.DashboardLive do
  use DxnnAnalyzerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :contexts, [])}
  end

  def handle_event("load_context", %{"path" => path}, socket) do
    # Handle user event
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>Dashboard content</div>
    """
  end
end
```

### 2. Erlang ↔ Elixir Bridge

The `AnalyzerBridge` GenServer provides seamless integration:

**Key Responsibilities:**
- Convert data structures (maps ↔ records, strings ↔ charlists)
- Manage Erlang code paths
- Handle timeouts for long operations
- Format errors for user display

**Example:**
```elixir
# Elixir side
def load_context(path, context_name) do
  GenServer.call(__MODULE__, {:load_context, path, context_name})
end

def handle_call({:load_context, path, context}, _from, state) do
  # Convert to Erlang types
  path_charlist = String.to_charlist(path)
  context_atom = String.to_atom(context)
  
  # Call Erlang function
  result = :analyzer.load(path_charlist, context_atom)
  
  # Format result
  {:reply, format_result(result), state}
end
```

### 3. Mnesia and ETS

**Mnesia**: Persistent database on disk
- Stores agent, neuron, sensor, actuator records
- ACID transactions
- Distributed capability

**ETS**: In-memory cache
- Fast O(1) lookups
- One table per context
- Concurrent reads
- No disk I/O

**Flow:**
```
Mnesia (disk) → mnesia_loader → ETS (memory) → analyzer functions
```

### 4. Agent Records

Agents are stored as Erlang records:

```erlang
-record(agent, {
    id,              % {agent, {UniqueId, UniqueId}}
    encoding_type,   % neural | substrate
    cx_id,           % Cortex ID
    substrate_id,    % Substrate ID (if substrate encoding)
    generation,      % Generation number
    fitness,         % Fitness score
    evo_hist,        % Evolution history
    ...
}).
```

## Common Tasks

### Adding a New LiveView Page

1. **Create the LiveView module:**
```elixir
# lib/dxnn_analyzer_web/live/my_feature_live.ex
defmodule DxnnAnalyzerWeb.MyFeatureLive do
  use DxnnAnalyzerWeb, :live_view
  alias DxnnAnalyzerWeb.AnalyzerBridge

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :data, [])}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>My Feature</h1>
    </div>
    """
  end
end
```

2. **Add route:**
```elixir
# lib/dxnn_analyzer_web/router.ex
live "/my-feature", MyFeatureLive, :index
```

3. **Add navigation link:**
```heex
<!-- lib/dxnn_analyzer_web/components/layouts/app.html.heex -->
<.link navigate={~p"/my-feature"}>My Feature</.link>
```

### Adding a New Analyzer Function

1. **Add to bridge:**
```elixir
# lib/dxnn_analyzer_web/analyzer_bridge.ex
def my_function(arg) do
  GenServer.call(__MODULE__, {:my_function, arg})
end

def handle_call({:my_function, arg}, _from, state) do
  result = :my_erlang_module.my_function(arg)
  {:reply, format_result(result), state}
end
```

2. **Use in LiveView:**
```elixir
def handle_event("do_something", params, socket) do
  result = AnalyzerBridge.my_function(params["arg"])
  {:noreply, assign(socket, :result, result)}
end
```

### Styling with Tailwind

Use Tailwind utility classes directly in templates:

```heex
<!-- Card -->
<div class="bg-white shadow rounded-lg p-6">
  <h2 class="text-xl font-semibold mb-4">Title</h2>
  <p class="text-gray-600">Content</p>
</div>

<!-- Button -->
<button class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
  Click Me
</button>

<!-- Grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- Items -->
</div>
```

After CSS changes, recompile:
```bash
cd dxnn_analyzer_web/assets
npm run deploy
```

## Development Workflow

### Local Development

1. **Start the server:**
```bash
cd dxnn_analyzer_web
mix phx.server
```

2. **Make changes** to `.ex` or `.heex` files

3. **Phoenix auto-reloads** - just refresh browser

4. **For CSS changes:**
```bash
cd assets
npm run deploy
```

### Docker Development

1. **Start dev container:**
```bash
docker-compose --profile dev up dxnn_analyzer_dev
```

2. **Source code is mounted** - changes reflect immediately

3. **Rebuild after dependency changes:**
```bash
docker-compose build
```

## Common Patterns

### Loading Data in LiveView

```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    # Load data only after WebSocket connection
    data = AnalyzerBridge.get_data()
    {:ok, assign(socket, :data, data)}
  else
    # Initial HTTP request
    {:ok, assign(socket, :data, [])}
  end
end
```

### Handling Events

```elixir
def handle_event("button_click", params, socket) do
  # Process event
  result = do_something(params)
  
  # Update socket
  socket = assign(socket, :result, result)
  
  # Optionally show flash message
  socket = put_flash(socket, :info, "Success!")
  
  {:noreply, socket}
end
```

### Navigation

```elixir
# Push navigate (updates URL, maintains LiveView)
{:noreply, push_navigate(socket, to: ~p"/agents")}

# Push patch (updates params, same LiveView)
{:noreply, push_patch(socket, to: ~p"/agents?context=exp1")}

# Redirect (full page load)
{:noreply, redirect(socket, to: ~p"/agents")}
```

### Conditional Rendering

```heex
<%= if @loading do %>
  <div>Loading...</div>
<% else %>
  <div>Content</div>
<% end %>

<%= for item <- @items do %>
  <div><%= item.name %></div>
<% end %>
```

## Debugging

### IEx (Interactive Elixir)

```bash
iex -S mix phx.server
```

In IEx:
```elixir
# Test bridge directly
DxnnAnalyzerWeb.AnalyzerBridge.start_analyzer()
DxnnAnalyzerWeb.AnalyzerBridge.list_contexts()

# Check if Erlang module is loaded
:code.which(:analyzer)

# Enable debug logging
require Logger
Logger.configure(level: :debug)
```

### Docker Logs

```bash
# View logs
docker-compose logs -f

# Specific service
docker-compose logs -f dxnn_analyzer_web

# Last 100 lines
docker-compose logs --tail=100 dxnn_analyzer_web
```

### Common Issues

**"Analyzer module not found":**
- Ensure Erlang analyzer is compiled: `cd dxnn_analyzer && rebar3 compile`
- Check beam files exist: `ls dxnn_analyzer/ebin/*.beam`

**"Port already in use":**
- Change port in `config/dev.exs`
- Or kill process: `lsof -ti:4000 | xargs kill` (Unix)

**LiveView not connecting:**
- Check browser console for WebSocket errors
- Verify `secret_key_base` is set
- Check firewall settings

**Assets not loading:**
- Recompile: `cd assets && npm run deploy`
- Check `priv/static/assets/` exists

## Testing

### Unit Tests

```elixir
# test/dxnn_analyzer_web/live/dashboard_live_test.exs
defmodule DxnnAnalyzerWeb.DashboardLiveTest do
  use DxnnAnalyzerWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders dashboard", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "DXNN Analyzer Dashboard"
  end
end
```

Run tests:
```bash
mix test
mix test --cover
mix test test/specific_test.exs
```

## Performance Tips

### For Large Populations (1000+ agents)

1. **Use pagination:**
```elixir
list_agents(context: exp1, limit: 50, offset: 0)
```

2. **Filter early:**
```elixir
list_agents(context: exp1, min_fitness: 0.7)
```

3. **Lazy load details:**
```elixir
# Load topology only when viewed
get_topology(agent_id, context)
```

4. **Unload unused contexts:**
```elixir
AnalyzerBridge.unload_context("old_context")
```

## Security Notes

### Current State
- Designed for local use
- No authentication
- CSRF protection enabled
- Signed session cookies

### For Production
- Add authentication (Pow, Guardian, phx.gen.auth)
- Use HTTPS only
- Set strong `SECRET_KEY_BASE`
- Configure firewall rules
- Implement rate limiting
- Add audit logging

## Docker Notes

### Building Images

```bash
# Production
docker build -t dxnn_analyzer_web:latest .

# Development
docker build -f Dockerfile.dev -t dxnn_analyzer_web:dev .
```

### Volume Mounts

Mount your Mnesia folders:
```yaml
volumes:
  - /path/to/mnesia:/app/mnesia:ro
```

Then use path `/app/mnesia/Mnesia.nonode@nohost` in the interface.

### Environment Variables

```bash
SECRET_KEY_BASE=your_secret_key
PHX_HOST=your-domain.com
PORT=4000
MIX_ENV=prod
```

## Useful Commands

```bash
# Elixir/Phoenix
mix deps.get              # Install dependencies
mix compile               # Compile project
mix phx.server            # Start server
iex -S mix phx.server     # Start with IEx
mix format                # Format code
mix test                  # Run tests

# Erlang
cd dxnn_analyzer
rebar3 compile            # Compile analyzer
rebar3 clean              # Clean build

# Node/Assets
cd dxnn_analyzer_web/assets
npm install               # Install dependencies
npm run deploy            # Build production assets

# Docker
docker-compose up -d      # Start containers
docker-compose down       # Stop containers
docker-compose logs -f    # View logs
docker-compose build      # Rebuild images
```

## Key Files to Know

**Configuration:**
- `dxnn_analyzer_web/config/dev.exs` - Development config
- `dxnn_analyzer_web/config/prod.exs` - Production config
- `dxnn_analyzer_web/mix.exs` - Elixir dependencies
- `dxnn_analyzer/rebar.config` - Erlang dependencies

**Core Logic:**
- `dxnn_analyzer_web/lib/dxnn_analyzer_web/analyzer_bridge.ex` - Erlang bridge
- `dxnn_analyzer_web/lib/dxnn_analyzer_web/router.ex` - Routes
- `dxnn_analyzer/src/analyzer.erl` - Main Erlang API

**UI:**
- `dxnn_analyzer_web/lib/dxnn_analyzer_web/live/*.ex` - LiveView pages
- `dxnn_analyzer_web/lib/dxnn_analyzer_web/components/layouts/app.html.heex` - Layout
- `dxnn_analyzer_web/assets/css/app.css` - Styles

## Resources

- [Phoenix LiveView Docs](https://hexdocs.pm/phoenix_live_view/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Lang](https://elixir-lang.org/)
- [Erlang Docs](https://www.erlang.org/docs)
- [Tailwind CSS](https://tailwindcss.com/)

## Summary

This is a Phoenix LiveView application that bridges Elixir and Erlang to provide a modern web interface for DXNN agent analysis. The key is understanding:

1. **LiveView** for real-time UI updates
2. **AnalyzerBridge** for Erlang ↔ Elixir integration
3. **ETS/Mnesia** for data storage
4. **Docker** for deployment

When making changes, focus on the LiveView pages for UI, the bridge for Erlang integration, and Tailwind classes for styling.
