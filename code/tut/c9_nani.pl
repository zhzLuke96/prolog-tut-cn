
:-dynamic here/1.
:-dynamic location/2.
:-dynamic have/1.

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chapter 5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% connect(X,Y) :- 
%     door(X,Y). 
% connect(X,Y) :- 
%     door(Y,X).

connect(X,Y) :- 
    door(X,Y);
    door(Y,X).

list_things(Place) :- 
    location(X, Place),
    tab(2),
    write(X),
    nl, fail. 
list_things(_).

list_connections(Place) :- 
    connect(Place, X),
    tab(2),
    write(X),
    nl, 
    fail.
list_connections(_).

look :-
    here(Place),
    write('You are in the '),
    write(Place),
    nl,
    write('You can see:'),
    nl,
    list_things(Place),
    write('You can go to:'),
    nl,
    list_connections(Place).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chapter 8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

goto(Place):- 
    can_go(Place), 
    move(Place), 
    look.

move(Place):- 
    retract(here(_)), 
    asserta(here(Place)).

can_go(Place):- 
    here(X), 
    connect(X, Place). 
can_go(_):- 
    write('You can''t get there from here.'),
    nl, fail.

take(X):- 
    can_take(X), 
    take_object(X).

can_take(Thing) :- 
    here(Place), 
    location(Thing, Place).
can_take(Thing) :- 
    write('There is no '), 
    write(Thing), 
    write(' here.'), 
    nl, fail.

take_object(X) :- 
    retract(location(X,_)), 
    asserta(have(X)),
    write('taken'),
    nl.

drop(X):-
    here(Place),
    asserta(location(X,Place)), 
    retract(have(X)),
    write('dropped.'),
    nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chapter 9
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

location(envelope, desk). 
location(stamp, envelope).
location(key, envelope).

is_contained_in(T1,T2) :-
    location(T1,T2). 

is_contained_in(T1,T2) :- 
    location(X,T2), 
    is_contained_in(T1,X). 

/** <examples> Your example queries go here, e.g.
?- X #> take(apple).
*/