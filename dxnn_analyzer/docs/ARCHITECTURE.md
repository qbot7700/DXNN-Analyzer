# DXNN Analyzer - Architecture & Development Guide

## System Architecture

### Overview

DXNN Analyzer is a self-contained Erlang application for analyzing DXNN trading agents. It uses ETS-based multi-context support to load and analyze multiple Mnesia databases simultaneously without modifying source data.

### Core Design Principles

1. **Separation** - Completely independent from DXNN-Trader
2. **Non-destructive** - Never modifies source Mnesia folders
3. **Pure Erlang** - All operations use native Erlang/Mnesia/ETS
4. **Type-safe** - Uses matching record definitions from DXNN-Trader
5. **Multi-context** - Supports simultaneous analysis of multiple experiments
6. **Validated** - Comprehensive integrity checks on all outputs

## Data Flow Architecture

```
┌─────────────────────┐
│  Source Mnesia      │
│  Folder (disk)      │
└──────────┬──────────┘
           │
           │ mnesia:dirty_read/2
           ↓
┌─────────────────────┐
│  Temporary Mnesia   │
│  Instance           │
└──────────┬──────────┘
           │
           │ Copy to ETS
           ↓
┌─────────────────────┐
│  ETS Tables         │
│  (per context)      │
└──────────┬──────────┘
           │
           │ Analysis & Processing
           ↓
┌─────────────────────┐
│  Results/Reports    │
└─────────────────────┘
           │
           │ mnesia:dirty_write/2
           ↓
┌─────────────────────┐
│  New Mnesia Folder  │
│  (disk)             │
└─────────────────────┘
```

## Module Architecture

### Layer 1: API Layer

**analyzer.erl** - Main public API
- High-level functions for all operations
- User-friendly interface
- Delegates to specialized modules
- Manages application lifecycle

### Layer 2: Core Services

**mnesia_loader.erl** - Context Management
- Loads Mnesia folders into ETS contexts
- Manages temporary Mnesia instances
- Handles context lifecycle
- Provides table name mapping

**agent_inspector.erl** - Agent Analysis
- Deep agent inspection
- Topology extraction
- Metrics calculation
- Component counting

**topology_mapper.erl** - Graph Operations
- Digraph construction
- Structural analysis
- DOT export for visualization
- Cycle detection

**mutation_analyzer.erl** - Evolution Tracking
- Mutation history parsing
- Pattern detection
- Fitness progression tracking

**population_builder.erl** - Population Management
- New population creation
- Mnesia schema initialization
- Data copying and validation
- Integrity checking

**comparator.erl** - Comparison Engine
- Multi-agent comparison
- Similarity calculation
- Statistical analysis
- Matrix generation

**stats_collector.erl** - Statistics
- Comprehensive statistics
- Report generation
- Summary creation
- Distribution analysis

### Layer 3: Data Layer

**ETS Tables** - In-memory cache
- One set of tables per context
- Fast query performance
- Independent contexts
- Automatic cleanup

**Mnesia** - Persistent storage
- Source data (read-only)
- Output data (write-only)
- Native Erlang term format
- ACID properties

## Context Management

### Context Lifecycle

```erlang
%% 1. Load Context
analyzer:load(MnesiaPath, ContextName)
    ↓
mnesia_loader:load_folder/2
    ↓
Create temp directory
Copy Mnesia files
Start Mnesia
Read all tables
Copy to ETS
Store context metadata
Cleanup temp directory
    ↓
Context ready for queries

%% 2. Use Context
analyzer:list_agents([{context, ContextName}])
    ↓
Query ETS tables
Process results
Return to user

%% 3. Unload Context
analyzer:unload(ContextName)
    ↓
Delete ETS tables
Remove context metadata
Free memory
```

### ETS Table Structure

Each context creates these tables:
- `{ContextName}_agent` - Agent records
- `{ContextName}_cortex` - Cortex records
- `{ContextName}_neuron` - Neuron records
- `{ContextName}_sensor` - Sensor records
- `{ContextName}_actuator` - Actuator records
- `{ContextName}_substrate` - Substrate records
- `{ContextName}_population` - Population records
- `{ContextName}_specie` - Specie records

Table naming: `list_to_atom(atom_to_list(ContextName) ++ "_" ++ atom_to_list(TableName))`

## Agent Analysis Pipeline

### Topology Extraction

```erlang
agent_inspector:get_full_topology(AgentId, Context)
    ↓
1. Read agent record from ETS
2. Read cortex record using agent.cx_id
3. Read all neurons using cortex.neuron_ids
4. Read all sensors using cortex.sensor_ids
5. Read all actuators using cortex.actuator_ids
6. Read substrate if agent.substrate_id exists
    ↓
Return topology map:
#{
    agent => #agent{},
    cortex => #cortex{},
    neurons => [#neuron{}],
    sensors => [#sensor{}],
    actuators => [#actuator{}],
    substrate => #substrate{} | undefined
}
```

### Metrics Calculation

```erlang
agent_inspector:calculate_metrics(AgentId, Context)
    ↓
1. Get full topology
2. Count components (sensors, neurons, actuators)
3. Calculate connections (sum of neuron.input_idps lengths)
4. Calculate depth (number of unique layers)
5. Calculate width (max neurons in any layer)
6. Count cycles (sum of neuron.ro_ids lengths)
    ↓
Return #topo_summary{}
```

### Graph Construction

```erlang
topology_mapper:build_digraph(AgentId, Context)
    ↓
1. Get full topology
2. Create new digraph
3. Add vertices for all components
4. Add edges from sensors to neurons
5. Add edges between neurons
6. Add edges from neurons to actuators
    ↓
Return digraph handle
```

## Population Creation Pipeline

### Creation Process

```erlang
population_builder:create_population(AgentIds, PopId, OutputFolder, Options)
    ↓
1. Initialize new Mnesia schema
   - Create output directory
   - Create Mnesia schema
   - Start Mnesia
   - Create all tables

2. Copy agents
   For each AgentId:
   - Get full topology from source context
   - Update agent record (new population_id, specie_id)
   - Write agent to new Mnesia
   - Write cortex to new Mnesia
   - Write all neurons to new Mnesia
   - Write all sensors to new Mnesia
   - Write all actuators to new Mnesia
   - Write substrate if exists

3. Create metadata
   - Create population record
   - Create specie record
   - Write to Mnesia

4. Validate
   - Check all agents exist
   - Check all cortexes exist
   - Check all neurons referenced exist
   - Check referential integrity

5. Return path to new Mnesia folder
```

### Validation Process

```erlang
population_builder:validate_population(MnesiaDir)
    ↓
1. Start Mnesia with MnesiaDir
2. Wait for tables
3. Get all agent IDs
4. For each agent:
   - Check agent record exists
   - Check cortex exists
   - Check all neurons exist
   - Verify no missing references
5. Report errors or success
```

## Comparison Engine

### Similarity Calculation

```erlang
comparator:calculate_similarity(AgentId1, AgentId2, Context)
    ↓
1. Get topologies for both agents
2. Calculate neuron similarity:
   min(N1, N2) / max(N1, N2)
3. Calculate connection similarity:
   min(C1, C2) / max(C1, C2)
4. Calculate structure similarity:
   common_layers / total_unique_layers
5. Weighted average:
   (neuron_sim * 0.4) + (conn_sim * 0.3) + (struct_sim * 0.3)
    ↓
Return similarity score (0.0 to 1.0)
```

### Comparison Matrix

```erlang
comparator:compare_agents(AgentIds, Context)
    ↓
1. Load all agent topologies
2. Build N×N similarity matrix
3. Calculate fitness ranking
4. Find common mutations
5. Calculate topology differences
6. Display formatted output
    ↓
Return #agent_comparison{}
```

## Performance Optimization

### Memory Management

**ETS Tables:**
- Bag type for flexibility
- Public access for concurrent reads
- Named tables for easy lookup
- Automatic garbage collection

**Context Caching:**
- Load once, query many times
- Unload when done to free memory
- Independent contexts don't interfere
- ~10-50MB per context

### Query Optimization

**Filtering:**
```erlang
%% Bad: Load all then filter
AllAgents = ets:tab2list(Table),
Filtered = [A || A <- AllAgents, A#agent.fitness > 0.7].

%% Good: Filter during query
ets:foldl(fun(Agent, Acc) ->
    case Agent#agent.fitness > 0.7 of
        true -> [Agent | Acc];
        false -> Acc
    end
end, [], Table).
```

**Batching:**
```erlang
%% Process large populations in batches
Agents = analyzer:find_best(1000, [{context, exp1}]).
Batches = [lists:sublist(Agents, N, 100) || N <- lists:seq(1, 1000, 100)].
lists:foreach(fun(Batch) -> process_batch(Batch) end, Batches).
```

## Error Handling

### Error Types

1. **Context Errors:**
   - `{error, context_not_found}` - Context not loaded
   - `{error, {invalid_path, Path}}` - Mnesia folder doesn't exist

2. **Agent Errors:**
   - `{error, agent_not_found}` - Agent doesn't exist in context
   - `{error, cortex_not_found}` - Cortex missing for agent

3. **Validation Errors:**
   - `{error, validation_failed}` - Population integrity check failed
   - `{error, {missing_neurons, List}}` - Referenced neurons don't exist

4. **System Errors:**
   - `{error, {timeout_waiting_for_tables, Tables}}` - Mnesia timeout
   - `{error, Reason}` - Generic Mnesia/file system errors

### Error Handling Pattern

```erlang
case analyzer:load(Path, Context) of
    {ok, _} ->
        %% Proceed with analysis
        ok;
    {error, Reason} ->
        %% Handle error
        io:format("Error: ~p~n", [Reason]),
        {error, Reason}
end.
```

## Testing Strategy

### Unit Tests

Test individual module functions:
```erlang
%% test/agent_inspector_tests.erl
-module(agent_inspector_tests).
-include_lib("eunit/include/eunit.hrl").

read_agent_test() ->
    %% Setup test context
    %% Test read_agent/2
    %% Verify results
    ok.
```

### Integration Tests

Test complete workflows:
```erlang
%% test/integration_tests.erl
full_workflow_test() ->
    analyzer:start(),
    analyzer:load(TestPath, test),
    Best = analyzer:find_best(5, [{context, test}]),
    Ids = [A#agent.id || A <- Best],
    {ok, _} = analyzer:create_population(Ids, test_pop, "./output/"),
    analyzer:stop().
```

### Validation Tests

Test data integrity:
```erlang
validate_population_test() ->
    {ok, Path} = create_test_population(),
    ?assertEqual(ok, population_builder:validate_population(Path)).
```

## Build System

### Rebar3 Configuration

```erlang
%% rebar.config
{erl_opts, [debug_info]}.
{deps, []}.

{shell, [
    {apps, [dxnn_analyzer]}
]}.

{profiles, [
    {test, [
        {deps, [{proper, "1.4.0"}]}
    ]}
]}.
```

### Makefile Targets

```makefile
compile:    # Compile all modules
clean:      # Remove build artifacts
test:       # Run unit tests
shell:      # Start Erlang shell with app loaded
```

## Development Workflow

### Adding New Features

1. **Define API** in `analyzer.erl`
2. **Implement logic** in specialized module
3. **Add tests** in `test/` directory
4. **Update documentation** in `docs/`
5. **Test integration** with DXNN-Trader

### Code Style

- Use descriptive function names
- Add type specs for public functions
- Include documentation comments
- Follow Erlang naming conventions
- Keep functions focused and small

### Example Module Template

```erlang
-module(new_module).
-export([public_function/2]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Public function description
-spec public_function(term(), atom()) -> {ok, term()} | {error, term()}.
public_function(Arg1, Arg2) ->
    %% Implementation
    {ok, result}.

%% Internal functions
internal_helper(Data) ->
    %% Helper logic
    processed_data.
```

## Deployment

### Prerequisites

- Erlang/OTP 26+
- Rebar3
- Access to DXNN-Trader Mnesia folders

### Installation

```bash
cd dxnn_analyzer
make compile
make shell
```

### Verification

```erlang
analyzer:start().
%% Should print: "Starting DXNN Analyzer..." and "Analyzer ready."
```

## Integration with DXNN-Trader

### Record Compatibility

The analyzer uses the same `records.hrl` as DXNN-Trader to ensure compatibility:

```bash
cp ../DXNN-Trader-V2/DXNN-Trader-v2/records.hrl include/records.hrl
```

### Mnesia Format

Generated Mnesia folders are fully compatible with DXNN-Trader:
- Same table structure
- Same record definitions
- Same data types
- Validated referential integrity

### Workflow Integration

```
DXNN-Trader Experiment
    ↓
Copy Mnesia folder
    ↓
Analyzer: Load & Analyze
    ↓
Analyzer: Select best agents
    ↓
Analyzer: Create elite population
    ↓
Copy new Mnesia folder
    ↓
DXNN-Trader: Continue evolution
```

## Future Enhancements

### Potential Features

1. **Web Interface**
   - REST API using Cowboy
   - Interactive topology viewer
   - Real-time analysis dashboard

2. **Advanced Analytics**
   - Pattern recognition in successful agents
   - Performance prediction models
   - Automated hyperparameter tuning

3. **Batch Processing**
   - Parallel analysis of multiple experiments
   - Automated report generation
   - Scheduled analysis jobs

4. **Visualization**
   - Interactive D3.js graphs
   - Evolution timeline animations
   - Heatmaps and distributions

5. **Real-time Simulation**
   - Execute agents with test data
   - Visualize activation patterns
   - Debug neural network behavior

## Troubleshooting

### Common Development Issues

**Compilation Errors:**
```bash
make clean
make compile
```

**Record Mismatch:**
```bash
cp ../DXNN-Trader-V2/DXNN-Trader-v2/records.hrl include/records.hrl
make clean && make compile
```

**ETS Table Conflicts:**
```erlang
%% Clear all ETS tables
lists:foreach(fun(T) -> ets:delete(T) end, ets:all()).
```

**Mnesia Lock Issues:**
```erlang
%% Stop Mnesia completely
application:stop(mnesia).
```

## Summary

DXNN Analyzer provides a robust, scalable architecture for analyzing DXNN agents with:

- Clean separation of concerns
- Pure Erlang implementation
- Multi-context support
- Comprehensive validation
- Full DXNN-Trader compatibility
- Extensible design

The modular architecture allows easy addition of new features while maintaining backward compatibility and data integrity.
