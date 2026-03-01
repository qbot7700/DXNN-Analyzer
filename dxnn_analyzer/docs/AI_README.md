# DXNN Analyzer - AI Agent Guide

## System Overview

DXNN Analyzer is an Erlang-based tool for analyzing, inspecting, and managing DXNN trading agents across multiple Mnesia database instances. It provides comprehensive agent analysis, comparison, and population management capabilities.

## Core Capabilities

### 1. Multi-Context Management
- Load multiple Mnesia folders simultaneously as independent "contexts"
- Each context maintains its own ETS-cached data
- Query and compare across contexts without interference
- Original Mnesia folders remain unchanged

### 2. Agent Analysis
- Deep inspection of agent structure and topology
- Neural network graph building and visualization
- Mutation history tracking and analysis
- Fitness and performance metrics calculation

### 3. Population Management
- Select best agents based on fitness criteria
- Create new populations from selected agents
- Validate population integrity
- Export to DXNN-Trader compatible Mnesia format

### 4. Comparison and Statistics
- Multi-agent comparison with similarity scoring
- Statistical analysis and report generation
- Topology visualization (DOT format for Graphviz)
- Mutation pattern detection

## Module Reference

### analyzer.erl - Main API
Primary interface for all operations.

**Key Functions:**
```erlang
start() -> ok
stop() -> ok
load(MnesiaPath, ContextName) -> {ok, Context} | {error, Reason}
unload(ContextName) -> ok | {error, Reason}
list_contexts() -> [Context]
list_agents(Options) -> [Agent]
find_best(N, Options) -> [Agent]
inspect(AgentId, Context) -> {ok, Agent} | {error, Reason}
show_topology(AgentId, Context) -> ok
show_mutations(AgentId, Context) -> ok
compare(AgentIds, Context) -> {ok, Comparison} | {error, Reason}
create_population(AgentIds, PopId, OutputFolder, Options) -> {ok, Path} | {error, Reason}
```

**Options for list_agents/1:**
- `{context, atom()}` - Specific context to query
- `{min_fitness, float()}` - Minimum fitness threshold
- `{sort, fitness | generation}` - Sort order
- `{limit, integer()}` - Maximum results

### mnesia_loader.erl - Context Management
Handles loading Mnesia folders into ETS-based contexts.

**Key Functions:**
```erlang
load_folder(MnesiaPath, ContextName) -> {ok, Context} | {error, Reason}
unload_context(ContextName) -> ok | {error, Reason}
get_context(ContextName) -> {ok, Context} | {error, Reason}
table_name(ContextName, TableName) -> atom()
```

**Process:**
1. Creates temporary Mnesia environment
2. Copies Mnesia files to temp directory
3. Starts Mnesia and reads all tables
4. Copies data to ETS tables (one per context)
5. Cleans up temporary files
6. Stores context metadata

### agent_inspector.erl - Agent Analysis
Deep analysis of individual agents.

**Key Functions:**
```erlang
inspect_agent(AgentId, Context) -> {ok, Agent} | {error, Reason}
query_agents(Context, MinFitness) -> [Agent]
get_full_topology(AgentId, Context) -> Map | {error, Reason}
get_component_counts(AgentId, Context) -> Map | {error, Reason}
calculate_metrics(AgentId, Context) -> #topo_summary{} | {error, Reason}
```

**Topology Map Structure:**
```erlang
#{
    agent => #agent{},
    cortex => #cortex{},
    neurons => [#neuron{}],
    sensors => [#sensor{}],
    actuators => [#actuator{}],
    substrate => #substrate{} | undefined
}
```

### topology_mapper.erl - Graph Operations
Neural network topology analysis and visualization.

**Key Functions:**
```erlang
build_digraph(AgentId, Context) -> {ok, Digraph} | {error, Reason}
display_topology(AgentId, Context) -> ok
analyze_structure(AgentId, Context) -> {ok, Analysis} | {error, Reason}
export_to_dot(AgentId, Context, Filename) -> ok | {error, Reason}
```

**Analysis Map:**
```erlang
#{
    vertex_count => integer(),
    edge_count => integer(),
    source_count => integer(),
    sink_count => integer(),
    cycle_count => integer(),
    largest_cycle => integer(),
    avg_degree => float()
}
```

### mutation_analyzer.erl - Evolution Tracking
Analyzes mutation history and evolution patterns.

**Key Functions:**
```erlang
display_mutations(AgentId, Context) -> ok
parse_evo_hist(AgentId, Context) -> {ok, [#mutation_event{}]} | {error, Reason}
find_common_mutations(AgentIds, Context) -> {ok, Map} | {error, Reason}
```

**Mutation Types:**
- `mutate_weights` - Weight adjustments
- `add_neuron` / `remove_neuron` - Topology changes
- `add_inlink` / `remove_inlink` - Connection modifications
- `add_sensor` / `remove_sensor` - Input changes
- `add_actuator` / `remove_actuator` - Output changes
- `mutate_af` - Activation function changes
- `mutate_plasticity_parameters` - Plasticity modifications

### population_builder.erl - Population Creation
Creates new populations from selected agents.

**Key Functions:**
```erlang
create_population(AgentIds, PopId, OutputFolder, Options) -> {ok, Path} | {error, Reason}
validate_population(MnesiaDir) -> ok | {error, Reason}
```

**Process:**
1. Initialize new Mnesia schema in output folder
2. Copy selected agents and all components
3. Update agent records with new population/specie IDs
4. Create population and specie records
5. Validate integrity (all references exist)
6. Return path to new Mnesia folder

**Options:**
- `{context, atom()}` - Source context
- `{specie_id, term()}` - Custom specie ID

### comparator.erl - Agent Comparison
Compares multiple agents across various dimensions.

**Key Functions:**
```erlang
compare_agents(AgentIds, Context) -> {ok, #agent_comparison{}} | {error, Reason}
calculate_similarity(AgentId1, AgentId2, Context) -> {ok, float()} | {error, Reason}
```

**Comparison Output:**
- Fitness comparison (sorted by fitness)
- Topology statistics (neurons, connections, etc.)
- Mutation comparison (types and counts)
- Structural similarity matrix (0.0-1.0 scale)

**Similarity Calculation:**
- 40% neuron count similarity
- 30% connection count similarity
- 30% layer structure similarity

### stats_collector.erl - Statistics
Comprehensive statistical analysis.

**Key Functions:**
```erlang
collect_stats(Context) -> {ok, Map} | {error, Reason}
generate_summary(Context) -> {ok, Map} | {error, Reason}
export_report(Agents, Filename) -> ok
```

**Statistics Map:**
```erlang
#{
    total_agents => integer(),
    fitness_stats => #{max, min, avg, median, std_dev},
    generation_stats => #{max, min, avg},
    topology_stats => #{avg_neurons, avg_connections, max_neurons, min_neurons},
    mutation_stats => #{total_mutations, avg_per_agent, type_distribution},
    encoding_distribution => #{neural => Count, substrate => Count}
}
```

## Data Structures

### Records

**Agent Record:**
```erlang
#agent{
    id,                      % {agent, {Timestamp, Unique}}
    encoding_type,           % neural | substrate
    generation,              % integer()
    population_id,           % term()
    specie_id,              % term()
    cx_id,                  % Cortex ID
    fingerprint,            % term()
    constraint,             % #constraint{}
    evo_hist = [],          % [Mutation]
    fitness = 0,            % float()
    innovation_factor = 0,  % integer()
    substrate_id            % term() | undefined
}
```

**Context Record:**
```erlang
#mnesia_context{
    name,                   % atom()
    path,                   % string()
    loaded_at,              % erlang:timestamp()
    agent_count = 0,        % integer()
    population_count = 0,   % integer()
    specie_count = 0,       % integer()
    tables = []             % [atom()]
}
```

**Topology Summary:**
```erlang
#topo_summary{
    agent_id,
    encoding_type,
    sensor_count,
    neuron_count,
    actuator_count,
    substrate_dimensions,
    total_connections,
    depth,
    width,
    cycles
}
```

## Common Workflows

### Workflow 1: Basic Analysis
```erlang
analyzer:start().
analyzer:load("./Mnesia.nonode@nohost", exp1).
BestAgents = analyzer:find_best(10, [{context, exp1}]).
[TopAgent|_] = BestAgents.
analyzer:inspect(TopAgent#agent.id, exp1).
stats_collector:generate_summary(exp1).
analyzer:stop().
```

### Workflow 2: Create Elite Population
```erlang
analyzer:start().
analyzer:load("./source/Mnesia.nonode@nohost", src).
Best = analyzer:find_best(10, [{context, src}, {min_fitness, 0.7}]).
AgentIds = [A#agent.id || A <- Best].
{ok, Path} = analyzer:create_population(AgentIds, elite_traders, "./elite/").
population_builder:validate_population(Path).
analyzer:stop().
```

### Workflow 3: Multi-Experiment Comparison
```erlang
analyzer:start().
analyzer:load("./exp1/Mnesia.nonode@nohost", exp1).
analyzer:load("./exp2/Mnesia.nonode@nohost", exp2).

Best1 = analyzer:find_best(5, [{context, exp1}]).
Best2 = analyzer:find_best(5, [{context, exp2}]).

Ids1 = [A#agent.id || A <- Best1].
Ids2 = [A#agent.id || A <- Best2].

analyzer:compare(Ids1, exp1).
analyzer:compare(Ids2, exp2).

stats_collector:generate_summary(exp1).
stats_collector:generate_summary(exp2).

analyzer:stop().
```

### Workflow 4: Topology Analysis
```erlang
analyzer:start().
analyzer:load("./Mnesia.nonode@nohost", exp1).
[Agent] = analyzer:find_best(1, [{context, exp1}]).
AgentId = Agent#agent.id.

analyzer:show_topology(AgentId, exp1).
{ok, Analysis} = topology_mapper:analyze_structure(AgentId, exp1).
topology_mapper:export_to_dot(AgentId, exp1, "topology.dot").

%% Then use Graphviz: dot -Tpng topology.dot -o topology.png

analyzer:stop().
```

## Technical Details

### Architecture

**Data Flow:**
```
Mnesia Folder (disk)
    ↓
mnesia:dirty_read/2
    ↓
ETS Tables (in-memory, per context)
    ↓
Analysis & Processing
    ↓
mnesia:dirty_write/2
    ↓
New Mnesia Folder (disk)
```

**Key Design Principles:**
1. Pure Erlang - All operations use native Mnesia/ETS
2. Non-destructive - Never modifies source data
3. Multi-context - Independent analysis of multiple experiments
4. Type-safe - Uses matching record definitions
5. Validated - Comprehensive integrity checks

### Performance Characteristics

- **Memory**: ~10-50MB per context (varies with population size)
- **Speed**: Fast ETS-based queries (microseconds)
- **Scalability**: Handles 1000+ agents per context
- **Contexts**: Supports 10+ simultaneous contexts
- **Validation**: Full referential integrity checks

### Error Handling

All functions return `{ok, Result}` or `{error, Reason}` tuples. Common errors:

- `{error, context_not_found}` - Context not loaded
- `{error, agent_not_found}` - Agent doesn't exist
- `{error, invalid_path}` - Mnesia folder path invalid
- `{error, validation_failed}` - Population integrity check failed
- `{error, {missing_neurons, List}}` - Neurons referenced but not found

### Integration with DXNN-Trader

The analyzer is fully compatible with DXNN-Trader:

1. Uses identical record definitions (records.hrl)
2. Generates DXNN-compatible Mnesia folders
3. Preserves all agent data and relationships
4. Validates population integrity before export

**Workflow:**
1. Run DXNN-Trader experiment
2. Copy Mnesia folder for analysis
3. Use analyzer to select best agents
4. Create new population
5. Copy new Mnesia folder back to DXNN-Trader
6. Continue evolution with elite population

## Best Practices

### Memory Management
```erlang
%% Unload contexts when done
analyzer:unload(old_context).

%% Check memory usage
erlang:memory().

%% Process in batches for large populations
Agents = analyzer:find_best(100, [{context, exp1}]).
Batch1 = lists:sublist(Agents, 1, 25).
Batch2 = lists:sublist(Agents, 26, 25).
```

### Validation
```erlang
%% Always validate created populations
{ok, Path} = analyzer:create_population(Ids, new_pop, "./output/").
case population_builder:validate_population(Path) of
    ok -> io:format("Population valid~n");
    {error, Reason} -> io:format("Validation failed: ~p~n", [Reason])
end.
```

### Filtering
```erlang
%% Use filters to reduce data
analyzer:list_agents([
    {context, exp1},
    {min_fitness, 0.7},
    {sort, fitness},
    {limit, 20}
]).
```

## Troubleshooting

### Common Issues

**Context not found:**
```erlang
analyzer:list_contexts().  %% Check loaded contexts
```

**Agent not found:**
```erlang
AllAgents = analyzer:list_agents([{context, exp1}]).
AgentIds = [A#agent.id || A <- AllAgents].
lists:member(MyAgentId, AgentIds).
```

**Mnesia schema mismatch:**
```bash
cp ../DXNN-Trader-V2/DXNN-Trader-v2/records.hrl include/records.hrl
make clean && make compile
```

**Out of memory:**
```erlang
analyzer:unload(context1).
analyzer:unload(context2).
%% Or restart with: erl +hms 2048 +hmbs 2048
```

## Example Scripts

Located in `priv/examples/`:

1. **basic_usage.erl** - Load, analyze, and inspect agents
2. **compare_experiments.erl** - Compare multiple experiments
3. **create_elite_population.erl** - Create elite population from best agents

Usage:
```bash
cd priv/examples
./basic_usage.erl path/to/Mnesia.nonode@nohost
./compare_experiments.erl ./exp1/Mnesia.nonode@nohost ./exp2/Mnesia.nonode@nohost
./create_elite_population.erl ./source/Mnesia.nonode@nohost ./output 10
```

## Summary

DXNN Analyzer provides comprehensive tools for analyzing DXNN trading agents with:

- Multi-context support for parallel analysis
- Deep agent inspection and topology visualization
- Population management with validation
- Comparison and statistical analysis
- Pure Erlang implementation
- Full DXNN-Trader compatibility

All operations are non-destructive and use native Erlang/Mnesia for maximum compatibility and performance.
