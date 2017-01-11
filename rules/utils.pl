list_print(L) :-
  maplist(term_to_atom, L, L1),
  atomic_list_concat(L1, L2),
  print(L2),
  write('\n').

% Get the last element of a list
last([], false).
last([X], X).
last([_|Z], X) :- last(Z, X).

% Same as above, but return false for empty arrays
has_last([X], X).
has_last([_|Z], X) :- has_last(Z, X).

% Check if the list is empty
list_empty([]).

% Ignore singleton variable warnings:
% Should only be used for variables that appear in debug messages
% that gets commented on / off occasionally.
ignore(_X).

% If current stop is an order, update the count
update_order_count(ID, OrderCount, OrderCount):- depot(ID, _, _).
update_order_count(ID, OrderCount, OrderCountNew):- order(ID, _, _, _), OrderCountNew is (OrderCount + 1).

% Get the ordinal suffix on numbers. ie. 1st, 2nd, 23rd, 111th ...
get_ordinal_suffix(Number, Suffix):- Mod10 is Number mod 10, Mod100 is Number mod 100, get_ordinal_suffix(Mod10, Mod100, Suffix).
get_ordinal_suffix(Mod10, Mod100, Suffix):- Mod10 == 1, not(Mod100 == 11), format(atom(Suffix),'~w', ['st']), !.
get_ordinal_suffix(Mod10, Mod100, Suffix):- Mod10 == 2, not(Mod100 == 12), format(atom(Suffix),'~w', ['nd']), !.
get_ordinal_suffix(Mod10, Mod100, Suffix):- Mod10 == 3, not(Mod100 == 13), format(atom(Suffix),'~w', ['rd']), !.
get_ordinal_suffix(_, _, Suffix):- format(atom(Suffix),'~w', ['th']), !.