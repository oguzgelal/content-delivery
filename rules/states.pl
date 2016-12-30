%%%%%%%%%%%%%%%%%% State functions %%%%%%%%%%%%%%%%%%

% State storage is just a simple list, holding the 
% latest state values for all data types including
% vehicles, depots and orders. 

% state(ID, Args) - State functor format
% [state(ID, Args), state(ID, Args), ...] - State storing format
% vargs(Location, CurrentLoad) - functor that holds arguments for vehicles
% dargs(Inventory) - functor that holds arguments for depots
% oargs() - functor that holds arguments for orders

% If not stored before, return the global state as current
get_state(ID, [], state(ID, vargs(L, 0))):- vehicle(ID, L, _, _, _, _).
get_state(ID, [], state(ID, dargs(Inventory))):- depot(ID, Inventory, _).
get_state(ID, [], state(ID, oargs())):- order(ID, _, _, _).

% If stored state found, return stored state
get_state(ID, [state(ID, Args)|_], state(ID, Args)).

% If stored state found not found, continue.
get_state(ID, [_|Rest], CurrentState):- get_state(ID, Rest, CurrentState).

% If stored before, remove it. Then append the new value.
update_state(state(ID, Args), StateArray, StateArrayNew):-
    get_state(ID, StateArray, StateOld),
    delete(StateArray, StateOld, StateArrayDeleted),
    append([state(ID, Args)], StateArrayDeleted, StateArrayNew).

% Update the state with respect to the current schedule
% This method runs after every check succeeds, so no need to check any validity
update_state_step(schedule(_, _, []), State, State).
update_state_step(schedule(VID, Day, [RouteStopID|RouteRest]), State, StateNew):-
    process_step(VID, RouteStopID, State, StateUpdated),
    update_state_step(schedule(VID, Day, RouteRest), StateUpdated, StateNew).

% Process to be taken if the route stop is a depot
process_step(VID, RouteStopID, State, StateUpdated):-
    depot(RouteStopID, _, _),
    update_state(state(VID, vargs(RouteStopID, _)), State, StateUpdated).

% TODO: No changes yet. Update when the load state of vehicle needs to be updated
% Process to be taken if the route stop is an order
process_step(_, _RouteStopID, State, State).
    %order(RouteStopID, _, _, _).
    %update_state(state(VID, vargs(RouteStopID, _)), State, StateUpdated).