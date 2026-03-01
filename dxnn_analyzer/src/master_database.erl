-module(master_database).
-export([
    init/1,
    add_agents/3,
    load_as_context/2,
    list_agents/1,
    remove_agents/2,
    clear_master/1,
    debug_check_source/2
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Initialize master database as DETS files
init(BasePath) ->
    MasterPath = filename:join(BasePath, "MasterDatabase"),
    filelib:ensure_dir(MasterPath ++ "/"),
    
    io:format("Initializing master database at: ~s~n", [MasterPath]),
    
    %% Create DETS files for each table
    %% Core tables: agent topology
    %% Optional tables: population, specie (for compatibility with analyzer loader)
    %% Use duplicate_bag to allow multiple records with same key (like ETS bag)
    Tables = [agent, cortex, neuron, sensor, actuator, substrate, population, specie],
    lists:foreach(fun(Table) ->
        DetsFile = filename:join(MasterPath, atom_to_list(Table) ++ ".dets"),
        %% Use duplicate_bag to match ETS bag behavior
        case dets:open_file(Table, [{file, DetsFile}, {type, duplicate_bag}]) of
            {ok, _} -> 
                dets:close(Table),
                io:format("  Initialized table: ~p~n", [Table]);
            {error, Reason} ->
                io:format("  Error initializing table ~p: ~p~n", [Table, Reason])
        end
    end, Tables),
    
    io:format("Master database initialized successfully~n"),
    {ok, MasterPath}.

%% @doc Add agents to master database (DETS)
add_agents(AgentIds, SourceContext, MasterPath) ->
    io:format("Adding ~w agents to master database from context ~p~n", [length(AgentIds), SourceContext]),
    
    %% Fetch all agent data from source context (ETS tables)
    io:format("Fetching agents from source context...~n"),
    AgentData = lists:map(fun(AgentId) ->
        case agent_inspector:get_full_topology(AgentId, SourceContext) of
            {error, Reason} ->
                io:format("  Error fetching agent ~p: ~p~n", [AgentId, Reason]),
                {error, AgentId, Reason};
            Topology ->
                %% Validate topology has all required components
                Agent = maps:get(agent, Topology),
                Cortex = maps:get(cortex, Topology),
                Neurons = maps:get(neurons, Topology),
                Sensors = maps:get(sensors, Topology),
                Actuators = maps:get(actuators, Topology),
                
                %% Check for undefined values
                UndefinedNeurons = length([N || N <- Neurons, N =:= undefined]),
                UndefinedSensors = length([S || S <- Sensors, S =:= undefined]),
                UndefinedActuators = length([A || A <- Actuators, A =:= undefined]),
                
                if
                    UndefinedNeurons > 0 ->
                        io:format("  WARNING: Agent ~p has ~w undefined neurons!~n", [AgentId, UndefinedNeurons]);
                    true -> ok
                end,
                if
                    UndefinedSensors > 0 ->
                        io:format("  WARNING: Agent ~p has ~w undefined sensors!~n", [AgentId, UndefinedSensors]);
                    true -> ok
                end,
                if
                    UndefinedActuators > 0 ->
                        io:format("  WARNING: Agent ~p has ~w undefined actuators!~n", [AgentId, UndefinedActuators]);
                    true -> ok
                end,
                
                io:format("  Fetched agent ~p: ~w neurons, ~w sensors, ~w actuators~n", 
                         [AgentId, length(Neurons) - UndefinedNeurons, 
                          length(Sensors) - UndefinedSensors, 
                          length(Actuators) - UndefinedActuators]),
                {ok, AgentId, Topology}
        end
    end, AgentIds),
    
    %% Check for fetch errors
    FetchErrors = [{Id, R} || {error, Id, R} <- AgentData],
    case FetchErrors of
        [] ->
            %% All agents fetched, now write to DETS
            io:format("Writing ~w agents to master database...~n", [length(AgentData)]),
            write_agents_to_dets(AgentData, MasterPath);
        _ ->
            io:format("Failed to fetch ~w agents: ~p~n", [length(FetchErrors), FetchErrors]),
            {error, {fetch_failed, FetchErrors}}
    end.

%% Write agents to DETS files
write_agents_to_dets(AgentData, MasterPath) ->
    try
        %% Open all DETS files
        Tables = [
            {agent, filename:join(MasterPath, "agent.dets")},
            {cortex, filename:join(MasterPath, "cortex.dets")},
            {neuron, filename:join(MasterPath, "neuron.dets")},
            {sensor, filename:join(MasterPath, "sensor.dets")},
            {actuator, filename:join(MasterPath, "actuator.dets")},
            {substrate, filename:join(MasterPath, "substrate.dets")},
            {population, filename:join(MasterPath, "population.dets")},
            {specie, filename:join(MasterPath, "specie.dets")}
        ],
        
        %% Open all tables with duplicate_bag type
        lists:foreach(fun({Table, File}) ->
            {ok, _} = dets:open_file(Table, [{file, File}, {type, duplicate_bag}])
        end, Tables),
        
        %% Write each agent
        Results = lists:map(fun({ok, AgentId, Topology}) ->
            write_agent_to_dets(AgentId, Topology)
        end, AgentData),
        
        %% Close all DETS files
        lists:foreach(fun({Table, _}) ->
            dets:close(Table)
        end, Tables),
        
        SuccessCount = length([ok || {ok, _} <- Results]),
        io:format("Successfully added ~w agents to master database~n", [SuccessCount]),
        {ok, SuccessCount}
    catch
        Error:Reason:Stack ->
            io:format("Error writing to DETS: ~p:~p~n~p~n", [Error, Reason, Stack]),
            {error, {dets_write_failed, Reason}}
    end.

write_agent_to_dets(AgentId, Topology) ->
    try
        %% Check if agent already exists
        case dets:lookup(agent, AgentId) of
            [_] ->
                io:format("  Agent ~p already exists, skipping~n", [AgentId]),
                {ok, skipped};
            [] ->
                %% Write all components, filtering out undefined values
                Agent = maps:get(agent, Topology),
                dets:insert(agent, Agent),
                io:format("  Wrote agent ~p~n", [AgentId]),
                
                Cortex = maps:get(cortex, Topology),
                dets:insert(cortex, Cortex),
                io:format("    Wrote cortex ~p~n", [Cortex#cortex.id]),
                
                %% Filter out undefined neurons
                Neurons = lists:filter(fun(N) -> N =/= undefined end, maps:get(neurons, Topology)),
                io:format("    Writing ~w neurons...~n", [length(Neurons)]),
                lists:foreach(fun(N) ->
                    dets:insert(neuron, N)
                end, Neurons),
                
                %% Filter out undefined sensors
                Sensors = lists:filter(fun(S) -> S =/= undefined end, maps:get(sensors, Topology)),
                io:format("    Writing ~w sensors...~n", [length(Sensors)]),
                lists:foreach(fun(S) ->
                    dets:insert(sensor, S)
                end, Sensors),
                
                %% Filter out undefined actuators
                Actuators = lists:filter(fun(A) -> A =/= undefined end, maps:get(actuators, Topology)),
                io:format("    Writing ~w actuators...~n", [length(Actuators)]),
                lists:foreach(fun(A) ->
                    dets:insert(actuator, A)
                end, Actuators),
                
                case maps:get(substrate, Topology) of
                    undefined -> 
                        io:format("    No substrate~n");
                    Substrate -> 
                        dets:insert(substrate, Substrate),
                        io:format("    Wrote substrate ~p~n", [Substrate#substrate.id])
                end,
                
                io:format("  Successfully wrote agent ~p with all components~n", [AgentId]),
                {ok, copied}
        end
    catch
        Error:WriteReason:Stack ->
            io:format("  Error writing agent ~p: ~p:~p~n~p~n", [AgentId, Error, WriteReason, Stack]),
            {error, {AgentId, WriteReason}}
    end.

%% @doc Load master database as a context (DETS -> ETS)
load_as_context(MasterPath, ContextName) ->
    io:format("Loading master database as context: ~p~n", [ContextName]),
    
    try
        %% Create ETS tables for this context
        %% Use 'bag' type to match source context behavior (allows multiple records per key)
        Tables = [agent, cortex, neuron, sensor, actuator, substrate, population, specie],
        EtsTables = lists:map(fun(TableName) ->
            EtsName = dxnn_mnesia_loader:table_name(ContextName, TableName),
            ets:new(EtsName, [named_table, public, bag, {keypos, 2}]),
            {TableName, EtsName}
        end, Tables),
        
        %% Load data from DETS to ETS
        lists:foreach(fun(Table) ->
            DetsFile = filename:join(MasterPath, atom_to_list(Table) ++ ".dets"),
            case filelib:is_file(DetsFile) of
                true ->
                    {ok, _} = dets:open_file(Table, [{file, DetsFile}, {type, duplicate_bag}]),
                    EtsTable = dxnn_mnesia_loader:table_name(ContextName, Table),
                    
                    %% Copy all records from DETS to ETS
                    dets:traverse(Table, fun(Record) ->
                        ets:insert(EtsTable, Record),
                        continue
                    end),
                    
                    RecordCount = ets:info(EtsTable, size),
                    dets:close(Table),
                    io:format("  Loaded ~p records from ~p~n", [RecordCount, Table]);
                false ->
                    io:format("  No DETS file for ~p, skipping~n", [Table])
            end
        end, Tables),
        
        %% Count agents
        AgentTable = dxnn_mnesia_loader:table_name(ContextName, agent),
        AgentCount = ets:info(AgentTable, size),
        
        %% Create context record
        Context = #mnesia_context{
            name = ContextName,
            path = MasterPath,
            loaded_at = erlang:timestamp(),
            agent_count = AgentCount,
            population_count = 0,
            specie_count = 0,
            tables = [T || {_, T} <- EtsTables]
        },
        
        %% Store context
        case ets:info(analyzer_contexts) of
            undefined ->
                ets:new(analyzer_contexts, [named_table, public, set]);
            _ -> ok
        end,
        ets:insert(analyzer_contexts, Context),
        
        io:format("Master database loaded as context '~p' with ~w agents~n", [ContextName, AgentCount]),
        {ok, Context}
    catch
        Error:Reason:Stack ->
            io:format("Error loading master as context: ~p:~p~n~p~n", [Error, Reason, Stack]),
            {error, {load_failed, Reason}}
    end.

%% @doc List all agents in master database
list_agents(MasterPath) ->
    DetsFile = filename:join(MasterPath, "agent.dets"),
    case filelib:is_file(DetsFile) of
        true ->
            {ok, _} = dets:open_file(master_agent, [{file, DetsFile}, {type, duplicate_bag}]),
            Agents = dets:foldl(fun(Agent, Acc) -> [Agent | Acc] end, [], master_agent),
            dets:close(master_agent),
            {ok, Agents};
        false ->
            {ok, []}
    end.

%% @doc Remove agents from master database
remove_agents(AgentIds, MasterPath) ->
    try
        %% Open DETS files
        Tables = [
            {agent, filename:join(MasterPath, "agent.dets")},
            {cortex, filename:join(MasterPath, "cortex.dets")},
            {neuron, filename:join(MasterPath, "neuron.dets")},
            {sensor, filename:join(MasterPath, "sensor.dets")},
            {actuator, filename:join(MasterPath, "actuator.dets")},
            {substrate, filename:join(MasterPath, "substrate.dets")}
        ],
        
        lists:foreach(fun({Table, File}) ->
            case filelib:is_file(File) of
                true -> {ok, _} = dets:open_file(Table, [{file, File}, {type, duplicate_bag}]);
                false -> ok
            end
        end, Tables),
        
        %% Delete each agent and its components
        lists:foreach(fun(AgentId) ->
            case dets:lookup(agent, AgentId) of
                [Agent] ->
                    %% Get cortex to find all components
                    CxId = Agent#agent.cx_id,
                    case dets:lookup(cortex, CxId) of
                        [Cortex] ->
                            %% Delete neurons
                            lists:foreach(fun(NId) ->
                                dets:delete(neuron, NId)
                            end, Cortex#cortex.neuron_ids),
                            
                            %% Delete sensors
                            lists:foreach(fun(SId) ->
                                dets:delete(sensor, SId)
                            end, Cortex#cortex.sensor_ids),
                            
                            %% Delete actuators
                            lists:foreach(fun(AId) ->
                                dets:delete(actuator, AId)
                            end, Cortex#cortex.actuator_ids),
                            
                            %% Delete cortex
                            dets:delete(cortex, CxId);
                        [] -> ok
                    end,
                    
                    %% Delete substrate if exists
                    case Agent#agent.substrate_id of
                        undefined -> ok;
                        SubId -> dets:delete(substrate, SubId)
                    end,
                    
                    %% Delete agent
                    dets:delete(agent, AgentId);
                [] -> ok
            end
        end, AgentIds),
        
        %% Close all DETS files
        lists:foreach(fun({Table, _}) ->
            dets:close(Table)
        end, Tables),
        
        {ok, length(AgentIds)}
    catch
        Error:Reason:Stack ->
            io:format("Error removing agents: ~p:~p~n~p~n", [Error, Reason, Stack]),
            {error, {remove_failed, Reason}}
    end.

%% @doc Clear all agents from master database
clear_master(MasterPath) ->
    Tables = [agent, cortex, neuron, sensor, actuator, substrate],
    lists:foreach(fun(Table) ->
        DetsFile = filename:join(MasterPath, atom_to_list(Table) ++ ".dets"),
        case filelib:is_file(DetsFile) of
            true -> file:delete(DetsFile);
            false -> ok
        end
    end, Tables),
    init(filename:dirname(MasterPath)).

%% @doc Debug function to check source context for an agent
debug_check_source(AgentId, SourceContext) ->
    io:format("~n=== Debugging Source Context for Agent ~p ===~n", [AgentId]),
    
    %% Check agent
    AgentTable = dxnn_mnesia_loader:table_name(SourceContext, agent),
    io:format("Agent table: ~p~n", [AgentTable]),
    case ets:lookup(AgentTable, AgentId) of
        [] -> io:format("  Agent NOT FOUND~n");
        Agents -> io:format("  Found ~w agent record(s)~n", [length(Agents)])
    end,
    
    %% Get topology
    case agent_inspector:get_full_topology(AgentId, SourceContext) of
        {error, Reason} ->
            io:format("  Error getting topology: ~p~n", [Reason]);
        Topology ->
            Agent = maps:get(agent, Topology),
            Cortex = maps:get(cortex, Topology),
            Neurons = maps:get(neurons, Topology),
            Sensors = maps:get(sensors, Topology),
            Actuators = maps:get(actuators, Topology),
            
            io:format("~nCortex: ~p~n", [Cortex#cortex.id]),
            io:format("  Neuron IDs in cortex: ~p~n", [Cortex#cortex.neuron_ids]),
            io:format("  Sensor IDs in cortex: ~p~n", [Cortex#cortex.sensor_ids]),
            io:format("  Actuator IDs in cortex: ~p~n", [Cortex#cortex.actuator_ids]),
            
            io:format("~nNeurons retrieved: ~w~n", [length(Neurons)]),
            lists:foreach(fun(N) ->
                case N of
                    undefined -> io:format("  - undefined~n");
                    _ -> io:format("  - ~p~n", [N#neuron.id])
                end
            end, Neurons),
            
            io:format("~nSensors retrieved: ~w~n", [length(Sensors)]),
            lists:foreach(fun(S) ->
                case S of
                    undefined -> io:format("  - undefined~n");
                    _ -> io:format("  - ~p~n", [S#sensor.id])
                end
            end, Sensors),
            
            io:format("~nActuators retrieved: ~w~n", [length(Actuators)]),
            lists:foreach(fun(A) ->
                case A of
                    undefined -> io:format("  - undefined~n");
                    _ -> io:format("  - ~p~n", [A#actuator.id])
                end
            end, Actuators),
            
            %% Check each neuron ID directly in ETS
            io:format("~nDirect ETS lookup for each neuron:~n"),
            NeuronTable = dxnn_mnesia_loader:table_name(SourceContext, neuron),
            lists:foreach(fun(NId) ->
                case ets:lookup(NeuronTable, NId) of
                    [] -> io:format("  ~p: NOT FOUND~n", [NId]);
                    Records -> io:format("  ~p: Found ~w record(s)~n", [NId, length(Records)])
                end
            end, Cortex#cortex.neuron_ids)
    end,
    
    ok.
