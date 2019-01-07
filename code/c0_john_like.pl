       
likes(bell,sports).         
likes(mary,music).
likes(mary,sports).
likes(jane,smith).

friend(john,X):-            
        likes(X,sports),
        likes(X,music).

/** <examples> Your example queries go here, e.g.
?- X #> friend(X,Y).
*/