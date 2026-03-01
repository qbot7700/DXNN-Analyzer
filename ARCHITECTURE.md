# DXNN Analyzer Web Interface - Architecture

## System Overview

This document describes the technical architecture of the DXNN Analyzer Web Interface, a Phoenix LiveView application that provides a modern web UI for the Erlang-based DXNN Analyzer.

## Technology Stack

- **Frontend**: Phoenix LiveView, Tailwind CSS
- **Backend**: Elixir/Phoenix, Erlang/OTP
- **Database**: Mnesia (via ETS cache)
- **Deployment**: Docker, Docker Compose
- **Real-time**: WebSockets (Phoenix Channels)

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Browser (Client)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Dashboard   │  │  Agent List  │  │   Inspector  │          │
│  │   LiveView   │  │   LiveView   │  │   LiveView   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ WebSocket (Phoenix Channel)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phoenix Server (Elixir)                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Phoenix Endpoint                       │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │  Router    │→ │ LiveView   │→ │  PubSub    │         │  │
│  │  │            │  │  Processes │  │            │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              │ GenServer Calls                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              AnalyzerBridge (GenServer)                   │  │
│  │  • Data format conversion (Elixir ↔ Erlang)             │  │
│  │  • Timeout management                                     │  │
│  │  • Error handling                                         │  │
│  │  • Code path management                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Erlang Interop
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DXNN Analyzer (Erlang)                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    analyzer.erl                           │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │  mnesia_   │  │  agent_    │  │ topology_  │         │  │
│  │  │  loader    │  │  inspector │  │  mapper    │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │ mutation_  │  │ comparator │  │  stats_    │         │  │
│  │  │ analyzer   │  │            │  │ collector  │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              │ ETS Operations                    │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              ETS Tables (In-Memory Cache)                 │  │
│  │  • Context 1: exp1                                        │  │
│  │  • Context 2: exp2                                        │  │
│  │  • Context N: ...                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Mnesia Operations
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Mnesia Database (Disk)                          │
│  • Agent records                                                 │
│  • Cortex records                                                │
│  • Neuron records                                                │
│  • Sensor/Actuator records                                       │
│  • Population records                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Component Layers

### 1. Browser Layer (Client)

**LiveView Pages** render UI and handle user interactions:
- Dashboard: Load/manage contexts
- Agent List: Browse and filter agents
- Agent Inspector: Detailed agent view
- Topology Viewer: Network visualization
- Comparator: Multi-agent comparison

**Key Features:**
- Real-time updates via WebSocket
- Automatic DOM diffing and patching
- No manual JavaScript for most interactions
- Form handling and validation

### 2. Phoenix Server Layer (Elixir)

**Components:**
- **Endpoint**: HTTP/WebSocket handling, static assets
- **Router**: URL routing to LiveView modules
- **LiveView Processes**: One per client, maintains session state
- **PubSub**: Broadcast updates to multiple clients

**LiveView State Example:**
```elixir
socket.assigns = %{
  contexts: [...],           # Loaded contexts
  selected_context: "exp1",  # Current context
  agents: [...],             # Agent list
  selected_agents: MapSet,   # Selected for comparison
  loading: false,            # Loading indicator
  error: nil                 # Error message
}
```

### 3. Bridge Layer (Erlang ↔ Elixir)

**AnalyzerBridge GenServer** provides seamless integration:

**Responsibilities:**
1. **Code Path Management**: Adds Erlang beam files to code path
2. **Data Conversion**: Elixir maps ↔ Erlang records, strings ↔ charlists
3. **Timeout Management**: Handles long operations (30-60s)
4. **Error Formatting**: User-friendly error messages

**Example Flow:**
```elixir
# 1. LiveView calls bridge
AnalyzerBridge.load_context("/path/to/mnesia", "exp1")

# 2. Bridge converts and calls Erlang
GenServer.call → :analyzer.load('/path/to/mnesia', exp1)

# 3. Erlang processes request
analyzer:load → mnesia_loader:load_folder → {ok, ContextRecord}

# 4. Bridge formats response
{:ok, %{name: :exp1, path: "...", agent_count: 45, specie_count: 3}}

# 5. LiveView receives formatted data and updates UI
```

### 4. Analyzer Layer (Erlang)

**Core Modules:**

| Module | Purpose |
|--------|---------|
| `analyzer.erl` | Main API, coordinates operations |
| `mnesia_loader.erl` | Loads Mnesia folders into ETS contexts |
| `agent_inspector.erl` | Deep agent analysis and topology extraction |
| `topology_mapper.erl` | Network graph building and DOT export |
| `mutation_analyzer.erl` | Evolution history and mutation tracking |
| `comparator.erl` | Multi-agent comparison and similarity |
| `stats_collector.erl` | Aggregate metrics and reports |
| `population_builder.erl` | Create new populations from selected agents |

### 5. Data Layer

**ETS Tables:**
- In-memory cache per context
- Fast O(1) lookups
- Isolated contexts
- Concurrent reads

**Mnesia Database:**
- Persistent storage on disk
- ACID transactions
- Record-based storage
- Distributed capability

## Data Flow Examples

### Loading a Context

```
User clicks "Load Context"
  ↓
DashboardLive.handle_event("load_context", params)
  ↓
AnalyzerBridge.load_context(path, name)
  ↓
GenServer.call → :analyzer.load(path, name)
  ↓
mnesia_loader:load_folder(path, name)
  ↓
Read Mnesia tables → Create ETS tables
  ↓
Return context record
  ↓
Bridge formats to Elixir map
  ↓
LiveView updates socket assigns
  ↓
Template re-renders
  ↓
Browser receives DOM diff via WebSocket
  ↓
UI updates (no page refresh)
```

### Viewing Agents

```
User navigates to /agents?context=exp1
  ↓
AgentListLive.handle_params(params)
  ↓
AnalyzerBridge.list_agents(context: "exp1")
  ↓
GenServer.call → :analyzer.list_agents([{context, exp1}])
  ↓
Query ETS tables for context exp1
  ↓
Return list of agent records
  ↓
Bridge formats to list of maps
  ↓
LiveView assigns agents
  ↓
Template renders table
  ↓
Browser displays agent list
```

## Concurrency Model

### Multiple Users

```
User A (Browser)          User B (Browser)
     ↓                         ↓
LiveView Process A      LiveView Process B
     ↓                         ↓
     └─────────┬───────────────┘
               ↓
        AnalyzerBridge (Single GenServer)
               ↓
        Erlang Analyzer (Concurrent)
               ↓
        ETS Tables (Concurrent Reads)
```

**Key Points:**
- Each user has their own LiveView process
- AnalyzerBridge serializes calls (single GenServer)
- Erlang analyzer functions run concurrently
- ETS allows concurrent reads without locking
- Scales well for read-heavy workloads

### Scalability Strategies

1. Add more Phoenix nodes (distributed Erlang)
2. Load balance WebSocket connections
3. Cache frequently accessed data
4. Implement pagination for large datasets
5. Use PubSub for real-time updates across nodes

## Performance Characteristics

### Strengths

- **Fast ETS lookups**: O(1) complexity
- **Efficient LiveView updates**: DOM diffing minimizes data transfer
- **Concurrent operations**: Erlang's lightweight processes
- **No database queries**: Data cached in ETS

### Bottlenecks

- Single AnalyzerBridge GenServer (serializes calls)
- Large agent lists (1000+) without pagination
- Complex topology rendering
- Initial context loading from disk

### Optimization Techniques

1. **Pagination:**
   ```elixir
   list_agents(context: exp1, limit: 50, offset: 0)
   ```

2. **Lazy Loading:**
   ```elixir
   # Load topology only when viewed
   get_topology(agent_id, context)
   ```

3. **Caching:**
   ```elixir
   # Cache frequently accessed data
   @cache_ttl 60_000  # 1 minute
   ```

4. **Filtering:**
   ```elixir
   # Reduce data transfer
   list_agents(context: exp1, min_fitness: 0.7, limit: 20)
   ```

## Security Considerations

### Current Implementation

- CSRF protection enabled
- Signed session cookies
- No authentication (designed for local use)

### Production Recommendations

1. **Authentication**: Add user accounts and session management
2. **Authorization**: Role-based access control
3. **HTTPS**: Enforce SSL/TLS in production
4. **Firewall**: Restrict access to trusted networks
5. **Rate Limiting**: Prevent abuse
6. **Audit Logging**: Track user actions

## Extension Points

### Adding New Features

**1. New LiveView Page:**
```elixir
# Create lib/dxnn_analyzer_web/live/my_feature_live.ex
defmodule DxnnAnalyzerWeb.MyFeatureLive do
  use DxnnAnalyzerWeb, :live_view
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :data, [])}
  end
  
  def render(assigns) do
    ~H"""
    <div>My Feature</div>
    """
  end
end

# Add route in router.ex
live "/my-feature", MyFeatureLive, :index
```

**2. New Analyzer Function:**
```elixir
# Add to analyzer_bridge.ex
def my_function(arg) do
  GenServer.call(__MODULE__, {:my_function, arg})
end

def handle_call({:my_function, arg}, _from, state) do
  result = :analyzer.my_erlang_function(arg)
  {:reply, format_result(result), state}
end
```

**3. New Component:**
```elixir
# Create in components/
defmodule DxnnAnalyzerWeb.MyComponent do
  use Phoenix.Component
  
  attr :data, :map, required: true
  
  def my_component(assigns) do
    ~H"""
    <div><%= @data %></div>
    """
  end
end
```

### Integration Options

1. **External Services**: Add HTTP client for API calls
2. **Background Jobs**: Use Oban for async processing
3. **Real-Time Updates**: PubSub for multi-client synchronization
4. **REST API**: Add JSON endpoints for external tools

## Testing Strategy

### Unit Tests
```elixir
test "loads context successfully" do
  {:ok, view, _html} = live(conn, "/")
  # Test LiveView logic
end
```

### Integration Tests
```elixir
test "user can load and view agents" do
  # Test full flow
end
```

### E2E Tests
- Use Wallaby or Hound
- Test browser interactions
- Verify WebSocket connections

## Monitoring

### Telemetry Events

Phoenix emits events for monitoring:
- `[:phoenix, :endpoint, :start]`
- `[:phoenix, :live_view, :mount]`
- `[:phoenix, :router_dispatch, :stop]`

### Key Metrics

**Performance:**
- Response times
- LiveView mount duration
- Bridge call duration

**Usage:**
- Active connections
- Contexts loaded
- Agents viewed

**Errors:**
- Failed context loads
- Bridge timeouts
- Erlang errors

## Docker Deployment

### Production Image

```dockerfile
# Multi-stage build
FROM erlang:26-alpine AS erlang-builder
# Compile Erlang analyzer

FROM elixir:1.16-alpine AS elixir-builder
# Compile Elixir web interface

FROM elixir:1.16-alpine AS runtime
# Minimal runtime image
```

### Docker Compose

```yaml
services:
  dxnn_analyzer_web:
    build: .
    ports:
      - "4000:4000"
    volumes:
      - ./DXNN-Trader-V2:/app/DXNN-Trader-V2:ro
    environment:
      - SECRET_KEY_BASE=...
```

## Summary

The architecture provides:

✓ **Clean separation of concerns** across layers
✓ **Seamless Erlang ↔ Elixir integration** via bridge pattern
✓ **Real-time updates** via Phoenix LiveView
✓ **Scalable concurrent design** leveraging BEAM VM
✓ **Extensible component structure** for new features
✓ **Production-ready** with Docker support

The bridge pattern allows the Elixir web interface to leverage the existing Erlang analyzer without modification, while providing a modern, interactive user experience through Phoenix LiveView.
