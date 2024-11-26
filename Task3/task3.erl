%% File: task3.erl

-module(task3).
-export([start/0, feeder/2, conveyor/2, truck/1]).

start() ->
    % Set 1
    Truck0ID = spawn(?MODULE, truck, ["Truck 0"]),
    Conveyor0ID = spawn(?MODULE, conveyor, ["Conveyor 0", Truck0ID]),
    spawn(?MODULE, feeder, ["Fedder 0", Conveyor0ID]),
    % Set 2
    Truck1ID = spawn(?MODULE, truck, ["Truck 1"]),
    Conveyor1ID = spawn(?MODULE, conveyor, ["Conveyor 1", Truck1ID]),
    spawn(?MODULE, feeder, ["Fedder 1", Conveyor1ID]),
    % Set 3
    Truck2ID = spawn(?MODULE, truck, ["Truck 2"]),
    Conveyor2ID = spawn(?MODULE, conveyor, ["Conveyor 2", Truck2ID]),
    spawn(?MODULE, feeder, ["Fedder 2", Conveyor2ID]).

feeder(Name, Conveyor) -> % Starts the loop which generates packages
    io:format("~p: Started generating packages.~n", [Name]),
    feederLoop(Name, Conveyor, 0).

feederLoop(Name, Conveyor, Counter) -> % Generates packages and sends them to the Conveyor belt
    Package = {package, Counter, rand:uniform(10)}, % Generate package.
    io:format("~p: generated ~p~n", [Name, Package]), 
    Conveyor ! {self(), Package}, % Sends package
    receive
        {pause} -> % If it receives a message to stop it will wait till it is told to resume
            io:format("~p: Paused package generation.~n", [Name]),
            receive
            {resume} -> % Resumes once told to do so
                io:format("~p: Resumed package generation.~n", [Name]),
                ok
            end
        after 1000 ->
            io:format("~p: Package unloaded.~n", [Name]),
            ok
    end,
    feederLoop(Name, Conveyor, Counter+1). % Updates counter and loops

conveyor(Name, Truck) -> % Starts the the conveyor loop which listens for packages and sends them to the truck
    io:format("~p: Started.~n", [Name]),
    beltLoop(Name, Truck).

beltLoop(Name, Truck) -> % Conveyor belt loop
    receive
        {Fedder, {package, Counter, Size}} -> % Listens for a new package
            Truck ! {self(), {package, Counter, Size}}, % Sends package to truck
            io:format("~p: Package unloaded.~n", [Name]),
            receive
            {pause} -> % If it receives a message to stop it will wait till it is told to resume
                io:format("~p: Paused package generation.~n", [Name]),
                Fedder ! {pause}, % Asks feeder to stop sending packages
                receive
                {resume} -> % Resumes once told to do so
                    io:format("~p: Resumed package generation.~n", [Name]),
                    Fedder ! {resume} % Tells feeder it can resume sending packages
                end
            after 1000 -> % If it doesn't receive a package just resets so there is no deadlock
                io:format("~p: Package unloaded.~n", [Name]),
                ok
            end
        after 1000 ->
            ok
    end,
    beltLoop(Name, Truck). % Loops

truck(Name) -> % Starts truck loop which receives packages and adds them to its load till it is full
    TruckCapacity = 100, % Max sum of package size the truck can handle
    io:format("~p: Started.~n", [Name]),
    truckLoop(Name, TruckCapacity, []).

truckLoop(Name, Capacity, Load) when Capacity < 0 -> % If New capacity after package is added overbooks the truck it resets holding the new package till a new truck arrives
    {Belt, {package, Counter, Size}} = lists:last(Load), % Removes overbooked package and uses PID Store to send message to Belt
    io:format("~p: Full! Leaving...~n", [Name]),
    Belt ! {pause}, % Asks belt to stop sending packages
    timer:sleep(rand:uniform(500)),
    io:format("~p: New truck arrived.~n", [Name]),
    Belt ! {resume}, % Tells belt it can resume sending packages
    truckLoop(Name, 100-Size, [{Belt, {package, Counter, Size}}]); % Recalls Loop

truckLoop(Name, Capacity, Load) -> % Truck Loop
    receive
        {Belt, {package, Counter, Size}} -> % Receives a package
            io:format("~p: Package Loaded.~n", [Name]),
            NewCapacity = Capacity - Size, % New capacity after package is added
            io:format("~p: Remaning capacity ~p.~n", [Name, NewCapacity]),
            truckLoop(Name, NewCapacity, Load ++ [{Belt, {package, Counter, Size}}]) % Updates capacity and adds package to Load.
        after 1500 -> % In case no packge is receive so it doesn't deadlock
            truckLoop(Name, Capacity, Load) % Just loops
    end.