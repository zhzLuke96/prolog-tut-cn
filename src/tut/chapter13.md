# 操作符

我们已经学习过了Prolog的数据结构,它的形式如下：

```
functor(arg1,arg2,...,argN).
```

这是Prolog的唯一的数据结构，但是Prolog允许这种数据结构有其它的表达方法（仅仅是表达方法不同）。这种表达方法有时候更加接近我们的习惯，正如列表的两种表达法一样。现在要介绍的是操作符语法。

以前曾经介绍了数学符号，在这一章我们将看到它和Prolog的数据结构是等价的，并且学习如何定义自己的操作符。

所有的数学操作符都是Prolog的基本符号，例如-/2、+/2、-/1。使用谓词display/1可以看到它们的标准的语法结构。

```
?- display(2 + 2). 
+(2,2) 
?- display(3 4 + 6). 
+((3,4),6) 
?- display(3 (4 + 6)). 
 (3,+(4,6))
```

你可以把任何谓词定义为操作符的形式，例如，如果我们把location/2定义为了操作符，那么我们就可以用：

```
apple location kitchen. 
```

来代替

```
location(apple, kitchen).
```

注意：这只是书写形式上的不同，在Prolog进行模式匹配时它们都是一样的。

操作符有三种形式：

中缀（infix）：例如3+4

前缀（prefix）：例如-7

后缀（postfix）：例如8 factorial

每个操作符有不同的优先权值，从1到1200。当某句中有多个操作符时，优先权高的将先被考虑。优先权值越小优先权越高。

使用内部谓词op/3来定义操作符，它的三个参数分别是：优先权、结合性、操作符名称。

结合性使用模板来定义，例如中缀操作符使用“xfx”来定义。“f”表示操作符的位置。

下面我们将重新编写location/2谓词，并改名为is_in/2。

```
is_in(apple, room(kitchen)). 
```

使用op/3谓词把is_in/2定义为操作符，优先权值为35。

```
?- op(35,xfx,is_in). 
```

下面是我们的询问。

```
?- apple is_in X. 
X = room(kitchen)
?- X is_in room(kitchen).
X = apple 
```

同样可以使用操作符来定义事实。

```
banana is_in room(kitchen). 
```

为了证明这两种数据结构是等价，我们可以进行如下的比较：

```
?- is_in(banana, room(kitchen)) = banana is_in room(kitchen). 
yes 
```

使用display/1可以清楚地看到这一点。

```
?- display(banana is_in room(kitchen)). 
is_in(banana, room(kitchen))
```


下面再把room/1定义为前缀操作符。前缀操作符的模板是fx。它的优先权应该比is_in的高。这里取33。

```
?- op(33,fx,room). 
?- room kitchen = room(kitchen). 
yes 
?- apple is_in X. 
X = room kitchen
```

使用上面的两个操作符，我们可以使用如下的方式定义事实。


```
pear is_in room kitchen. 
?- is_in(pear, room(kitchen)) = pear is_in room kitchen. 
yes 
?- display(pear is_in room kitchen).
is_in(pear, room(kitchen))
```


注意如果操作符的优先权搞错了，那就全部乱了套。例如：如果room/1的优先权低于is_in/2，那么上面的结构就变成了下面这个样子：

```
room(is_in(apple, kitchen)) 
```

不但如此，Prolog的联合操作也将出现问题。所以一定要仔细考虑操作符的优先权。

最后我们来定义后缀操作符，使用模板xf。

```
?- op(33,xf,turned_on).
flashlight turned_on. 
?- turned_on(flashlight) = flashlight turned_on. 
yes 
```

使用操作符可以使程序更容易阅读。

在我们的命令驱动的“寻找Nani”游戏中，为了使发出的命令更接近自然语言，可以使用操作符来定义。

```
goto(kitchen) -> goto kitchen. 
turn_on(flashlight) -> turn_on flashlight. 
take(apple) -> take apple. 
```

虽然这还不是真正的自然语言，可是比起带括号的来还是方便多了。

当操作符的优先权相同时，Prolog必须决定是从左到右还是从右到左地读入操作符。这就是操作符的左右结合性。有些操作符没有结合性，如果你把两个这种操作符放到一起将产生错误。

下面是结合性的模板：

```
Infix: 
xfx non-associative （没有结合性） 
xfy right to left 
yfx left to right 
Prefix 
fx non-associative 
fy left to right 
Postfix: 
xf non-associative 
yf right to left 
```

前面所定义的谓词is_in/2没有结合性，所以下面的句子是错误的。

```
key is_in desk is_in office. 
```

为了表示这种嵌套关系，我们可以使用从右到左的结合性。


```
?- op(35,xfy,is_in). 
yes 
?- display(key is_in desk is_in office). 
is_in(key, is_in(desk, office))
```


如果使用从左到右的结合性，我们的结果将不同。

```
?- op(35,yfx,is_in). 
yes 
?- display(key is_in desk is_in office). 
is_in(is_in(key, desk), office)
```

但是使用括号可以改变这种结合性：

```
?- display(key is_in (desk is_in office)). 
is_in(key, is_in(desk, office)) 
```

由许多内部谓词都定义为了中缀操作符。因此我们可以使用“arg1 predicate arg2. ”来代替predicate(arg1,arg2) 。

我们所见过的数学符号就是如此，例如+-/。但是一定要牢记这只是表达形式上的区别，因此3+4和7是不一样的，它就是+（3，4）。

只有一些特殊的内部谓词（例如is/2）进行真正的数学运算。is/2计算它右边表达式的值，并让左边绑定为此值。它与联合（=）谓词是不同的，=只进行联合而不进行计算。

```
?- X is 3 + 4. 
X = 7 
?- X = 3 + 4.
X = 3 + 4
?- 10 is 5 2. 
yes
?- 10 = 5 2. 
no 
?- X is 3 4 + (6 / 2). 
X = 15
?- X = 3 4 + (6 / 2). 
X = 3 4 + (6 / 2)
X = 15 
?- 3 [4 + (6 / 2) = +(: create](3,4),/(6,2)).
yes 
```

只有当使用is/2来计算时，数学操作符才显示出其不同之处，而一般情况下与其它的谓词没有任何区别。

```
?- X = 3 4 + likes(john, 6/2).
X = 3 4 + likes(john, 6/2). 
?- X is 3 4 + likes(john, 6/2). 
error
```

我们已经知道Prolog的程序是由一系列的子句构成的。其实这些子句也是使用操作符书写的Prolog的数据结构。这里的操作符是":-"，它是中缀操作符，有两个参数。

```
:-(Head, Body). 
```

Body也是由操作符书写的数据结构。这里的操作符为","，它表示并且的意思，所以Body的形式如下：

```
,(goal1, ,(goal2,,goal3)) 
```

好像看不明白，操作符","与分隔符","无法区别，所以我们就是用"&"来代替操作符","，于是上面的形式就变成了下面这个样子了。

```
&(goal1, &(goal2, & goal3)) 
```

下面的两种形式表达的意思是相同的。

```
head :- goal1 & goal2 & goal3. 
:-(head, &(goal1, &(goal2, & goal3))). 
```

实际上是下面的形式：


```
head :- goal1 , goal2 , goal3. 
:-(head, ,(goal1, ,(goal2, , goal3))).
```


数学操作符不但可以用来计算，还有许多其它的用途。例如write/1，只能有一个参数，当我们想同时显示两个变量的值时， 就可以使用下面的方法。

```
?- X = one, Y = two, write(X-Y).
one - two
```

因为X-Y实际上是一个数据结构，所以它相对于write来说就只是一个参数。

当然其它的数学操作符也能完成相同的功能，例如/。在有些Prolog的版本中干脆引入了“：”这个操作符来专门完成这种任务，有了它我们可以很方便的书写复杂的数据结构了。

```
object(apple, size:small, color:red, weight:1). 
?- object(X, size:small, color:C, weight:W). 
X = apple
C = red 
W = 1
```

这里我们使用size:small，代替了原来的size(small)，实际上“：”是中缀操作符，它的原始表达形式是:(size,small)。

从这一章所介绍的内容我们可以发现Prolog的程序实际上也是一种数据结构，只不过是使用专门的操作符连接起来的。那么到现在为止，我们所学习过的所有Prolog内容：事实、规则、结构、列表等的实质都是一样的，这也正是Prolog与其它语言的最大区别---程序与数据的高度统一。正是它的这种极其简洁的表达形式，使得它被广泛地应用于人工智能领域。 

