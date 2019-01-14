father(a,b). 
father(a,d).
father(a,t).
father(b,c).

wife(aw,a).
wife(bw,b).

male(t).
female(d).
male(c).

male(X):-
    father(X,_). 

% male(X):-
%     wife(_,X).

female(X):-
    wife(X,_).

grandfather(X,Y):-
    father(X,Z),
    father(Z,Y).

mother(X,Y):-
    wife(X,Z),
    father(Z,Y).

brother(X,Y):-
    father(Z,X),
    father(Z,Y),
    male(X),
    male(Y),
    X\=Y.

uncle(X,Y):-
    brother(X,Z),
    father(Z,Y).

/** <examples> Your example queries go here, e.g.
?- X #> uncle(X,Y).
*/