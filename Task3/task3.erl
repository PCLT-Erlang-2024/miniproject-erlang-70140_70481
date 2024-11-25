%% File: task3.erl

-module(task3).
-export([start/0, feeder/2, conveyor/2, truck/1]).

start() ->
    Truck0ID = spawn(?MODULE, truck, ["Truck 0"]),
    Conveyor0ID = spawn(?MODULE, conveyor, ["Conveyor 0", Truck0ID]),
    spawn(?MODULE, feeder, ["Fedder 0", Conveyor0ID]),
    Truck1ID = spawn(?MODULE, truck, ["Truck 1"]),
    Conveyor1ID = spawn(?MODULE, conveyor, ["Conveyor 1", Truck1ID]),
    spawn(?MODULE, feeder, ["Fedder 1", Conveyor1ID]),
    Truck2ID = spawn(?MODULE, truck, ["Truck 2"]),
    Conveyor2ID = spawn(?MODULE, conveyor, ["Conveyor 2", Truck2ID]),
    spawn(?MODULE, feeder, ["Fedder 2", Conveyor2ID]).

feeder(Name, Conveyor) ->
    io:format("~p: Started generating packages.~n", [Name]),
    feederLoop(Name, Conveyor, 0).

feederLoop(Name, Conveyor, Counter) ->
    Package = {package, Counter, rand:uniform(10)}, % Generate package.
    io:format("~p: generated ~p~n", [Name, Package]),
    Conveyor ! {self(), Package},
    receive
        {pause} ->
            io:format("~p: Paused package generation.~n", [Name]),
            receive
            {resume} ->
                io:format("~p: Resumed package generation.~n", [Name]),
                feederLoop(Name, Conveyor, Counter)
            end
        after 1000 ->
            io:format("~p: Package unloaded.~n", [Name]),
            ok
    end,
    feederLoop(Name, Conveyor, Counter+1).

conveyor(Name, Truck) ->
    io:format("~p: Started.~n", [Name]),
    beltLoop(Name, Truck).

beltLoop(Name, Truck) ->
    receive
        {Fedder, {package, Counter, Size}} ->
            Truck ! {self(), {package, Counter, Size}},
            io:format("~p: Package unloaded.~n", [Name]),
            receive
            {pause} ->
                io:format("~p: Paused package generation.~n", [Name]),
                Fedder ! {pause},
                receive
                {resume} ->
                    io:format("~p: Resumed package generation.~n", [Name]),
                    Fedder ! {resume}
                end
            after 1000 ->
                io:format("~p: Package unloaded.~n", [Name]),
                ok
            end
        after 1000 ->
            ok
    end,
    beltLoop(Name, Truck).

truck(Name) ->
    TruckCapacity = 100,
    io:format("~p: Started.~n", [Name]),
    truckLoop(Name, TruckCapacity, []).

truckLoop(Name, Capacity, Load) ->
    receive
        {Belt, {package, Counter, Size}} ->
            io:format("~p: Package Loaded.~n", [Name]),
            NewCapacity = Capacity - Size,
            if 
                NewCapacity < 0 ->
                    io:format("~p: Full! Leaving...~n", [Name]),
                    Belt ! {pause},
                    timer:sleep(rand:uniform(500)),
                    io:format("~p: New truck arrived.~n", [Name]),
                    Belt ! {resume},
                    truckLoop(Name, 100-Size, [Size]);
                true ->
                    io:format("~p: Remaning capacity ~p.~n", [Name, NewCapacity]),
                    truckLoop(Name, NewCapacity, Load ++ [{package, Counter, Size}])
            end
        after 1500 ->
            truckLoop(Name, Capacity, Load)
    end.