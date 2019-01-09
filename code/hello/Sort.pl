:- encoding(utf8).

/* sortcsj.pl    原始參考：Computer Science  J. Glenn Brookshear   */
/* sortcsj()中的第二個引數帶有排序好的結果　*/
/* 僅為示範，若為gprolog使用者則用內建sort等較佳 */
/* 在gprolog下之編譯例：gplc --min-size sortcsj.pl　*/
/*   執行 sortcsj 後會出現排序結果 [2,9,18,18,25,33,66,77] */

% :- initialization(q).

% q:-
%     L=[33,18,2,77,18,66,9,25],
%     sort(L).

mysort(L):-
    (sortcsj(L,P),
    write(P), nl).

sortcsj(L,S) :-
    permutation(L,S),
    ordered(S).
/* L為原list, S為排序好的list, 此為permutation關係(built-in) */

ordered([]).        /* 表empty list視為排序好的list */
ordered([_|[]]).    /* 只有一元素之list視為排序好的list */
ordered([A|[B|T]]) :-
    A =< B,
    ordered([B|T]).
    /* 此规则約束所謂的排序好是指前項元素小於或等於後一項元素 */