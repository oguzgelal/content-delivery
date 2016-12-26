%%%%%%%%%%%%%%%%%% Core functions %%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% Check if a schedule valid %%%%%%%%%%%%

is_schedule_valid(schedule(_, _, []), _, OrdersDelivered, OrdersDelivered).

% For order:
is_schedule_valid(schedule(VID, Day, [OID|RouteRest]), States, OrdersDelivered, OrdersDeliveredNew):-
    order(OID, _, _, _),
    % Order ID shouldnt be found in the Orders delivered list.
    % Violation of Hard-constraint 2 (order delivered twice)
    not(member(OID, OrdersDelivered)),
    is_schedule_valid(schedule(VID, Day, RouteRest), States, [OID|OrdersDelivered], OrdersDeliveredNew).

% For depot:
is_schedule_valid(schedule(VID, Day, [DID|RouteRest]), States, OrdersDelivered, OrdersDeliveredNew):-
    depot(DID, _, _),
    is_schedule_valid(schedule(VID, Day, RouteRest), States, OrdersDelivered, OrdersDeliveredNew).


%%%%%%%%%%%% Check if schedule time sufficient %%%%%%%%%%%%

is_schedule_time_valid(schedule(VID, Day, Route), States):- 
    % Get the current state of vehicle
    get_state(VID, States, state(VID, vargs(CurrentDepotID))),
    % Debug
    write('Starting location for '), write(VID), write(' is '), write(CurrentDepotID), write('\n'),
    % Append current location of vehicle to the head of the route so that it starts calculating from there
    is_schedule_time_valid_acc(schedule(VID, Day, [CurrentDepotID|Route]), States, 0, 0).

% If current stop is an order, update the count
update_order_count(ID, OrderCount, OrderCount):- depot(ID, _, _).
update_order_count(ID, OrderCount, OrderCountNew):- order(ID, _, _, _), OrderCountNew is (OrderCount + 1).

% Current stop to next
is_schedule_time_valid_acc(schedule(VID, Day, [ID,IDNext|RouteRest]), States, OrderCount, TimeSpent):-
    driving_duration(VID, ID, IDNext, TimeSpentDriving),
    TimeSpentNew is (TimeSpent + TimeSpentDriving),
    update_order_count(ID, OrderCount, OrderCountNew),
    is_schedule_time_valid_acc(schedule(VID, Day, [IDNext|RouteRest]), States, OrderCountNew, TimeSpentNew).

% Last stop
is_schedule_time_valid_acc(schedule(VID, Day, [ID|[]]), States, OrderCount, TimeSpent):-
    update_order_count(ID, OrderCount, OrderCountNew),
    % TODO - If the last stop is not a depot, fail ?
    % TODO - Find a way to update vehicle location
    is_schedule_time_valid_acc(schedule(VID, Day, []), States, OrderCountNew, TimeSpent).

% Secures Hard-constraint 3
is_schedule_time_valid_acc(schedule(VID, Day, []), _, OrderCount, TimeSpent):-
    working_day(Day, DayStart, DayEnd),
    TotalTimeSpent is (TimeSpent + (10 * OrderCount)),
    TimeInDay is (DayEnd - DayStart),
    % Debug
    ignore(VID),
    write('Vehicle: '), write(VID), write('\n'), write('Day: '), write(Day), write('\n'), write('Total Time Spent - '), write(TotalTimeSpent), write('\n'), write('Time In Day - '), write(TimeInDay), write('\n'), write('\n'),
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
    is_schedule_valid(schedule(VID, Day, Route), States, OrdersDelivered, OrdersDeliveredNew),
    % Make sure the vehicle has enough time in a day to complete the trip (HC3)
    is_schedule_time_valid(schedule(VID, Day, Route), States),
    % Update the state to the point after a schedule, and pass on the new state to the next recursion
    update_state_step(schedule(VID, Day, Route), States, StatesNew),
    is_plan_valid(plan(SchedulesRest), StatesNew, VehiclesDaysNew, OrdersDeliveredNew).

is_plan_valid(plan([]), _, [], _). % Secures Hard-constraint 1



% profit(+P,-Profit).
% find_optimal(-P).
% find_heuristically(-P).
% pretty_print(+P).