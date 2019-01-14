# 入门

## 探索`Prolog`

`Prolog`在英语中的意思就是`Programming in LOGic`（逻辑编程）。它是建立在逻辑学的理论基础之上的，最初是运用于自然语言的研究领域。然而现在它被广泛的应用在人工智能的研究中，它可以用来建造专家系统、自然语言理解、智能知识库等。同时它对一些通常的应用程序的编写也很有帮助。使用它能够比其他的语言更快速地开发程序，因为它的编程方法更象是使用逻辑的语言来描述程序。

从纯理论的角度来讲，`Prolog`是一种令人陶醉的编程语言，但是在这本书中还是着重介绍他的实际使用方法。

## 进入`Prolog`世界

和其他的语言一样，最好的学习方法是实践。这本书将使用`Prolog`的解释器来向大家介绍几个具体的应用程序的编写过程。

首先你应该拥有一个`Prolog`的解释器，你可以在`Google`中找到它。关于解释器的使用，请参阅相关的使用说明文档，建议使用`amzi prolog `或者`swi prolog`来运行本网站的程序。

## 逻辑编程

什么叫逻辑编程？也许你还没有一个整体的印象，还是让我们首先来研究一个简单的例子吧。运用经典的逻辑理论，我们可以说“所有的人（`person`）都属于人类（`moral`）”，如果用`Prolog`的语言来说就是“对于所有的`X`，只要`X`是一个人，它就属于人类。”
```prolog
moral(X):-
    person(X).
```
同样，我们还可以加入一些简单的事实，比如：苏格拉底（`socrates`）是一个人。
```
person(socrates).
```
有了这两条逻辑声明，`Prolog`就可以判断苏格拉底是不是属于人类。在`Prolog`的`Listener`中键入如下的命令：

`?-mortal(socrates).` (此句中的`?-`是`Listener`的提示符，本句表示询问苏格拉底是不是属于人类。）

`Linstener`将给出答案：
```
yes
```
我们还可以询问，“谁属于人类？”
```
?- mortal(X).
```
我们会得到如下的答案：
```
X= socrates
```
这个简单的例子显示了`Prolog`的一些强大的功能。它能让程序代码更简洁、更容易编写。在多数情况下`Prolog`的程序员不需要关心程序的运行流程，这些都由`Prolog`自动地完成了。

当然，一个完整的程序不能只包括逻辑运算部分，还必须拥有输入输出，乃至用户界面部分。很遗憾，`Prolog`在这些方面做得不好，或者说很差。不过它还是提供了一些基本的方法的。下面是上述的程序一个完整的例子。
```prolog
% This is the syntax for comments. % MORTAL - The first illustrative Prolog program
mortal(X) :- 
        person(X).

person(socrates).
person(plato).
person(aristotle).

mortal_report:-
    write('Known mortals are:'),
    nl,
    mortal(X),
    write(X),
    nl,
    fail.
```
把这个程序调入Listener中，运行mortal_report.。
```js
?- mortal_report. 
Known mortals are:
socrates
plato
aristotle
no 
```
以上程序中的一些函数以后还会详细的介绍的。最后的那个`no`表示没有其他的人了。

## 进入下一章

从下一章起，就开始正式介绍`Prolog`的编程方法了。我将用一个实例来介绍`Prolog`，这是一个文字的冒险游戏，你所扮演的角色是一个三岁的小女孩，你想睡觉了，可是没有毛毯（`nani`）你就不能安心的睡觉。所以你必须在那个大房子中找到你的毛毯，这就是你的任务。这个游戏能够显示出一些`Prolog`的独到之处，不过`Prolog`的功能远不止编个简单的游戏，所以文中还将介绍一些其他的小程序。