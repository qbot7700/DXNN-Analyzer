#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa _build/default/lib/*/ebin

%% Example: Compare agents from multiple experiments

main([Path1, Path2]) ->
    io:format("DXNN Analyzer - Compare Experiments~n~n"),
    
    %% Start analyzer
    analyzer:start(),
    
    %% Load both experiments
    io:format("Loading experiment 1: ~s~n", [Path1]),
    case analyzer:load(Path1, exp1) of
        {ok, _} ->
            io:format("Loading experiment 2: ~s~n", [Path2]),
            case analyzer:load(Path2, exp2) of
                {ok, _} ->
                    %% Show contexts
                    io:format("~n"),
                    analyzer:list_contexts(),
                    
                    %% Get best from each
                    io:format("~nFinding best agents from each experiment...~n"),
                    Best1 = analyzer:find_best(3, [{context, exp1}]),
                    Best2 = analyzer:find_best(3, [{context, exp2}]),
                    
                    %% Compare within exp1
                    io:format("~n=== Comparing Experiment 1 Agents ===~n"),
                    Ids1 = [A#agent.id || A <- Best1],
                    analyzer:compare(Ids1, exp1),
                    
                    %% Compare within exp2
                    io:format("~n=== Comparing Experiment 2 Agents ===~n"),
                    Ids2 = [A#agent.id || A <- Best2],
                    analyzer:compare(Ids2, exp2),
                    
                    %% Generate summaries
                    io:format("~n=== Experiment 1 Summary ===~n"),
                    stats_collector:generate_summary(exp1),
                    
                    io:format("~n=== Experiment 2 Summary ===~n"),
                    stats_collector:generate_summary(exp2),
                    
                    analyzer:stop();
                {error, Reason} ->
                    io:format("Error loading experiment 2: ~p~n", [Reason]),
                    halt(1)
            end;
        {error, Reason} ->
            io:format("Error loading experiment 1: ~p~n", [Reason]),
            halt(1)
    end;

main(_) ->
    io:format("Usage: compare_experiments.erl <mnesia_path1> <mnesia_path2>~n"),
    io:format("Example: compare_experiments.erl ./exp1/Mnesia.nonode@nohost ./exp2/Mnesia.nonode@nohost~n"),
    halt(1).
