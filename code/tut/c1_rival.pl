
love(zhangxueyou,wanfei).
love(zhangxueyou,zouhuimin).
love(wanfei,xietinfen).
love(zouhuimin,zhangxueyou).
love(xietinfen,wanfei).
love(xietinfen,zouhuimin).
love(liudehua,zouhuimin).

rival_in_love(X,Y):-
        love(X,Z),
        not(love(Z,X)),
        love(Z,Y).

/** <examples> Your example queries go here, e.g.
?- X #> rival_in_love(X,Y).
*/