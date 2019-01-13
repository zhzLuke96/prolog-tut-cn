room(kitchen).
room(office).
room(hall).
room('dining room').
room(cellar).

door(office,hall).
door(kitchen,office).
door(hall,'dining room').
door(kitchen,cellar).
door('dining room',kitchen).

location(desk,office).
location(apple,kitchen).
location(flashlight,desk).
location('washing machine',cellar).
location(nani,'washing machine').
location(broccoli,kitchen).
location(crackers,kitchen).
location(computer,office).

edible(apple).
edible(crackers).
tastes_yucky(broccoli).

here(kitchen).

where_food(X,Y) :- 
    location(X,Y),
    edible(X).

where_food(X,Y) :- 
    location(X,Y), 
    tastes_yucky(X).


/** <examples> Your example queries go here, e.g.
?- X #> where_food(X,Y), write(X), write(" => "), write(Y), nl, fail.
*/