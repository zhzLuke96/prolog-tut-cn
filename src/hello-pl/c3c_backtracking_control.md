# 回溯与控制流

> 回溯是 Prolog 的隐形循环，cut 是你给它画的一条线。

> 前置：c3b | 难度：★★★ | 后续：c4

## 回溯机制

Prolog 找答案靠的是回溯。当目标有多个匹配子句时，Prolog 在第一个子句处设一个选择点（choice point），记下"这里还有备选"。如果第一个子句走到一半失败，引擎跳回最近的选择点，试下一条。

选几个事实看：

```prolog
%% file: food.pl
fruit(apple).
fruit(banana).
fruit(cherry).

color(apple, red).
color(banana, yellow).
color(cherry, red).
```

查询 `fruit(X)`：

```prolog
?- fruit(X).
X = apple ;
X = banana ;
X = cherry .
```

每输入 `;` 就回溯到最近的选择点。用 `trace/0` 看内部发生了什么：

```prolog
?- trace, fruit(X), X = cherry.
   Call: fruit(_4010)
   Exit: fruit(apple)
   Call: apple=cherry
   Fail: apple=cherry
   Redo: fruit(_4010)
   Exit: fruit(banana)
   Call: banana=cherry
   Fail: banana=cherry
   Redo: fruit(_4010)
   Exit: fruit(cherry)
   Call: cherry=cherry
   Exit: cherry=cherry

X = cherry .
```

关键行 `Redo: fruit(_4010)`——引擎回到选择点，取下一个解。SLD 树搜索路径就是深度优先遍历，回溯是它的"往回走"机制。

## !/0 — 截断

`!/0` (cut) 切掉当前选择点之后的备选分支。分两类。

> 类比 | 其他语言无精确对应。-> ; 约等于 if-else，cut 约等于在 if-else 后禁止 fallthrough

### Green cut — 不移除语义

只移除不可能成功的冗余分支，不改变程序逻辑含义。

```prolog
%% green cut
is_digit(X) :- X >= 0, X =< 9, !.

?- is_digit(5).
true .

?- is_digit(15).
false .
```

`!/0` 只是告诉 Prolog：`X` 在 0-9 之间时不需要再找其他解。去掉 `!` 结果一样，只是多了冗余选择点。

### Red cut — 改变语义

cut 改变了程序本来的逻辑含义，子句顺序变得关键。

```prolog
%% red cut — max/3
max(A, B, A) :- A >= B, !.
max(_, B, B).

?- max(3, 5, M).
M = 5 .

?- max(3, 5, 5).
true .
```

如果交换子句顺序：

```prolog
max_bad(_, B, B) :- !.
max_bad(A, B, A) :- A >= B.

?- max_bad(3, 5, M).
M = 3 .  % 错！
```

`!/0` 切掉了选择点，子句顺序决定一切。纯版本用 `if_/3` (library(reif)) 避免 cut：

```prolog
:- use_module(library(reif)).

max_if(A, B, M) :-
    if_(A >= B, M = A, M = B).

?- max_if(3, 5, M).
M = 5 .
```

## -> ; — if-then-else

`(Condition -> Then ; Else)` 是 Cut 的语法糖——它编译成 `(Condition, !, Then ; Else)`。

> 类比 | SQL CASE WHEN / JS if-else / Python if-elif-else

```prolog
max_ifte(A, B, M) :-
    (   A >= B
    ->  M = A
    ;   M = B
    ).

?- max_ifte(3, 5, M).
M = 5 .
```

看 `(-> ;)` 的行为：

```prolog
test(X) :-
    (   X > 0
    ->  write(positive)
    ;   X < 0
    ->  write(negative)
    ;   write(zero)
    ).

?- test(5).
positive

?- test(-3).
negative

?- test(0).
zero
```

注意 `(-> ;)` 隐式含 `!`，条件一旦成功就不可能回溯到 Else 分支。想保留回溯选项请用 `*-> ;`（软截断）：

```prolog
test_soft(X) :-
    (   between(1, 3, X)
    *->  format("try ~w ", [X])
    ;   write(other)
    ).

?- test_soft(2).
try 2

?- test_soft(X).
try 1
try 2
try 3
```

`->` 只取第一个解就切，`*->` 保留选择点。

## fail/0 — 强制失败

`fail/0` 永远失败，触发回溯。常见模式是 force failure 做副作用循环。

```prolog
%% 打印所有红色水果
print_red :-
    color(F, red),
    write(F), nl,
    fail.
print_red.

?- print_red.
apple
cherry
true .
```

`fail` 迫使 Prolog 回溯找 `color/2` 的下一个解，直到无解后走第二条子句 `print_red.` 成功退出。

### repeat/0 + fail/0 命令循环

> 类比 | JS: `while(true)` + `break` | Python: `while True` + `break`

`repeat/0` 在失败时永远成功，制造无限循环。

```prolog
%% 简易 REPL
command_loop :-
    repeat,
    write("> "),
    read(X),
    write("got: "), write(X), nl,
    X = end,
    !.

?- command_loop.
|: hello.
got: hello
|: test.
got: test
|: end.
got: end
true .
```

退出条件是 `X = end`——只有输入 `end.` 时才成功，跳出循环。最后的 `!` 切掉 `repeat` 的选择点，避免再次回溯到 repeat。

## 收集谓词：findall/3, setof/3, bagof/3

这里只讲它们与回溯的关系和差异。具体用法参见[c3 高阶谓词](c3.md)。

```prolog
%% 数据
parent(ann, bob).
parent(ann, carol).
parent(bob, dave).
parent(bob, eve).
```

### findall/3 — 收集所有解

```prolog
?- findall(C, parent(ann, C), L).
L = [bob, carol].
```

> 类比 | JS: `Array.from(map)` / `filter` + `map` | Python: 列表推导式

不依赖回溯——findall 内部会自动回溯收集所有解。即使没有解也返回空列表。

### setof/3 — 排序去重

```prolog
?- setof(C, parent(P, C), L).
P = ann,
L = [bob, carol] ;
P = bob,
L = [dave, eve].
```

> 类比 | JS: `[...new Set(arr)]` | Python: `set()`

`setof/3` 会按变量分组。`P` 未绑定时，每组一个答案。

### bagof/3 — 分组收集

```prolog
?- bagof(C, parent(P, C), L).
P = ann,
L = [bob, carol] ;
P = bob,
L = [dave, eve].
```

> 类比 | JS: `groupBy` / `reduce` | Python: `groupby` / `defaultdict`

与 setof 唯一区别：bagof 不去重不排序。

### 三者差异查表

| 谓词 | 排序 | 去重 | 空结果 | 自由变量分组 |
|------|------|------|--------|-------------|
| `findall/3` | 否 | 否 | `[]` | 不分（收集所有组合） |
| `setof/3` | 是 | 是 | 失败 | 分（每组一个解） |
| `bagof/3` | 否 | 否 | 失败 | 分（每组一个解） |

```prolog
%% findall 在无解时返回[]
?- findall(X, parent(x, X), L).
L = [].

%% setof 在无解时失败
?- setof(X, parent(x, X), L).
false.
```

## 实践建议

1. **先写纯逻辑，再加 cut**。纯版本可读性好，调试方便。

2. **用 `once/1` 替代 `!, fail` 模式**。`once(G)` 等价于 `(G, !)`，语义更清晰。

3. **`(-> ;)` 适合互斥条件，不要嵌套超过三层**。嵌套太多建议抽成单独谓词。

4. **收集谓词优于手写 `fail` 循环**。`findall/3` 比 `fail/write` 循环更声明式、更安全。

5. **Red cut 是最后手段**。能用 `if_/3` 或 `(-> ;)` 就不要用 red cut。

```prolog
%% 好：once/1
try(Goal) :- once(Goal), write(ok).

%% 差：!, fail 模式
try(Goal) :- call(Goal), !.
try(_) :- write(fail).
```

## 总结

回溯是 Prolog 的核心引擎。`!/0` 给它画边界，`(-> ;)` 提供分支，`fail/0` 触发回溯循环，`findall/3` 等收集谓词从回溯中采集结果。记住顺序：纯逻辑优先，cut 最后加。

## 参考

- 「从零开始」chapter14、chapter15、chapter6
- [The Power of Prolog — Cut](https://www.metalevel.at/prolog/cut)
- [The Power of Prolog — Collection](https://www.metalevel.at/prolog/collection)
- SWI-Prolog manual: [Control Predicates](https://www.swi-prolog.org/pldoc/man?section=control)an?section=control)swi-prolog.org/pldoc/man?section=control)