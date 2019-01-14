:- encoding(utf8).

父亲(甲,乙). 
父亲(甲,丁).
父亲(甲,路人).
父亲(乙,丙).

妻子(甲妻,甲).
妻子(乙妻,乙).

男人(路人).
女人(丁).
男人(丙).

男人(X):-
    父亲(X,_). 

% 男人(X):-
%     妻子(_,X).

女人(X):-
    妻子(X,_).

祖父(X,Y):-
    父亲(X,Z),
    父亲(Z,Y).

母亲(X,Y):-
    妻子(X,Z),
    父亲(Z,Y).

兄弟(X,Y):-
    父亲(Z,X),
    父亲(Z,Y),
    男人(X),
    男人(Y),
    X\=Y.

叔伯(X,Y):-
    兄弟(X,Z),
    父亲(Z,Y).

/** <examples> Your example queries go here, e.g.
?- X #> 叔伯(X,Y), write(X), write(" 是 "), write(Y) , write(" 的叔伯。"), nl, fail.
?- X #> 兄弟(X,Y), write(X), write(" 是 "), write(Y) , write(" 的兄弟。"), nl, fail.
?- X #> 母亲(X,Y), write(X), write(" 是 "), write(Y) , write(" 的母亲。"), nl, fail.
?- X #> 祖父(X,Y), write(X), write(" 是 "), write(Y) , write(" 的祖父。"), nl, fail.
*/