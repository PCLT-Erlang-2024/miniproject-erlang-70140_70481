%% File: task1.erl

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
    feederLoop(Name, Conveyor, Counter+1).

conveyor(Name, Truck) ->
    io:format("~p: Started.~n", [Name]),
    beltLoop(Name, Truck, []).

beltLoop(Name, Truck, []) ->
    receive
        {_, {package, Counter, Size}} ->
            Truck ! {self(), {package, Counter, Size}},
            io:format("~p: Package unloaded.~n", [Name])
        after 1000 ->
            ok
    end,
    beltLoop(Name, Truck, []).

truck(Name) ->
    TruckCapacity = 100,
    io:format("~p: Started.~n", [Name]),
    truckLoop(Name, TruckCapacity, []).

truckLoop(Name, Capacity, Load) ->
    receive
        {_, {package, Counter, Size}} ->
            io:format("~p: Package Loaded.~n", [Name]),
            if 
                Capacity - Size == 0 ->
                    io:format("~p: Leaving.~n", [Name]),
                    io:format("~p: New truck arrived.~n", [Name]),
                    truckLoop(Name, 100, []);
                true ->
                    truckLoop(Name, Capacity - Size, Load ++ [{package, Counter, Size}])
            end
        after 1000 ->
            truckLoop(Name, Capacity, Load)
    end.