:- encoding(utf8).

相爱(张学友,王菲).
相爱(张学友,周慧敏).
相爱(王菲,谢霆锋).
相爱(周慧敏,张学友).
相爱(谢霆锋,王菲).
相爱(谢霆锋,周慧敏).
相爱(刘德华,周慧敏).

爱人(X,Y):- 
    相爱(X,Y),相爱(Y,X).

/** <examples> Your example queries go here, e.g.
?- X #> 爱人(X,Y).
*/