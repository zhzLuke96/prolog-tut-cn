# 搜索与自然语言

> 一句话概括：搜索是推理的引擎，DCG 是语言的门——路径规划和 ELIZA 聊天机器人，展示 Prolog 在两个方向的极致表达力。

> 前置：c4 | 难度：★★★ | 后续：—

## 路径规划：机器人电池

经典猴子香蕉问题改编：机器人要从门口拿到天花板的电池，有箱子可以垫脚。

### 状态表示

```prolog
%% state(机器人位置, 是否在箱子上, 箱子位置, 是否有电)
do(state(middle, onbox, middle, no),  grab,   state(middle, onbox, middle, yes)).
do(state(L,    onfloor, L,    Power), climb,  state(L, onbox, L, Power)).
do(state(L1, onfloor, L1, Power), push(L1, L2), state(L2, onfloor, L2, Power)).
do(state(L1, onfloor, Box, Power), walk(L1, L2), state(L2, onfloor, Box, Power)).
```

四个动作：`walk/2` 移动、`push/2` 推箱子、`climb/0` 爬上箱子、`grab/0` 抓电池。

### DFS 深度优先搜索

```prolog
canget(state(_, _, _, yes)) :- !.

canget(State) :-
    do(State, Action, Next),
    canget(Next).

%% 记录路径
canget(state(_, _, _, yes), []) :- !.
canget(State, [Action|Plan]) :-
    do(State, Action, Next),
    canget(Next, Plan).
```

> **Prolog 时刻** — 同一个 predicate 的多个子句天然构成搜索树。DFS 是 Prolog 的默认搜索策略。

查询：

```prolog
?- canget(state(door, onfloor, window, no), Plan).
Plan = [walk(door, window), push(window, middle), climb, grab] .
```

DFS 的问题：遇到循环会无限递归。用 `\+` 检查 visited 状态可以缓解：

```prolog
canget(State, Visited, [Action|Plan]) :-
    do(State, Action, Next),
    \+ memberchk(Next, Visited),
    canget(Next, [Next|Visited], Plan).
```

### BFS 广度优先搜索

BFS 保证最短路径，代价是内存更高：

```prolog
canget_bfs(Start, Plan) :-
    bfs([[Start, []]], Plan).

bfs([[state(_, _, _, yes), Plan]|_], Plan) :- !.
bfs([[State, Plan]|Rest], Result) :-
    findall([Next, [A|Plan]],
            do(State, A, Next),
            Children),
    append(Rest, Children, Queue),
    bfs(Queue, Result).
```

BFS 用队列 FIFO——每次扩展当前状态的所有后继，逐层推进。第一个到达目标状态的就是最短路径。

### 延伸：A* 搜索

DFS 和 BFS 是盲目搜索。当问题空间有可用的启发式信息时，A*（A-star）更高效。A* 维护优先级队列，根据 `f(n) = g(n) + h(n)` 选择下一个扩展节点——其中 g(n) 是已耗代价，h(n) 是剩余代价的启发估计。

Prolog 实现 A* 的挑战在于需要全局优先级队列，这偏离了纯声明式风格。通常用 `library(heaps)` 或 `library(assoc)` 实现。

> 超出本教程范围。有兴趣的读者参考 Ivan Bratko《Prolog Programming for Artificial Intelligence》第 4 版。

### 搜索策略对比

| 策略 | 完备性 | 最优性 | 内存 |
|------|--------|--------|------|
| DFS | 不完备（循环） | 不保证 | O(d) |
| DFS + visited | 完备 | 不保证 | O(d) |
| BFS | 完备 | 最优 | O(b^d) |
| 迭代加深 | 完备 | 最优 | O(d) |

Prolog 的天然回溯机制让 DFS 实现最简单。需要最优解时，BFS 或迭代加深是更好选择。

> 参考：[The Power of Prolog - Search](https://www.metalevel.at/prolog/search) — 搜索策略在 Prolog 中的实现与优化。

## DCG 与自然语言

Prolog 的 DCG（定子句文法，c4 和"从零开始"chapter16 有完整介绍）让自然语言处理变得极其自然。

### DCG 回顾

DCG 本质是语法糖：`a --> b, c.` 编译为 `a(X, Y) :- b(X, Z), c(Z, Y).`。隐藏的差量列表参数自动传递，你可以专注写文法规则。

从零开始 chapter16 的句子解析：

```prolog
sentence --> noun_phrase, verb_phrase.
noun_phrase --> determiner, noun.
verb_phrase --> verb, noun_phrase.
determiner --> [the]; [a].
noun --> [cat]; [dog]; [apple].
verb --> [eats]; [chases].
```

DCG 不只能解析——加上参数还能构建语义树：

```prolog
sentence(VP) --> noun_phrase(Subj), verb_phrase(VP), { VP =.. [_, Subj] }.
```

### ELIZA：用模式匹配做对话

ELIZA（1966）是第一个聊天机器人。它不"理解"语言——只是用模式匹配抓关键词，反转句式。Prolog 的 DCG 和模式匹配是实现 ELIZA 的绝配。

```prolog
:- use_module(library(readutil)).
:- use_module(library(strings)).

eliza :-
    repeat,
        write("> "),
        read_line_to_string(user_input, Input),
        (   Input == "bye"
        ->  write("Goodbye."), nl, !
        ;   respond(Input, Reply),
            format("Eliza: ~w~n", [Reply]),
            fail
        ).

respond(Input, Reply) :-
    string_lower(Input, Lower),
    split_string(Lower, " .,!?", "", Words),
    rule_match(Words, Reply).

rule_match(Words, Reply) :-
    pattern(Words, Reply), !.
rule_match(_, "I see. Tell me more.").
```

### 模式规则

```prolog
pattern([i, need, X|_], Reply) :-
    format(string(Reply), "Why do you need ~w?", [X]).
pattern([i, am, X|_], Reply) :-
    format(string(Reply), "How long have you been ~w?", [X]).
pattern([i, feel, X|_], Reply) :-
    format(string(Reply), "Tell me about feeling ~w.", [X]).
pattern([how, i, can, X|_], Reply) :-
    format(string(Reply), "Why do you want to ~w?", [X]).
pattern([because, X|_], Reply) :-
    format(string(Reply), "Is ~w the real reason?", [X]).
pattern(_, "That is interesting. Please continue.").
```

运行 `eliza.` 即可聊天。

### 用 DCG 改写模式匹配

上面用 `split_string` 切词、`pattern` 匹配。DCG 版本更优雅——直接在语法层操作 token 流：

```prolog
%% 用 DCG 定义对话模式
eliza_reply(Reply) -->
    keyword(i, need),        rest(X),
    { format(string(Reply), "Why do you need ~w?", [X]) }.
eliza_reply(Reply) -->
    keyword(i, am),          rest(X),
    { format(string(Reply), "How long have you been ~w?", [X]) }.
eliza_reply(Reply) -->
    keyword(i, feel),        rest(X),
    { format(string(Reply), "Tell me about feeling ~w.", [X]) }.
eliza_reply("I see. Tell me more.") --> [].

keyword(K1, K2) --> [K1, K2].
rest([W|Ws]) --> [W], rest(Ws).
rest([]) --> [].
```

DCG 的自动差量列表传递，省掉了手动管理 token 位置的代码。

### 从零开始 chapter16 联动

从零开始 chapter16 覆盖了 DCG 基础：句子解析、树构建、自然语言接口。本章 ELIZA 展示 DCG 的另一个应用场景——对话引擎。

两者结合可以做更复杂的系统：

1. 用 DCG 解析用户输入 → 语义树
2. 用规则引擎（c9a）推理意图
3. 用 DCG 生成自然语言回复

整套 pipeline 用纯 Prolog 实现，不过几百行。

### 为什么这很重要

ELIZA 展示了规则型系统的核心模式：模式匹配 + 模板输出。在 2026 年，规则型对话在客服工单、故障排查等场景仍有生产价值。混合架构（LLM 语义理解 + 规则决策）是当前最佳实践。

### 局限性

当前 ELIZA 实现不做状态追踪（不记得你之前说了什么），模式匹配是线性的（长输入下 O(n)），也没有情感分析。完整的对话系统还需要意图识别、实体提取、对话管理——这些在 Prolog 中可以用 DCG + 高阶谓词组合实现，但复杂度远超本节的 toy 实现范围。

## 总结

- 路径规划：DFS 直接利用 Prolog 回溯，BFS 保证最优解
- 搜索策略选型取决于场景——有限状态空间用 DFS + visited，需要最优用 BFS
- DCG 从 parsing 到 generation 统一语法，ELIZA 展示模式匹配 + 对话管理
- 搜索 + DCG + 规则引擎组合，就是一个轻量级对话 AI 的基石

## 参考

- [The Power of Prolog - Search](https://www.metalevel.at/prolog/search) — 搜索策略深度分析
- [The Power of Prolog - Constraints](https://www.metalevel.at/prolog/constraints) — 约束与搜索
- SWI-Prolog DCG 文档：`library(dcg/basics)` 实用 DCG 工具
- ELIZA 完整实现参考：https://gist.github.com/thaenor/2c79139c4a2e9e5135c5