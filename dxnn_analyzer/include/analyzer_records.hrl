%% Analyzer-specific records

%% Context management
-record(mnesia_context, {
    name,                    % atom() - Context identifier
    path,                    % string() - Original Mnesia folder path
    loaded_at,               % erlang:timestamp()
    agent_count = 0,         % integer()
    population_count = 0,    % integer()
    specie_count = 0,        % integer()
    tables = []              % [atom()] - ETS table names
}).

%% Agent topology summary
-record(topo_summary, {
    agent_id,
    encoding_type,           % neural | substrate
    sensor_count,
    neuron_count,
    actuator_count,
    substrate_dimensions,    % undefined | [integer()]
    total_connections,
    depth,                   % Network depth
    width,                   % Max layer width
    cycles                   % Number of recurrent cycles
}).

%% Mutation event
-record(mutation_event, {
    generation,
    operator,                % atom() - Mutation type
    details,                 % term() - Mutation-specific data
    fitness_before,
    fitness_after
}).

%% Comparison result
-record(agent_comparison, {
    agents,                  % [agent_id()]
    common_mutations = [],
    topology_diffs = [],
    fitness_ranking = [],
    structural_similarity    % float() 0.0-1.0
}).
