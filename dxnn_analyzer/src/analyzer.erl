-module(analyzer).
-export([
    start/0, stop/0,
    load/2, unload/1, list_contexts/0,
    list_agents/0, list_agents/1,
    inspect/1, inspect/2,
    show_topology/1, show_topology/2,
    show_mutations/1, show_mutations/2,
    compare/1, compare/2,
    find_best/1, find_best/2,
    create_population/3, create_population/4,
    export_report/2
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Start the analyzer application
start() ->
    io:format("Starting DXNN Analyzer...~n"),
    application:ensure_all_started(mnesia),
    ets:new(analyzer_contexts, [named_table, public, {keypos, #mnesia_context.name}]),
    io:format("Analyzer ready.~n"),
    ok.

%% @doc Stop the analyzer application
stop() ->
    io:format("Stopping DXNN Analyzer...~n"),
    lists:foreach(fun(Context) ->
        unload(Context#mnesia_context.name)
    end, ets:tab2list(analyzer_contexts)),
    ets:delete(analyzer_contexts),
    ok.

%% @doc Load a Mnesia folder into a named context
load(MnesiaPath, ContextName) ->
    dxnn_mnesia_loader:load_folder(MnesiaPath, ContextName).

%% @doc Unload a context and free resources
unload(ContextName) ->
    dxnn_mnesia_loader:unload_context(ContextName).

%% @doc List all loaded contexts
list_contexts() ->
    Contexts = ets:tab2list(analyzer_contexts),
    io:format("~nLoaded Contexts:~n"),
    io:format("~-20s ~-50s ~10s ~10s~n", 
              ["Name", "Path", "Agents", "Species"]),
    io:format("~s~n", [lists:duplicate(90, $-)]),
    lists:foreach(fun(C) ->
        io:format("~-20s ~-50s ~10w ~10w~n",
                  [C#mnesia_context.name, 
                   C#mnesia_context.path,
                   C#mnesia_context.agent_count,
                   C#mnesia_context.specie_count])
    end, Contexts),
    Contexts.

%% @doc List all agents (all contexts)
list_agents() ->
    list_agents([]).

%% @doc List agents with filters
list_agents(Options) ->
    Context = proplists:get_value(context, Options, all),
    MinFitness = proplists:get_value(min_fitness, Options, 0.0),
    SortBy = proplists:get_value(sort, Options, fitness),
    Limit = proplists:get_value(limit, Options, all),
    
    % Use query_agents_with_topology to get neuron counts and sensors
    AgentsWithTopology = agent_inspector:query_agents_with_topology(Context, MinFitness),
    Sorted = sort_agents_with_topology(AgentsWithTopology, SortBy),
    Limited = case Limit of
        all -> Sorted;
        N -> lists:sublist(Sorted, N)
    end,
    
    Limited.

%% @doc Inspect a single agent (current context)
inspect(AgentId) ->
    inspect(AgentId, current).

%% @doc Inspect a single agent in specific context
inspect(AgentId, Context) ->
    agent_inspector:inspect_agent(AgentId, Context).

%% @doc Show topology for an agent
show_topology(AgentId) ->
    show_topology(AgentId, current).

show_topology(AgentId, Context) ->
    topology_mapper:display_topology(AgentId, Context).

%% @doc Show mutation history
show_mutations(AgentId) ->
    show_mutations(AgentId, current).

show_mutations(AgentId, Context) ->
    mutation_analyzer:display_mutations(AgentId, Context).

%% @doc Compare multiple agents (current context)
compare(AgentIds) ->
    compare(AgentIds, current).

compare(AgentIds, Context) ->
    comparator:compare_agents(AgentIds, Context).

%% @doc Find best N agents (current context)
find_best(N) ->
    find_best(N, []).

find_best(N, Options) ->
    list_agents([{sort, fitness}, {limit, N} | Options]).

%% @doc Create new population from selected agents
create_population(AgentIds, NewPopulationId, OutputFolder) ->
    create_population(AgentIds, NewPopulationId, OutputFolder, []).

create_population(AgentIds, NewPopulationId, OutputFolder, Options) ->
    population_builder:create_population(AgentIds, NewPopulationId, 
                                         OutputFolder, Options).

%% @doc Export analysis report to file
export_report(Agents, Filename) ->
    stats_collector:export_report(Agents, Filename).

%% Internal helpers
sort_agents(Agents, fitness) ->
    lists:sort(fun(A1, A2) -> 
        A1#agent.fitness >= A2#agent.fitness 
    end, Agents);
sort_agents(Agents, generation) ->
    lists:sort(fun(A1, A2) -> 
        A1#agent.generation =< A2#agent.generation 
    end, Agents).

sort_agents_with_topology(AgentsWithTopology, fitness) ->
    lists:sort(fun({A1, _, _}, {A2, _, _}) -> 
        A1#agent.fitness >= A2#agent.fitness 
    end, AgentsWithTopology);
sort_agents_with_topology(AgentsWithTopology, generation) ->
    lists:sort(fun({A1, _, _}, {A2, _, _}) -> 
        A1#agent.generation =< A2#agent.generation 
    end, AgentsWithTopology).

print_agent_list(Agents) ->
    io:format("~n~-40s ~10s ~10s ~10s~n", 
              ["Agent ID", "Fitness", "Gen", "Neurons"]),
    io:format("~s~n", [lists:duplicate(70, $-)]),
    lists:foreach(fun(Agent) ->
        NeuronCount = length(get_neuron_ids(Agent)),
        io:format("~-40w ~10.4f ~10w ~10w~n",
                  [Agent#agent.id, Agent#agent.fitness, 
                   Agent#agent.generation, NeuronCount])
    end, Agents).

get_neuron_ids(Agent) ->
    TableName = list_to_atom("current_cortex"),
    case ets:lookup(TableName, Agent#agent.cx_id) of
        [Cortex] -> Cortex#cortex.neuron_ids;
        [] -> []
    end.
