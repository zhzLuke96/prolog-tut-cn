# 数据管理
Prolog的程序就是谓词的数据库，我们通常把这些谓词的子句写入Prolog的程序中的。在运行Prolog时，解释器首先把所有的子句调入到内存中。所以这些写在程序中的子句都是固定不变的。那么有没有办法动态地控制内存中的子句呢？Prolog提供了这方面的功能。这就意味着，Prolog程序在运行过程中，还能够改变它自己。它使用一些内部谓词来完成这个功能。最重要的几个谓词如下：

```prolog
asserta(X)
```

把子句X当作此子句的谓词的第一个子句加入到动态数据库中。它和I/O内部谓词的流程控制相同。回溯是失败，并且不会取消它所完成的工作。例如：如果内存中已经有了下面的几个事实：

```prolog
people(a).
people(b).
people(c).
```

如果运行了asserta(people(d))之后，内存中的people/1的子句就变成了下面这个样子：

```prolog
people(d).
people(a).
people(b).
people(c).
asserta(X)
```

和asserta/1的功能类似，只不过它把X子句追加为最后一个子句。 

```prolog
retract(X)
```

把子句X从动态数据库中删除。此操作也是永久性的，也就是说回溯的时候不能撤销此操作。

* **在swi prolog中需要对动态操作的谓词名进行声明，例如前面如果希望能够动态修改people/1的子句，需要在程序最前面运行：**

```prolog
:-dynamic people/1.
```

能够动态的修改数据库显然是很重要的。它有助于我们完成“寻找Nani”。使用这些谓词，我们可以很方便地改变玩家和物体的位置。

下面我们来设计goto/1这个谓词，它能够把玩家从一个房间移到另一个房间。我们采取从顶向下的设计方法，这和我们设计look/0时的方法不同。

当玩家键入了goto命令之后，首先判断他能否去他想去的位置，如果可以，则移动到此位置，并把此位置的情况告诉玩家。

```prolog
goto(Place):- 
    can_go(Place), 
    move(Place), 
    look.
```

下面来一步一步地完成这些还没定义的谓词。

玩家所能够去的房间的条件是：此房间和玩家所在的房间是相通的，即：

```prolog
can_go(Place):- 
    here(X), 
    connect(X, Place). 
```

我们可以马上测试一下，（假定玩家在厨房）

```prolog
?- can_go(office). 
yes 
?- can_go(hall).
no
```

现在can_go/1已经可以工作了，但是如果它在失败时能够给出一条消息就很好了。所以还需要另外增加一条子句，如果第一条子句失败，也就是说不能去那个房间时，第二个子句将显示一条消息。

```prolog
can_go(Place):- 
    here(X), 
    connect(X, Place). 
can_go(Place):- 
    write('You can''t get there from here.'),
    nl, fail. 
```

注意第二条子句最后的那个fail，因为当目标与第二条子句匹配时，表示不能去此房间，所以它应该返回fail。这次的运行结果比上次要好多了。

```prolog
?- can_go(hall). 
You can't get there from here. 
no 
```

下面再来设计move/1谓词，它必须能够动态的修改数据库中的here谓词的子句。首先把玩家的旧位置的数据删除，再加上新位置的数据。

```prolog
move(Place):- 
    retract(here(X)), 
    asserta(here(Place)). 
```

现在我们可以使用goto/1在游戏的所有房间里走动了。

```prolog
?- goto(office).
You are in the office 
You can see: 
desk 
computer 
You can go to:
hall 
kitchen 
yes 
?- goto(hall). 
You are in the hall 
You can see:
You can go to:
dining 
room
office 
yes 
?- goto(kitchen).
You can't get there from here.
no 
```

好像有点游戏的味道了。:)

下面开始编写take和put谓词，使用这两个谓词，我们可以拿取或丢弃游戏中的物品。使用have/1谓词来储存玩加身上所携带的物品，一开始，玩家身上没有物品，所以我们没有在程序的事实中定义have/1谓词。

```prolog
take(X):- 
    can_take(X), 
    take_object(X). 
```

其中can_take(X)的设计方法与can_go/1相同。

```prolog
can_take(Thing) :- 
    here(Place), 
    location(Thing, Place).

can_take(Thing) :- 
    write('There is no '), 
    write(Thing), 
    write(' here.'), 
    nl, fail. 
```

take_object/1与move/1类似，它首先删除一条location/1的子句，然后添加一条have/1的子句。这反映出了物品从其所在位置移到玩家身上的过程。

```prolog
take_object(X) :- 
    retract(location(X,_)), 
    asserta(have(X)),
    write('taken'),
    nl.
```

正如我们所看到的那样，Prolog子句中的变量全部都是局部变量。与其他的语言不同，在Prolog中没有全局变量，取而代之的是Prolog的数据库。它使得所有的Prolog子句能够共享信息。而asserts和retracts就是控制这些全局数据的工具。

使用全局数据有助于在子句之间快速的传递信息。不过，这种方式隐藏了子句之间的调用关系，所以一旦程序出错，是很难找到原因的。

我们完全也可以不使用assert和retract来完成上述的功能，不过这就需要把信息作为参数在子句中传递。在这种情况下，游戏中的状态将使用谓词的参数来储存，而不是谓词的子句。每一个谓词的入口参数是当前状态，而出口参数则为此谓词修改后的状态，状态在谓词之间传递，从而达到了预期的目的。我们还将在以后的章节中介绍这种方法。

我们现在所编写的程序并不都是从纯逻辑的考虑出发的，不过你可以看出使用Prolog编写这个游戏的过程非常自然，并没有什么晦涩难懂的东西。

一般情况下，asserta等谓词是不会在回溯的时候还原数据库的，所以上面的几个数据管理谓词的内部流程与I/O谓词相同，不过我们可以很容易的编写出能够在回溯时取消修改的谓词。

```prolog
backtracking_assert(X):- 
    asserta(X). 
backtracking_assert(X):- 
    retract(X),fail.
```

首先第一个子句被运行，在数据库中添加一条X子句。当其后的目标失败而产生回溯时，第二个子句将被调用，于是它把第一个子句的操作给取消了，又把子句X从数据库中上除了。 