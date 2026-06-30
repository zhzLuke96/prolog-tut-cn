# 列表与递归

> 列表是 [H|T]，递归是处理列表的唯一方式。

> 前置：c2 | 难度：★★ | 后续：c3c

## 列表表示法

列表在 Prolog 里是递归结构。写成 `[H|T]`，H 是 head（第一个元素），T 是 tail（剩余列表）。空表是 `[]`。

> 类比 | JS: `const [H, ...T] = arr` | Python: `H, *T = arr`

对比其他语言：你熟悉的数组（C/Java）是连续内存块，支持随机访问；链表（Lisp/Scheme）本质和 Prolog 列表一样——每个节点分两半：数据和下一个节点。Prolog 列表就是伪装成美观语法的链表。

```prolog
?- [H|T] = [apple, broccoli, crackers].
H = apple,
T = [broccoli, crackers].
```

空表不能拆：

```prolog
?- [H|T] = [].
false.
```

列表本质上是一个嵌套的 dot 结构——SWI-Prolog 里用 `.` 做函子。`write_term/3` 加 `[dot(true)]` 选项能露出现形：

```prolog
?- write_term([a,b,c], [dot(true)]).
.(a,.(b,.(c,[])))
true.
```

也可以用 `=..`（univ）拆开列表的顶层结构：

```prolog
?- [a,b,c] =.. X.
X = ['.', a, [b, c]].
```

第一个参数是 `.`（列表函子），第二个是 head `a`，第三个是 tail `[b, c]`。

记住：`[a,b,c]` 只是 `.(a, .(b, .(c, [])))` 的语法糖。处理列表就是处理这棵右倾二叉树。

## member/2 — 元素与列表的关系

member/2 定义的是**元素和列表之间的关系**：当 X 是列表 L 的一个元素时，关系成立。这不是"检查函数"，而是双向关系。

最一般的查询：

```prolog
?- member(X, [a,b,c]).
X = a ;
X = b ;
X = c .
```

## member/2 -- 遍历列表

最基础的列表谓词，定义只有两行：

```prolog
member(X, [X|_]).          % 找到了！head 就是要找的元素
member(X, [_|T]) :-        % 当前 head 不是，去 tail 找
    member(X, T).
```

边界条件：X 就是 head。递归条件：跳过 head，从 tail 继续找。

> 类比 | JS: `arr.includes(x)` / `arr.some()` | Python: `x in list` / `any()`

> **Prolog 时刻** — member/2 既是检查器又是生成器。同一份代码两种用法。

查询模式 1--检查元素是否在列表中：

```prolog
?- member(c, [a,b,c]).
true .

?- member(z, [a,b,c]).
false.
```

查询模式 2--生成列表的所有元素（回溯驱动）：

```prolog
?- member(X, [a,b,c]).
X = a ;
X = b ;
X = c .
```

拿分号回溯时，Prolog 放弃第一个子句（head 匹配），进入第二个子句递归到 tail。整个过程就是深度优先遍历列表。

如果你只需要"在不在"，不要写 `member(X, List), X = a` 这种绕弯写法--直接 `member(a, List)`。

member/2 也能检查多个条件：

```prolog
?- member(X, [1,2,3,4]), X > 2.
X = 3 ;
X = 4 .
```

先回溯生成值，再筛选--顺序决定了结果。

## append/3 -- 拼接列表

append/3 把两个列表拼成一个：

```prolog
append([], X, X).                 % 空表 + X = X
append([H|T1], X, [H|T2]) :-      % 把 H 放到结果 head，递归拼 tail
    append(T1, X, T2).
```

> 类比 | JS: `arr1.concat(arr2)` / `[...a, ...b]` | Python: `list1 + list2`

正向用--拼接：

```prolog
?- append([a,b], [c,d], X).
X = [a, b, c, d].
```

反向用--枚举所有拆分方式：

```prolog
?- append(X, Y, [a,b,c]).
X = [],
Y = [a, b, c] ;
X = [a],
Y = [b, c] ;
X = [a, b],
Y = [c] ;
X = [a, b, c],
Y = [] ;
false.
```

这是 append/3 最惊人的特性：同一份代码，能算拼合也能算拆分。背后是 Prolog 的联合机制--第三个参数已知时，第一个参数的 head 和 tail 被逐步展开，直到第一个参数缩减为 `[]`。

性能：append/3 是 O(n)，n 是第一个参数的长度。**第一个参数短，append 就快。** 如果反复往列表末尾加元素，考虑用差量列表（DCG）或先构建再翻转。

append/3 也能拼三个以上的列表--嵌套调用：

```prolog
?- append([a], [b], X), append(X, [c], Y).
X = [a, b],
Y = [a, b, c].
```

## 递归模式

处理 Prolog 列表的标准三步：

1. **处理 head** -- 对当前第一个元素做点什么
2. **递归 tail** -- 剩下的交给递归
3. **合并结果** -- 把第一步和第二步组合起来

示例：list_length/2

```prolog
list_length([], 0).                 % 空表长度 = 0
list_length([_|T], N) :-            % 不管 head 是什么
    list_length(T, N1),             % 先算 tail 长度
    N is N1 + 1.                    % 合并：+1
```

```prolog
?- list_length([a,b,c], N).
N = 3.
```

示例：sum_list/2

```prolog
sum_list([], 0).
sum_list([H|T], S) :-
    sum_list(T, S1),
    S is H + S1.
```

```prolog
?- sum_list([1,2,3,4], S).
S = 10.
```

两个谓词走的是同一个模式：边界条件处理空表，递归步拆 head/tail，最后用 `is/2` 合并结果。

## 累加器模式

前面的递归模式有一个问题：每层递归都要等下一层返回结果才能计算。这意味着 Prolog 必须保留每个栈帧--栈空间 O(n)。如果列表很长（数万元素），栈溢出。

解决方案：引入累加器（accumulator）参数，把计算结果"向下传递"，而不是"向上返回"。

这称为**尾递归**（tail recursion）--递归调用出现在子句最后一步（尾位置），且当前层不再需要对返回值做额外操作。

> 类比 | JS: `reduce()` | Python: `functools.reduce()`

### 累加器版 factorial

先看非尾递归版：

```prolog
fact1(1, 1).
fact1(N, F) :-
    N > 1,
    N1 is N - 1,
    fact1(N1, F1),
    F is N * F1.
```

尾递归版--引入累加器参数：

```prolog
fact2(1, Acc, Acc).
fact2(N, Acc, F) :-
    N > 1,
    N1 is N - 1,
    Acc1 is N * Acc,
    fact2(N1, Acc1, F).
```

```prolog
?- fact2(5, 1, F).
F = 120.
```

初始累加器是 `1`（乘法的单位元）。每层递归做 `N * Acc` 并传给下一层。到达边界时直接返回累加器。

### 累加器版 reverse

非尾递归版--需要在递归返回后 append：

```prolog
naive_rev([], []).
naive_rev([H|T], R) :-
    naive_rev(T, R1),
    append(R1, [H], R).
```

```prolog
?- naive_rev([a,b,c], R).
R = [c, b, a].
```

性能问题：每层递归都调用 append/3，复杂度 O(n^2)。

尾递归版--用累加器构建反向列表：

```prolog
rev_acc([], Acc, Acc).
rev_acc([H|T], Acc, R) :-
    rev_acc(T, [H|Acc], R).
```

```prolog
?- rev_acc([a,b,c], [], R).
R = [c, b, a].
```

初始累加器是 `[]`。遍历原列表时，把每个 head 塞到累加器前面。第一个元素到累加器时在最底，最后一个元素在最顶--刚好翻转。

复杂度 O(n)，常数栈空间。

### 对比总结

| 特性 | 非尾递归 | 尾递归（累加器）|
|------|----------|----------------|
| 空间复杂度 | O(n) 栈 | O(1) 栈 |
| 递归位置 | 不在尾位置 | 尾位置 |
| 需要等返回值 | 是 | 否 |
| 累加器参数 | 无 | 有 |
| 适合场景 | 小列表、树结构 | 大列表、线性遍历 |

如果 Prolog 实现支持 TRO（Tail Recursion Optimization，SWI-Prolog 默认启用），尾递归栈空间常量。否则递归多了一样栈溢出。

经验法则：需要遍历整个列表生成一个值--用累加器。需要构建或遍历树形结构--非尾递归更自然。

## 总结

- 列表是 `[H|T]` 结构，本质是嵌套 dot/2 函子
- member/2 遍历列表：head 匹配或递归 tail
- append/3 正向拼合、反向拆分，Prolog 联合的双向性体现
- 递归三步：处理 head、递归 tail、合并结果
- 累加器模式把"向上返回"变"向下传递"，达到尾递归 TRO

当你想"对一个列表每个元素做 X"，先想清楚是遍历、过滤、转换还是累积。每类操作都有对应模式--member、append、累加器，再加后面会学的 maplist 和 fold。

## 参考

- 「从零开始」chapter12（列表基础）、chapter9（递归）、chapter15（流程控制与尾递归）
- The Power of Prolog -- Lists (https://www.metalevel.at/prolog/lists)
- SWI-Prolog 手册 -- Section 4.2 (Lists)

