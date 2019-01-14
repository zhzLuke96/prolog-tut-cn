# 自然语言
Prolog特别适合开发自然语言的应用系统。在这一章，我们将为寻找Nani游戏添加自然语言理解的部分。（由于Prolog谓词是使用的英文符号，所以这里的自然语言理解只能局限在英文中）

在着手于编制寻找Nani之前， 我们先来开发一个能够分析简单英语句子的模块。把这种方法掌握之后，编制寻找Nani的自然语言部分就不在话下了。

下面是两个简单的英语句子：

```
The dog ate the bone.
The big brown mouse chases a lazy cat.
```

我们可以使用下面的语法规则来描述这种句子。

```
sentence : (句子）
nounphrase, verbphrase. 
nounphrase : （名词短语）
determiner, nounexpression. 
nounphrase : （名词短语）
nounexpression. 
nounexpression : 
noun. 
nounexpression : 
adjective（形容词）, nounexpression. 
verbphrase : （动词短语）
verb, nounphrase. 
determiner : （限定词）
the | a. 
noun : （名词）
dog | bone | mouse | cat. 
verb : （动词）
ate | chases. 
adjective : 
big | brown | lazy. 
```

稍微解释一下：第一条规则说明一个句子有一个名词短语和一个动词短语构成。最后的一个规则定义了单词big、brown和lazy是形容词，中间的“|”表示或者的意思。

首先，来判断某个句子是否是合法的句子。我们编写了sentence/1谓词，它可以判断它的参数是否是一个句子。

句子必须用Prolog的一种数据结构来表达，这里使用列表。例如，前面的两个句子的Prolog表达形式如下：

```
 [the,dog,ate,the,bone]
 [the,big,brown,mouse,chases,a,lazy,cat]
```

分析句子的方法有两种。第一种是选择并校样的方法（见后面的人工智能实例部分），使用这种方法，首先把句子的可能分解情况找出来，再来测试被分解的每一个部分是否合法。我们前面已经介绍过使用append/3谓词能够把列表分成两个部分。使用这种方法，顶层的规则可以是如下的形式：

```
sentence(L) :-
append(NP, VP, L),
nounphrase(NP),
verbphrase(VP).
```

append/3谓词可以把列表L的所有可能的分解情况穷举出来，分解后的两个部分为NP和VP，其后的两个目标则分别测试NP和VP是否是合法的，如果不是则会产生回溯，从而测试其他的分解情况。

谓词nounphrase/1和verbphrase/1的编写方法与sentence/1基本相同，它们调用其他的谓词来判断句子中的更小的部分是否合法，只到调用到定义单词的谓词，例如：

```
verb([ate]).
verb([chases]).
noun([mouse]).
noun([dog]).
```

# 差异表

前面的这种方法效率是非常低的，这是因为选择并校验的方法需要穷举所有的情况，更何况在每一层的目标之中都要进行这种测试。

更有效的方法就是跳过选择的步骤，而直接把整个列表传到下一级的谓词中，每个谓词把自己所要寻找的语法元素找出来，并返回剩下的列表。

为了能够达到这个目标，我们需要介绍一种新的数据结构：差异表。它由两个相关的表构成，第一个表称为全表，而第二个表称为余表。这两个表可以作为谓词的两个参数，不过我们通常使用‘-’连接这两个表，这样易于阅读。它的形式是X-Y。

我们使用差异表改写了第一条语法规则。如果能够从列表S的头开始，提取出一个名词短语，其余部分S1,并且能够从S1的头开始，提取出一个动词短语，并且其余部分为空表，那么列表S是一个句子。（这句话要细心理解，差异表所表示的表是全表和余表之间的差异。）

```
sentence(S) :-
nounphrase(S-S1),
verbphrase(S1-[]).
```

我们先跳过谓词nounphrase/1和verbphrase/1的编写，而来看看是如何定义真正的单词的。这些单词也必须书写成差异表的形式，这个很容易做到：如果列表的第一个元素是所需的单词，那么余表就是除去第一个单词的表。

```
noun([dog|X]-X).
noun([cat|X]-X).
noun([mouse|X]-X).
verb([ate|X]-X).
verb([chases|X]-X).
adjective([big|X]-X).
adjective([brown|X]-X).
adjective([lazy|X]-X).
determiner([the|X]-X).
determiner([a|X]-X).
```

下面是两个简单的测试，

```
?- noun([dog,ate,the,bone]-X). 
```

%第一个单词dog是名词，于是成功，并且余表是后面的元素组成的表。

```
X = [ate,the,bone] 
?- verb([dog,ate,the,bone]-X).
no
```

我们把剩下的一些语法规则写完：

```
nounphrase(NP-X):-
determiner(NP-S1),
nounexpression(S1-X).
nounphrase(NP-X):-
nounexpression(NP-X).
nounexpression(NE-X):-
noun(NE-X).
nounexpression(NE-X):-
adjective(NE-S1),
nounexpression(S1-X).
verbphrase(VP-X):-
verb(VP-S1),
nounphrase(S1-X).
```

注意谓词nounexpression/1的递归定义，这样就可以处理名词前面有任意多个形容词的情况。

我们来用几个句子测试一下：

```
?- sentence([the,lazy,mouse,ate,a,dog]).
yes
?- sentence([the,dog,ate]).
no
?- sentence([a,big,brown,cat,chases,a,lazy,brown,dog]).
yes
?- sentence([the,cat,jumps,the,mouse]).
no
```

下面是单步跟踪某个句子的情况：

询问是 

```
?- sentence([dog,chases,cat]).
1-1 CALL sentence([dog,chases,cat])
2-1 CALL nounphrase([dog,chases,cat]-_0)
3-1 CALL determiner([dog,chases,cat]-_0)
3-1 FAIL determiner([dog,chases,cat]-_0)
2-1 REDO nounphrase([dog,chases,cat]-_0)
3-1 CALL nounexpression([dog,chases,cat]- _0)
4-1 CALL noun([dog,chases,cat]-_0)
4-1 EXIT noun([dog,chases,cat]- 
 [chases,cat])
```

注意，表示余表的变量的绑定操作是直到延伸至最底层时才进行的，每一层把它的余表和上一层的绑定。这样，当到达了词汇层时，绑定的值将通过嵌套的调用返回。

```
3-1 EXIT nounexpression([dog,chases,cat]-
 [chases,cat])
2-1 EXIT nounphrase([dog,chases,cat]-
 [chases,cat])
```

现在已经找出了名词短语，下面来测试余表是否为动词短语。

```
2-2 CALL verbphrase([chases,cat]-[])
3-1 CALL verb([chases,cat]-_4)
3-1 EXIT verb([chases,cat]-[cat])
```

很容易地就找出了动词，下面寻找最后的动词短语。

```
3-2 CALL nounphrase([cat]-[])
4-1 CALL determiner([cat]-[])
4-1 FAIL determiner([cat]-[])
3-2 REDO nounphrase([cat]-[])
4-1 CALL nounexpression([cat]-[])
5-1 CALL noun([cat]-[])
5-1 EXIT noun([cat]-[])
4-1 EXIT nounexpression([cat]-[])
3-2 EXIT nounphrase([cat]-[])
2-2 EXIT verbphrase([chases,cat]-[])
1-1 EXIT sentence([dog,chases,cat])
yes
```

# 寻找nani

现在将使用这种分析句法结构的技术，来完成寻找Nani。

我们首先假设已经完成以下的两个任务。第一，已经完成了把用户的输入转换成列表的工作。第二，我们可是使用列表的形式来表示命令，例如，goto(office)表示成为[goto,office]，而look表示成为[look]。

有了这两个假设，现在的任务就是把用户的自然语言转换成为程序能够理解的命令列表。例如，我们希望程序能够把[go,to,the,office]转换成为[goto,office]。

最高层的谓词叫做command/2，它的形式如下：

```
command(OutputList, InputList).
```

最简单的命令就是只有一个动词的命令，例如look、list_possessions和end。我们可以使用下面的子句来识别这种命令：

```
command([V], InList):- verb(V, InList-[]).
```

我们使用前面介绍过的方法来定义动词，不过这次将多加入一个参数，这个参数用来构造返回的标准命令列表。为了使这个程序看上去更有趣，我们让它能够识别命令多种表达形式。例如结束游戏可以输入：end、quit和good bye。

下面是几个简单的测试：

```
?- command(X,[look]).
X = [look]
?- command(X,[look,around]).
X = [look]
?- command(X,[inventory]).
X = [list_possessions]
?- command(X,[good,bye]).
X = [end]
```

下面的任务要复杂一些，我们将考虑动宾结构的命令。使用前面介绍过的知识，可以很容易地完成这个任务。不过此处，还希望除了语法以外还能够识别语义。

例如，goto动词后面所跟随的物体必须是一个地方，而其他的谓词后面的宾语则是个物体。为了完成这个任务，我们引入了另一个参数。

下面是主子句，我们可以看出新的参数是如何工作的。

```
command([V,O], InList) :-
verb(Object_Type, V, InList-S1),
object(Object_Type, O, S1-[]).
```

还必须用事实来定义一些新的动词：


```
verb(place, goto, [go,to|X]-X).
verb(place, goto, [go|X]-X).
verb(place, goto, [move,to|X]-X).
```


我们甚至可以识别goto动词被隐含的情况，即如果玩家仅仅输入某个房间的名称，而没有前面的谓词。这种情况下列表及其余表相同。而room/1谓词则用来检测列表的元素是否为一个房间，除了房间的名字是两个单词的情况。

下面这条规则的意思是：如果我们从列表的头开始寻找某个动词，而列表的头确是一个房间的名称，那么就认为找到了动词goto，并且返回完成的列表，好让后面的操作找到 goto动词的宾语。

```
verb(place, goto, [X|Y]-[X|Y]):- room(X).
verb(place, goto, [dining,room|Y]-[dining,room|Y]).
```

下面是关于物品的谓词：

```
verb(thing, take, [take|X]-X).
verb(thing, drop, [drop|X]-X).
verb(thing, drop, [put|X]-X).
verb(thing, turn_on, [turn,on|X]-X).
```

有时候，物品前面可能有限定词，下面的两个子句考虑的有无限定词的两种情况：

```
object(Type, N, S1-S3) :-
det(S1-S2),
noun(Type, N, S2-S3).
object(Type, N, S1-S2) :-
noun(Type, N, S1-S2).
```

由于我们处理句子时只需要去掉限定词，所以就不需要额外的参数。

```
det([the|X]- X).
det([a|X]-X).
det([an|X]-X).
```

定义名词的方法与动词相似，不过大部分可以使用原来的定义方法，而只有那些两个单词以上的名词才需要特殊的定义方法。位置名词使用room谓词定义。

```
noun(place, R, [R|X]-X):- room(R).
noun(place, 'dining room', [dining,room|X]-X).
```

location谓词和have谓词所定义的东西是物品，这里我们又必须把两个单词的物品单独定义。

```
noun(thing, T, [T|X]-X):- location(T,_).
noun(thing, T, [T|X]-X):- have(T).
noun(thing, 'washing machine', [washing,machine|X]-X).
```

我们可以把对游戏当前状态的识别也做到语法中去。例如，我们想做一个可以开关灯的命令，这个命令是turn_on(light)，和turn_on(flashlight)相对应。如果玩家输入turn on the light，我们必须决定这个light是指房间里的灯还是flashlight。

在这个游戏中，房间的灯是永远也打不开的，因为玩家所扮演的角色是一个3岁的小孩，不过她可以打开手电筒。下面的程序把turn on the light翻译成turn on light或者turn on flashlight，这样就能让后面的程序来进行判断了。

```
noun(thing, flashlight, [light|X], X):- have(flashlight).
noun(thing, light, [light|X], X).
```

下面来全面的测试一下：

```
?- command(X,[go,to,the,office]).
X = [goto, office]
?- command(X,[go,dining,room]).
X = [goto, 'dining room']
?- command(X,[kitchen]).
X = [goto, kitchen]
?- command(X,[take,the,apple]).
X = [take, apple]
?- command(X,[turn,on,the,light]).
X = [turn_on, light]
?- asserta(have(flashlight)), command(X,[turn,on,the,light]).
X = [turn_on, flashlight]
```

下面的几个句子不合法：

```
?- command(X,[go,to,the,desk]).
no
?- command(X,[go,attic]).
no
?- command(X,[drop,an,office]).
no
```

# Definite Clasue Grammar(DCG)

在Prolog中经常用到差异表，因此许多Prolog版本都对差异表有很好的支持，这样就可以隐去差异表的一些繁琐复杂之处。这种语法称为Definite Clasue Grammer(DCG)，它看上去和一般的Prolog子句非常相似，只不过把连接符:-替换成为-->，这种表达形式由Prolog翻译成为普通的差异表形式。

使用DCG，原来的句子谓词将写为：

```
sentence --> nounphrase, verbphrase.
```

这个句子将被翻译成一般的使用差异表的Prolog子句，但是这里不再用“-”隔开，而是变成了两个参数，上面的这个句子与下面的Prolog子句等价。

```
sentence(S1, S2):-
nounphrase(S1, S3),
verbphrase(S3, S2).
```

因此，既是使用DCG形式定义sentence谓词，我们在调用时仍然需要两个参数。

```
?- sentence([dog,chases,cat], []).
```

用DCG来表示词汇只需要使用一个列表：

```
noun --> [dog].
verb --> [chases].
```

这两个句子被翻译成：

```
noun([dog|X], X).
verb([chases|X], X).
```

就象在本游戏中所需要的那样，有时需要额外的参数来返回语法信息。这个参数只需要简单地加入就行了，而句中纯Prolog则使用{}括起来，这样DCG分析器就不会翻译它。游戏中的复杂的规则将写成如下的形式：

```
command([V,O]) --> 
verb(Object_Type, V), 
object(Object_Type, O).
verb(place, goto) --> [go, to].
verb(thing, take) --> [take].
object(Type, N) --> det, noun(Type, N).
object(Type, N) --> noun(Type, N).
det --> [the].
det --> [a].
noun(place,X) --> [X], {room(X)}.
noun(place,'dining room') --> [dining, room].
noun(thing,X) --> [X], {location(X,_)}.
```

由于DCG自动的取走第一个参数，如果只输房间名称，前面的子句就不能起作用，所以我们还要加上一条：

command([goto, Place]) --> noun(place, Place).

# 读入句子

让我们来最后完工吧。最后的工作是把用户的输入变成一张表。下面的程序很够完成这个任务：

```
% read a line of words from the user
read_list(L) :-
write('> '),
read_line(CL),
wordlist(L,CL,[]), !.
read_line(L) :-
get0(C),
buildlist(C,L).
buildlist(13,[]) :- !.
buildlist(C,[C|X]) :-
get0(C2),
buildlist(C2,X).
wordlist([X|Y]) --> word(X), whitespace, wordlist(Y).
wordlist([X]) --> whitespace, wordlist(X).
wordlist([X]) --> word(X).
wordlist([X]) --> word(X), whitespace.
word(W) --> charlist(X), {name(W,X)}.
charlist([X|Y]) --> chr(X), charlist(Y).
charlist([X]) --> chr(X).
chr(X) --> [X],{X>=48}.
whitespace --> whsp, whitespace.
whitespace --> whsp.
whsp --> [X], {X48}.
```

它包括两个部分：首先使用内部谓词get0/1读入单个的ASCII字符， ASCII 13代表句子结束。第二部分使用DCG分析字符列表，从而把它转化为单词列表，这里使用了另一个内部谓词name/2，它把有ASCII字符组成的列表转化为原子。

另外一部分是把形如[goto,office]的命令，转化为goto(office)，我们使用称为univ的内部谓词完成这个工作，使用"=.."表示。它的作用如下，把一个谓词转化为了一个列表，或者反过来。

```
?- pred(arg1,arg2) =.. X.
X = [pred, arg1, arg2] 
?- pred =.. X.
X = [pred] 
?- X =.. [pred,arg1,arg1].
X = pred(arg1, arg2) 
?- X =.. [pred].
X = pred 
```

最后我们使用前面的两个部分做成一个命令循环：

```
get_command(C) :-
read_list(L),
command(CL,L),
C =.. CL, !.
get_command(_) :-
write('I don''t understand'), nl, fail.
```
