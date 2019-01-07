
love(zhangxueyou,wanfei).
love(zhangxueyou,zouhuimin).
love(wanfei,xietinfen).
love(zouhuimin,zhangxueyou).
love(xietinfen,wanfei).
love(xietinfen,zouhuimin).
love(liudehua,zouhuimin).

lovers(X,Y):-
        love(X,Y),love(Y,X).

/** <examples> Your example queries go here, e.g.
?- X #> lovers(X,Y).
*/