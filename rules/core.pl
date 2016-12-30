%%%%%%%%%%%%%%%%%% Core functions %%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% Check if a schedule valid %%%%%%%%%%%%

is_schedule_valid(schedule(VID, Day, Route), States, StatesNew, OrdersDelivered, OrdersDeliveredNew):- 
    % Get the current state of vehicle
    get_state(VID, States, state(VID, vargs(CurrentDepotID, _))),
    % Debug
    % write('\n *** Schedule start '), write('Vehicle:'), write(VID), write(' Day:'), write(Day), write(' *** \n\n'),
    % write('*Starting location for '), write(VID), write(' is '), write(CurrentDepotID), write('\n'),
    !, is_schedule_valid_acc(schedule(VID, Day, [CurrentDepotID|Route]), States, StatesNew, OrdersDelivered, OrdersDeliveredNew, [], CurrentDepotID).

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
    !, update_inventory_bulk(LastDepotInventory, OrdersDeliveredToday, LastDepotNewInventory),
    update_state(state(LastVisitedDepot, dargs(LastDepotNewInventory)), StatesUpdated, StatesUpdatedFinal),
    % Debug
    % write(LastVisitedDepot), write(' inventory now is: \n'), list_print(LastDepotNewInventory), write('\n'),
    !, is_schedule_valid_acc(schedule(VID, Day, RouteRest), StatesUpdatedFinal, StatesNew, OrdersDelivered, OrdersDeliveredNew, [], DID).

%%%%%%%%%%%% Check if schedule time sufficient %%%%%%%%%%%%

is_schedule_time_valid(schedule(VID, Day, Route), States):- 
    % Get the current state of vehicle
    get_state(VID, States, state(VID, vargs(CurrentDepotID, _))),
    % Debug
    % write('Starting location for '), write(VID), write(' is '), write(CurrentDepotID), write('\n'),
    % Append current location of vehicle to the head of the route so that it starts calculating from there
    !, is_schedule_time_valid_acc(schedule(VID, Day, [CurrentDepotID|Route]), States, 0, 0).

% Current stop to next
is_schedule_time_valid_acc(schedule(VID, Day, [ID,IDNext|RouteRest]), States, OrderCount, TimeSpent):-
    driving_duration(VID, ID, IDNext, TimeSpentDriving),
    % Debug
    % write('Time spent between '), write(ID), write(' and '), write(IDNext), write(' is '), write(TimeSpentDriving), write('\n'),
    TimeSpentNew is (TimeSpent + TimeSpentDriving),
    update_order_count(ID, OrderCount, OrderCountNew),
    !, is_schedule_time_valid_acc(schedule(VID, Day, [IDNext|RouteRest]), States, OrderCountNew, TimeSpentNew).

% Last stop
is_schedule_time_valid_acc(schedule(VID, Day, [ID|[]]), States, OrderCount, TimeSpent):-
    update_order_count(ID, OrderCount, OrderCountNew),
    % TODO - If the last stop is not a depot, fail ?
    !, is_schedule_time_valid_acc(schedule(VID, Day, []), States, OrderCountNew, TimeSpent).

% Secures Hard-constraint 3
is_schedule_time_valid_acc(schedule(VID, Day, []), _, OrderCount, TimeSpent):-
    working_day(Day, DayStart, DayEnd),
    TotalTimeSpent is (TimeSpent + (10 * OrderCount)),
    TimeInDay is (DayEnd - DayStart),
    ignore(VID), 
    % Debug
    % write('Vehicle: '), write(VID), write('\n'), write('Day: '), write(Day), write('\n'), write('Total Time Spent: '), write(TotalTimeSpent), write('\n'), write('Time In Day: '), write(TimeInDay), write('\n'), write('\n'),
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
    is_plan_valid(plan(SchedulesRest), StatesNew, VehiclesDaysNew, OrdersDeliveredNew).

is_plan_valid(plan([]), _, [], _). % Secures Hard-constraint 1


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


% find_optimal(-P).
% find_heuristically(-P).
% pretty_print(+P).