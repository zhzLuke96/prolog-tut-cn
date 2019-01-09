:- encoding(utf8).

illegal(放火烧山).
illegal(酒驾).
illegal(走私).
illegal(盗窃).

legal(X) :-
    \+ illegal(X).