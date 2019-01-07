# 第0章 人工智能语言—PROLOG简介
> 人工智能语言是一类适应于人工智能和知识工程领域的、具有符号处理和逻辑推理能力的计算机程序设计语言,其中`Prolog`是当代最有影响的人工智能语言之一。
### 一、什么是人工智能语言
人工智能（`AI`）语言是一类适应于人工智能和知识工程领域的、具有符号处理和逻辑推理能力的计算机程序设计语言。能够用它来编写程序求解非数值计算、知识处理、推理、规划、决策等具有智能的各种复杂问题。

典型的人工智能语言主要有`LISP`、`Prolog`、`Smaltalk`、`C++`等。

一般来说，人工智能语言应具备如下特点：
- 具有符号处理能力（即非数值处理能力）; 
- 适合于结构化程序设计，编程容易; 
- 具有递归功能和回溯功能; 
- 具有人机交互能力; 
- 适合于推理; 
- 既有把过程与说明式数据结构混合起来的能力，又有辨别数据、确定控制的模式匹配机制。 

人们可能会问，用人工智能语言解决问题与传统的方法有什么区别呢？

传统方法通常把问题的全部知识以各种的模型表达在固定程序中，问题的求解完全在程序制导下按着预先安排好的步骤一步一步（逐条）执行。解决问题的思路与冯.诺依曼式计算机结构相吻合。当前大型数据库法、数学模型法、统计方法等都是严格结构化的方法。

对于人工智能技术要解决的问题，往往无法把全部知识都体现在固定的程序中。通常需要建立一个知识库（包含事实和推理规则），程序根据环境和所给的输入信息以及所要解决的问题来决定自己的行动，所以它是在环境模式的制导下的推理过程。这种方法有极大的灵活性、对话能力、有自我解释能力和学习能力。这种方法对解决一些条件和目标不大明确或不完备，（即不能很好地形式化，不好描述）的非结构化问题比传统方法好，它通常采用启发式、试探法策略来解决问题。

### 二、`Prolog`语言及其基本结构
`Prolog`是当代最有影响的人工智能语言之一，由于该语言很适合表达人的思维和推理规则，在自然语言理解、机器定理证明、专家系统等方面得到了广泛的应用，已经成为人工智能应用领域的强有力的开发语言。

尽管`Prolog`语言有许多版本，但它们的核心部分都是一样的。`Prolog`的基本语句仅有三种，即事实、规则和目标三种类型的语句，且都用谓词表示，因而程序逻辑性强，文法简捷，清晰易懂。另一方面，`Prolog`是陈述性语言，一旦给它提交必要的事实和规则之后，`Prolog`就使用内部的演绎推理机制自动求解程序给定的目标，而不需要在程序中列出详细的求解步骤。

#### 1、事实
事实用来说明一个问题中已知的对象和它们之间的关系。在`Prolog`程序中，事实由谓词名及用括号括起来的一个或几个对象组成。谓词和对象可由用户自己定义。

例如，谓词`likes(bill，book)`.

是一个名为`like`的关系，表示对象`bill`和`book`之间有喜欢的关系。

#### 2、规则
规则由几个互相有依赖性的简单句（谓词）组成，用来描述事实之间的依赖关系。从形式上看，规则由左边表示结论的后件谓词和右边表示条件的前提谓词组成。

例如，规则 `bird(X):-animal(X),has(X,feather).`

表示凡是动物并且有羽毛，那么它就是鸟。

#### 3、目标（问题）
把事实和规则写进`Prolog`程序中后，就可以向`Prolog`询问有关问题的答案，询问的问题就是程序运行的目标。目标的结构与事实或规则相同，可以是一个简单的谓词，也可以是多个谓词的组合。目标分内、外两种，内部目标写在程序中，外部目标在程序运行时由用户手工键入。

例如问题 `?-student(john).`

表示`“john是学生吗？”`

### 三、简单例子
以下两个例子在`Swi-Prolog`环境下运行通过。

#### 例1 谁是`john`的朋友？

```prolog
likes(bell,sports).         
likes(mary,music).
likes(mary,sports).
likes(jane,smith).

friend(john,X):-            
        likes(X,sports),
        likes(X,music).
```
当上述事实与规则输入计算机后，运行该程序，用户就可以进行询问，如输入目标：

`friend(john,X) `

即询问`john`的朋友是谁,,这时计算机的运行结果为：
```js
X=mary      //（mary是john的朋友）
```

#### 例2 汉诺塔问题：

> 有N个有孔的盘子，最初这些盘子都叠放在柱a上，要求将这N个盘子借助柱b从柱a移到柱c，移动时有以下限制：每次只能移动一个盘子;大盘不能放在小盘上。问如何移动？

![](https://www.cpp.edu/~jrfisher/www/prolog_tutorial/f2_3.gif)
 

该问题可以采用递归法思想来求解,其源程序为:
```prolog
move(1,X,Y,_) :-  
    write('Move top disk from '), 
    write(X), 
    write(' to '), 
    write(Y), 
    nl. 

move(N,X,Y,Z) :- 
    N>1, 
    M is N-1, 
    move(M,X,Z,Y), 
    move(1,X,Y,_), 
    move(M,Z,Y,X).  
```

这里调用比较特殊`move(3,left,right,center).`，代表了标准的汉诺塔在最左边放了三个盘子，并给每个杆子命名为`left` `right` `center`.(这里换成更多的4 5 6都是可以的，但是杆子命名不能相同)

输出
```
Move top disk from left to right
Move top disk from left to center
Move top disk from right to center
Move top disk from left to right
Move top disk from center to left
Move top disk from center to right
Move top disk from left to right
```

### 四、Prolog语言的常用版本

`Prolog`语言最早是由法国马赛大学的`Colmerauer`和他的研究小组于`1972`年研制成功。早期的`Prolog`版本都是解释型的，自`1986`年美国`Borland`公司推出编译型`Prolog,`即`Turbo Prolog`以后，`Prolog`便很快在`PC`机上流行起来。后来又经历了`PDC PROLOG`、`Visual Prolog`不同版本的发展。并行的逻辑语言也于`80`年代初开始研制，其中比较著名的有`PARLOG`、`Concurrent PROLOG`等。

#### 1、SWI-Prolog ***(特别推荐)***
> SWI-Prolog offers a comprehensive free Prolog environment. Since its start in 1987, SWI-Prolog development has been driven by the needs of real world applications. SWI-Prolog is widely used in research and education as well as commercial applications. Join over a million users who have downloaded SWI-Prolog. 

http://www.swi-prolog.org/

[online prolog shell](http://swish.swi-prolog.org/)

> 这个在线编译器很好用，并且有非常丰富的例子，且一直在持续更新，github有上百star

(swipl特别想推广它的web库...这个笔者就不太感冒了)

#### 2、Turbo Prolog
由美国`Prolog`开发中心（`Prolog Development Center, PDC`）`1986`年开发成功、`Borland`公司对外发行，其`1.0`，`2.0`，`2.1`版本取名为`Turbo Prolog`，主要在`IBM PC`系列计算机，`MS-DOS`环境下运行。

#### 3、PDC Prolog
`1990`年后，`PDC`推出新的版本，更名为`PDC Prolog 3.0`，`3.2`，它把运行环境扩展到`OS/2`操作系统，并且向全世界发行。它的主要特点是:

- 速度快。编译及运行速度都很快，产生的代码非常紧凑。 
- 用户界面友好。提供了图形化的集成开发环境。 
- 提供了强有力的外部数据库系统。 
- 提供了一个用`PDC Prolog`编写的`Prolog`解释起源代码。用户可以用它研究`Prolog`的内部机制，并创建自己的专用编程语言、推理机、专家系统外壳或程序接口。 
- 提供了与其他语言（如C、`Pascal`、`Fortran`等）的接口。`Prolog`和其他语言可以相互调用对方的子程序。 
- 具有强大的图形功能。支持`Turbo C`、`Turbo Pascal`同样的功能。 

#### 4、Visual Prolog
`Visual Prolog`是基于`Prolog`语言的可视化集成开发环境，是`PDC`推出的基于`Windows`环境的智能化编程工具。目前，`Visual Prolog`在美国、西欧、日本、加拿大、澳大利亚等国家和地区十分流行，是国际上研究和开发智能化应用的主流工具之一。

`Visual Prolog`具有模式匹配、递归、回溯、对象机制、事实数据库和谓词库等强大功能。它包含构建大型应用程序所需要的一切特性：图形开发环境、编译器、连接器和调试器，支持模块化和面向对象程序设计，支持系统级编程、文件操作、字符串处理、位级运算、算术与逻辑运算，以及与其它编程语言的接口。

`Visual Prolog`包含一个全部使用`Visual Prolog`语言写成的有效的开发环境，包含对话框、菜单、工具栏等编辑功能。

`Visual Prolog`与`SQL`数据库系统、`C++`开发系统、以及`Visual Basic`、`Delphi`或`Visual Age`等编程语言一样，也可以用来轻松地开发各种应用。

`Visual Prolog`软件的下载地址为：http://www.visual-prolog.com。
