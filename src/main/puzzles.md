# 脑筋急转弯
:- use_module(library(clpfd)).

> 前置：[列表与递归](../hello-pl/c3b_lists_recursion.md), [规则引擎与约束求解](../hello-pl/c9a.md) | 难度：★★★ | 后续：—

常见的，Prolog 会被认为是解决脑筋急转弯的利器。

在逻辑问题上比其他语言更强吗？下面展示几个例子试图弄清这个问题。

---

> `clpb`（Boolean 约束）和 `clpfd`（Finite Domain 约束）是 SWI-Prolog 的两种约束求解库。
> clpb 处理布尔变量（0/1），clpfd 处理整数域，底层都基于约束传播。

> 参考：[The Power of Prolog - Boolean Constraints](https://www.metalevel.at/prolog/clpb) — clpb 指南。

## 言灵岛

> 就是只能说真话和假话的小岛，很多和逻辑有关的书中都会提到。最原始的版本被叫做 Knights and Knaves

设定：

**作为冒险者的你无意中踏上了一座诡异的小岛，岛上的人天生会被分为只会说谎言（山间土匪）和只会说实话（圣光骑士）两种**

> 需要使用 CLP 约束库<br>
> `use_module(library(clpb)).`<br>
> `sat`约束规则的用法比较简单，`~`表示 false 约束，`*`表示且，`+`表示或

### 场景 1

**你遇到了两个岛民，A，B，A 说："我们两个都说假话！或者他（B）会说真话"**

翻译成约束:

```prolog
?- sat(A =:= ~A + B).
A = B, B = 1.
```

推理结果秒出：A 和 B 都是说真话的。

为什么？A 说"（我说假话 AND B 说假话）OR B 说真话"。如果 B 说真话，则括号内无条件满足（B 真意味着后半句真）。但 A 说假话的话（A=0），~A + B = 1 + B = 1，与 A=0 矛盾，所以 A 必须为真，进而 B 也为真。

### 场景 2

**A 说"我只说假话，B 只说真话"**

```prolog
?- sat(A =:= ~A * B).
A = B, B = 0.
```

A 和 B 都是说谎者。因为 A 说"我是假的且 B 是真的"，如果 A 是真话则 ~A*B 为假 → 矛盾。所以 A 必须是假话，推出 ~A*B = 真 → B 为假（因为如果 B 真则 ~A*B = A 假 * 真 = 0，但 A=0 所以 0=0 不对...等等，检查一下）。

细看：A =:= ~A*B。如果 A=0（假话），则 RHS = ~0 * B = 1 * B = B，约束是 0 =:= B，所以 B=0。如果 A=1 则 RHS = 0*B = 0，1 =:= 0 矛盾。所以 A=0, B=0。

### 场景 3

**你遇到了三个岛民，A 说："我们都说假话"，B 说"我们中有一个人是真话的"**

> 这里需要一个 `card` 语句<br>
> `card([1],[A,B,C])` => ABC 中有一个为真<br>

```prolog
?- sat(A =:= (~A * ~B * ~C)), sat(B =:= card([1],[A,B,C])).
A = C, C = 0,
B = 1.
```

A 明确说了"我们三个都说假话"，如果 A 真则三个都假，与 A 真矛盾，所以 A 假。
B 说"三人中一个真"，A 假所以 B 必须真（这样正好一个真）。C 假。

### 场景 4

这个例子来自于百度知道，且标榜最佳答案的选手还是错的...

```prolog
?- sat(A =:= ~B * ~C), sat(B =:= B), sat(C =:= ~B).
A = 0,
sat(B=\=C)
```

即 A 肯定是说谎者，而 BC 无法确定，同时 BC 是不同的。

`B =:= B` 是永真公式，对 B 无任何约束。`C =:= ~B`使 C 与 B 相反。`A =:= ~B*~C`简化为 `A =:= B`（因为 C=~B，所以 ~B*~C = ~B*B = 0），所以 A=0。

---

#> 更多 CLP(FD) 实例（数独）见 Hello Prolog [c9 篇](../hello-pl/c9.md#ai-和-专家系统)。

# 四色地图

四色定理：任何平面地图可以用最多四种颜色染色，使得相邻区域颜色不同。

用 `clpfd` 约束实现：

```prolog
:- use_module(library(clpfd)).

map_color(Vars) :-
    Vars = [A, B, C, D, E, F],  % 六个区域
    Vars ins 1..4,               % 四色
    A #\= B, A #\= C, A #\= D,
    B #\= C, B #\= E,
    C #\= D, C #\= E, C #\= F,
    D #\= F,
    E #\= F,
    labeling([], Vars).
```

查询：

```prolog
?- map_color([A,B,C,D,E,F]).
A = 1, B = 2, C = 3, D = 2, E = 1, F = 3 ;
A = 1, B = 2, C = 3, D = 2, E = 4, F = 3 ;
...
```

`labeling/2` 是 `clpfd` 的核心——它将变量实例化到具体值。上面只给了相邻不等于约束，没有指定地图的具体形状，因此很多解。

如果不想用 `clpfd`，`clpb` 也可以——每个区域用 2 位二进制表示颜色：

```prolog
:- use_module(library(clpb)).

map_color_b([A1,A2,B1,B2,C1,C2,D1,D2,E1,E2,F1,F2]) :-
    % 每种颜色 2-bit 表示
    sat(A1 * A2 + ~A1 * ~A2),  % 00 或...等等这个约束不对
    % 相邻区域颜色不同 => 对应的 (A1⊕B1) ∨ (A2⊕B2) 必须真
    ...
```

`clpb` 版本比 `clpfd` 繁琐很多——因为位运算要手动做。实际上，`clpfd` 是四色地图更好的选择。

---

## 农夫过河

经典的"狼、羊、白菜"问题：农夫用船把狼、羊、白菜从河的一岸运到另一岸，船每次只能带一样东西。约束：狼不能和羊独处，羊不能和白菜独处。

状态表示：`[Farmer, Wolf, Goat, Cabbage]`，每个变量取值 `e`（东岸）或 `w`（西岸）。

初始状态 `[w,w,w,w]`，目标 `[e,e,e,e]`。

```prolog
:- encoding(utf8).
% 农夫过河 / Wolf Goat Cabbage

travel(e, w).
travel(w, e).

move([X,X,Goat,Cabbage], wolf,   [Y,Y,Goat,Cabbage]) :- travel(X,Y).
move([X,Wolf,X,Cabbage], goat,   [Y,Wolf,Y,Cabbage]) :- travel(X,Y).
move([X,Wolf,Goat,X],    cabbage,[Y,Wolf,Goat,Y])    :- travel(X,Y).
move([X,Wolf,Goat,Cabbage],nothing,[Y,Wolf,Goat,Cabbage]) :- travel(X,Y).

safe([X,_,X,_]).        % 羊和农夫同岸
safe([X,X,_,X]).        % 狼和白菜与农夫同岸（意味着羊在另一边也是安全的）

solve([e,e,e,e], []).
solve(State, [Move|Moves]) :-
    move(State, Move, NextState),
    safe(NextState),
    solve(NextState, Moves).
```

查询：

```prolog
?- length(X,7), solve([w,w,w,w], X).
X = [goat, nothing, wolf, goat, cabbage, nothing, goat] ;
X = [goat, nothing, cabbage, goat, wolf, nothing, goat] ;
false.
```

`length(X,7)` 限制步长为 7 步（最短解）。结果有两个对称解：先运羊 → 空手回 → 运狼/白菜 → 羊回 → 运白菜/狼 → 空手回 → 运羊。

这个问题的 Prolog 解法展示了状态空间搜索的核心模式：
1. **状态表示**：一个列表表示当前状态
2. **转移规则**：`move/3` 定义了合法的状态变化
3. **安全条件**：`safe/1` 过滤非法状态
4. **递归搜索**：`solve/2` DFS 遍历状态空间

如果用其他语言写广度优先搜索（BFS）需要显式维护队列。Prolog 用递归 + 回溯自然地做了 DFS，对于 10 步内能解决的问题足够快。

---

## 汉诺塔

汉诺塔问题：三根柱子，大小不同的盘子从 A 移到 C，大盘不能放在小盘上。

DCG 版本的汉诺塔是递归的经典演示：

```prolog
:- encoding(utf8).

hanoi(N) :-
    phrase(hanoi(N, a, c, b), Moves),
    maplist(writeln, Moves).

hanoi(0, _, _, _) --> [].
hanoi(N, Src, Dst, Aux) -->
    { N #> 0,       N1 is N - 1 },
    hanoi(N1, Src, Aux, Dst),
    [move(N, Src, Dst)],
    hanoi(N1, Aux, Dst, Src).
```

执行：

```prolog
?- hanoi(3).
move(1, a, c)
move(2, a, b)
move(1, c, b)
move(3, a, c)
move(1, b, a)
move(2, b, c)
move(1, a, c)
true.
```

DCG 在这里的作用是**收集移动步骤为一个列表**。`phrase/2` 将 DCG 规则生成的移动序列收集到 `Moves` 中。

对比非 DCG 版本：

```prolog
hanoi(0, _, _, _) :- !.
hanoi(N, Src, Dst, Aux) :-
    N1 is N - 1,
    hanoi(N1, Src, Aux, Dst),
    format("move ~w from ~w to ~w~n", [N, Src, Dst]),
    hanoi(N1, Aux, Dst, Src).
```

DCG 版本的优势：产生式式定义——`hanoi//4` 生成一个移动序列，是声明式的"什么"而非"怎么做"。非 DCG 版本直接输出副作用，难以在其他场景复用。

---

## 数独

Prolog + `clpfd` 的数独求解是约束编程的"Hello World"。完整版：

```prolog
:- use_module(library(clpfd)).

sudoku(Rows) :-
    length(Rows, 9),
    maplist(same_length(Rows), Rows),
    append(Rows, Vars),
    Vars ins 1..9,
    maplist(all_different, Rows),
    transpose(Rows, Cols),
    maplist(all_different, Cols),
    Rows = [A,B,C,D,E,F,G,H,I],
    blocks(A, B, C),
    blocks(D, E, F),
    blocks(G, H, I),
    labeling([], Vars).

blocks([], [], []).
blocks([A,B,C|Bs1], [D,E,F|Bs2], [G,H,I|Bs3]) :-
    all_different([A,B,C,D,E,F,G,H,I]),
    blocks(Bs1, Bs2, Bs3).
```

查询：

```prolog
?- Puzzle = [
    [5,3,_, _,7,_, _,_,_],
    [6,_,_, 1,9,5, _,_,_],
    [_,9,8, _,_,_, _,6,_],
    [8,_,_, _,6,_, _,_,3],
    [4,_,_, 8,_,3, _,_,1],
    [7,_,_, _,2,_, _,_,6],
    [_,6,_, _,_,_, 2,8,_],
    [_,_,_, 4,1,9, _,_,5],
    [_,_,_, _,8,_, _,7,9]
],
sudoku(Puzzle).
```

`clpfd` 的求解过程是声明式的：
1. `ins 1..9`：约束所有变量取值 1~9
2. `all_different/1`：每行、每列、每宫互异
3. `labeling/2`：搜索实例化

步骤 1-2 是**约束建立**阶段，步骤 3 是**搜索求解**阶段。这是约束编程的核心模式——约束传播缩小搜索空间，然后 label 找到解。

与非 clpfd 的"暴力枚举 + 检查"方式比：

```prolog
% 纯 Prolog 数独（无约束传播，慢得多）
sudoku_naive(Rows) :-
    ... 需要手动 perm 九个数 ...
```

`clpfd` 版本的优势：
- 约束传播提前剪枝
- `labeling` 有多种策略可选（`ff` 最约束变量优先）
- 支持更多约束扩展（求和、计数等）

## 小结

这几个脑筋急转弯展示了 Prolog 在逻辑推理问题上的几个核心能力：

- **言灵岛**：`clpb` 布尔约束，真值表推理 → 专用领域秒出
- **四色地图**：`clpfd` 整数约束，邻接约束 → 约束传播剪枝
- **农夫过河**：状态空间搜索 + 递归 DFS → 小状态空间直接暴力
- **汉诺塔**：DCG 产生式序列 → 递归结构天然对应递归解法
- **数独**：`clpfd` 完整约束编程 → 约束建立 + 搜索两步

共同的模式：**声明式规则 + 自动搜索/求解**。这是 Prolog 在逻辑谜题领域的核心竞争力——不需要写算法细节，只需要描述规则和约束。

## 参考

- [The Power of Prolog — Logic Puzzles](https://www.metalevel.at/prolog/puzzles)
- [The Power of Prolog — Boolean Constraints](https://www.metalevel.at/prolog/clpb)
- [The Power of Prolog — Combinatorial Optimization](https://www.metalevel.at/prolog/optimization)