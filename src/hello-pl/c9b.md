# 搜索与自然语言

> 一句话概括：DFS/BFS 不是理论概念——是让机器人自己找到电池的手段。DCG 不是语法玩具——几十行就能写个心理医生。

> 前置：[DCG](c4.md) | 难度：★★★ | 后续：—

学完这章，你能让机器人在房间里自己找路拿到电池，再用几十行代码写一个能跟你聊天的心理医生。

## 让机器人自己找路

地上一个箱子，天花板上有块电池。机器人在门口，它要拿到电池。怎么过去？

人类一下就想到：走到箱子旁，推箱子到电池下方，爬上去，拿到电池。但计算机不懂这些——它需要你把"房间的状态"和"动作的效果"描述清楚。

### 先描述这个世界

```prolog
%% state(机器人位置, 是否在箱子上, 箱子位置, 是否有电)
do(state(middle, onbox, middle, no),  grab,   state(middle, onbox, middle, yes)).
do(state(L,    onfloor, L,    Power), climb,  state(L, onbox, L, Power)).
do(state(L1, onfloor, L1, Power), push(L1, L2), state(L2, onfloor, L2, Power)).
do(state(L1, onfloor, Box, Power), walk(L1, L2), state(L2, onfloor, Box, Power)).
```

四条规则定义了四个动作：
- `walk(L1, L2)` — 从位置 L1 走到 L2
- `push(L1, L2)` — 把箱子从 L1 推到 L2（自己也在 L1）
- `climb` — 爬上箱子（必须在箱子位置）
- `grab` — 抓电池（必须在箱子上，且在中部位置）

够描述整个问题了。现在问题是：怎么让计算机自己找到一系列动作？

### 最简单的解法：一路试到底

```prolog
canget(state(_, _, _, yes)) :- !.   %% 已经拿到了

canget(State) :-
    do(State, Action, Next),        %% 试一个动作
    canget(Next).                   %% 继续试
```

这就完了？这就完了。

Prolog 的搜索策略就是深度优先。`canget(Start)` 先试一个动作，走到新状态，继续试下一个动作。如果走不通（不满足任何 `do`），回溯到上一步试别的。

但跑一下就发现问题了——机器人会来回走："走到窗口，走回门口，走到窗口，走回门口……" 无限循环。因为 DFS 不记录去过哪。

### 加个备忘录

```prolog
canget(State, Visited, [Action|Plan]) :-
    do(State, Action, Next),
    \+ memberchk(Next, Visited),          %% 没去过的地方才走
    canget(Next, [Next|Visited], Plan).
```

把去过的地方记下来，已经走过的状态就不走了。同时输出路径：

```prolog
canget(state(_, _, _, yes), _, []).     %% 到了目标，路径为空
canget(State, Visited, [Action|Plan]) :-
    do(State, Action, Next),
    \+ memberchk(Next, Visited),
    canget(Next, [Next|Visited], Plan).
```

查询：

```prolog
?- canget(state(door, onfloor, window, no), [state(door, onfloor, window, no)], Plan).
Plan = [walk(door, window), push(window, middle), climb, grab] .
```

机器人找到路了：先走到窗口，把箱子推到中间，爬上去，抓电池。

> **Prolog 时刻** — 同一个 predicate 的多个子句天然构成搜索树。`do(State, Action, Next)` 每回溯一次返回一种可能的动作——你不需要写循环、不需要手动管理栈。DFS 是 Prolog 的默认搜索策略。

### 但 DFS 找到的不一定最短

DFS 的脾气：一条路走到黑。如果中间有任意一条路径通到目标，它就停了，不保证是最短路径。

要最短路径，用 BFS：

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

BFS 换了个思路：不一次探到底，而是逐层展开——先看一步能到哪些状态，再看两步，再看三步……第一个到达目标状态的路径一定是最短的。

代价呢？内存。BFS 要维护一整个队列，最坏情况能膨胀到 $O(b^d)$——b 是分支因子，d 是深度。DFS 的 visited 版本只需要 $O(d)$。

> 类比 | Git: DFS 类似 `git log --first-parent` 一条线追到底；BFS 类似 `git log --all --graph` 逐层展开所有分支。

### 延伸：如果问题再大一点

DFS 和 BFS 都是盲目搜索——它们不管"目标在哪"，只管"把所有可能状态试一遍"。如果房间有 100 个位置、1000 个物体，这就不行了。

A* 搜索引入了启发函数 `h(n)`——估计"从当前状态到目标还要多远"。选择下一个扩展节点时，按 `f(n) = g(n)（已走距离） + h(n)（估计还剩多远）` 排序，优先试最有希望的方向。

Prolog 实现 A* 的挑战在全局优先级队列，偏离了纯声明式风格。通常用 `library(heaps)` 或 `library(assoc)` 来模拟。

> 超出本教程范围。有兴趣的读者参考 Ivan Bratko《Prolog Programming for Artificial Intelligence》第 4 版。

### 搜索策略速查

| 策略 | 能找到解吗 | 最短路径？ | 内存 |
|------|-----------|-----------|------|
| DFS | 循环时不行 | 不保证 | $O(d)$ |
| DFS + visited | 能 | 不保证 | $O(d)$ |
| BFS | 能 | 是 | $O(b^d)$ |
| 迭代加深 | 能 | 是 | $O(d)$ |

> 参考：[The Power of Prolog - Search](https://www.metalevel.at/prolog/search) — 搜索策略在 Prolog 中的实现与优化。

## 几十行代码写个心理医生

1966 年，MIT 的 Joseph Weizenbaum 写了一个叫 ELIZA 的程序。它假装成心理医生，用模式匹配把用户说的话换个角度抛回去。你抱怨"我很累"，它回"你感觉累多久了？" —— 完全不懂什么是累，但对话竟然"好像"能进行下去。

现在的 LLM 风生水起，但 ELIZA 的哲学依然有用：模式匹配 + 模板输出，几千条规则就能覆盖大部分客服、故障排查场景。而且 ELIZA 全部代码就几十行。

### Prolog 版本的核心循环

```prolog
:- use_module(library(readultil)).
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
```

`repeat` + `fail` 结构构成了一个永远循环的 REPL，只有输入 `bye` 才退出。

### 模式匹配规则

```prolog
respond(Input, Reply) :-
    string_lower(Input, Lower),
    split_string(Lower, " .,!?", "", Words),
    rule_match(Words, Reply).

rule_match(Words, Reply) :-
    pattern(Words, Reply), !.
rule_match(_, "I see. Tell me more.").
```

切词、小写、匹配规则。没有匹配到任何规则时就回个通用回答。

规则的写法很直白：

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

模式匹配检查句子前几个词，把剩下的内容抓到 X 里，塞进模板输出。你说"I need help"，它问"Why do you need help?"——完全不懂 help 是什么意思，但对话就是"进行下去了"。

> 类比 | React: pattern 规则 ≈ switch-case 路由，format 模板 ≈ JSX 表达式插值

### 用 DCG 改写得更好看

上面的实现用了 `split_string` 切词、`pattern` 做前缀匹配。DCG 版本在语法层操作 token 流，更优雅：

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

DCG 的自动差量列表参数，省掉了手动管理 token 位置的代码。每一条 `eliza_reply` 规则就是一个对话模式——匹配输入 token 流，提取关键词后的内容，生成回复。

### 从 ELIZA 到真的对话系统

ELIZA 只是起点。把这个跟 c9a 的规则引擎结合，就能搭一个真正的对话系统：

1. DCG 解析用户输入 → 语义树
2. 规则引擎推理 → 理解意图
3. DCG 生成自然语言回复

整套 pipeline 几百行纯 Prolog。跟 LLM 比，规则系统不会胡编乱造、可调试、可追溯。2026 年混合架构（LLM 语义理解 + 规则决策）是生产标准。

> 从零开始 chapter16 覆盖了 DCG 基础：句子解析、树构建、自然语言接口。本章 ELIZA 是 DCG 在对话场景的应用。

### 当前的局限

- 不存状态 — ELIZA 不记得你上句说了什么
- 线性的模式匹配 — 长输入下 O(n) 扫一遍
- 无情感分析 — 不管你说什么，调子一样

完整的对话系统还需要意图消歧、实体提取、对话管理——Prolog 用 DCG + 高阶谓词组合能做，但那又是另一章了。

## 总结

- 机器人找电池：DFS 直接利用 Prolog 回溯，BFS 保证最优解。选择看场景——有限状态空间用 DFS + visited，要最短路径上 BFS。
- ELIZA 心理医生：几十行代码 + 模式匹配规则，就能做出"能对话"的程序。DCG 版本更优雅，把模式匹配写在语法层。
- 搜索 + DCG + 规则引擎组合，就是一个轻量级对话 AI 的基石。

## 参考

- [The Power of Prolog - Search](https://www.metalevel.at/prolog/search) — 搜索策略深度分析
- [The Power of Prolog - Constraints](https://www.metalevel.at/prolog/constraints) — 约束与搜索
- SWI-Prolog DCG 文档：`library(dcg/basics)` 实用 DCG 工具
- ELIZA 完整实现参考：https://gist.github.com/thaenor/2c79139c4a2e9e5135c5