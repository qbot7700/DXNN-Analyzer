#!/usr/bin/env escript
%% Verification script to check Master Database contents

-module(verify_master_db).
-export([main/1]).

-include("include/records.hrl").

main([MasterPath]) ->
    io:format("~n=== Verifying Master Database ===~n"),
    io:format("Path: ~s~n~n", [MasterPath]),
    
    Tables = [agent, cortex, neuron, sensor, actuator, substrate],
    
    lists:foreach(fun(Table) ->
        DetsFile = filename:join(MasterPath, atom_to_list(Table) ++ ".dets"),
        case filelib:is_file(DetsFile) of
            true ->
                {ok, _} = dets:open_file(Table, [{file, DetsFile}, {type, set}]),
                Count = dets:info(Table, size),
                io:format("Table ~p: ~w records~n", [Table, Count]),
                
                % Show sample records
                case Table of
                    agent ->
                        dets:traverse(Table, fun(Agent) ->
                            io:format("  Agent ID: ~p~n", [Agent#agent.id]),
                            io:format("    Cortex ID: ~p~n", [Agent#agent.cx_id]),
                            io:format("    Fitness: ~.6f~n", [Agent#agent.fitness]),
                            io:format("    Generation: ~p~n~n", [Agent#agent.generation]),
                            continue
                        end);
                    cortex ->
                        dets:traverse(Table, fun(Cortex) ->
                            io:format("  Cortex ID: ~p~n", [Cortex#cortex.id]),
                            io:format("    Neurons: ~w~n", [length(Cortex#cortex.neuron_ids)]),
                            io:format("    Sensors: ~w~n", [length(Cortex#cortex.sensor_ids)]),
                            io:format("    Actuators: ~w~n~n", [length(Cortex#cortex.actuator_ids)]),
                            continue
                        end);
                    _ -> ok
                end,
                
                dets:close(Table);
            false ->
                io:format("Table ~p: NOT FOUND~n", [Table])
        end
    end, Tables),
    
    io:format("~n=== Verification Complete ===~n");

main(_) ->
    io:format("Usage: ./verify_master_db.erl <master_database_path>~n"),
    io:format("Example: ./verify_master_db.erl ./data/MasterDatabase~n").
