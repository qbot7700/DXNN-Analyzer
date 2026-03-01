-module(agent_inspector).
-export([
    inspect_agent/2,
    query_agents/2,
    query_agents_with_topology/2,
    get_full_topology/2,
    get_component_counts/2,
    calculate_metrics/2,
    read_agent/2
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Inspect a single agent and return detailed information as a map
inspect_agent(AgentId, Context) ->
    case read_agent(AgentId, Context) of
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason]),
            {error, Reason};
        {ok, Agent} ->
            display_agent_info(Agent, Context),
            build_inspection_map(Agent, Context)
    end.

%% @doc Build comprehensive inspection map for web interface
build_inspection_map(Agent, Context) ->
    Topology = get_full_topology(Agent#agent.id, Context),
    Counts = get_component_counts(Agent#agent.id, Context),
    
    #{
        id => Agent#agent.id,
        encoding_type => Agent#agent.encoding_type,
        generation => Agent#agent.generation,
        population_id => Agent#agent.population_id,
        specie_id => Agent#agent.specie_id,
        cx_id => Agent#agent.cx_id,
        substrate_id => Agent#agent.substrate_id,
        fingerprint => Agent#agent.fingerprint,
        fitness => Agent#agent.fitness,
        innovation_factor => Agent#agent.innovation_factor,
        pattern => Agent#agent.pattern,
        tuning_selection_f => Agent#agent.tuning_selection_f,
        annealing_parameter => Agent#agent.annealing_parameter,
        tuning_duration_f => Agent#agent.tuning_duration_f,
        perturbation_range => Agent#agent.perturbation_range,
        heredity_type => Agent#agent.heredity_type,
        evo_hist => Agent#agent.evo_hist,
        mutation_operators => get_mutation_operators(Agent),
        constraint => format_constraint(Agent#agent.constraint),
        topology => Topology,
        component_counts => Counts,
        metrics => calculate_metrics(Agent#agent.id, Context)
    }.

%% @doc Query agents matching criteria
query_agents(Context, MinFitness) ->
    TableName = dxnn_mnesia_loader:table_name(Context, agent),
    AllAgents = ets:tab2list(TableName),
    lists:filter(fun(Agent) ->
        Agent#agent.fitness >= MinFitness
    end, AllAgents).

%% @doc Query agents with topology information included
query_agents_with_topology(Context, MinFitness) ->
    Agents = query_agents(Context, MinFitness),
    lists:map(fun(Agent) ->
        try
            CxId = Agent#agent.cx_id,
            Cortex = read_record(cortex, CxId, Context),
            NeuronCount = case Cortex of
                undefined -> 0;
                _ -> length(Cortex#cortex.neuron_ids)
            end,
            SensorIds = case Cortex of
                undefined -> [];
                _ -> Cortex#cortex.sensor_ids
            end,
            % Get sensor names
            SensorNames = lists:map(fun(SId) ->
                case read_record(sensor, SId, Context) of
                    undefined -> undefined;
                    S -> S#sensor.name
                end
            end, SensorIds),
            
            {Agent, NeuronCount, SensorNames}
        catch
            _:_ ->
                % If there's an error, return agent with default values
                {Agent, 0, []}
        end
    end, Agents).

%% @doc Get complete topology for an agent
get_full_topology(AgentId, Context) ->
    case read_agent(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        {ok, Agent} ->
            Cortex = read_record(cortex, Agent#agent.cx_id, Context),
            
            case Cortex of
                undefined ->
                    {error, cortex_not_found};
                _ ->
                    %% Read neurons with error tracking
                    Neurons = lists:map(fun(NId) ->
                        case read_record(neuron, NId, Context) of
                            undefined ->
                                io:format("WARNING: Neuron ~p not found in context ~p~n", [NId, Context]),
                                undefined;
                            N -> N
                        end
                    end, Cortex#cortex.neuron_ids),
                    
                    Sensors = lists:map(fun(SId) ->
                        case read_record(sensor, SId, Context) of
                            undefined ->
                                io:format("WARNING: Sensor ~p not found in context ~p~n", [SId, Context]),
                                undefined;
                            S -> S
                        end
                    end, Cortex#cortex.sensor_ids),
                    
                    Actuators = lists:map(fun(AId) ->
                        case read_record(actuator, AId, Context) of
                            undefined ->
                                io:format("WARNING: Actuator ~p not found in context ~p~n", [AId, Context]),
                                undefined;
                            A -> A
                        end
                    end, Cortex#cortex.actuator_ids),
                    
                    Substrate = case Agent#agent.substrate_id of
                        undefined -> undefined;
                        SubId -> read_record(substrate, SubId, Context)
                    end,
                    
                    #{
                        agent => Agent,
                        cortex => Cortex,
                        neurons => Neurons,
                        sensors => Sensors,
                        actuators => Actuators,
                        substrate => Substrate
                    }
            end
    end.

%% @doc Get component counts for an agent
get_component_counts(AgentId, Context) ->
    case get_full_topology(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        Topology ->
            #{
                sensors => length(maps:get(sensors, Topology)),
                neurons => length(maps:get(neurons, Topology)),
                actuators => length(maps:get(actuators, Topology)),
                total_connections => count_connections(Topology)
            }
    end.

%% @doc Calculate detailed metrics for an agent
calculate_metrics(AgentId, Context) ->
    case get_full_topology(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        Topology ->
            Agent = maps:get(agent, Topology),
            Neurons = maps:get(neurons, Topology),
            
            TotalWeights = lists:sum([length(N#neuron.input_idps) || N <- Neurons]),
            
            #topo_summary{
                agent_id = AgentId,
                encoding_type = Agent#agent.encoding_type,
                sensor_count = length(maps:get(sensors, Topology)),
                neuron_count = length(Neurons),
                actuator_count = length(maps:get(actuators, Topology)),
                substrate_dimensions = get_substrate_dims(Topology),
                total_connections = TotalWeights,
                depth = calculate_depth(Topology),
                width = calculate_width(Topology),
                cycles = count_cycles(Topology)
            }
    end.

%% Internal functions

read_agent(AgentId, Context) ->
    TableName = dxnn_mnesia_loader:table_name(Context, agent),
    io:format("~n=== read_agent Debug ===~n"),
    io:format("Looking for agent: ~p~n", [AgentId]),
    io:format("In table: ~p~n", [TableName]),
    
    % Get first agent to see actual format
    case ets:first(TableName) of
        '$end_of_table' -> 
            io:format("Table is empty!~n");
        FirstKey ->
            io:format("Sample agent key from table: ~p~n", [FirstKey]),
            [FirstAgent] = ets:lookup(TableName, FirstKey),
            io:format("Sample agent ID field: ~p~n", [element(2, FirstAgent)])
    end,
    
    case ets:lookup(TableName, AgentId) of
        [] -> 
            io:format("Agent not found with key: ~p~n", [AgentId]),
            {error, agent_not_found};
        [Agent] -> 
            io:format("Agent found successfully~n"),
            {ok, Agent}
    end.

read_record(Type, Id, Context) ->
    TableName = dxnn_mnesia_loader:table_name(Context, Type),
    case ets:lookup(TableName, Id) of
        [] -> undefined;
        [Record] -> Record;
        [Record | _] -> Record  % For bag tables with multiple records, take the first
    end.

display_agent_info(Agent, Context) ->
    io:format("~n=== Agent Information ===~n"),
    io:format("ID: ~p~n", [Agent#agent.id]),
    io:format("Encoding: ~p~n", [Agent#agent.encoding_type]),
    io:format("Generation: ~p~n", [Agent#agent.generation]),
    io:format("Fitness: ~.6f~n", [Agent#agent.fitness]),
    io:format("Population: ~p~n", [Agent#agent.population_id]),
    io:format("Specie: ~p~n", [Agent#agent.specie_id]),
    
    Counts = get_component_counts(Agent#agent.id, Context),
    io:format("~nTopology:~n"),
    io:format("  Sensors: ~w~n", [maps:get(sensors, Counts)]),
    io:format("  Neurons: ~w~n", [maps:get(neurons, Counts)]),
    io:format("  Actuators: ~w~n", [maps:get(actuators, Counts)]),
    io:format("  Connections: ~w~n", [maps:get(total_connections, Counts)]),
    
    io:format("~nEvolution History:~n"),
    lists:foreach(fun(Mutation) ->
        io:format("  - ~p~n", [Mutation])
    end, lists:sublist(Agent#agent.evo_hist, 10)),
    
    ok.

count_connections(Topology) ->
    Neurons = maps:get(neurons, Topology),
    lists:sum([length(N#neuron.input_idps) || N <- Neurons]).

get_substrate_dims(Topology) ->
    case maps:get(substrate, Topology) of
        undefined -> undefined;
        Substrate -> Substrate#substrate.densities
    end.

calculate_depth(Topology) ->
    Neurons = maps:get(neurons, Topology),
    case Neurons of
        [] -> 0;
        _ ->
            Layers = lists:usort([element(1, element(1, N#neuron.id)) || N <- Neurons]),
            length(Layers)
    end.

calculate_width(Topology) ->
    Neurons = maps:get(neurons, Topology),
    case Neurons of
        [] -> 0;
        _ ->
            LayerMap = lists:foldl(fun(N, Acc) ->
                Layer = element(1, element(1, N#neuron.id)),
                maps:update_with(Layer, fun(Count) -> Count + 1 end, 1, Acc)
            end, #{}, Neurons),
            lists:max(maps:values(LayerMap))
    end.

count_cycles(Topology) ->
    Neurons = maps:get(neurons, Topology),
    lists:sum([length(N#neuron.ro_ids) || N <- Neurons]).

get_mutation_operators(Agent) ->
    case Agent#agent.mutation_operators of
        undefined -> [];
        Ops -> Ops
    end.

format_constraint(undefined) ->
    undefined;
format_constraint(Constraint) ->
    #{
        morphology => Constraint#constraint.morphology,
        connection_architecture => Constraint#constraint.connection_architecture,
        neural_afs => Constraint#constraint.neural_afs,
        neural_pfns => Constraint#constraint.neural_pfns,
        substrate_plasticities => Constraint#constraint.substrate_plasticities,
        substrate_linkforms => Constraint#constraint.substrate_linkforms,
        neural_aggr_fs => Constraint#constraint.neural_aggr_fs,
        tuning_selection_fs => Constraint#constraint.tuning_selection_fs,
        tuning_duration_f => Constraint#constraint.tuning_duration_f,
        annealing_parameters => Constraint#constraint.annealing_parameters,
        perturbation_ranges => Constraint#constraint.perturbation_ranges,
        agent_encoding_types => Constraint#constraint.agent_encoding_types,
        heredity_types => Constraint#constraint.heredity_types,
        mutation_operators => Constraint#constraint.mutation_operators,
        tot_topological_mutations_fs => Constraint#constraint.tot_topological_mutations_fs,
        population_evo_alg_f => Constraint#constraint.population_evo_alg_f,
        population_fitness_postprocessor_f => Constraint#constraint.population_fitness_postprocessor_f,
        population_selection_f => Constraint#constraint.population_selection_f
    }.
