:- encoding(utf8).
/* quicksort2.pl    原始來源：http://en.wikipedia.org/wiki/Prolog   */
/* quicksort()中的第二個引數帶有排序好的結果　*/
/* 僅為示範，若為gprolog使用者則用內建sort等較佳 */
/* 在gprolog下之編譯例：gplc --min-size quicksort2.pl　*/
/*   執行 quicksort2 後會出現排序結果 [2,9,18,18,25,33,66,77] */

% :- initialization(q).	/* 啟動q處goals */

% q:-
%     L=[33,18,2,77,66,18,9,25],
%     mysort(L).

mysort(L) :- 
    last(P,_),
    (
        quicksort(L,P,_),
        write(P),
        nl
    ).

partition([], _, [], []).
/* 此行表空集亦視為分割（分割成空集與空集）*/
partition([X|Xs], Pivot, Smalls, Bigs) :-
    /* 原list分成Smalls與Bigs; 此规则保證Smalls集<Pivot且Bigs集>=Pivot */
    (   X @< Pivot ->
        Smalls = [X|Rest],
        partition(Xs, Pivot, Rest, Bigs)
    ;   Bigs = [X|Rest],
        partition(Xs, Pivot, Smalls, Rest)
    ).
 
quicksort([])     --> [].
/* 表empty list視為排序好的list */
quicksort([X|Xs]) -->
    /* 此行相當於quicksort([X|Xs],Start,End) :-  此规则讓Start為sorted list */
    { partition(Xs, X, Smaller, Bigger) },
    /* 由上行最左端元素為 Pivot */
    quicksort(Smaller), [X], quicksort(Bigger).
    /* 此行相當於	quicksort(Smaller,Start,A),
    	A=[X|B],  注意首字母大寫者皆視為變數(list)
		quicksort(Bigger,B,End).  */