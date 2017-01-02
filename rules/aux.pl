% Auxilary functions

%%%%%% To get location from either a depot or an order %%%%%%
get_location(ID, Location):- depot(ID, _, Location), !.
get_location(ID, Location):- order(ID, _, Location, _).

%%%%%% Calculate the distance between two points %%%%%%
distance(location(X1,Y1), location(X2,Y2), Distance):- Distance is (abs(X1 - X2) + abs(Y1 - Y2)).
get_distance(FromID, ToID, Distance):-
    get_location(FromID, L1),
    get_location(ToID, L2),
    distance(L1, L2, Distance).

%%%%%% Calculate the driving duration between two orders/depots %%%%%%
driving_duration(VID, FromID, ToID, Duration):-
    vehicle(VID, _, _, Pace, _, _),
    get_location(FromID, L1),
    get_location(ToID, L2),
    distance(L1, L2, Distance),
    Duration is (Distance * Pace).

%%%%%% Calculate product values given [PID/Amount] array %%%%%%
calculate_earnings(Products, Value):-calculate_earnings(Products, 0.0, Value).
calculate_earnings([], Value, Value).
calculate_earnings([PID/ProductAmount|Tail], Acc, Value):-
    product(PID, ProductValue, _), 
    NewAcc is Acc + (ProductValue * ProductAmount),
    calculate_earnings(Tail, NewAcc, Value).

%%%%%% The percentage of the cut due to late delivery %%%%%%
penalty_constant(Day, Deadline, Coef):- Day > Deadline, !, Coef is 1 / 2.
penalty_constant(_, _, 1).

%%%%%% Calculate revenue given order id %%%%%%
earning(OID, Day, Value):-
    order(OID, Products, _, Deadline),
    working_day(Day, _, _), 
    calculate_earnings(Products, RawValue),
    penalty_constant(Day, Deadline, Coef),
    Value is (RawValue * Coef).

%%%%%% Calculate product weights given [PID/Amount] array %%%%%%
calculate_weights(Products, Weight):-calculate_weights(Products, 0.0, Weight).
calculate_weights([], Weight, Weight).
calculate_weights([PID/ProductAmount|Tail], Acc, Weight):-
    product(PID, _, ProductWeight), 
    NewAcc is Acc + (ProductWeight * ProductAmount),
    calculate_weights(Tail, NewAcc, Weight).

%%%%%% Calculate the weight of an order %%%%%%
order_weight(OID, Weight):-
    order(OID, Products, _, _),
    calculate_weights(Products, Weight),

%%%%%% Calculate the weight of an array of orders %%%%%%
load([], 0.0).
load(OIDs, Weight):- load(OIDs, 0.0, Weight).
load([], Weight, Weight).
load([OID|Rest], Acc, Weight):-
    order_weight(OID, OrderWeight),
    NewAcc is (Acc + OrderWeight),
    load(Rest, NewAcc, Weight).

%%%%%% Subtract a product from an inventory instance %%%%%%
subtract_product([], _, NewProductInventoryAmount, NewProductInventoryAmount).
subtract_product([PID_Order/ProductOrderAmount|_], PID_Inventory, ProductInventoryAmount, NewProductInventoryAmount):-
    % We found the product in the order
    PID_Order == PID_Inventory, !,
    ProductInventoryAmount >= ProductOrderAmount,
    NewProductInventoryAmount is (ProductInventoryAmount - ProductOrderAmount),
    % we're done here, no need to check the rest. Just call to recursion to jump into the base case.
    subtract_product([], _, NewProductInventoryAmount, NewProductInventoryAmount). 
    
subtract_product([_|Rest], PID_Inventory, ProductInventoryAmount, NewProductInventoryAmount):- 
    subtract_product(Rest, PID_Inventory, ProductInventoryAmount, NewProductInventoryAmount).

%%%%%% Subtract the products in an order from an inventory %%%%%%
update_inventory(Inventory, OID, NewInventory):- update_inventory(Inventory, OID, NewInventory, []).
update_inventory([], _, NewInventory, NewInventory).
update_inventory([PID/ProductInventoryAmount|Tail], OID, NewInventory, Acc):-
    order(OID, ProductsInOrder, _, _),
    subtract_product(ProductsInOrder, PID, ProductInventoryAmount, NewProductInventoryAmount),
    append(Acc, [PID/NewProductInventoryAmount], NewAcc),
    update_inventory(Tail, OID, NewInventory, NewAcc).    
update_inventory_bulk(Inventory, [], Inventory).
update_inventory_bulk(Inventory, [OID|OrdersRest], NewInventory):-
    update_inventory(Inventory, OID, InventoryUpdated),
    update_inventory_bulk(InventoryUpdated, OrdersRest, NewInventory).
