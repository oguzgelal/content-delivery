% Core functions

%%%%%%%%%%%% Check if a schedule valid %%%%%%%%%%%%

is_schedule_valid(schedule(VID, Day, Route), States, StatesNew, OrdersDelivered, OrdersDeliveredNew):- 
    % Get the current state of vehicle
    get_state(VID, States, state(VID, vargs(CurrentDepotID, _))),
    % Debug
    % write('\n *** Schedule start '), write('Vehicle:'), write(VID), write(' Day:'), write(Day), write(' *** \n\n'),
    % write('*Starting location for '), write(VID), write(' is '), write(CurrentDepotID), write('\n'),
    is_schedule_valid_acc(schedule(VID, Day, [CurrentDepotID|Route]), States, StatesNew, OrdersDelivered, OrdersDeliveredNew, [], CurrentDepotID).

is_schedule_valid_acc(schedule(_, _, []), States, States, OrdersDelivered, OrdersDelivered, _, _).

% For order:
is_schedule_valid_acc(schedule(VID, Day, [OID|RouteRest]), States, StatesNew, OrdersDelivered, OrdersDeliveredNew, OrdersDeliveredToday, LastVisitedDepot):-
    order(OID, _, _, _),
    % Order ID shouldnt be found in the Orders delivered list.
    % Violation of Hard-constraint 2 (order delivered twice)
    not(member(OID, OrdersDelivered)),
    % Get current state of the vehicle
    get_state(VID, States, state(VID, vargs(VehicleLocation, _))),
    % Set current load of vehicle to zero (initial of the day is -1)
    update_state(state(VID, vargs(VehicleLocation, 0)), States, StatesUpdated),
    !, is_schedule_valid_acc(schedule(VID, Day, RouteRest), StatesUpdated, StatesNew, [OID|OrdersDelivered], OrdersDeliveredNew, [OID|OrdersDeliveredToday], LastVisitedDepot).

% For depot:
is_schedule_valid_acc(schedule(VID, Day, [DID|RouteRest]), States, StatesNew, OrdersDelivered, OrdersDeliveredNew, OrdersDeliveredToday, LastVisitedDepot):-
    depot(DID, _, _),
    % Get current state of vehicle
    get_state(VID, States, state(VID, vargs(VehicleLocation, VehicleCurrentLoad))),
    % Secures Hard-constraint 4 (Vehicles are only allowed to visit a depot empty)
    not(VehicleCurrentLoad \= 0),
    % Get weights of orders onboard
    load(OrdersDeliveredToday, OrdersWeight),
    % Check if capacity of the vehicle was good for the carried orders
    % Secures Hard-constraint 6
    vehicle(VID, _, VehicleCapacity, _, _, _),
    % Debug
    % write('Vehicle '), write(VID), write(' has capacity '), write(VehicleCapacity), write(' and carried '), write(OrdersWeight), write(' of: \n'), list_print(OrdersDeliveredToday),
    not(OrdersWeight > VehicleCapacity),
    % Update current load 
    update_state(state(VID, vargs(VehicleLocation, 1)), States, StatesUpdated),
    % Check if orders in OrdersDeliveredToday list is good for depot LastVisitedDepot, and update its inventory.
    get_state(LastVisitedDepot, StatesUpdated, state(LastVisitedDepot, dargs(LastDepotInventory))),
    % Debug
    % write('-- V: '), write(VID), write(' Current Dpt: '), write(DID), write(' Prev Dpt: '), write(LastVisitedDepot), write(' Day: '), write(Day), write('-- \n'), write('From '), write(LastVisitedDepot), write(' we took out following orders: \n'), list_print(OrdersDeliveredToday), write(LastVisitedDepot), write(' inventory was: \n'), list_print(LastDepotInventory),
    update_inventory_bulk(LastDepotInventory, OrdersDeliveredToday, LastDepotNewInventory),
    update_state(state(LastVisitedDepot, dargs(LastDepotNewInventory)), StatesUpdated, StatesUpdatedFinal),
    % Debug
    % write(LastVisitedDepot), write(' inventory now is: \n'), list_print(LastDepotNewInventory), write('\n'),
    !, is_schedule_valid_acc(schedule(VID, Day, RouteRest), StatesUpdatedFinal, StatesNew, OrdersDelivered, OrdersDeliveredNew, [], DID).

%%%%%%%%%%%% Check if schedule time sufficient %%%%%%%%%%%%

is_schedule_time_valid(schedule(VID, Day, Route), States):- 
    % Get the current state of vehicle
    get_state(VID, States, state(VID, vargs(CurrentDepotID, _))),
    % Debug
    %write('Starting location for '), write(VID), write(' is '), write(CurrentDepotID), write('\n'),
    % Append current location of vehicle to the head of the route so that it starts calculating from there
    is_schedule_time_valid_acc(schedule(VID, Day, [CurrentDepotID|Route]), States, 0, 0).

% Current stop to next
is_schedule_time_valid_acc(schedule(VID, Day, [ID,IDNext|RouteRest]), States, OrderCount, TimeSpent):-
    driving_duration(VID, ID, IDNext, TimeSpentDriving),
    % Debug
    %write('Time spent between '), write(ID), write(' and '), write(IDNext), write(' is '), write(TimeSpentDriving), write('\n'),
    TimeSpentNew is (TimeSpent + TimeSpentDriving),
    update_order_count(ID, OrderCount, OrderCountNew),
    !, is_schedule_time_valid_acc(schedule(VID, Day, [IDNext|RouteRest]), States, OrderCountNew, TimeSpentNew).

% Last stop
is_schedule_time_valid_acc(schedule(VID, Day, [ID|[]]), States, OrderCount, TimeSpent):-
    update_order_count(ID, OrderCount, OrderCountNew),
    !, is_schedule_time_valid_acc(schedule(VID, Day, []), States, OrderCountNew, TimeSpent).

% Secures Hard-constraint 3
is_schedule_time_valid_acc(schedule(VID, Day, []), _, OrderCount, TimeSpent):-
    working_day(Day, DayStart, DayEnd),
    TotalTimeSpent is (TimeSpent + (10 * OrderCount)),
    TimeInDay is (DayEnd - DayStart),
    ignore(VID), 
    % Debug
    %write('Vehicle: '), write(VID), write('\n'), write('Day: '), write(Day), write('\n'), write('Total Time Spent: '), write(TotalTimeSpent), write('\n'), write('Time In Day: '), write(TimeInDay), write('\n'), write('\n'),
    not(TotalTimeSpent > TimeInDay).

%%%%%%%%%%%% Check if a plan valid %%%%%%%%%%%%

is_valid(P):-
    % Get cartesian product of vehicles and working days in [Vehicle_ID/Working_day] list
    findall(VID/WD, (vehicle(VID,_,_,_,_,_), working_day(WD,_,_)), VehiclesDays),
    is_plan_valid(P, [], VehiclesDays, []).

is_plan_valid(plan([schedule(VID, Day, Route)|SchedulesRest]), States, VehiclesDays, OrdersDelivered):-
    % Delete matching Vehicle/Day combination from Cartesian Product list
    delete(VehiclesDays, VID/Day, VehiclesDaysNew),
    % Vehicle/Day combination has to be deleted from the cartesian array. If not:
    %  a) It is already deleted => a vehicle assigned twice for the same day
    %  b) It is not found => assignment for a vehicle on a non-working day
    %  c) It is not found => assignment for an unknown vehicle 
    % Either way, violates Hard-constraint 1
    not(VehiclesDays==VehiclesDaysNew),
    % Make sure the schedule is valid (HC2)
    is_schedule_valid(schedule(VID, Day, Route), States, StatesUpdated, OrdersDelivered, OrdersDeliveredNew),
    % Make sure the vehicle has enough time in a day to complete the trip (HC3)
    is_schedule_time_valid(schedule(VID, Day, Route), StatesUpdated),
    % Update the state to the point after a schedule, and pass on the new state to the next recursion
    update_vehicle_state(schedule(VID, Day, Route), StatesUpdated, StatesNew),
    !, is_plan_valid(plan(SchedulesRest), StatesNew, VehiclesDaysNew, OrdersDeliveredNew).

is_plan_valid(plan([]), _, [], _). % Secures Hard-constraint 1

% Check to see if a plan is partially correct (ignore overall constraints)
is_partial_plan_valid(P):- is_partial_plan_valid(P, []).
is_partial_plan_valid(plan([Schedule|ScheduleRest]), States):-
    is_schedule_valid(Schedule, States, StatesUpdated, [], _),
    is_schedule_time_valid(Schedule, StatesUpdated),
    update_vehicle_state(Schedule, StatesUpdated, StatesNew),
    is_partial_plan_valid(plan(ScheduleRest), StatesNew).
is_partial_plan_valid(plan([]), _).


%%%%%%%%%%%% Calculate usage cost of a vehicle for a schedule %%%%%%%%%%%%
get_usage_cost(schedule(_, _, []), 0).
get_usage_cost(schedule(VID, _, _), VehicleUsageCost):- vehicle(VID, _, _, _, VehicleUsageCost, _).

%%%%%%%%%%%% Calculate travel profit from point A to point B %%%%%%%%%%%%
travel_profit(_, IDTo, _, 0):- depot(IDTo, _, _).
travel_profit(_, IDTo, Day, Profit):- order(IDTo, _, _, _), earning(IDTo, Day, Profit).

%%%%%%%%%%%% Calculate profit of a schedule %%%%%%%%%%%%
calculate_schedule_profit(schedule(VID, Day, Route), ScheduleProfit, States):- 
    get_state(VID, States, state(VID, vargs(CurrentDepotID, _))),
    % Debug
    % write('Starting point for '), write(VID), write(' is set to '), write(CurrentDepotID), write('\n'),
    calculate_schedule_profit(schedule(VID, Day, [CurrentDepotID|Route]), ScheduleProfit, States, 0.0).
calculate_schedule_profit(schedule(_, _, []), ScheduleProfit, _, ScheduleProfit).
calculate_schedule_profit(schedule(VID, Day, [_|[]]), ScheduleProfit, States, ScheduleProfitAcc):- calculate_schedule_profit(schedule(VID, Day, []), ScheduleProfit, States, ScheduleProfitAcc).
calculate_schedule_profit(schedule(VID, Day, [ID,IDNext|RouteRest]), ScheduleProfit, States, ScheduleProfitAcc):-
    vehicle(VID, _, _, _, _, VehicleKMCost),
    get_distance(ID, IDNext, DistanceKM),
    TravelCost is (VehicleKMCost * DistanceKM),
    travel_profit(ID, IDNext, Day, TravelEarnings),
    % Debug
    % write('-> Earnings from '), write(ID), write(' to '), write(IDNext), write(': '), write(TravelEarnings), write('\n'),
    ScheduleProfitNew is ((ScheduleProfitAcc + TravelEarnings) - TravelCost),
    calculate_schedule_profit(schedule(VID, Day, [IDNext|RouteRest]), ScheduleProfit, States, ScheduleProfitNew).

%%%%%%%%%%%% Calculate profit of a plan %%%%%%%%%%%%
calculate_profit(P, Profit, States):- calculate_profit(P, Profit, States, 0.0).
calculate_profit(plan([]), Profit, _, Profit).
calculate_profit(plan([schedule(VID, Day, Route)|SchedulesRest]), Profit, States, ProfitAcc):-
    calculate_schedule_profit(schedule(VID, Day, Route), ScheduleProfit, States),
    get_usage_cost(schedule(VID, Day, Route), VehicleUsageCost),
    ScheduleProfitTotal is (ProfitAcc + ScheduleProfit),
    ScheduleProfitNet is (ScheduleProfitTotal - VehicleUsageCost),
    % Debug
    % write('For the route '), list_print(Route), write('Profit: '), write(ScheduleProfit), write('\n'), write('Current profit: '), write(ProfitAcc), write('\n'), write('Subtotal profit: '), write(ScheduleProfitTotal), write('\n'), write('Vehicle usage cost: '), write(VehicleUsageCost), write('\n'), write('Schedule net profit: '), write(ScheduleProfitNet), write('\n\n'),
    update_vehicle_state(schedule(VID, Day, Route), States, StatesNew),
    calculate_profit(plan(SchedulesRest), Profit, StatesNew, ScheduleProfitNet).

%%%%%%%%%%%% Calculate profit %%%%%%%%%%%%
profit(P, Profit):- is_valid(P), calculate_profit(P, Profit, []).


%%%%%%%%%%%% Generate plan %%%%%%%%%%%%

% Find the most profitable (and possible) order (if any) taking all hard constraints into consideration
find_most_profitable_order(VID, Day, States, RouteSoFar, OrderStack, OrdersTried, MaxOrder, MaxOrderID):- find_most_profitable_order(VID, Day, States, RouteSoFar, OrderStack, OrdersTried, MaxOrder, MaxOrderID, -99999, -1).
find_most_profitable_order(VID, Day, States, RouteSoFar, [OID|OrderRest], OrdersTried, MaxOrder, MaxOrderID, MaxOrderAcc, MaxOrderIDAcc):-
    % Get the current location of the vehicle in question
    (
        % If route is not empty, vehicle is traveling and currently at a stop
        has_last(RouteSoFar, ID) ->
        % Set the vehicle location accordingly.
        LocationID = ID ;
        % If not, get where it currently is.
        get_state(VID, States, state(VID, vargs(LocationID, _)))
    ),
    % Get theKM cost of the vehicle in question
    vehicle(VID, _, _, _, _, VehicleKMCost),
    % Get the earning from delivering order in question
    earning(OID, Day, OrderEarning),
    % Get the cost of delivering order in question
    get_distance(LocationID, OID, DistanceKM),
    TravelCost is (VehicleKMCost * DistanceKM),
    % Calculate order profit
    OrderProfit is (OrderEarning - TravelCost),
    % Debug
    %write('Order : '), write(OID), writeln(''), write('Earning : '), write(OrderEarning), writeln(''), write('Cost : '), write(TravelCost), writeln(''), write('Profit : '), write(OrderProfit), writeln(''), writeln(''),
    append(RouteSoFar, [OID], RouteSoFarTest),
    (
        % If current orders profit is bigger and is valid
        MaxOrderAcc =< OrderProfit, is_partial_plan_valid(plan([schedule(VID, Day, RouteSoFarTest)])), not(member(OID, OrdersTried)) -> 
        % Set it as the best order
        NewMaxOrder = OrderProfit, NewMaxOrderID = OID ; 
        % If not, continue the recursion with current values
        NewMaxOrder = MaxOrderAcc, NewMaxOrderID = MaxOrderIDAcc
    ),
    find_most_profitable_order(VID, Day, States, RouteSoFar, OrderRest, OrdersTried, MaxOrder, MaxOrderID, NewMaxOrder, NewMaxOrderID).
find_most_profitable_order(_, _, _, _, [], _, MaxOrder, MaxOrderID, MaxOrder, MaxOrderID).

% Find the nearest depot (making the plan valid)
find_most_profitable_depot(VID, Day, RouteSoFar, DepotStack, MinDepot, MinDepotID):- find_most_profitable_depot(VID, Day, RouteSoFar, DepotStack, MinDepot, MinDepotID, 99999, -1).
find_most_profitable_depot(VID, Day, RouteSoFar, [DID|DepotStackRest], MinDepot, MinDepotID, MinDepotAcc, MinDepotIDAcc):-
    %write('Vehicle '), write(VID), write(' for day '), write(Day),
    % RouteSoFar cannot be empty (initial point would be a depot - cannot travel from depot to depot)
    last(RouteSoFar, LastID),
    % Get theKM cost of the vehicle in question
    vehicle(VID, _, _, _, _, VehicleKMCost),
    % Get the cost of delivering order in question
    get_distance(LastID, DID, DistanceKM),
    TravelCost is (VehicleKMCost * DistanceKM),
    % Simulate routesofar with depot appended to the end
    append(RouteSoFar, [DID], RouteSoFarTest),
    (
        % If travel cost smaller and is valid
        TravelCost =< MinDepotAcc, is_partial_plan_valid(plan([schedule(VID, Day, RouteSoFarTest)])) -> 
        % Set it as the best depot
        NewMinDepot = TravelCost, NewMinDepotID = DID ; 
        % If not, continue the recursion with current values
        NewMinDepot = MinDepotAcc, NewMinDepotID = MinDepotIDAcc
    ),
    find_most_profitable_depot(VID, Day, RouteSoFar, DepotStackRest, MinDepot, MinDepotID, NewMinDepot, NewMinDepotID).
find_most_profitable_depot(_, _, _, [], MinDepot, MinDepotID, MinDepot, MinDepotID).
    
% Only append depot if last item is an order
append_depot(RouteSoFar, ID, RouteSoFarNew):-
    last(RouteSoFar, LastID),
    order(LastID, _, _, _),
    append(RouteSoFar, [ID], RouteSoFarNew).
append_depot(RouteSoFar, _, RouteSoFar).

generate_schedule(Schedule, Schedule).
generate_schedule(VID, Day, OrderStack, DepotStack, States, Schedule):- generate_schedule(VID, Day, OrderStack, [], DepotStack, States, Schedule, _, []).
generate_schedule(VID, Day, OrderStack, OrdersTried, DepotStack, States, Schedule, _, RouteSoFar):-
    %write('Generating schedule... \n'),
    find_most_profitable_order(VID, Day, States, RouteSoFar, OrderStack, OrdersTried, _, MaxOrderID),
    (
        MaxOrderID == -1 ->
        % A valid best order cannot be found.
        %write('No best order found for route: '), write('\n'), list_print(RouteSoFar),
        % Check the last ID. If last item is a depot, couldn't add any order to it. We're done.
        last(RouteSoFar, LastItemID),
        (
            % Last item is an order. Has to be a depot.
            order(LastItemID, _, _, _) ->
            % Vehicle cannot reach any depot by the end of the day. Last destination has to be a depot.
            %write('Last added item is an order. Trying to find best possible depot.'), write('\n'),
            % Check for the best and valid depot (in case no order could be found due to stock insufficiency)
            find_most_profitable_depot(VID, Day, RouteSoFar, DepotStack, _, MinDepotID),
            (
                MinDepotID == -1 ->
                % Remove it from the route and add it back to order stack.
                delete(RouteSoFar, LastItemID, RouteSoFarNew),
                append(OrderStack, [LastItemID], OrderStackUpdated),
                append(OrdersTried, [LastItemID], OrdersTriedNew),
                %write('No depot possible found. Removing last order: '), write('\n'), list_print(RouteSoFarNew),
                % Call recursion with old order stack (so that it won't find the same order next recursion)
                generate_schedule(VID, Day, OrderStackUpdated, OrdersTriedNew, DepotStack, States, Schedule, _, RouteSoFarNew);
                % Best depot found. Append the best depot found to route and call recursion.
                append_depot(RouteSoFar, MinDepotID, RouteSoFarNew),
                %write('Best depot found. Added to route: '), write('\n'), list_print(RouteSoFarNew),
                generate_schedule(VID, Day, OrderStack, [], DepotStack, States, Schedule, _, RouteSoFarNew)
            );
            %writeln('Last added item is a depot (or empty). Route completed for today.'),
            generate_schedule(Schedule, schedule(VID, Day, RouteSoFar))
        );
        % Best and valid order found. Delete it from the order stack and append it to routesofar.
        % Delete it from the order stack
        delete(OrderStack, MaxOrderID, OrderStackUpdated),
        % Append it to the end of routesofar
        append(RouteSoFar, [MaxOrderID], RouteSoFarNew),
        %write('Best order found: '), write(MaxOrderID), write(' -> Adding it to routesofar: \n'), list_print(RouteSoFarNew),
        % Call recursion with the new values
        generate_schedule(VID, Day, OrderStackUpdated, OrdersTried, DepotStack, States, Schedule, _, RouteSoFarNew)
    ).

heuristically_generate_plan(Plan):- heuristically_generate_plan(Plan, plan([]), []).
heuristically_generate_plan(Plan, PlanAcc, States):-
    % Get cartesian product of vehicles / working days
    findall(VID/WD, (vehicle(VID,_,_,_,_,_), working_day(WD,_,_)), VehiclesDaysStack),
    % Get the order stack
    findall(OID, (order(OID, _, _, _)), OrderStack),
    % Get the depot stack
    findall(DID, (depot(DID, _, _)), DepotStack),
    % Initiate the procedure
    heuristically_generate_plan(Plan, PlanAcc, States, VehiclesDaysStack, OrderStack, DepotStack).

% Generate schedules on each step until all orders distributed
heuristically_generate_plan(Plan, plan(Routes), States, [VID/Day|VehiclesDaysRest], OrderStack, DepotStack):-
    %write('***** Generating route for '), write(VID), write(' on day '), write(Day), write(' *****\n'),write('Using order stack: '),list_print(OrderStack),
    generate_schedule(VID, Day, OrderStack, DepotStack, States, schedule(VID, Day, GeneratedRoute)),
    % write('Generated route : \n'),list_print(GeneratedRoute),
    % Update vehicle state
    update_vehicle_state(schedule(VID, Day, GeneratedRoute), States, StatesUpdated),
    % Update depot states
    update_depot_state(schedule(VID, Day, GeneratedRoute), StatesUpdated, StatesNew),
    % Update order stack
    subtract(OrderStack, GeneratedRoute, OrderStackNew),
    % Append schedule to plan & Recurse
    heuristically_generate_plan(Plan, plan([schedule(VID, Day, GeneratedRoute)|Routes]), StatesNew, VehiclesDaysRest, OrderStackNew, DepotStack).

% When all orders are distributed, assign the rest of vehicle / days an empty schedule
heuristically_generate_plan(Plan, plan(Routes), States, [VID/Day|VehiclesDaysRest], [], DepotStack):-
    heuristically_generate_plan(Plan, plan([schedule(VID, Day, [])|Routes]), States, VehiclesDaysRest, [], DepotStack).

% Orders are done and all vehicle / days assigned, we got a plan.
%heuristically_generate_plan(Plan, Plan, _, [], _, _).
heuristically_generate_plan(Plan, Plan, _, [], _, _):-
    profit(Plan, Profit),
    write('Profit: '), write(Profit), write('\n\n'),
    pretty_print(Plan).


find_heuristically(P):- heuristically_generate_plan(P).

% find_optimal(-P).


pretty_print(P):- findall(WD, working_day(WD,_,_), WorkingDays), pretty_print(P, WorkingDays, []).
pretty_print(P, [WD|Rest], States):- print_day(P, WD, States, StatesNew), pretty_print(P, Rest, StatesNew).
pretty_print(_, [], _).

print_day(P, WD, States, StatesNew):- print_day(P, WD, States, StatesNew, 0).
print_day(plan([]), _, States, States, _).
print_day(plan([schedule(VID, Day, Route)|Rest]), WD, States, StatesNew, IsDayTitlePrinted):-
    (
        Day == WD ->
        (IsDayTitlePrinted == 0 -> write('\n\n\n *** Schedule for day '), write(Day), write(' *** \n'); true),
        print_schedule(schedule(VID, Day, Route), States, StatesUpdated),
        print_day(plan(Rest), WD, StatesUpdated, StatesNew, 1);
        print_day(plan(Rest), WD, States, StatesNew, IsDayTitlePrinted)
    ).

print_schedule_row(Cols):- format('~s~t~10+ ~s~t~12+ ~s~t~12+ ~s~t~50+ ~n', Cols).
print_schedule(schedule(VID, Day, Route), States, StatesNew):-
    get_state(VID, States, state(VID, vargs(CurrentDepotID, _))),
    write('\n\n'),
    write('< Vehicle '), write(VID), write(' > \n\n'),
    print_schedule_row(['Time', 'Loc.', 'Load', 'Action']),
    print_schedule_table(schedule(VID, Day, Route), States, StatesNew, CurrentDepotID).

print_schedule_table(Schedule, States, StatesNew, LastVisitedDepot):- print_schedule_table(Schedule, States, StatesNew, LastVisitedDepot, 0, []).
print_schedule_table(schedule(_, Day, []), States, States, _, TimePassed, _):-
    get_state(VID, States, state(VID, vargs(CurrentLocationID, CurrentLoad))),
    depot(CurrentLocationID, _, DepotLocation),
    format(atom(ActionText), 'Park at depot ~w.', [CurrentLocationID]),
    time_tostr(Day, TimePassed, TimeStr),
    location_tostr(DepotLocation, LocationStr),
    load_tostr(CurrentLoad, LoadStr),
    print_schedule_row([TimeStr, LocationStr, LoadStr, ActionText]).

print_schedule_table(schedule(VID, Day, [ID|Rest]), States, StatesNew, LastVisitedDepot, TimePassed, OrdersOnBoard):-
    order(ID, _, OrderLocation, _),
    get_state(VID, States, state(VID, vargs(_, CurrentLoad))),
    % Print current step
    format(atom(ActionText), 'Pick up order ~w from depot ~w', [ID, LastVisitedDepot]),
    time_tostr(Day, TimePassed, TimeStr),
    location_tostr(OrderLocation, LocationStr),
    load_tostr(CurrentLoad, LoadStr),
    print_schedule_row([TimeStr, LocationStr, LoadStr, ActionText]),
    % Calculate time spent to pick up order
    TimePassedNew is TimePassed + 5,
    % Update the load of vehicle after picking up the order
    order_weight(ID, OrderWeight),
    NewLoad is CurrentLoad + OrderWeight,
    update_state(state(VID, vargs(ID, NewLoad)), States, StatesUpdated),
    print_schedule_table(schedule(VID, Day, Rest), StatesUpdated, StatesNew, LastVisitedDepot, TimePassedNew, [ID|OrdersOnBoard]).

print_schedule_table(schedule(VID, Day, [ID|Rest]), States, StatesNew, _, TimePassed, OrdersOnBoard):-
    depot(ID, _, DepotLocation),
    get_state(VID, States, state(VID, vargs(CurrentLocationID, CurrentLoad))),
    get_location(CurrentLocationID, CurrentLocation),
    distance(CurrentLocation, DepotLocation, DistanceDriven),
    duration(VID, CurrentLocation, DepotLocation, DurationDriven),
    distance_tostr(DistanceDriven, DistanceDrivenStr),
    % Print current step
    location_description_tostr(DepotLocation, DescStr),
    format(atom(ActionText), 'Drive ~w to depot ~w ~w', [DistanceDrivenStr, ID, DescStr]),
    time_tostr(Day, TimePassed, TimeStr),
    location_tostr(CurrentLocation, LocationStr),
    load_tostr(CurrentLoad, LoadStr),
    print_schedule_row([TimeStr, LocationStr, LoadStr, ActionText]),
    % Calculate time passed after driving
    TimePassedUpdated is TimePassed + DurationDriven,
    % Print deliver orders and get new time & load 
    % ps. No need to update state here, load will be zero when all orders are delivered
    print_deliver_orders(VID, Day, DepotLocation, OrdersOnBoard, States, TimePassedUpdated, TimePassedNew),
    % Update the state of vehicle - set it to zero
    update_state(state(VID, vargs(ID, 0)), States, StatesUpdated),
    print_schedule_table(schedule(VID, Day, Rest), StatesUpdated, StatesNew, ID, TimePassedNew, []).

print_deliver_orders(_, _, _, [], _, TimePassed, TimePassed).
print_deliver_orders(VID, Day, DepotLocation, [OID|OrdersRest], States, TimePassed, TimePassedNew):-
    get_state(VID, States, state(VID, vargs(CurrentLocation, CurrentLoad))),
    % Print current state
    format(atom(ActionText), 'Deliver order ~w', [OID]),
    time_tostr(Day, TimePassed, TimeStr),
    location_tostr(DepotLocation, LocationStr),
    load_tostr(CurrentLoad, LoadStr),
    print_schedule_row([TimeStr, LocationStr, LoadStr, ActionText]),
    % Update passed time to unload order
    TimePassedUpdated is TimePassed + 5,
    % Get the order weight and calculate the new load
    order_weight(OID, OrderWeight),
    NewLoad is CurrentLoad - OrderWeight,
    % Update state of the vehicle
    update_state(state(VID, vargs(CurrentLocation, NewLoad)), States, StatesUpdated),
    print_deliver_orders(VID, Day, DepotLocation, OrdersRest, StatesUpdated, TimePassedUpdated, TimePassedNew).


time_tostr(Day, Time, Out):- 
    working_day(Day, DayStart, _),
    TimeTotal is DayStart + Time,
    TimeTotalInt is round(TimeTotal),
    Minute is TimeTotalInt mod 60,
    Hour is (TimeTotalInt - Minute) / 60,
    (
        Minute > 9 ->
        format(atom(MinuteStr),'~w', [Minute]);
        format(atom(MinuteStr),'0~w', [Minute])
    ),
    format(atom(Out),'~w:~w', [Hour, MinuteStr]).
location_tostr(location(L1, L2), Out):- format(atom(Out),'(~w,~w)', [L1, L2]).
location_description_tostr(location(L1, L2), Out):-
    get_ordinal_suffix(L1, S1),
    get_ordinal_suffix(L2, S2),
    format(atom(Out),'on the intersectoin of ~w~w avenue and ~w~w street', [L1, S1, L2, S2]).
load_tostr(Load, Out):- format(atom(Out),'~1fkg', [Load]).
distance_tostr(Distance, Out):- format(atom(Out),'~1fkm', [Distance]).