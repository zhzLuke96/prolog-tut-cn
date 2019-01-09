:- encoding(utf8).

move(1,X,Y,_) :-  
    write('把顶部的盘子从 '), 
    write(X), 
    write(' 移动到 '), 
    write(Y), 
    nl. 

move(N,X,Y,Z) :- 
    N>1, 
    M is N-1, 
    move(M,X,Z,Y), 
    move(1,X,Y,_), 
    move(M,Z,Y,X).  

/** <examples> Your example queries go here, e.g.
?- X #> move(3,第一根,第二根,第三根).
*/