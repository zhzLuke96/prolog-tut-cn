# 数据结构
到目前为止，所介绍的事实、查询以及规则都使用的是最简单的数据结构。谓词的参数都是原子或者整数，这些都是Prolog的基本组成元素。例如我们所使用过的原子有:

```prolog
office, apple flashlight, nani
```

通过把这些最简单的数据组合起来，可以生成复杂的数据类型，我们称之为结构。结构由结构名和一定数量的参数组成。这与以前所学过的目标和事实是一样的。

```prolog
functor(arg1,arg2,...) 
```

结构的参数可以是简单的数据类型或者是另一个结构。现在在游戏中的物品都是由原子表示的，例如，desk、apple。但是使用结构可以更好的表达这些东西。下面的结构描述了物品的颜色、大小以及重量。

```prolog
object(candle, red, small, 1).
object(apple, red, small, 1).
object(apple, green, small, 1).
object(table, blue, big, 50). 
```

这些结构可以直接取代原来的location/2中的参数。但是这里我们再定义一个谓词location_s/2。注意，虽然定义的结构较为复杂，但是它仍然是location_s/2的一个参数。

```prolog
location_s(object(candle, red, small, 1), kitchen).
location_s(object(apple, red, small, 1), kitchen). 
location_s(object(apple, green, small, 1), kitchen).
location_s(object(table, blue, big, 50), kitchen). 
```

Prolog的变量是没有数据类型之分的，所以它可以很容易的绑定为结构，如同它绑定为原子一样。事实上，原子就是没有参数的最简单的结构。因此可以有如下的询问。

```prolog
?- location_s(X, kitchen). 
X = object(candle, red, small, 1) ;
X = object(apple, red, small, 1) ;
X = object(apple, green, small, 1) ;
X = object(table, blue, big, 50) ;
no
```

我们还可以让变量绑定为结构中的某些参数，下面的询问可以找出厨房中所有红色的东西。

```prolog
?- location_s(object(X, red, S, W), kitchen).
X = candle 
S = small
W = 1 ;
X = apple
S = small 
W = 1 ;
no
```

如果不关心大小和重量，可以使用下面的询问，其中变量‘_’是匿名变量。

```prolog
?- location_s(object(X, red, _, _), kitchen). 
X = candle ;
X = apple ;
no
```

使用这些结构，可以使得游戏更加真实。例如，我们可以修改以前所编写的can_take/1谓词，使得只有较轻的物品才能被玩家携带。

```prolog
can_take_s(Thing) :-
here(Room), 
location_s(object(Thing, _, small,_), Room). 
```

同时，也可以把不能拿取某物品的原因说得更详细一些，现在有两个拿不了物品的原因。为了让Prolog在回溯时不把两个原因同时显示出来，我们为每个原因建立一条子句。这里要用到内部谓词not/1，它的参数是一个目标，如果此目标失败，则它成功；目标成功则它失败。例如，

```prolog
?- not( room(office) ). 
no
?- not( location(cabbage, 'living room') ) 
yes
```

注意，在Prolog中的not的意思是：不能通过当前数据库中的事实和规则推出查询的目标。下面是使用not重新编写的can_take_s/1。

```prolog
can_take_s(Thing) :- 
here(Room),
location_s(object(Thing, _, small, _), Room).
can_take_s(Thing) :-
here(Room),
location_s(object(Thing, _, big, _), Room),
write('The '), write(Thing), 
write(' is too big to carry.'), nl,
fail.
can_take_s(Thing) :-
here(Room),
not (location_s(object(Thing, _, _, _), Room)),
write('There is no '), write(Thing), write(' here.'), nl,
fail.
```

下面来试试功能，假设玩家在厨房里。

```prolog
?- can_take_s(candle).
yes 
?- can_take_s(table).
The table is too big to carry. 
no
?- can_take_s(desk). 
There is no desk here.
no 
```

原来的list_things/1谓词也可以加上一些功能，下面的list_things_s/1不但可以列出房间中的物品，还可以给出它们的描述。

```prolog
list_things_s(Place) :- 
location_s(object(Thing, Color, Size, Weight),Place),
write('A '),write(Size),tab(1),
write(Color),tab(1),
write(Thing), write(', weighing '),
write(Weight), write(' pounds'), nl,
fail.
list_things_s(_)
```

它的回答令人满意多了。

```prolog
?- list_things_s(kitchen). 
A small red candle, weighing 1 pounds 
A small red apple, weighing 1 pounds
A small green apple, weighing 1 pounds 
A big blue table, weighing 50 pounds 
yes
```

如果你觉得使用1 pounds不太准确的话，我们可以再使用另一个谓词来解决此问题。

```prolog
write_weight(1) :- write('1 pound'). 
write_weight(W) :- W > 1, write(W), write(' pounds').
```

下面试试看

```prolog
?- write_weight(4). 
4 pounds 
yes 
?- write_weight(1). 
1 pound 
yes
```

第一个子句中不需要使用W=1这样的判断，我们可以直接把１写到谓词的参数中，因为只有为１时是使用单数，其他情况下都使用复数。第二个子句中需要加入W>1，要不然当重量为１时两条子句就同时满足。

结构可以任意的嵌套，下面使用dimension结构来描述物体的长、宽、高。

```prolog
object(desk, brown, dimension(6,3,3), 90).
```

当然，也可以这样来表达物品的特性

```prolog
object(desk, color(brown), size(large), weight(90)) 
```

下面是针对它的一条查询。

```prolog
location_s(object(X, _, size(large), _), office). 
```

要注意变量的位置哟，不要搞混了。