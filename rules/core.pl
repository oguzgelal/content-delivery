%%%%%%%%%%%%%%%%%% Core functions %%%%%%%%%%%%%%%%%%

%%%%%% Check if a schedule valid %%%%%%

is_schedule_valid(schedule(_, _, []), OrdersDelivered, OrdersDelivered).

% For order:
is_schedule_valid(schedule(VID, Day, [OID|RouteRest]), OrdersDelivered, OrdersDeliveredNew):-
    order(OID, _, _, _),
    % Order ID shouldnt be found in the Orders delivered list.
    % Violation of Hard-constraint 2 (order delivered twice)
    not(member(OID, OrdersDelivered)),
    is_schedule_valid(schedule(VID, Day, RouteRest), [OID|OrdersDelivered], OrdersDeliveredNew).

% For depot:
is_schedule_valid(schedule(VID, Day, [DID|RouteRest]), OrdersDelivered, OrdersDeliveredNew):-
    depot(DID, _, _),
    is_schedule_valid(schedule(VID, Day, RouteRest), OrdersDelivered, OrdersDeliveredNew).

%%%%%% Check if a plan valid %%%%%%

is_valid(P):-
    % Get cartesian product of vehicles and working days in [Vehicle_ID/Working_day] list
    findall(VID/WD, (vehicle(VID,_,_,_,_,_), working_day(WD,_,_)), VehiclesDays),
    is_plan_valid(P, VehiclesDays, []).

is_plan_valid(plan([schedule(VID, Day, Route)|SchedulesRest]), VehiclesDays, OrdersDelivered):-
    % Delete matching Vehicle/Day combination from Cartesian Product list
    delete(VehiclesDays, VID/Day, VehiclesDaysNew),
    % Vehicle/Day combination has to be deleted from the cartesian array. If not:
    %  a) It is already deleted => a vehicle assigned twice for the same day
    %  b) It is not found => assignment for a vehicle on a non-working day
    %  c) It is not found => assignment for an unknown vehicle 
    % Either way, violates Hard-constraint 1
    not(VehiclesDays==VehiclesDaysNew),
    is_schedule_valid(schedule(VID, Day, Route), OrdersDelivered, OrdersDeliveredNew),
    /* Do something */
    is_plan_valid(plan(SchedulesRest), VehiclesDaysNew, OrdersDeliveredNew).

is_plan_valid(plan([]), [], _). % Secures Hard-constraint 1

% profit(+P,-Profit).
% find_optimal(-P).
% find_heuristically(-P).
% pretty_print(+P).