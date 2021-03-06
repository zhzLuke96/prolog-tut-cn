# 小结

到现在为止，我们已经对`Prolog`有了一个基本的了解，现在有必要对我们所学过的知识做一个系统的总结。

- `Prolog`的程序是由一系列的事实和规则组成的数据库。
- 规则之间的调用是通过联合操作完成的，`Prolog`能够自动的完成模式匹配。
- 规则还可以调用内部谓词，例如`write/1`。
- 我们可以在`Prolog`的解释器中单独地对规则进行查询（调用）。

在`Prolog`的程序的运行流程方面我们有了如下的认识：

- 规则的运行是通过`Prolog`内建的回溯功能实现的。
- 我们可以使用内部谓词`fail`来强制实现回溯。
- 我们也可以通过加入一条参数为伪变量（下划线）无`Body`部分的子句，来实现强制让谓词成功。

我们还学习了，

- 数据库中的事实代替了一般语言中的数据结构。
- 回溯功能能够完成一般语言中的循环操作。
- 而通过模式匹配能够完成一般语言中的判断操作。
- 规则能够被单独地调试，它和一般语言中的模块相对应。
- 而规则之间的调用和一般语言中的函数的调用类似。
  有了以上的知识，我们还可以编写出一些让其它语言的程序员吃惊的小程序。下面就举一个分析家谱的程序。

假如我们把家族成员之间的父子关系和夫妻关系，以及成员的性别属性定义为基本的事实数据库，我们就可以编出许多规则来判断其他的亲戚关系了。

例如我们有如下的数据库：

```prolog
father(a,b). 
father(a,d).
father(a,t).
father(b,c).

wife(aw,a).
wife(bw,b).

male(t).
female(d).
male(c).
```

> father(a,b).表示 a 是 b 的父亲。<br>
> wife(aw,a). 表示 aw 是 a 的妻子。<br>
> male(t).表示 b 是男性。<br>
> female(d).表示 d 是女性。

上面我们并没有定义`a`、`b`、`aw`、`bw`的性别。因为通过他们和其他人的关系我们可以很容易地确定他们的性别。不过要想让`Prolog`知道他们的性别我们就要定义如下的规则。

```prolog
male(X):-father(X,_).
female(X):-wife(X,_).
```

上面的`male/1`和`female/1`的谓词名称和事实的名称相同，这并不是什么特别的情况，你可以把所有定义相同的谓词的子句之间的关系想象“或者”的关系。也就是说：`t`和`d`是男性，或者如果`X`是其他人的父亲，则它也是男性。在判断性别时，我们并不关心此人是谁的父亲，所以后面一个变量用“`_`”代替了。

好了，假如有如下的询问：

```js
?-male(t).
yes.

?-male(a).
yes.

?-male(X).
X=t;
X=c;
X=a;
X=a;
X=a;
X=b;
no.
```

最后一个询问，它虽然把所有的男性找了出来，可是它把`a`找了三次，原因很简单，因为我们有三个`father/2`的子句都包含`a`，好像不太理想，不过现在只能将就一下了，当我们学习了更多的知识后，就好解决了。

下面我们定义一些其他的亲戚关系的规则。你大概一看就能够理解。例如：`X`和`Y`是兄弟的条件是`: X`和`Y`有相同的父亲 `{father(Z,X),father(Z,Y)}`，并且他们都是男性`{male(X),male(Y)}`，最后由于`X`和`Y`可以取相同的值，所以我们不得不加上一条`X`和`Y`不是同一个人。

```prolog
grandfather(X,Y):-
        father(X,Z),
        father(Z,Y).
mother(X,Y):-
        wife(X,Z),
        father(Z,Y).
brother(X,Y):-
        father(Z,X),
        father(Z,Y),
        male(X),
        male(Y),
        X\=Y.
```

当然我们还可以加入更复杂一点的规则，

```prolog
uncle(X,Y):-
        brother(X,Z),
        father(Z,Y).
```

这个叔伯的规则`uncle/2`调用了前面的规则`brother/2`。

这里只是简单回顾一下前面所学习的知识，所以这个家族程序虽然可以使用，但是却极不完善。例如：它会把某一答案重复多次，还不能描述没有小孩的丈夫的性别。我们这样改一下会更好一点：`male(X):-wife(_,X)`。因此，规则的定义是多种多样的，到底哪种更好、哪种更快，这就是我们以后所要研究的问题之一了。
