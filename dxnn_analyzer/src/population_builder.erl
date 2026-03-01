-module(population_builder).
-export([
    create_population/4,
    validate_population/1
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Create a new population from selected agents
create_population(AgentIds, NewPopulationId, OutputFolder, Options) ->
    io:format("Creating new population: ~p~n", [NewPopulationId]),
    io:format("Output folder: ~s~n", [OutputFolder]),
    io:format("Selected agents: ~w~n~n", [length(AgentIds)]),
    
    Context = proplists:get_value(context, Options, current),
    SpecieId = proplists:get_value(specie_id, Options, {specie, generate_id()}),
    
    filelib:ensure_dir(OutputFolder ++ "/"),
    
    MnesiaDir = filename:join(OutputFolder, "Mnesia.nonode@nohost"),
    filelib:ensure_dir(MnesiaDir ++ "/"),
    
    case init_mnesia_schema(MnesiaDir) of
        ok ->
            lists:foreach(fun(AgentId) ->
                io:format("Copying agent ~p...~n", [AgentId]),
                copy_agent_full(AgentId, Context, NewPopulationId, SpecieId)
            end, AgentIds),
            
            create_population_record(NewPopulationId, SpecieId, AgentIds),
            create_specie_record(SpecieId, NewPopulationId, AgentIds),
            
            case validate_population(MnesiaDir) of
                ok ->
                    io:format("~nPopulation created successfully!~n"),
                    io:format("Location: ~s~n", [MnesiaDir]),
                    {ok, MnesiaDir};
                {error, Reason} ->
                    io:format("Validation failed: ~p~n", [Reason]),
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

%% @doc Validate population integrity
validate_population(MnesiaDir) ->
    io:format("Validating population...~n"),
    
    application:stop(mnesia),
    application:set_env(mnesia, dir, MnesiaDir),
    mnesia:start(),
    
    case mnesia:wait_for_tables([agent, cortex, neuron, sensor, actuator], 5000) of
        ok ->
            AgentIds = mnesia:dirty_all_keys(agent),
            io:format("  Found ~w agents~n", [length(AgentIds)]),
            
            Errors = lists:filtermap(fun(AgentId) ->
                case validate_agent(AgentId) of
                    ok -> false;
                    {error, Reason} -> {true, {AgentId, Reason}}
                end
            end, AgentIds),
            
            case Errors of
                [] ->
                    io:format("  Validation passed!~n"),
                    ok;
                _ ->
                    io:format("  Validation errors:~n"),
                    lists:foreach(fun({Id, Reason}) ->
                        io:format("    ~p: ~p~n", [Id, Reason])
                    end, Errors),
                    {error, validation_failed}
            end;
        {timeout, Tables} ->
            {error, {timeout_waiting_for_tables, Tables}}
    end.

%% Internal functions

init_mnesia_schema(MnesiaDir) ->
    application:stop(mnesia),
    
    file:del_dir_r(MnesiaDir),
    filelib:ensure_dir(MnesiaDir ++ "/"),
    
    application:set_env(mnesia, dir, MnesiaDir),
    case mnesia:create_schema([node()]) of
        ok ->
            mnesia:start(),
            create_tables(),
            ok;
        {error, Reason} ->
            {error, Reason}
    end.

create_tables() ->
    mnesia:create_table(agent, [
        {attributes, record_info(fields, agent)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(cortex, [
        {attributes, record_info(fields, cortex)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(neuron, [
        {attributes, record_info(fields, neuron)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(sensor, [
        {attributes, record_info(fields, sensor)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(actuator, [
        {attributes, record_info(fields, actuator)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(substrate, [
        {attributes, record_info(fields, substrate)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(population, [
        {attributes, record_info(fields, population)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    mnesia:create_table(specie, [
        {attributes, record_info(fields, specie)},
        {disc_copies, [node()]},
        {type, set}
    ]),
    ok.

copy_agent_full(AgentId, SourceContext, NewPopulationId, NewSpecieId) ->
    case agent_inspector:get_full_topology(AgentId, SourceContext) of
        {error, Reason} ->
            io:format("  Error: ~p~n", [Reason]),
            {error, Reason};
        Topology ->
            Agent = maps:get(agent, Topology),
            UpdatedAgent = Agent#agent{
                population_id = NewPopulationId,
                specie_id = NewSpecieId
            },
            
            mnesia:dirty_write(agent, UpdatedAgent),
            mnesia:dirty_write(cortex, maps:get(cortex, Topology)),
            
            lists:foreach(fun(N) ->
                mnesia:dirty_write(neuron, N)
            end, maps:get(neurons, Topology)),
            
            lists:foreach(fun(S) ->
                mnesia:dirty_write(sensor, S)
            end, maps:get(sensors, Topology)),
            
            lists:foreach(fun(A) ->
                mnesia:dirty_write(actuator, A)
            end, maps:get(actuators, Topology)),
            
            case maps:get(substrate, Topology) of
                undefined -> ok;
                Substrate -> mnesia:dirty_write(substrate, Substrate)
            end,
            
            ok
    end.

create_population_record(PopulationId, SpecieId, _AgentIds) ->
    Population = #population{
        id = PopulationId,
        polis_id = mathema,
        specie_ids = [SpecieId],
        morphologies = [forex_trader],
        innovation_factor = {0, 0},
        evo_alg_f = generational,
        fitness_postprocessor_f = none,
        selection_f = competition,
        trace = #trace{}
    },
    mnesia:dirty_write(population, Population).

create_specie_record(SpecieId, PopulationId, AgentIds) ->
    [FirstAgent] = mnesia:dirty_read(agent, hd(AgentIds)),
    
    Specie = #specie{
        id = SpecieId,
        population_id = PopulationId,
        fingerprint = FirstAgent#agent.fingerprint,
        constraint = FirstAgent#agent.constraint,
        agent_ids = AgentIds,
        dead_pool = [],
        champion_ids = [],
        fitness = 0.0,
        innovation_factor = {0, 0},
        stats = []
    },
    mnesia:dirty_write(specie, Specie).

validate_agent(AgentId) ->
    case mnesia:dirty_read(agent, AgentId) of
        [] ->
            {error, agent_not_found};
        [Agent] ->
            case mnesia:dirty_read(cortex, Agent#agent.cx_id) of
                [] ->
                    {error, cortex_not_found};
                [Cortex] ->
                    MissingNeurons = lists:filter(fun(NId) ->
                        mnesia:dirty_read(neuron, NId) == []
                    end, Cortex#cortex.neuron_ids),
                    
                    case MissingNeurons of
                        [] -> ok;
                        _ -> {error, {missing_neurons, MissingNeurons}}
                    end
            end
    end.

generate_id() ->
    {erlang:system_time(), erlang:unique_integer([positive])}.
