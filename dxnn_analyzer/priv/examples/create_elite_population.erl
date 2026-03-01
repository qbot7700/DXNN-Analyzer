#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa _build/default/lib/*/ebin

%% Example: Create elite population from best agents

main([MnesiaPath, OutputPath, NumAgents]) ->
    io:format("DXNN Analyzer - Create Elite Population~n~n"),
    
    N = list_to_integer(NumAgents),
    
    %% Start analyzer
    analyzer:start(),
    
    %% Load source population
    io:format("Loading source population: ~s~n", [MnesiaPath]),
    case analyzer:load(MnesiaPath, source) of
        {ok, _Context} ->
            %% Find best agents
            io:format("Finding top ~w agents...~n", [N]),
            BestAgents = analyzer:find_best(N, [{context, source}]),
            
            case BestAgents of
                [] ->
                    io:format("No agents found~n"),
                    halt(1);
                _ ->
                    AgentIds = [A#agent.id || A <- BestAgents],
                    
                    %% Show selected agents
                    io:format("~nSelected agents:~n"),
                    lists:foreach(fun(Agent) ->
                        io:format("  ~p: Fitness=~.6f, Gen=~w~n",
                                 [Agent#agent.id, Agent#agent.fitness, 
                                  Agent#agent.generation])
                    end, BestAgents),
                    
                    %% Create new population
                    io:format("~nCreating elite population...~n"),
                    case analyzer:create_population(AgentIds, elite_traders, 
                                                   OutputPath, [{context, source}]) of
                        {ok, NewPath} ->
                            io:format("~nSuccess! Elite population created at:~n"),
                            io:format("  ~s~n", [NewPath]),
                            
                            %% Generate report
                            ReportFile = filename:join(OutputPath, "elite_report.txt"),
                            analyzer:export_report(BestAgents, ReportFile),
                            io:format("  Report: ~s~n", [ReportFile]);
                        {error, Reason} ->
                            io:format("Error creating population: ~p~n", [Reason]),
                            halt(1)
                    end
            end,
            
            analyzer:stop();
        {error, Reason} ->
            io:format("Error loading Mnesia folder: ~p~n", [Reason]),
            halt(1)
    end;

main(_) ->
    io:format("Usage: create_elite_population.erl <source_mnesia_path> <output_path> <num_agents>~n"),
    io:format("Example: create_elite_population.erl ./Mnesia.nonode@nohost ./elite_output 10~n"),
    halt(1).
