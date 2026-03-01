#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa _build/default/lib/*/ebin

%% Basic usage example for DXNN Analyzer

main([MnesiaPath]) ->
    io:format("DXNN Analyzer - Basic Usage Example~n~n"),
    
    %% Start analyzer
    io:format("Starting analyzer...~n"),
    analyzer:start(),
    
    %% Load Mnesia folder
    io:format("Loading Mnesia folder: ~s~n", [MnesiaPath]),
    case analyzer:load(MnesiaPath, experiment1) of
        {ok, Context} ->
            io:format("Loaded successfully!~n"),
            io:format("  Agents: ~w~n", [Context#mnesia_context.agent_count]),
            io:format("  Species: ~w~n~n", [Context#mnesia_context.specie_count]),
            
            %% Find best agents
            io:format("Finding top 5 agents...~n"),
            BestAgents = analyzer:find_best(5, [{context, experiment1}]),
            
            %% Inspect first agent
            case BestAgents of
                [] ->
                    io:format("No agents found~n");
                [FirstAgent|_] ->
                    io:format("~nInspecting best agent...~n"),
                    analyzer:inspect(FirstAgent#agent.id, experiment1),
                    
                    io:format("~nShowing topology...~n"),
                    analyzer:show_topology(FirstAgent#agent.id, experiment1),
                    
                    io:format("~nGenerating summary...~n"),
                    stats_collector:generate_summary(experiment1)
            end,
            
            %% Cleanup
            analyzer:stop(),
            io:format("~nDone!~n");
        {error, Reason} ->
            io:format("Error loading Mnesia folder: ~p~n", [Reason]),
            halt(1)
    end;

main(_) ->
    io:format("Usage: basic_usage.erl <mnesia_path>~n"),
    io:format("Example: basic_usage.erl ../DXNN-Trader-V2/DXNN-Trader-v2/Mnesia.nonode@nohost~n"),
    halt(1).
