# 图灵完备

> 前置：[列表与递归](../hello-pl/c3b_lists_recursion.md), [元编译器](../hello-pl/c5.md) | 难度：★★★ | 后续：—

如何证明一个语言是否图灵完备？用这个语言实现一个图灵机模拟器，应该是最直接的方法了。

> Prolog 是图灵完备的吗？是的。
> 但它的控制结构（回溯、联合、未实例化变量）和传统命令式语言完全不同——证明它图灵完备有助于理解 Prolog 的计算能力边界。

参考 Markus Triska 的实现：

https://www.metalevel.at/prolog/showcases/turing.pl

---

## 代码结构

Triska 的图灵机模拟器核心代码约 50 行，结构清晰：

```prolog
:- use_module(library(clpfd)).

turing(Tape, Initial, Rules, Final, FinalTape) :- ...
```

参数：

| 参数 | 含义 |
|------|------|
| `Tape` | 初始纸带（列表） |
| `Initial` | 初始状态 |
| `Rules` | 转移规则列表 |
| `Final` | 终止状态 |
| `FinalTape` | 最终纸带 |

五参入口覆盖了图灵机的全部要素：纸带、状态、规则、终止条件、输出。

## 纸带表示

图灵机的纸带是无限长的。我们没法在 Prolog 中表示无限长列表。

解决方案：**用差异表（difference list）表示纸带的左右两部分**。

```prolog
tape(Left, Right, Blank).
```

- `Left`：读写头左边的部分（逆序存储，方便在头部插入）
- `Right`：读写头当前位置及右边的部分
- `Blank`：空白符号

差异表的关键优势：向纸带两端延伸时，不需要预先分配空间。空白部分"虚拟存在"——当需要延伸到空白区域时，才生成一个空白符号。

例如，纸带 `[a,b,c]` 读写头在 `b`：

```prolog
tape([a], [b, c], \'_\')
```

`Left = [a]` 是左边的部分逆序（实际上顺序是从左到右读——`[a]` 是逆序存储所以左边只有一个元素 `a`），`Right = [b,c]` 是当前位置及右边的部分。

向左移动时，从 Left 头取一个符号放到 Right 头部：

```prolog
left(tape([L|Ls], Rs, B), tape(Ls, [L|Rs], B)).
```

向右移动时，从 Right 头取一个符号放到 Left 头部：

```prolog
right(tape(Ls, [R|Rs], B), tape([R|Ls], Rs, B)).
```

边界情况——如果需要延伸到空白区域，`Right = []` 时用 `[B]` 代替：

```prolog
right(tape(Ls, [], B), tape([B|Ls], [], B)).
```

## 转移规则

```prolog
rule(Q0, S0, Q1, S1, D)
```

- `Q0`：当前状态
- `S0`：当前符号
- `Q1`：下一个状态
- `S1`：写入的符号
- `D`：移动方向（`left` / `right`）

示例规则（从初态 `q0` 读取 `0`，向左移动并保持）：

```prolog
rule(q0, 0, q0, 0, left).
```

## 执行引擎

核心循环：

```prolog
turing(tape(L, [S|Rs], B), Q0, Rules, Final, Tape) :-
    (   Q0 == Final
    ->  Tape = tape(L, [S|Rs], B)
    ;   member(rule(Q0, S, Q1, S1, D), Rules),
        symbol(S1, tape(L, [S1|Rs], B), Tape1),
        move(D, Tape1, Tape2),
        turing(Tape2, Q1, Rules, Final, Tape)
    ).
```

这是一个递归谓词：

1. 检查当前状态是否等于终止状态。是则返回结果。
2. 否则在规则列表中找一条匹配 `(Q0, S)` 的规则。
3. 写入新符号 `S1`。
4. 执行移动（左/右）。
5. 递归进入下一个状态。

`member/2` 搜索规则列表，实现非确定性——如果有多个规则匹配同一个 (Q0, S)，Prolog 的回溯会尝试所有可能的路径。这意味着这个模拟器本身就是一个非确定性图灵机（NDTM）。

## Step 细节

```prolog
symbol(S, tape(L, [_|Rs], B), tape(L, [S|Rs], B)).
move(D, Tape, NewTape) :-
    (   D == left  -> left(Tape, NewTape)
    ;   D == right -> right(Tape, NewTape)
    ).
```

`symbol/3` 用 `[_|Rs]` 丢弃当前符号，并将 `S` 写入对应位置。

`move/3` 根据 `D` 选择左/右移动。这是显式的条件分支，没有使用回溯。

## 例子：递增二进制数

Triska 给的例子：递增一个二进制数。

```prolog
inc(L0, L) :-
    Rules = [rule(q0, 0, q0, 0, right),
             rule(q0, 1, q0, 1, right),
             rule(q0, b, q1, b, left),
             rule(q1, 0, q1, 1, left),
             rule(q1, 1, q1, 0, left),
             rule(q1, b, q2, 1, right)],
    turing(tape([], L0, b), q0, Rules, q2, Tape),
    tape(_, L, _) = Tape.
```

逻辑：
1. 右移到最右端（`q0` 状态）
2. 左移回来（`q1` 状态）
3. 遇到 0 变 1 进位停止，遇到 1 变 0 继续左移
4. 碰到空格在最前面加 1

执行：

```prolog
?- inc([1,0,1,1], L).
L = [1,1,0,0].
```

像 Prolog 常见的做法，`inc/2` 是一个封装谓词，隐藏了图灵机状态的管理。调用者只需提供和接收纸带列表，不接触图灵机内部细节。

## 证明图灵完备

要证明 Prolog 图灵完备，需要展示：

1. **Prolog 可以实现任意图灵机**：上面的模拟器证明了这一点——任何图灵机的规则都能用 `rule/5` 表示，并驱动 `turing/5` 执行。

2. **Prolog 可以模拟任意图灵机计算**：因为 `turing/5` 是一个递归谓词，递归深度不限（实际上受栈限制，但理论上无上限），纸带可以无限延伸（差异表惰性生成空白），所以任何计算都可以模拟。

3. **Prolog 有无限存储**：列表可以包含任意多项，差异表使纸带可以向两端无限延伸。

反过来，图灵机也可以模拟 Prolog——所有图灵完备的语言在计算能力上等价（Church-Turing 论题）。

## 实际限制

理论上图灵完备，但实际中要承认几个约束：

- **递归深度**：SWI-Prolog 默认局部栈约 128MB，可调整
- **有限内存**：纸带差异表惰性扩展但终究受物理内存限制
- **全局变量不在回溯中重置**：`nb_setval/2` 等破坏性赋值打破了声明式语义
- **Term 大小限制**：SWI-Prolog 有最大项大小限制（`max_arity`）

但这些是工程实现限制，不影响理论图灵完备性。

> 本节内容基于 [The Power of Prolog - Turing Machines](https://www.metalevel.at/prolog/showcases/turing.pl) 的分析与扩展。

## 意义

学这个的意义不在于你真的会用图灵机做实际开发——你不会的。

意义在于：

1. **理解 Prolog 的计算模型**：Prolog 不只是一个规则匹配器，它是一个通用计算系统。能模拟图灵机说明它的计算能力和 C、Java、Python 一样强。

2. **理解声明式语言中的控制流**：`turing/5` 的核心是递归 + member 搜索规则——不是循环 + switch。这种控制流是 Prolog 式的。

3. **理解差异表的实际应用**：纸带的左右分片是差异表在"无限"数据上的应用。对比其他语言中为了无限纸带做的复杂抽象，Prolog 的差异表方案几乎是零样板代码。

4. **元编程练习**：`turing/5` 是一个图灵机解释器——它把用规则描述的程序（图灵机指令）执行在 Prolog 运行时上。这和 lisprolog（cs2）的 eval 是同类东西。

> 把 https://www.metalevel.at/prolog/showcases/turing.pl 贴进 SWI-Prolog 跑一下。
> 改几条规则，看看能不能实现一个加法图灵机。

## 参考

- [The Power of Prolog — Meta-interpreters](https://www.metalevel.at/acomip/)
- SWI-Prolog manual: Clause creation and destruction