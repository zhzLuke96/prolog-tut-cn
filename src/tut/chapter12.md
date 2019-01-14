# 列表

为了能够更好地表达一组数据，Prolog引入了列表(List)这种数据结构。 列表是一组项目的集合，此项目可以是Prolog的任何数据类型，包括结构和列表。列表的元素由方括号括起来，项目中间使用逗号分割。例如下面的列表列出了厨房中的物品。

 [apple, broccoli, refrigerator] 

我们可以使用列表来代替以前的多个子句。例如：

loc_list([apple, broccoli, crackers], kitchen).
loc_list([desk, computer], office).
loc_list([flashlight, envelope], desk).
loc_list([stamp, key], envelope). 
loc_list(['washing machine'], cellar).
loc_list([nani], 'washing machine'). 

可见使用列表能够简化程序。

当某个列表中没有项目时我们称之为空表，使用“[]”表示。也可以使用nil来表示。下面的句子表示hall中没有东西。

loc_list([], hall) 

变量也可以与列表联合,就像它与其他的数据结构联合一样。假如数据库中有了上面的子句，就可以进行如下的询问。

?- loc_list(X, kitchen). 
X = [apple, broccoli, crackers] 
?- [_,X,_] = [apples, broccoli, crackers]. 
X = broccoli 

最后这个例子可以取出列表中任何一个项目的值，但是这种方法是不切实际的。你必须知道列表的长度，但是在很多情况下，列表的长度是变化的。

为了更加有效的使用列表，必须找到存取、添加和删除列表项目的方法。并且，我们应该不用对列表项目数和它们的顺序操心。

Prolog提供的两个特性可以方便的完成以上任务。首先，Prolog提供了把表头项目以及除去表头项目后剩下的列表分离的方法。其次，Prolog强大的递归功能可以方便地访问除去表头项目后的列表。

使用这两个性质，我们可以编出一些列表的实用谓词。例如member/2，它能够找到列表中的元素；append/3可以把两个列表连接起来。这些谓词都是首先对列表头进行处理，然后使用递归处理剩下的列表。

首先，请看一般的列表形式。

 [X | Y]

使用此列表可以与任意的列表匹配，匹配成功后，X绑定为列表的第一个项目的值，我们称之为表头（head）。而Y则绑定为剩下的列表，我们称之为表尾（tail)。

下面我们看几个例子。

?- [a|[b,c,d]] = [a,b,c,d]. 
yes 

上面的联合之所以成功，是因为等号两边的列表是等价的。注意表尾tail一定是列表，而表头则是一个项目，可以是表，也可以是其他的任何数据结构。下面的匹配失败，在“|”之后只能是一个列表，而不能是多个项目。

?- [a|b,c,d] = [a,b,c,d].
no

下面是其它的一些列表的例子。

?- [H|T] = [apple, broccoli, refrigerator].
H = apple 
T = [broccoli, refrigerator] 
?- [H|T] = [a, b, c, d, e].
H = a
T = [b, c, d, e] 
?- [H|T] = [apples, bananas].
H = apples 
T = [bananas]
?- [H|T] = [a, [b,c,d]]. 这个例子中的第一层列表有两个项目。
H = a 
T = [[b, c, d]] 
?- [H|T] = [apples]. 列表中只有一个项目的情况
H = apples
T = [] 

空表不能与[H|T]匹配，因为它没有表头。


?- [H|T] = []. 
no


注意：最后这个匹配失败非常重要，在递归过程中经常使用它作为边界检测。即只要表不为空，那么它就能与[X|Y]匹配，当表为空时，就不能匹配，表示已经到达的边界条件。

我们还可以在第二个项目后面使用“|”，事实上，|前面的都是项目，后面的是一个表。

?- [One, Two | T] = [apple, sprouts, fridge, milk].
One = apple 
Two = sprouts 
T = [fridge, milk]

请注意下面的例子中变量是如何与结构绑定的。内部变量现实除了变量之间的联系。


?- [X,Y|T] = [a|Z].
X = a 
Y = _01 
T = _03
Z = [_01 | _03]


这个例子中，右边列表中的Z代表其表尾，与左边列表中的[Y|T]绑定。

?- [H|T] = [apple, Z]. 
H = apple
T = [_01]
Z = _01 


上面的例子中，左边的表为T绑定为右边的表尾[Z]。

请仔细研究最后的这两个例子，表的联合对编制列表谓词是很有帮助的。

表可以看作是表头项目与表尾列表组合而成。而表尾列表又是由同样的方式组成的。所以表的定义本质上是递归定义。我们来看看下面的例子。

?- [a|[b|[c|[d|[]]]]] = [a,b,c,d]. 
yes

前面我们说过，列表是一种特殊的结构。最后的这个例子让我们对表的理解加深了。它事实上是一个有两个参数的谓词。第一个参数是表头项目，第二个参数是表尾列表。如果我们把这个谓词叫做dot/2的话，那么列表[a，b，c，d]可以表示为：


dot(a,dot(b,dot(c,dot(d,[])))) 


事实上，这个谓词是存在的，至少在概念上是这样，我们用“.”来表示这个谓词，读作dot。

我们可以使用内部谓词display/1来显示dot，它和谓词write/1大致上相同，但是当它的参数为列表时将使用dot语法来显示列表。



?- X = [a,b,c,d], write(X), nl, display(X), nl. 
 [a,b,c,d] 
.(a,.(b,.(c,.d(,[])))) 
?- X = [Head|Tail], write(X), nl, display(X), nl.
 [_01, _02] 
.(_01,_02)
?- X = [a,b,[c,d],e], write(X), nl, display(X), nl.
 [a,b,[c,d],e]
.(a,.(b,.(.(c,.(d,[])),.(e,[])))) 



从这个例子中我们可以看出为什么不使用结构的语法来表示列表。因为它太复杂了，不过实际上列表就是一种嵌套式的结构。这一点在我们编制列表的谓词时应该牢牢地记住。

我们可以很容易地写出递归的谓词来处理列表。首先我们来编写谓词member/2，它能够判断某个项目是否在列表中。

首先我们考虑边界条件，即最简单的情况。某项目是列表中的元素，如果此项目是列表的表头。写成Prolog语言就是：
```
member(H,[H|T]).
```
从这个子句我们可以看出含有变量的事实可以当作规则使用。

第二个子句用到了递归，其意义是：如果项目是某表的表尾tail的元素，那么它也是此列表的元素。
```
member(X,[H|T]) :- member(X,T). 
```
完整的谓词如下：
```
member(H,[H|T]). 
member(X,[H|T]) :- member(X,T).
```
请注意两个member/2谓词的第二个参数都是列表。由于第二个子句中的T也是一个列表，所以可以递归地进行下去。

```
?- member(apple, [apple, broccoli, crackers]).
yes 
?- member(broccoli, [apple, broccoli, crackers]). 
yes
?- member(banana, [apple, broccoli, crackers]).
no 
```

下面是member/2谓词的单步运行结果。

我们的询问是 

```
?- member(b, [a,b,c]).
1-1 CALL member(b,[a,b,c])
```

目标模板与第一个子句不匹配，因为b不是[a，b，c]列表的头部。但是它可以与第二个子句匹配。

```
1-1 try (2) member(b,[a,b,c])
```

第二个子句递归调用member/2谓词。

```
2-1 CALL member(b,[b,c])
```

这时，能够与第一个子句匹配了。

```
2-1 EXIT (1) member(b,[b,c]) 
```

于是一直成功地返回到我们的询问子句。

```
1-1 EXIT (2) member(b,[a,b,c]) 
yes
```

和大部分Prolog的谓词一样，member/2有多种使用方法。如果询问的第一参数是变量，member/2可以把列表中所有的项目找出来。


?- member(X, [apple, broccoli, crackers]).
X = apple ; 
X = broccoli ;
X = crackers ;
no


下面我们将使用内部变量来跟踪member/2的这种使用方法。请记住每一层递归都会产生自己的变量，但是它们之间通过模板联合在一起。

由于第一个参数是变量，所以询问的模板能够与第一个子句匹配，并且变量X将绑定为表头。回显出X的值后，用户使用分号引起回溯，Prolog继续寻找更多的答案，与第二个子句进行匹配，这样就形成了递归调用。

我们的询问是 


?- member(X,[a,b,c]).


当X=a时，目标能够与第一个子句匹配。

```
1-1 CALL member(_0,[a,b,c]) 
1-1 EXIT (1) member(a,[a,b,c]) 
X = a ;
```

回溯时释放变量，并且开始考虑第二条子句。

```
1-1 REDO member(_0,[a,b,c]) 
1-1 try (2) member(_0,[a,b,c])
```

第二层也成功了，和第一层相同。

```
2-1 CALL member(_0,[b,c]) 
2-1 EXIT (1) member(b,[b,c]) 
1-1 EXIT member(b,[a,b,c]) 
X = b ;
```

继续第三层，和前面相似。

```
2-1 REDO member(_0,[b,c]) 
2-1 try (2) member(_0,[b,c])
3-1 CALL member(_0,[c]) 
3-1 EXIT (1) member(c,[c]) 
2-1 EXIT (2) member(c,[b,c]) 
1-1 EXIT (2) member(c,[a,b,c]) 
X = c ;
```


下面试图找到空表中的元素。而空表不能与两个子句中的任何一个表匹配，所以查询失败了。

```
3-1 REDO member(_0,[c]) 
3-1 try (2) member(_0,[c])
4-1 CALL member(_0,[])
4-1 FAIL member(_0,[])
3-1 FAIL member(_0,[c])
2-1 FAIL member(_0,[b,c])
1-1 FAIL member(_0,[a,b,c])
no
```

下面再介绍一个有用的列表谓词。它能够把两个列表连接成一个列表。此谓词是append/3。第一个参数和第二个参数连接的表为第三个参数。例如：

```
?- append([a,b,c],[d,e,f],X). 
X = [a,b,c,d,e,f] 
```

这个地方有一个小小的麻烦，因为最基本的列表操作只能取得列表的头部，而不能在内表尾部添加项目。append/3使用递归地减少第一个列表长度的方法来解决这个问题。

边界条件是：如果空表与某个表连接就是此表本身。

```
append([],X,X). 
```

而递归的方法是：如果列表[H|T1]与列表X连接，那么新的表的表头为H，表尾则是列表T1与X连接的表。

```
append([H|T1],X,[H|T2]) :- append(T1,X,T2)
```

完整的谓词就是：

```
append([],X,X). 
append([H|T1],X,[H|T2]) :- append(T1,X,T2).
```

Prolog真正独特的地方就在这里了。在每一层都将有新的变量被绑定，它们和上一层的变量联合起来。第二条子句的递归部分的第三个参数T2，与其头部的第三个参数的表尾相同，这种关系在每一层中都是使用变量的绑定来体现的。下面是跟踪运行的结果。

我们的询问是： 

```
?- append([a,b,c],[d,e,f],X).
1-1 CALL append([a,b,c],[d,e,f],_0)
X = _0
2-1 CALL append([b,c],[d,e,f],_5)
_0 = [a|_5]
3-1 CALL append([c],[d,e,f],_9)
_5 = [b|_9]
4-1 CALL append([],[d,e,f],_14)
_9 = [c|_14]
```

把变量的所有联系都考虑进来，我们可以看出，这时变量X有如下的绑定值。

```
X = [a|[b|[c|_14]]]
```

到达了边界条件，因为第一个参数已经递减为了空表。与第一条子句匹配时，变量_14绑定为表[d，e，f]，这样我们就得到了X的值。

```
4-1 EXIT (1) append([],[d,e,f],[d,e,f])
3-1 EXIT (2) append([c],[d,e,f],[c,d,e,f])
2-1 EXIT (2) append([b,c],[d,e,f],[b,c,d,e,f])
1-1 EXIT (2)append([a,b,c],[d,e,f],[a,b,c,d,e,f])
X = [a,b,c,d,e,f] 
```

和member/2一样，append/3还有别的使用方法。下面这个例子显示了append/3是如何把一个表分解的。

```
?- append(X,Y,[a,b,c]). 
X = [] 
Y = [a,b,c] ;
X = [a] 
Y = [b,c] ;
X = [a,b] 
Y = [c] ;
X = [a,b,c] 
Y = [] ;
no 
```

# 使用列表

现在有了能够处理列表的谓词，我们就可以在游戏中使用它们。例如使用谓词loc_list/2代替原来的谓词location/2来储存物品，然后再重新编写location/2来完成与以前同样的操作。只不过是以前是通过location/2寻找答案，而现在是使用location/2计算答案了。这个例子从某种程度上说明了Prolog的数据与过程之间没有明显的界限。无论是从数据库中直接找到答案，或是通过一定的计算得到答案，对于调用它的谓词来说都是一样的。

```
location(X,Y):- loc_list(List, Y), member(X, List). 
```

当某个物品被放入房间时，需要修改此房间的loc_lists，我们使用append/3来编写谓词add_thing/3：

```
add_thing(NewThing, Container, NewList):- 
loc_list(OldList, Container), 
append([NewThing],OldList, NewList). 
```

其中，NewThing是要添加的物品，Container是此物品的位置，NewList是添加物品后的列表。

```
?- add_thing(plum, kitchen, X). 
X = [plum, apple, broccoli, crackers] 
```

当然，也可以直接使用[Head|Tail]这种列表结构来编写add_thing/3。

```
add_thing2(NewThing, Container, NewList):- 
loc_list(OldList, Container), 
NewList = [NewThing | OldList].
```

它和前面的add_thing/3功能相同。

```
?- add_thing2(plum, kitchen, X). 
X = [plum, apple, broccoli, crackers]
```

我们还可以对add_thing2/3进行简化，不是用显式的联合，而改为在子句头部的隐式联合。

```
add_thing3(NewTh, Container,[NewTh|OldList]) :-
loc_list(OldList, Container).
```

它同样能完成我们的任务。

```
?- add_thing3(plum, kitchen, X).
X = [plum, apple, broccoli, crackers]
```

下面的put_thing/2，能够直接修改动态数据库，请自己研究一下。

```
put_thing(Thing,Place) :- 
retract(loc_list(List, Place)), 
asserta(loc_list([Thing|List],Place)).
```

到底是使用多条子句，还是使用列表方式，这完全有你的编程习惯来决定。有时使用Prolog的自动回溯功能较好，而有时则使用递归的方式较好。还有些较为复杂的情况，需要同时使用子句和列表来表达数据。 这就必须掌握两种数据表达方式之间的转换。

把一个列表转换为多条子句并不难。使用递归过程逐步地把表头asserts到数据库中就行了。下面的例子把列表转化为了stuff的一系列子句。

```
break_out([]). 
break_out([Head | Tail]):- 
assertz(stuff(Head)), 
break_out(Tail).
?- break_out([pencil, cookie, snow]). 
yes 
?- stuff(X). 
X = pencil ;
X = cookie ;
X = snow ;
no
```

把多条事实转化为列表就困难多了。因此Prolog提供了一些内部谓词来完成这个任务。最常用的谓词是findall/3，它的参数意义如下：

参数1： 结果列表的模板。

参数2： 目标模板。

参数3： 结果列表。

findall/3自动地寻找目标，并把结果储存到一个列表中。使用它可以方便的把stuff子句还原成列表。

```
?- findall(X, stuff(X), L).
L = [pencil, cookie, snow]
```

下面把所有与厨房相连的房间找出来。

```
?- findall(X, connect(kitchen, X), L). 
L = [office, cellar, 'dining room']
```

最后我们再来看一个复杂的例子：

```
?- findall(foodat(X,Y), (location(X,Y) , edible(X)), L).
L = [foodat(apple, kitchen), foodat(crackers, kitchen)] 
```

它找出了所有能吃的东西及其位置，并把结果放到了列表中。