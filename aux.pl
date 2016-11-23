% Auxilary functions

% To get location from either a depot or an order
get_location(ID, Location):- depot(ID, _, Location), !.
get_location(ID, Location):- order(ID, _, Location, _).

% Calculate the distance between two points
distance(location(X1,Y1), location(X2,Y2), Distance):- 
    Distance is (abs(X1 - X2) + abs(Y1 - Y2)).

% Calculate the driving duration between two orders/depots
driving_duration(VID, FromID, ToID, Duration):-
    vehicle(VID, _, _, KmInMin, _, _),
    get_location(FromID, L1),
    get_location(ToID, L2),
    distance(L1, L2, Distance),
    Duration is (Distance * KmInMin).


%earning(OID,Day,-Value).
%load(OIDs,-Weight).
%update_inventory(Inventory,?OID,?NewInventory).