% This files contains some examples which you can use to validate your solution.
% All examples below are for the multi_small instance.
% Disclaimer: Correct behavior for these examples, does not guarantee your solution is in fact correct.

% Take care handling rounding errors in output arguments:
% Your output may contain a small numerical error (errors < 0.001 will be accepted)
% Larger errors (e.g. due to floating point->integer conversion) may affect your grade.

%AUXILIARY FUNCTIONALITY

%driving_duration/4
driving_duration(v1,d1,d1,0.0).
driving_duration(v1,d1,d2,240.0).
driving_duration(v2,d1,d2,150.0).
driving_duration(v1,d2,o2,90.0).
driving_duration(v1,o6,o9,220.8).

%load/2
load([],0.0).
load([o1],0.7).
load([o1,o2],200.7).
load([o10],187.9).
load([o10,o5],209.3).
load([o9,o8,o7,o6,o5,o4,o3,o2,o1],658.0).

%earning/3
earning(o1,1,385.0).
earning(o6,3,175.0).
earning(o1,3,192.5).
earning(o3,3,105.0).
%?- earning(o5,2,_). should return False because 2 is not a working day

%update_inventory/3
update_inventory([p1/50,p3/10,p2/10],o1,[p1/50,p3/3,p2/10]). %when NewInventory is bound, all orders must be accepted. When unbound, only a single order may be returned.
update_inventory([p1/50,p3/10,p2/10],o3,[p1/40,p2/2,p3/10]).
update_inventory([p1/50,p2/10,p3/10],o9,[p1/50,p2/0,p3/10]). %When 0 of one product pi, either pi/0 or omit pi (when bound, both true. When unbound, generate 1)
update_inventory([p1/50,p2/10,p3/10],o9,[p3/10,p1/50]).
%?- update_inventory([p1/50,p2/10,p3/10],o5,_). should return False because not enough items of p1 are available.

%CORE FUNCTIONALITY:

%is_valid/1

//valid examples
is_valid(plan([schedule(v1,1,[]),schedule(v2,1,[]),schedule(v1,3,[]),schedule(v2,3,[])])).
is_valid(plan([schedule(v2,1,[d2,d1]),schedule(v1,1,[]),schedule(v2,3,[]),schedule(v1,3,[])])).
is_valid(plan([schedule(v2,1,[o6,d1]),schedule(v1,1,[o8,o1,d2]),schedule(v2,3,[o5,d2]),schedule(v1,3,[o2,o7,d2])])).
is_valid(plan([schedule(v2,3,[]),schedule(v1,3,[]),schedule(v2,1,[o6,d2,o8,d1]),schedule(v1,1,[])])).
is_valid(plan([schedule(v2,1,[o5,d2]),schedule(v1,1,[o2,d1]),schedule(v2,3,[o1,d1]),schedule(v1,3,[o3,d2])])).

//invalid examples
%plan([]). %No schedule for each vehicle each working day
%plan([schedule(v1,1,[]),schedule(v2,1,[]),schedule(v1,2,[]),schedule(v2,2,[]),schedule(v1,3,[]),schedule(v2,3,[])]) %should return False because schedules for non-working days
%plan([schedule(v1,1,[o6,d1]),schedule(v2,1,[]),schedule(v1,3,[o6,d1]),schedule(v2,3,[])]) %o6 is delivered twice
%plan([schedule(v2,1,[o6,d1]),schedule(v1,1,[o1,o8,d2]),schedule(v2,3,[o5,d2]),schedule(v1,3,[o2,o7,d2])]) %v1's delivery route takes too long on day 1. 
%plan([schedule(v1,1,[]),schedule(v2,1,[d2,o5,d2]),schedule(v1,3,[]),schedule(v2,3,[])]) %not enough of p1 is available in d2 to load o5.
%plan([schedule(v1,1,[]),schedule(v2,1,[o2,d2]),schedule(v1,3,[]),schedule(v2,3,[])]) %v2 has insufficient capacity to load o2

%profit/2
profit(plan([schedule(v1,1,[]),schedule(v2,1,[]),schedule(v1,3,[]),schedule(v2,3,[])]),0.0).
profit(plan([schedule(v2,1,[d2,d1]),schedule(v1,1,[]),schedule(v2,3,[]),schedule(v1,3,[])]),-280.0).
profit(plan([schedule(v2,1,[o6,d1]),schedule(v1,1,[o8,o1,d2]),schedule(v2,3,[o5,d2]),schedule(v1,3,[o2,o7,d2])]),-106.2).
profit(plan([schedule(v2,3,[]),schedule(v1,3,[]),schedule(v2,1,[o6,d2,o8,d1]),schedule(v1,1,[])]),-56.4).
profit(plan([schedule(v2,1,[o5,d2]),schedule(v1,1,[o2,d1]),schedule(v2,3,[o1,d1]),schedule(v1,3,[o3,d2])]),-254.5).

% To validate find_optimal/1: Compare with the optimal profit given in last column of the table in the assignment.
% To validate find_heuristically/1: On small: Compare to optimal. On large compare your experimental results to those of your fellow students (or try to improve your own).
% To validate pretty_print/1, one an example is provided in the slides. Try to provide a clear, yet informative overview.


