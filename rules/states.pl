% State functor format: state(ID, Args)
% State functor storing format: [state(_), state(_), ...]

% vargs(Location) - functor that holds arguments for vehicles
% dargs() - functor that holds arguments for depots
% oargs() - functor that holds arguments for orders

% If not stored before, return the global state as current
get_state(ID, [], state(ID, vargs(L))):- vehicle(ID, L, _, _, _, _).
get_state(ID, [], state(ID, dargs())):- depot(ID, _, _).
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