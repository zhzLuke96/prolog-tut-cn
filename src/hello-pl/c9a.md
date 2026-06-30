# 规则引擎与约束求解

> 一句话概括：10 行代码解数独？Prolog 的 CLP(FD) 和元解释器，让你只描述"是什么"，引擎做"怎么办"。

> 前置：[回溯与控制流](c3c_backtracking_control.md) | 难度：★★★ | 后续：[搜索与自然语言](c9b.md)

学完这章，你能用 CLPFD 十行代码写一个数独求解器，再用元解释器写一个能推理的专家系统。

## 10 行代码解数独

信不信？就这一段：

```prolog
:- use_module(library(clpfd)).

sudoku(Rows) :-
    length(Rows, 9), maplist(same_length(Rows), Rows),
    append(Rows, Vs), Vs ins 1..9,
    maplist(all_different, Rows),
    transpose(Rows, Columns),
    maplist(all_different, Columns),
    Rows = [A,B,C,D,E,F,G,H,I],
    blocks(A, B, C), blocks(D, E, F), blocks(G, H, I),
    label(Vs).

blocks([], [], []).
blocks([A1,A2,A3|As], [B1,B2,B3|Bs], [C1,C2,C3|Cs]) :-
    all_different([A1,A2,A3,B1,B2,B3,C1,C2,C3]),
    blocks(As, Bs, Cs).
```

丢进去跑：

```prolog
?- Rows = [
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _],
     [_, _, _,  _, _, _,  _, _, _]],
   sudoku(Rows).
```

啪一下，Prolog 把数独解出来了。几个下划线变量，没有任何"怎么求解"的指令。怎么做到的？

## CLPFD 怎么工作的

你写了三样东西：

**定义了取值范围** — `Vs ins 1..9` 告诉 Prolog：所有格子只填 1 到 9。

**定义了约束条件** — `maplist(all_different, Rows)` 每行数字不重复，transpose 后同样约束给列，blocks 约束给每个 3×3 宫。

**触发了搜索** — `label(Vs)`，Prolog 开始试值，不满足约束就回溯。

没了。这就是约束编程的全部：你说"什么是对的"，引擎自己找"怎么到达对的状态"。

剩下的代码全是 Prolog 的"胶水"：`append(Rows, Vs)` 把 9 个 list 拍平成一个变量列表，`transpose` 算出行转列，blocks 用递归把每三行切成三个宫。

> 类比 | SQL: `Vs ins 1..9` ≈ 字段类型约束，`all_different` ≈ UNIQUE 约束，`label(Vs)` ≈ 执行查询计划

> 类比 | 前端开发者: CLPFD ≈ zod/yup schema — 声明式定义数据合法范围，引擎自动校验+找解

### 如果我们用其他语言写

命令式解数独：嵌套循环 + 深度优先搜索 + 手动回溯 + 剪枝优化。几百行起步。Prolog 版本把"搜索"这个脏活外包给了引擎，你只管描述规则。

框架就是一个三段论：
- 定义域——变量可以取什么值
- 发布约束——变量之间什么关系
- 标签搜索——让引擎干活

### 给搜索加点智慧

`label(Vs)` 是最朴素的搜索——一个个变量顺序试值。遇到"最难"的数独要跑很久。Prolog 给了你更聪明的策略：

```prolog
labeling([ff], Vs).  %% "first fail" —— 值域最小的变量先试
```

`ff` 策略先选可能性最少的格子试，减少分支。类似人类解数独的思路：看哪个格子能填的数字最少，先试它。

更多约束表达：

```prolog
X #= Y   %% 等于
X #\= Y  %% 不等于
X #> Y   %% 大于
X #< Y   %% 小于
```

> 参考：[The Power of Prolog - Constraints](https://www.metalevel.at/prolog/constraints) — CLPFD 完整指南，含全局约束、具体化、自定义搜索。

## 写一个能推理的 AI

CLPFD 解决的是"约束满足"。但真实 AI 场景里，更多时候我们需要的是"规则推理"——给定事实和规则，推导出新事实。想象一个动物识别系统：你知道它有毛发、吃奶，推出来是哺乳动物。再发现它是黑白色的，推出是斑马。

这不就是人类推理的方式吗？你的知识库就是一堆如果-那么规则，Prolog 天生就能跑这个。

### 一个简单的推理引擎

从回溯章的 vanilla meta-interpreter 扩展：

```prolog
:- dynamic known/1, rule/2.

%% 规则库
rule(animal(mammal),    [has(hair), eats(milk)]).
rule(animal(bird),      [has(feathers), lays(eggs)]).
rule(animal(carnivore), [animal(mammal), eats(meat)]).
rule(animal(zebra),     [animal(mammal), color(black_and_white)]).
rule(animal(tiger),     [animal(carnivore), color(orange_black_stripes)]).

%% 事实
has(hair).
eats(milk).
color(black_and_white).

%% 推理引擎（带深度追踪）
solve(true, _) :- !.
solve((A, B), Depth) :- !, solve(A, Depth), solve(B, Depth).
solve(H, Depth) :-
    known(H), !.
solve(H, Depth) :-
    rule(H, Body),
    D1 is Depth + 1,
    solve(Body, D1),
    assertz(known(H)).  %% 缓存结果，避免重复推理
```

查询：

```prolog
?- solve(animal(zebra), 0).
true .
```

推理过程：你问"zebra 是动物吗？"，引擎找到规则 `rule(animal(zebra), [animal(mammal), color(black_and_white)])`，然后递归去证明 `animal(mammal)` 和 `color(black_and_white)`，前者又触发 `rule(animal(mammal), [has(hair), eats(milk)])` 继续递归，直到命中已知事实 `has(hair)`、`eats(milk)`。

### 两种推理方向

上面是**后向链**（backward chaining）：从目标出发，找能推导目标的规则，再去满足规则的前提。问题是 Prolog 的默认策略——你用 `?- solve(G).` 查什么，引擎就从 G 往回推。

反过来也有场景——给你一堆事实，你想看"能推出什么新东西"。这叫**前向链**（forward chaining）：

```prolog
forward :-
    rule(Head, Body),
    \+ known(Head),
    maplist(known, Body),   %% 所有前提已满足
    assertz(known(Head)),
    write(推导: ), write(Head), nl,
    fail.                   %% 继续找下一条可触发的规则
forward :- true.
```

跑 `forward.`，它会反复扫规则库，直到不能再推出新事实。每次触发一条规则就输出一条。

### 两种推理用在什么场景

| 场景 | 用哪种 | 原因 |
|------|--------|------|
| 诊断系统 | 后向链 | 从症状倒推病因 |
| 配置系统 | 前向链 | 从零件推导可行配置 |
| 规划系统 | 混合 | 目标导向 + 事实驱动 |

### 让 AI 告诉你为什么

推理引擎不止给出结论，还能解释推理过程：

```prolog
explain(Goal) :-
    solve(Goal, 0),
    format("~w 成立~n", [Goal]).
```

再加个深度追踪就能输出推理链，做"为什么"和"怎么做到的"解释——这在医疗诊断、法律推理等需要可解释性的场景里很关键。

### 知识库怎么组织

实际系统不可能把事实和规则写在一个文件里。分开管理：

```prolog
%% rules.pl
:- multifile rule/2.
rule(animal(mammal), [has(hair), eats(milk)]).

%% facts.pl
:- dynamic known/1.
has(hair).
eats(milk).
```

通过 `consult` 或 `use_module` 加载。推理引擎做公共库，规则和事实做数据文件。

### 性能跟得上吗

| 场景 | 适用推理 | 限制 |
|------|----------|------|
| CLPFD 约束求解 | 变量数百以内 | 更大规模用 OR-Tools、Choco |
| 规则推理 | 规则数千以内 | 更大规模用 Rete 算法（Drools） |

Prolog 的优势不在硬扛大规模，在灵活性和与 DCG、元编程的无缝集成。一个系统里，你可以用 DCG 解析自然语言，用元解释器推理，用 CLPFD 做约束——全在一个语言里。

> 参考：Ivan Bratko《Prolog Programming for Artificial Intelligence》第 4 版 — 专家系统设计与搜索策略的经典

## 总结

- 数独求解器：你写规则，Prolog 找解。声明域→发布约束→标签搜索，三段论搞定。
- 规则推理引擎：后向链从目标推前提，前向链从事实推结论。你定义"如果-那么"，引擎自动推导。
- 两者共享一个哲学：你写"是什么"，引擎做"怎么办"。

## 参考

- [The Power of Prolog - Constraints](https://www.metalevel.at/prolog/constraints) — CLPFD 完整指南
- [CLP(FD) Library](https://www.swi-prolog.org/man/clpfd.html) — SWI-Prolog 官方文档
- Sterling & Shapiro, *The Art of Prolog* — meta-interpreter 设计经典
- [The Power of Prolog - Search](https://www.metalevel.at/prolog/search) — 搜索策略深度分析