list_print(L) :-
  maplist(term_to_atom, L, L1),
  atomic_list_concat(L1, L2),
  print(L2).

% Ignore singleton variable warnings:
% Should only be used for variables that appear in debug messages
% that gets commented on / off occasionally.
ignore(_X).