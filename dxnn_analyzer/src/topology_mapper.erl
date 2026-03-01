-module(topology_mapper).
-export([
    build_digraph/2,
    display_topology/2,
    analyze_structure/2,
    export_to_dot/3
]).

-include("../include/records.hrl").
-include("../include/analyzer_records.hrl").

%% @doc Build a digraph representation of agent topology
build_digraph(AgentId, Context) ->
    case agent_inspector:get_full_topology(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        Topology ->
            G = digraph:new([cyclic]),
            
            Sensors = maps:get(sensors, Topology),
            Neurons = maps:get(neurons, Topology),
            Actuators = maps:get(actuators, Topology),
            
            lists:foreach(fun(S) ->
                digraph:add_vertex(G, S#sensor.id, {sensor, S})
            end, Sensors),
            
            lists:foreach(fun(N) ->
                digraph:add_vertex(G, N#neuron.id, {neuron, N})
            end, Neurons),
            
            lists:foreach(fun(A) ->
                digraph:add_vertex(G, A#actuator.id, {actuator, A})
            end, Actuators),
            
            lists:foreach(fun(Sensor) ->
                lists:foreach(fun(TargetId) ->
                    digraph:add_edge(G, Sensor#sensor.id, TargetId)
                end, Sensor#sensor.fanout_ids)
            end, Sensors),
            
            lists:foreach(fun(Neuron) ->
                lists:foreach(fun({InputId, _Weight}) ->
                    digraph:add_edge(G, InputId, Neuron#neuron.id)
                end, Neuron#neuron.input_idps),
                
                lists:foreach(fun(OutputId) ->
                    digraph:add_edge(G, Neuron#neuron.id, OutputId)
                end, Neuron#neuron.output_ids)
            end, Neurons),
            
            {ok, G}
    end.

%% @doc Display topology in human-readable format
display_topology(AgentId, Context) ->
    case agent_inspector:get_full_topology(AgentId, Context) of
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason]);
        Topology ->
            Agent = maps:get(agent, Topology),
            Sensors = maps:get(sensors, Topology),
            Neurons = maps:get(neurons, Topology),
            Actuators = maps:get(actuators, Topology),
            
            io:format("~n=== Agent Topology: ~p ===~n", [AgentId]),
            io:format("Encoding: ~p~n~n", [Agent#agent.encoding_type]),
            
            io:format("Sensors (~w):~n", [length(Sensors)]),
            lists:foreach(fun(S) ->
                io:format("  ~p: ~p (VL: ~w, Fanout: ~w)~n",
                         [S#sensor.id, S#sensor.name, S#sensor.vl, 
                          length(S#sensor.fanout_ids)])
            end, Sensors),
            
            io:format("~nNeurons (~w):~n", [length(Neurons)]),
            NeuronsByLayer = group_by_layer(Neurons),
            maps:foreach(fun(Layer, LayerNeurons) ->
                io:format("  Layer ~w: ~w neurons~n", [Layer, length(LayerNeurons)]),
                lists:foreach(fun(N) ->
                    io:format("    ~p: AF=~p, Inputs=~w, Outputs=~w~n",
                             [N#neuron.id, N#neuron.af, 
                              length(N#neuron.input_idps),
                              length(N#neuron.output_ids)])
                end, lists:sublist(LayerNeurons, 5))
            end, NeuronsByLayer),
            
            io:format("~nActuators (~w):~n", [length(Actuators)]),
            lists:foreach(fun(A) ->
                io:format("  ~p: ~p (VL: ~w, Fanin: ~w)~n",
                         [A#actuator.id, A#actuator.name, A#actuator.vl,
                          length(A#actuator.fanin_ids)])
            end, Actuators),
            
            case maps:get(substrate, Topology) of
                undefined ->
                    ok;
                Substrate ->
                    io:format("~nSubstrate:~n"),
                    io:format("  Dimensions: ~p~n", [Substrate#substrate.densities]),
                    io:format("  Plasticity: ~p~n", [Substrate#substrate.plasticity]),
                    io:format("  Linkform: ~p~n", [Substrate#substrate.linkform])
            end,
            
            ok
    end.

%% @doc Analyze structural properties
analyze_structure(AgentId, Context) ->
    case build_digraph(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        {ok, G} ->
            Vertices = digraph:vertices(G),
            Edges = digraph:edges(G),
            
            Components = digraph_utils:strong_components(G),
            Cycles = [C || C <- Components, length(C) > 1],
            
            Sources = [V || V <- Vertices, digraph:in_degree(G, V) == 0],
            Sinks = [V || V <- Vertices, digraph:out_degree(G, V) == 0],
            
            Analysis = #{
                vertex_count => length(Vertices),
                edge_count => length(Edges),
                source_count => length(Sources),
                sink_count => length(Sinks),
                cycle_count => length(Cycles),
                largest_cycle => case Cycles of
                    [] -> 0;
                    _ -> length(lists:max(Cycles))
                end,
                avg_degree => case length(Vertices) of
                    0 -> 0;
                    N -> length(Edges) / N
                end
            },
            
            digraph:delete(G),
            {ok, Analysis}
    end.

%% @doc Export topology to DOT format for Graphviz
export_to_dot(AgentId, Context, Filename) ->
    case build_digraph(AgentId, Context) of
        {error, Reason} ->
            {error, Reason};
        {ok, G} ->
            {ok, File} = file:open(Filename, [write]),
            
            io:format(File, "digraph agent_~p {~n", [AgentId]),
            io:format(File, "  rankdir=LR;~n", []),
            io:format(File, "  node [shape=circle];~n~n", []),
            
            lists:foreach(fun(V) ->
                {_, {Type, _Record}} = digraph:vertex(G, V),
                Color = case Type of
                    sensor -> "lightblue";
                    neuron -> "lightgreen";
                    actuator -> "lightcoral"
                end,
                io:format(File, "  \"~p\" [fillcolor=~s, style=filled];~n", 
                         [V, Color])
            end, digraph:vertices(G)),
            
            io:format(File, "~n", []),
            
            lists:foreach(fun(E) ->
                {_, V1, V2, _Label} = digraph:edge(G, E),
                io:format(File, "  \"~p\" -> \"~p\";~n", [V1, V2])
            end, digraph:edges(G)),
            
            io:format(File, "}~n", []),
            file:close(File),
            
            digraph:delete(G),
            io:format("Topology exported to ~s~n", [Filename]),
            ok
    end.

%% Internal functions

group_by_layer(Neurons) ->
    lists:foldl(fun(N, Acc) ->
        Layer = element(1, element(1, N#neuron.id)),
        maps:update_with(Layer, fun(List) -> [N | List] end, [N], Acc)
    end, #{}, Neurons).
