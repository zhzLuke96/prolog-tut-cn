# 联合

Prolog的最强大的功能之一就是它内建了模式匹配的算法----`联合(Unification)`。以前我们所介绍的例子中的联合都是较为简单的。现在来仔细研究一下联合。下表中列出了联合操作的简要情况。

* `变量`&`任何项目`: 变量可以与任何项目绑定，其中也包括变量 
* `原始项目`&`原始项目`: 两个原始项目（原子或整数）只有当它们相同时才能联合。 
* `结构`&`结构`: 如果两个结构的每个相应的参数能联合，那么这两个结构可以联合。 

为了更清楚地介绍联合操作，我们将使用Prolog的内部谓词`‘=/2’`，此谓词当它的两个参数能够联合时成功，反之则失败。它的语法如下：
```prolog
=(arg1, arg2) 
```
为了方便阅读，也可以写成如下形式：
```prolog
arg1 = arg2 
```
* 注意：此处的等号在Prolog中的意义与其他语言中的不同。它不是数学运算符或者赋值符。

使用`=`进行联合操作与Prolog使用目标与子句联合时相同。在回溯时，变量将被释放。

下面举了几个最简单的联合的例子。

```prolog
?- a = a.
yes 
?- a = b.
no 
?- location(apple, kitchen) = location(apple, kitchen). 
yes 
?- location(apple, kitchen) = location(pear, kitchen). 
no
?- a(b,c(d,e(f,g))) = a(b,c(d,e(f,g))).
yes 
?- a(b,c(d,e(f,g))) = a(b,c(d,e(g,f))).
no 
```

在下面的例子中使用的变量，注意变量是如何绑定为某个值的。

```prolog
?- X = a. 
X = a 
?- 4 = Y. 
Y = 4 
?- location(apple, kitchen) = location(apple, X).
X = kitchen 
```

当然也可以同时使用多个变量。

```prolog
?- location(X,Y) = location(apple, kitchen).
X = apple
Y = kitchen 
?- location(apple, X) = location(Y, kitchen). 
X = kitchen
Y = apple
```

变量之间也可以联合。每个变量都对应一个Prolog的内部值。当两个变量之间进行联合时，Prolog就把它们标记为相同的值。在下面的例子中，我们假设Prolog使用`‘_nn’`，其中`‘n’`为数字，代表没有绑定的变量。

```prolog
?- X = Y.
X = _01
Y = _01 
?- location(X, kitchen) = location(Y, kitchen).
X = _01
Y = _01
```

Prolog记住了被绑定在一起的变量，这将在后面的绑定中反映出来，请看下面的例子。 

```prolog
?- X = Y, Y = hello.
X = hello 
Y = hello 
?- X = Y, a(Z) = a(Y), X = hello.
X = hello
Y = hello
Z = hello
```

最后的这个例子能够很好地说明Prolog的变量绑定与其他语言中的变量赋值的区别。请仔细分析下面的询问。

```prolog
?- X = Y, Y = 3, write(X).
3
X = 3 
Y = 3
?- X = Y, tastes_yucky(X), write(Y).
broccoli
X = broccoli 
Y = broccoli
```

当两个含变量的结构之间进行联合时，变量所取的值使得这两个结构相同。

```prolog
?- X = a(b,c).
X = a(b,c)
?- a(b,X) = a(b,c(d,e)).
X = c(d,e) 
?- a(b,X) = a(b,c(Y,e)).
X = c(_01,e) 
Y = _01
```

无论多么复杂，Prolog都将准确地记录下变量之间的关系，一旦某个变量绑定为某值，与之有关的变量都将改变。

```prolog
?- a(b,X) = a(b,c(Y,e)), Y = hello.
X = c(hello, e) 
Y = hello 
?- food(X,Y) = Z, write(Z), nl, tastes_yucky(X), edible(Y), write(Z). food(_01,_02)
food(broccoli, apple) 
X = broccoli 
Y = apple
Z = food(broccoli, apple)
```

如果在两次绑定中变量的值发生冲突，那么目标就失败了。

```prolog
?- a(b,X) = a(b,c(Y,e)), X = hello. 
no
```

上面的例子中，第二个子目标失败了，因为找不到一个y的值使得hello与c(Y,e)之间能够联合。而下面的例子是成功的。

```prolog
?- a(b,X) = a(b,c(Y,e)), X = c(hello, e). 
X = c(hello, e)
Y = hello
```

如果变量不能绑定为某一可能的值，那么联合也将失败。

```prolog
?- a(X) = a(b,c).
no 
?- a(b,c,d) = a(X,X,d).
no 
```

下面的这个例子很有趣，请你研究一下吧。

```prolog
?- a(c,X,X) = a(Y,Y,b). 
no
```

你明白为什么这个例子失败么？第一个参数的绑定使得Y绑定为c，第二个参数之间的绑定告诉Prolog变量`X`与`Y`的值相同，那么X也绑定c，而最后一个参数的绑定使得X为b，有矛盾，所以失败了。这就是说没有什么办法能使得这两个结构联合。

匿名变量`_`不会绑定为任何值。所以也不要求它所出现的位置的值必须相同。

```prolog
?- a(c,X,X) = a(_,_,b). 
X = b
```

如果使用`=`那么联合操作时显式的。而Prolog在使用子句与目标匹配时的联合则是隐式的。

