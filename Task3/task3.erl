%% File: task3.erl

-module(task1).
-export([start/0, feeder/2, conveyor/2, truck/1]).

start() ->
    TruckID = spawn(?MODULE, truck, ["Truck 0"]),
    ConveyorID = spawn(?MODULE, conveyor, ["Conveyor 0", TruckID]),
    spawn(?MODULE, feeder, ["Fedder 0", ConveyorID]).

feeder(Name, Conveyor) ->
    io:format("~p: Started generating packages.~n", [Name]),
    feederLoop(Name, Conveyor, 0).

feederLoop(Name, Conveyor, Counter) ->
    Package = {package, Counter, 1}, % Generate package.
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
    beltLoop(Name, Truck, []).

beltLoop(Name, Truck, List) ->
    receive
      {Fedder, {package, Counter, Size}} ->
        Truck ! {self(), {package, Counter, Size}},
        receive
        {pause} ->
            io:format("~p: Paused package generation.~n", [Name]),
            Fedder ! {pause},
            receive
            {resume} ->
                io:format("~p: Resumed package generation.~n", [Name]),
                Fedder ! {resume},
                beltLoop(Name, Truck, List)
            end
        after 1000 ->
            io:format("~p: Package unloaded.~n", [Name]),
            ok
        end
    end,
    beltLoop(Name, Truck, List).

truck(Name) ->
    TruckCapacity = 100,
    io:format("~p: Started.~n", [Name]),
    truckLoop(Name, TruckCapacity, []).

truckLoop(Name, Capacity, Load) ->
    receive
        {Belt, {package, Counter, Size}} ->
            Load ++ [{package, Counter, Size}]
            if Capacity - Size == 0 ->
                Belt ! {pause}
        after 1000 ->
            ok
    end,
    truckLoop(Name, Capacity, Load).