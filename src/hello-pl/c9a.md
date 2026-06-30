# 规则引擎与约束求解

> 一句话概括：用 Prolog 描述"是什么"，约束求解器和推理引擎自动处理"怎么做"——数独、专家系统，一个套路。

> 前置：c3c | 难度：★★★ | 后续：—

## 约束求解：数独

数独是 CLP(FD)（有限域约束）的教科书案例。约束编程的核心三步骤：

1. **定义域** — 每个变量取值范围
2. **发布约束** — 变量间关系
3. **标签搜索** — 找到满足所有约束的解

> 类比 | SQL: CLPFD 的 domain + all_different + labeling ≈ DDL CHECK + UNIQUE 约束 + 查询执行计划

### 完整实现

```prolog
:- use_module(library(clpfd)).

sudoku(Rows) :-
    length(Rows, 9), maplist(same_length(Rows), Rows),
    append(Rows, Vs), Vs ins 1..9,

    %% 行约束
    maplist(all_different, Rows),
    %% 列约束
    transpose(Rows, Columns),
    maplist(all_different, Columns),
    %% 宫约束
    Rows = [A,B,C,D,E,F,G,H,I],
    blocks(A, B, C), blocks(D, E, F), blocks(G, H, I),

    %% 搜索
    label(Vs).

blocks([], [], []).
blocks([A1,A2,A3|As], [B1,B2,B3|Bs], [C1,C2,C3|Cs]) :-
    all_different([A1,A2,A3,B1,B2,B3,C1,C2,C3]),
    blocks(As, Bs, Cs).
```

查询：

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

`Vs ins 1..9` 声明所有变量取值 1-9。`all_different` 约束每行/每列/每宫数字互异。`label(Vs)` 触发搜索——Prolog 自动回溯直到找到解。

### 声明式建模的精髓

对比命令式解法（嵌套循环 + 回溯手写），CLPFD 写法几乎直接对应数独的数学定义：

- 每行数字不同 → `maplist(all_different, Rows)`
- 每列数字不同 → `transpose + maplist(all_different)`
- 每宫数字不同 → `blocks` 谓词

代码即规格。你不需要告诉计算机"怎么检查"，只需要描述"什么是合法的"。

> 类比 | 前端开发者: CLPFD ≈ zod/yup schema validation — 声明式定义数据合法范围，引擎自动找解

### 进阶

- `labeling([ff], Vs)` — 用"最先失败"启发式优化搜索顺序
- `(#=)/2`, `(#\=)/2`, `(#>)/2` — 更丰富的约束表达
- `indomain/1` — 逐个试探值域

> 参考：[The Power of Prolog - Constraints](https://www.metalevel.at/prolog/constraints) — CLPFD 深度指南，含全局约束、具体化、自定义搜索。

## 专家系统

CLPFD 解决"约束满足"问题。但很多 AI 场景需要的是"规则推理"——给定事实和规则，推导出新事实。

### 推理引擎基础

基于 c5 的 vanilla meta-interpreter 扩展：

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
    assertz(known(H)).  %% 缓存结果防重复推理
```

### 前向链 vs 后向链

上面的引擎是**后向链**（backward chaining）：从目标出发，找到能推导目标的规则，再去满足规则的前提。

**前向链**（forward chaining）相反：从已知事实出发，不断触发规则直到无法推导新事实。

```prolog
%% 前向链推理
forward :-
    rule(Head, Body),
    \+ known(Head),
    maplist(known, Body),   %% 所有前提已知
    assertz(known(Head)),
    write(推导: ), write(Head), nl,
    fail.                   %% 继续寻找新规则
forward :- true.
```

运行 `forward.` 后会反复扫描规则库，直到所有能推导的事实都被推导。

### 带解释的查询

```prolog
explain(Goal) :-
    solve(Goal, 0),
    format("~w 成立~n", [Goal]).

%% 查询
?- explain(animal(zebra)).
zebra 成立
true .
```

### 知识库的组织

实际专家系统会把规则和事实分开文件管理：

```prolog
%% rules.pl
:- multifile rule/2.

rule(animal(mammal), [has(hair), eats(milk)]).

%% facts.pl
:- dynamic known/1.
has(hair).
eats(milk).
```

通过 `consult` 或 `use_module` 加载，推理引擎作为公共库。

### 适用场景

| 场景 | 适用推理 | 原因 |
|------|----------|------|
| 诊断系统 | 后向链 | 从症状倒推病因 |
| 配置系统 | 前向链 | 从零件推导可行配置 |
| 规划系统 | 混合 | 目标导向 + 事实驱动 |

### 性能考量

CLPFD 适合中小型约束系统（变量数百级别）。更大规模时，专业的约束求解器（Google OR-Tools、Choco）通常更快，因为它们针对搜索启发作专门优化。Prolog 的优势在于灵活性和与语言其他特性（DCG、元编程）的无缝集成。

参考：Ivan Bratko《Prolog Programming for Artificial Intelligence》第 4 版。

## 总结

- 约束求解（CLPFD）：声明域 → 发布约束 → 标签搜索。Prolog 替你做回溯。
- 规则推理（专家系统）：后向链从目标推前提，前向链从事实推结论。
- 两者共享同一哲学：你写"是什么"，引擎做"怎么办"。

## 参考

- [The Power of Prolog - Constraints](https://www.metalevel.at/prolog/constraints) — CLPFD 完整指南
- [CLP(FD) Library](https://www.swi-prolog.org/man/clpfd.html) — SWI-Prolog 官方文档
- Sterling & Shapiro, *The Art of Prolog* — meta-interpreter 设计经典
- [The Power of Prolog - Search](https://www.metalevel.at/prolog/search) — 搜索策略深度分析