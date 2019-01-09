#!/usr/bin/env swipl

:- initialization(main, main).

main([_|Argv]) :-
        pl_eval(Argv),
        halt.

pl_eval(Expr) :- 
        concat_atom(Expr, ' ', SingleArg),
        term_to_atom(Term, SingleArg),
        Val is Term,
        format('~w~n', [Val]).