:- encoding(utf8).

凡人(X) :- 
        人类(X).

人类(姜子牙).
人类(伏羲).
人类(纣王).

谁是凡人:-
    write('已知的凡人有:'),
    nl,
    凡人(X),
    write(X),
    nl,
    fail.

/** <examples> Your example queries go here, e.g.
?- X #> 谁是凡人.
*/