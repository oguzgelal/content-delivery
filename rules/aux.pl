% Auxilary functions

% To get location from either a depot or an order
get_location(ID, Location):- depot(ID, _, Location), !.
get_location(ID, Location):- order(ID, _, Location, _).

% Calculate the distance between two points
distance(location(X1,Y1), location(X2,Y2), Distance):- Distance is (abs(X1 - X2) + abs(Y1 - Y2)).

% Calculate the driving duration between two orders/depots
driving_duration(VID, FromID, ToID, Duration):-
    vehicle(VID, _, _, KmInMin, _, _),
    get_location(FromID, L1),
    get_location(ToID, L2),
    distance(L1, L2, Distance),
    Duration is (Distance * KmInMin).

% Calculate values given [PID/Amount] array
calculate_earnings(Products, Value):-calculate_earnings(Products, 0.0, Value).
calculate_earnings([], Value, Value).
calculate_earnings([PID/ProductAmount|Tail], Acc, Value):-
    product(PID, ProductValue, _), 
    NewAcc is Acc + (ProductValue * ProductAmount),
    calculate_earnings(Tail, NewAcc, Value).

% Return how much percent 
penalty_constant(Day, Deadline, Coef):- Day > Deadline, !, Coef is 1 / 2.
penalty_constant(_, _, 1).

% Calculate revenue given order id
earning(OID, Day, Value):-
    order(OID, Products, _, Deadline),
    working_day(Day, _, _), 
    calculate_earnings(Products, RawValue),
    penalty_constant(Day, Deadline, Coef),
    Value is (RawValue * Coef).


%load(OIDs,-Weight).
%update_inventory(Inventory,?OID,?NewInventory).