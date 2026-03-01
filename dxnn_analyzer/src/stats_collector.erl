-module(stats_collector).
-export([
    collect_stats/1,
    export_report/2,
    generate_summary/1
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Collect comprehensive statistics for a context
collect_stats(Context) ->
    TableName = dxnn_mnesia_loader:table_name(Context, agent),
    Agents = ets:tab2list(TableName),
    
    case Agents of
        [] ->
            {error, no_agents};
        _ ->
            Stats = #{
                total_agents => length(Agents),
                fitness_stats => calculate_fitness_stats(Agents),
                generation_stats => calculate_generation_stats(Agents),
                topology_stats => calculate_topology_stats(Agents, Context),
                mutation_stats => calculate_mutation_stats(Agents),
                encoding_distribution => calculate_encoding_distribution(Agents)
            },
            {ok, Stats}
    end.

%% @doc Export analysis report to file
export_report(Agents, Filename) ->
    {ok, File} = file:open(Filename, [write]),
    
    io:format(File, "DXNN Agent Analysis Report~n", []),
    io:format(File, "Generated: ~s~n~n", [format_timestamp(erlang:timestamp())]),
    
    io:format(File, "Total Agents: ~w~n~n", [length(Agents)]),
    
    io:format(File, "Top Agents by Fitness:~n", []),
    Sorted = lists:sort(fun(A1, A2) -> 
        A1#agent.fitness >= A2#agent.fitness 
    end, Agents),
    
    lists:foreach(fun(Agent) ->
        io:format(File, "  ~p: Fitness=~.6f, Gen=~w~n",
                 [Agent#agent.id, Agent#agent.fitness, Agent#agent.generation])
    end, lists:sublist(Sorted, 10)),
    
    file:close(File),
    io:format("Report exported to ~s~n", [Filename]),
    ok.

%% @doc Generate summary for a context
generate_summary(Context) ->
    case collect_stats(Context) of
        {error, Reason} ->
            {error, Reason};
        {ok, Stats} ->
            io:format("~n=== Context Summary: ~p ===~n~n", [Context]),
            
            io:format("Total Agents: ~w~n~n", [maps:get(total_agents, Stats)]),
            
            FitnessStats = maps:get(fitness_stats, Stats),
            io:format("Fitness:~n"),
            io:format("  Best: ~.6f~n", [maps:get(max, FitnessStats)]),
            io:format("  Average: ~.6f~n", [maps:get(avg, FitnessStats)]),
            io:format("  Worst: ~.6f~n~n", [maps:get(min, FitnessStats)]),
            
            GenStats = maps:get(generation_stats, Stats),
            io:format("Generations:~n"),
            io:format("  Max: ~w~n", [maps:get(max, GenStats)]),
            io:format("  Average: ~.2f~n~n", [maps:get(avg, GenStats)]),
            
            TopoStats = maps:get(topology_stats, Stats),
            io:format("Topology:~n"),
            io:format("  Avg Neurons: ~.2f~n", [maps:get(avg_neurons, TopoStats)]),
            io:format("  Avg Connections: ~.2f~n~n", [maps:get(avg_connections, TopoStats)]),
            
            EncDist = maps:get(encoding_distribution, Stats),
            io:format("Encoding Distribution:~n"),
            maps:foreach(fun(Type, Count) ->
                io:format("  ~p: ~w~n", [Type, Count])
            end, EncDist),
            
            {ok, Stats}
    end.

%% Internal functions

calculate_fitness_stats(Agents) ->
    Fitnesses = [A#agent.fitness || A <- Agents],
    #{
        max => lists:max(Fitnesses),
        min => lists:min(Fitnesses),
        avg => lists:sum(Fitnesses) / length(Fitnesses),
        median => median(Fitnesses),
        std_dev => std_deviation(Fitnesses)
    }.

calculate_generation_stats(Agents) ->
    Generations = [A#agent.generation || A <- Agents],
    #{
        max => lists:max(Generations),
        min => lists:min(Generations),
        avg => lists:sum(Generations) / length(Generations)
    }.

calculate_topology_stats(Agents, Context) ->
    Topologies = lists:filtermap(fun(Agent) ->
        case agent_inspector:get_full_topology(Agent#agent.id, Context) of
            {error, _} -> false;
            Topo -> {true, Topo}
        end
    end, Agents),
    
    case Topologies of
        [] ->
            #{avg_neurons => 0, avg_connections => 0};
        _ ->
            NeuronCounts = [length(maps:get(neurons, T)) || T <- Topologies],
            ConnectionCounts = [count_connections(T) || T <- Topologies],
            
            #{
                avg_neurons => lists:sum(NeuronCounts) / length(NeuronCounts),
                avg_connections => lists:sum(ConnectionCounts) / length(ConnectionCounts),
                max_neurons => lists:max(NeuronCounts),
                min_neurons => lists:min(NeuronCounts)
            }
    end.

calculate_mutation_stats(Agents) ->
    AllMutations = lists:flatten([A#agent.evo_hist || A <- Agents]),
    MutationTypes = [element(1, M) || M <- AllMutations],
    
    Counts = lists:foldl(fun(Type, Acc) ->
        maps:update_with(Type, fun(C) -> C + 1 end, 1, Acc)
    end, #{}, MutationTypes),
    
    #{
        total_mutations => length(AllMutations),
        avg_per_agent => length(AllMutations) / length(Agents),
        type_distribution => Counts
    }.

calculate_encoding_distribution(Agents) ->
    lists:foldl(fun(Agent, Acc) ->
        Type = Agent#agent.encoding_type,
        maps:update_with(Type, fun(C) -> C + 1 end, 1, Acc)
    end, #{}, Agents).

count_connections(Topology) ->
    Neurons = maps:get(neurons, Topology),
    lists:sum([length(N#neuron.input_idps) || N <- Neurons]).

median(List) ->
    Sorted = lists:sort(List),
    Len = length(Sorted),
    case Len rem 2 of
        0 ->
            (lists:nth(Len div 2, Sorted) + lists:nth(Len div 2 + 1, Sorted)) / 2;
        1 ->
            lists:nth(Len div 2 + 1, Sorted)
    end.

std_deviation(List) ->
    Mean = lists:sum(List) / length(List),
    Variance = lists:sum([math:pow(X - Mean, 2) || X <- List]) / length(List),
    math:sqrt(Variance).

format_timestamp({MegaSecs, Secs, _MicroSecs}) ->
    DateTime = calendar:now_to_datetime({MegaSecs, Secs, 0}),
    {{Year, Month, Day}, {Hour, Min, Sec}} = DateTime,
    io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
                 [Year, Month, Day, Hour, Min, Sec]).
