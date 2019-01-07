:- encoding(utf8).

相好(小王,小红).
相好(小马,小张).
相好(小马,小红).
相好(路人甲,路人乙).

朋友(主人公,X):-   
        相好(X,小红),
        相好(X,小张).

/** <examples> Your example queries go here, e.g.
?- X #> 朋友(主人公,X).
*/