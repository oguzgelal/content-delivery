list_print(L) :-
  maplist(term_to_atom, L, L1),
  atomic_list_concat(L1, L2),
  print(L2),
  write('\n').

% Get the last element of a list
last(X,[X]).
last(X,[_|Z]) :- last(X,Z).

% Ignore singleton variable warnings:
% Should only be used for variables that appear in debug messages
% that gets commented on / off occasionally.
ignore(_X).

% If current stop is an order, update the count
update_order_count(ID, OrderCount, OrderCount):- depot(ID, _, _).
update_order_count(ID, OrderCount, OrderCountNew):- order(ID, _, _, _), OrderCountNew is (OrderCount + 1).