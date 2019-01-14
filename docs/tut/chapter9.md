# 递归
递归的确是一种功能强大的编程算法，现在绝大部分的程序语言都支持函数的递归调用，Prolog也不例外，而且如果没有递归，Prolog就不能叫做Prolog了。

在Prolog中，当某个谓词的目标中包含了此谓词本身时，Prolog将进行递归调用。

正如前面所述的，某一规则被调用时，Prolog使用新的变量为此规则的body部分建立新的查询。由于每次的查询都是独立的，所以某一规则调用其自身与调用其他规则没有任何区别。

任何语言中的递归定义都包括两个部分：`边界条件`与`递归部分`。

边界条件定义最简单的情况。而递归部分，则首先解决一部分问题，然后再调用其自身来解决剩下的部分，每一次都将进行边界检测，如果剩下的部分已经是边界条件中所定义的情况时，那么递归就圆满成功了。

下面我们将定义一个能够检测某物体在其他物体中的谓词，这里将使用到递归。

以前所定义的`location/2`谓词，表述了`手电筒（flashlight）`在`桌子（desk）`里，而`桌子在办公室（office）`中。但是那时Prolog并不能判断手电筒是否在办公室中。

```prolog
?- location(flashlight, office). 
no 
```

如果使用递归，我们就可以很轻松地写出谓词`is_contained_in/2`，它能够跟踪物体的所在的位置，因此它能判断手电筒是否在办公室中。

为了让问题更加有趣一些，我们再加入一些物品，它们的位置是一层一层地嵌套的。

```prolog
location(envelope, desk). 
location(stamp, envelope).
location(key, envelope).
```

要想列出办公室中的所有物品，我们首先可以列出直接位于办公室的物品，例如桌子；然后，再列出桌子中的物品，再桌子中的物品中的物品......

如果把房间也看作一个物品的话，我们就可以很容易地写出具有两个部分的规则，它能够判断某物品是否在另一个物品中的。

如果物品T1直接位于物品T2中，则物品T1在物品T2中。(此为边界条件）

如果某一物品X直接位于T2中，而物品T1在物品X中（此处为递归调用），则物品T1在物品T2中。

用Prolog的语言来表达，上面的第一句可以写成，

```prolog
is_contained_in(T1,T2) :-
    location(T1,T2). 
```

而第二句则是，

```prolog
is_contained_in(T1,T2) :- 
    location(X,T2), 
    is_contained_in(T1,X). 
```

上面的递归很直接，请注意它是如何调用其自身的。

下面是此谓词的运行实例，

```prolog
?- is_contained_in(X, office). 
X = desk ; 
X = computer ; 
X = flashlight ; 
X = envelope ; 
X = stamp ; 
X = key ; 
no 
?- is_contained_in(envelope, office).
yes 
?- is_contained_in(apple, office).
no 
```

# 递归的工作原理
规则中所定义的变量都是局部的。这意味着每次调用某一规则时，Prolog都将为此次调用新建一个独立的变量集。因此递归第一层的变量X、T1、T2，与第二层的变量X、T1、T2的变量名虽然相同，但是它们的值却是不同的。

我们可以使用带标号的变量或者Prolog的内部变量来区分这些局部变量。一开始，查询的目标是，

```prolog
?- is_contained_in(XQ, office).
```

第一层递归的子句是：（在此使用带标号的变量来区分不同的递归级别，此处，T11表示是T1在第一层递归中的变量）

```prolog
is_contained_in(T11, T21) :-
    location(X1, T21),
    is_contained_in(T11, X1). 
```

当查询的目标与此子句匹配时，变量的绑定情况如下：

```prolog
XQ = _01 
T11 = _01 
T21 = office 
X1 = _02 
```

注意，查询目标中的变量`XQ`与`T11`同时绑定为`_01`，因此，一旦`_01`的值找到了，则`XQ`和`T11`的值也就同时找到了。

使用这些绑定后的变量，可以重写上面的子句，

```prolog
is_contained_in(_01, office) :-
    location(_02, office),
    is_contained_in(_01, _02). 
```

当locatio/2目标成功后，变量`_02`绑定为`desk`，即`_02=desk`，那么后面的递归调用就变成了，

```prolog
is_contained_in(_01, desk) 
```

这个新的目标将与`is_contained_in/2`的子句匹配，此时Prolog为本次匹配重新分配变量，此时所有产生的变量如下，

```prolog
XQ = _01 T11 = _01 T12 = _01 
T21 = office T22 = desk 
X1 = desk X2 = _03 
```

当最后的递归找了某个答案，例如`envelope`，则变量`T12`、`T11`、`XQ`将同时取为此值。下面是这个查询的详细步骤。

我们询问是， 

```prolog
?- is_contained_in(X, office).
```

递归的每一层都有自己独立的变量，但是正如调用其他的规则一样，上一层的变量会与正在调用的那一层的变量之间通过绑定联系起来，在下面的程序跟踪中，将使用Prolog的内部变量来说明，这样可以很容易知道哪些变量被绑定了。 

```prolog
1-1 CALL is_contained_in(_0, office) 
1-1 try (1) is_contained_in(_0, office)
2-1 CALL location(_0, office) 
2-1 EXIT location(desk, office) 
1-1 EXIT is_contained_in(desk, office) 
X = desk ;
2-1 REDO location(_0, office) 
2-1 EXIT location(computer, office) 
1-1 EXIT is_contained_in(computer, office) 
X = computer ;
2-1 REDO location(_0,office) 
2-1 FAIL location(_0,office) 
```

当没有更多的`location(X,office)`子句时，`is_contained_in/2`的第一条子句就失败了，Prolog将试图满足第二条子句。请注意，在下面的调用中，`location`子句没有使用以前的变量，而是一个新的内部变量，`_4`。而`T1`仍然与`_0`绑定。

```prolog
1-1 REDO is_contained_in(_0, office) 
1-1 try (2) is_contained_in(_0, office)
2-1 CALL location(_4, office) 
2-1 EXIT location(desk, office) 
```

当对`is_contained_in/2`进行一次新的调用时，与我们在解释器的提示符后面直接输入`is_contained_in(X,desk)`是完全相同的。这次调用将找出所有直接位于desk中的物品，正如上面找出直接位于office中的物品一样。

```prolog
2-2 CALL is_contained_in(_0, desk) 
2-2 try (1) is_contained_in(_0, desk)
3-1 CALL location(_0, desk) 
3-1 EXIT location(flashlight, desk) 
```

在第二层的`is_contained_in/2`中找到了`flashlight`，这个答案将被传递到最上层的`is_contained_in/2`中。

```prolog
2-2 EXIT is_contained_in(flashlight, desk) 
1-1 EXIT is_contained_in(flashlight, office) 
X = flashlight ;
```

同样，在第二层的递归中还找到了envelope。

```prolog
3-1 REDO location(_0, desk) 
3-1 EXIT location(envelope, desk) 
2-2 EXIT is_contained_in(envelope, desk) 
1-1 EXIT is_contained_in(envelope, office) 
X = envelope ;
```

找完了桌子里面的东西后，它开始找桌子里的东西的里面的东西。

```prolog
3-1 REDO location(_0, desk) 
3-1 FAIL location(_0, desk) 
2-2 REDO is_contained_in(_0, desk) 
2-2 try (2) is_contained_in(_0, desk)
3-1 CALL location(_7, desk) 
3-1 EXIT location(flashlight, desk) 
```

首先，看看flashlight里面还有没有东西，两个`is_contained_in/2`都失败了，因为在flashlight中找不到别的东西了。 

```prolog
3-2 CALL is_contained_in(_0, flashlight) 
4-1 CALL location(_0, flashlight) 
4-1 FAIL location(_0, flashlight) 
3-2 REDO is_contained_in(_0, flashlight) 
3-2 try (2) is_contained_in(_0, flashlight)
4-1 CALL location(_11, flashlight) 
4-1 FAIL location(_11, flashlight) 
3-2 FAIL is_contained_in(_0, flashlight)
```

下面，再开始找envelope中的stamp。

```prolog
3-1 REDO location(_7, desk) 
3-1 EXIT location(envelope, desk) 
3-2 CALL is_contained_in(_0, envelope) 
4-1 CALL location(_0, envelope) 
4-1 EXIT location(stamp, envelope) 
3-2 EXIT is_contained_in(stamp, envelope) 
2-2 EXIT is_contained_in(stamp, desk) 
1-1 EXIT is_contained_in(stamp, office) 
X = stamp ;
```

然后是key。

```prolog
4-1 REDO location(_0,envelope) 
4-1 EXIT location(key, envelope) 
3-2 EXIT is_contained_in(key, envelope) 
2-2 EXIT is_contained_in(key, desk) 
1-1 EXIT is_contained_in(key, office) 
X = key ;
```

再没有别的东西的，于是就一路失败回去。

```prolog
3-2 REDO is_contained_in(_0, envelope) 
3-2 try (2) is_contained_in(_0, envelope)
4-1 CALL location(_11, envelope) 
4-1 EXIT location(stamp, envelope) 
4-2 CALL is_contained_in(_0, stamp) 
5-1 CALL location(_0, stamp) 
5-1 FAIL location(_0, stamp) 
4-2 REDO is_contained_in(_0, stamp) 
4-2 try(2) is_contained_in(_0, stamp)
5-1 CALL location(_14, stamp) 
5-1 FAIL location(_14, stamp) 
4-1 REDO location(_11, envelope) 
4-1 EXIT location(key, envelope) 
4-2 CALL is_contained_in(_0, key) 
4-2 try (1) is_contained_in(_0, key)
5-1 CALL location(_0, key) 
5-1 FAIL location(_0, key) 
4-2 REDO is_contained_in(_0, key) 
4-2 try (2) is_contained_in(_0, key)
5-1 CALL location(_14, key) 
5-1 FAIL location(_14, key) 
4-1 REDO location(_7, desk) 
4-1 FAIL location(_7, desk) 
3-1 REDO location(_4, office) 
3-1 EXIT location(computer, office) 
3-2 CALL is_contained_in(_0, computer) 
4-1 CALL location(_0, computer) 
4-1 FAIL location(_0, computer) 
3-2 REDO is_contained_in(_0, computer) 
4-1 CALL location(_7, computer) 
4-1 FAIL location(_7, computer) 
3-1 REDO location(_4, office) 
3-1 FAIL location(_4, office) 
no
```

# 优化
现在我们已经接触到了Prolog程序的一些神奇的地方，它所提供的编程方式不需要考虑程序的运行流程，而是注重于逻辑关系。但是，某些情况下，为了能够是程序快速的运行，我们不得不考虑这个问题。下面是一个例子。


首先目标`location(X,Y)`将于任何`location/2`子句匹配，而目标`location(X,office)`或`location(envelope,X)`只能与某些子句匹配。


下面我们来看一看`is_contained_in/2`谓词的第二条子句的两种写法。

```prolog
is_contained_in(T1,T2):- 
    location(X,T2),
    is_contained_in(T1,X). 

is_contained_in(T1,T2):- 
    location(T1,X),
    is_contained_in(X,T2). 
```

它们都可以找到正确的答案，但是它们的运行性能将取决于我们的询问方式。当询问是`is_contained_in(X,office)`时，前者的运行速度较快。这是因为当T2绑定时，搜寻`location(X,T2)`目标将比两个变量都不绑定时容易。同样，后者却能够较快地完成查询`is_contained_in(key,X)`。


看样子，要想编出性能优越的程序还是要下一番工夫的啊。