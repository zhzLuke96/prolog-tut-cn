takeout(X,[X|R],R).  
takeout(X,[F |R],[F|S]) :- takeout(X,R,S).

perm([X|Y],Z) :- perm(Y,W), takeout(X,Z,W).  
perm([],[]).

ordered([]).
ordered([_|[]]).
ordered([A|[B|T]]) :-
    A =< B,
    ordered([B|T]).
	
sortls(L,O) :-
	perm(L,O),
	ordered(O).
