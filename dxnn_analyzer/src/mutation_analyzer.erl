-module(mutation_analyzer).
-export([
    display_mutations/2,
    parse_evo_hist/2,
    find_common_mutations/2
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Display mutation history for an agent
display_mutations(AgentId, Context) ->
    case agent_inspector:read_agent(AgentId, Context) of
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason]);
        {ok, Agent} ->
            io:format("~n=== Mutation History: ~p ===~n", [AgentId]),
            io:format("Generation: ~w~n", [Agent#agent.generation]),
            io:format("Total Mutations: ~w~n~n", [length(Agent#agent.evo_hist)]),
            
            lists:foreach(fun(M) ->
                io:format("  - ~s~n", [format_mutation(M)])
            end, Agent#agent.evo_hist),
            
            MutationTypes = count_mutation_types(Agent#agent.evo_hist),
            io:format("~nMutation Summary:~n"),
            maps:foreach(fun(Type, Count) ->
                io:format("  ~p: ~w~n", [Type, Count])
            end, MutationTypes),
            
            ok
    end.

%% @doc Parse evolution history into structured format
parse_evo_hist(AgentId, Context) ->
    case agent_inspector:read_agent(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        {ok, Agent} ->
            Events = lists:map(fun(Mutation) ->
                #mutation_event{
                    generation = Agent#agent.generation,
                    operator = element(1, Mutation),
                    details = Mutation,
                    fitness_before = undefined,
                    fitness_after = Agent#agent.fitness
                }
            end, Agent#agent.evo_hist),
            {ok, Events}
    end.

%% @doc Find mutations common across multiple agents
find_common_mutations(AgentIds, Context) ->
    Agents = lists:filtermap(fun(Id) ->
        case agent_inspector:read_agent(Id, Context) of
            {ok, Agent} -> {true, Agent};
            {error, _} -> false
        end
    end, AgentIds),
    
    case Agents of
        [] ->
            {error, no_agents_found};
        _ ->
            AllMutations = lists:flatten([A#agent.evo_hist || A <- Agents]),
            MutationTypes = [element(1, M) || M <- AllMutations],
            
            Counts = lists:foldl(fun(Type, Acc) ->
                maps:update_with(Type, fun(C) -> C + 1 end, 1, Acc)
            end, #{}, MutationTypes),
            
            Threshold = length(Agents) / 2,
            Common = maps:filter(fun(_, Count) -> Count >= Threshold end, Counts),
            
            {ok, Common}
    end.

%% Internal functions

format_mutation(Mutation) when is_tuple(Mutation) ->
    Type = element(1, Mutation),
    case Type of
        mutate_weights -> "Weight mutation";
        add_neuron -> "Added neuron";
        remove_neuron -> "Removed neuron";
        add_inlink -> "Added input link";
        add_outlink -> "Added output link";
        remove_inlink -> "Removed input link";
        remove_outlink -> "Removed output link";
        add_sensor -> "Added sensor";
        remove_sensor -> "Removed sensor";
        add_actuator -> "Added actuator";
        remove_actuator -> "Removed actuator";
        mutate_af -> "Changed activation function";
        add_bias -> "Added bias";
        remove_bias -> "Removed bias";
        mutate_plasticity_parameters -> "Modified plasticity parameters";
        _ -> io_lib:format("~p", [Mutation])
    end;
format_mutation(Mutation) ->
    io_lib:format("~p", [Mutation]).

count_mutation_types(EvoHist) ->
    lists:foldl(fun(Mutation, Acc) ->
        Type = element(1, Mutation),
        maps:update_with(Type, fun(C) -> C + 1 end, 1, Acc)
    end, #{}, EvoHist).
