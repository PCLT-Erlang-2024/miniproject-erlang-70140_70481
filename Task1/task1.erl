%% File: task1.erl

-module(task1).
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
    timer:sleep(500),
    Package = {package, Counter, 1}, % Generate package.
    io:format("~p: generated ~p~n", [Name, Package]),
    Conveyor ! {self(), Package},
    feederLoop(Name, Conveyor, Counter+1).

conveyor(Name, Truck) ->
    io:format("~p: Started.~n", [Name]),
    beltLoop(Name, Truck, []).

beltLoop(Name, Truck, []) ->
    timer:sleep(500),
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
    timer:sleep(500),
    receive
        {_, {package, Counter, Size}} ->
            io:format("~p: Package Loaded.~n", [Name]),
            NewCapacity = Capacity - Size,
            if 
                NewCapacity == 0 ->
                    io:format("~p: Full! Leaving...~n", [Name]),
                    io:format("~p: New truck arrived.~n", [Name]),
                    truckLoop(Name, 100, []);
                true ->
                    io:format("~p: Remaning capacity ~p.~n", [Name, NewCapacity]),
                    truckLoop(Name, NewCapacity, Load ++ [{package, Counter, Size}])
            end
        after 1000 ->
            truckLoop(Name, Capacity, Load)
    end.