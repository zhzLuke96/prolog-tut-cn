:- use_module(library(tabling)).
:- table fib/2.

% fib(0, 1).
% fib(1, 1).
% fib(N, F) :-
%         N > 1,
%         N1 is N - 1,
%         N2 is N - 2,
%         fib(N1, F1),
%         fib(N2, F2),
%         F is F1 + F2.

fib(0, 1) :- !.
fib(1, 1) :- !.
fib(N, F) :-
        fib(1,1,1,N,F).

fib(_F, F1, N, N, F1) :- !.
fib(F0, F1, I, N, F) :-
        F2 is F0+F1,
        I2 is I + 1,
        fib(F1, F2, I2, N, F).
