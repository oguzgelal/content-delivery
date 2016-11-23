% Location on map
% location(X, Y).

% Product
% product(+PID, +Weight, +Kilos).

% Order
% order(+OID, [+PID/+Quantity|T], location(X, Y), DeliveryDeadline).

% Depot
% depot(+DID, [+PID/+Quantity|T], location(X, Y)).

% Vehicle
% vehicle(+VID, +DID, +Capacity, +KmInMin, +DailyCost, +KmCost).

% Working Day
% working_day(+Day,+StartHourInMinutes,+EndHourInMinutes).