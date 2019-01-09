#!/usr/bin/env swipl

:- initialization(main,main).

%%%%%%%%%%%%%%%%%%
%  0 way
%%%%%%%%%%%%%%%%%%

main([_]) :-
    write("Hello world!"),
    halt.

%%%%%%%%%%%%%%%%%%
%  1 way
%%%%%%%%%%%%%%%%%%

% main([_|[Name|_]]) :-
%     write("Hello "),
%     write(Name),
%     write("!"),
%     halt.

%%%%%%%%%%%%%%%%%%
%  2 way
%%%%%%%%%%%%%%%%%%

% % print_ls([]) :- !.

% print_ls([P|[]]) :-
%     write(P).

% print_ls([P|NP]) :-
%     write(P),
%     tab(1),
%     print_ls(NP).

% main([_|Argv]) :-
%     write("Hello "),
%     print_ls(Argv),
%     write("!"),
%     halt.

%%%%%%%%%%%%%%%%%%
%  3 way
%%%%%%%%%%%%%%%%%%

main([_|Argv]) :-
    concat_atom(Argv, ' ', ArgString),
    format('~w ~w~w',["Hello",ArgString,"!"]),
    halt.
