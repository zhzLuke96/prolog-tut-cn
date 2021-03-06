:- encoding(utf8).
:-dynamic 我在/1.
:-dynamic 存在/2.
:-dynamic 拥有/1.

房间( 厨房 ).
房间( 办公室 ).
房间( 客厅 ).
房间( 餐厅 ).
房间( 地下室 ).

门( 办公室 , 客厅 ).
门( 厨房 , 办公室 ).
门( 客厅 , 餐厅 ).
门( 厨房 , 地下室 ).
门( 餐厅 , 厨房 ).

存在( 桌子 , 办公室 ).
存在( 苹果 , 厨房 ).
存在( 手电筒 , 桌子 ).
存在( 洗衣机 , 地下室 ).
存在( 纳尼 , 洗衣机 ).
存在( 花椰菜 , 厨房 ).
存在( 饼干 , 厨房 ).
存在( 电脑 , 办公室 ).

可食用( 苹果 ).
可食用( 饼干 ).
难以下咽( 花椰菜 ).

我在( 厨房 ).

哪有食物(X,Y) :- 
    存在(X,Y),
    可食用(X).

哪有食物(X,Y) :- 
    存在(X,Y), 
    难以下咽(X).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chapter 5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 连接(X,Y) :- 
%     门(X,Y). 
% 连接(X,Y) :- 
%     门(Y,X).

连接的(X,Y) :- 
    门(X,Y);
    门(Y,X).

显示物品(Place) :- 
    存在(X, Place),
    tab(2),
    write(X),
    nl, fail. 
显示物品(_).

显示连接房间(Place) :- 
    连接的(Place, X),
    tab(2),
    write(X),
    nl, 
    fail.
显示连接房间(_).

环顾四周 :-
    我在(Place),
    write('你站在 '),
    write(Place),
    nl,
    write('能看到:'),
    nl,
    显示物品(Place),
    write('可以到达:'),
    nl,
    显示连接房间(Place).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chapter 8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

走到(Place):- 
    可达(Place), 
    移动(Place), 
    环顾四周.

移动(Place):- 
    retract(我在(_)), 
    asserta(我在(Place)).

可达(Place):- 
    我在(X), 
    连接的(X, Place). 
可达(_):- 
    write('无法到那里.'),
    nl, fail.

拿起(X):- 
    可拿起(X), 
    拿起物体(X).

可拿起(Thing) :- 
    我在(Place), 
    存在(Thing, Place).
可拿起(Thing) :- 
    write('这里没有 '), 
    write(Thing), 
    write(' .'), 
    nl, fail.

拿起物体(X) :- 
    retract(存在(X,_)), 
    asserta(拥有(X)),
    write('拿起了.'),
    nl.

放下(X):-
    我在(Place),
    asserta(存在(X,Place)), 
    retract(拥有(X)),
    write('已放下.'),
    nl.

/** <examples> Your example queries go here, e.g.
?- X #> 拿起(苹果).
*/