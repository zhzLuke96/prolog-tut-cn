> 高阶阅读：本系列是深度代码分析，适合完成全部 Hello Prolog 章节后阅读。
> 读前须知：本章需完成 Hello Prolog 全部章节。前置依赖：[列表与递归](c3b_lists_recursion.md), [元编译器](../hello-pl/c5.md)。

# bencode

> DCG 基础请参考 Hello Prolog [c4 篇](../hello-pl/c4.md)。

> 前置：[列表与递归](../hello-pl/c3b_lists_recursion.md), [元编译器](../hello-pl/c5.md) | 难度：★★★ | 后续：—


> 在油管看到一个 prolog 的讲座说到了它在特殊领域的优势
> 其中就提到了通过逻辑编程来实现 bencode 的解析工作
> 于是乎找来看了看

https://github.com/mndrix/bencode

> 我曾经尝试过用 py 实现 bencode 解析器
> 说实话，编码上没感觉 pl 有什么优势，反倒更啰嗦
> 但是对于逻辑上的正确性却是出奇的高的

> 单纯和 py 比较的话，py 写代码需要十份时间，而调试需要一百份时间
> pl 的话，花九十份时间写完代码，就能直接跑了，基本不会有问题

---

## 什么是 bencode

BitTorrent 协议用的编码格式。四种类型：

- 整数: `i42e`
- 字节串: `4:spam`（长度前缀+冒号+内容）
- 列表: `l4:spami42ee`
- 字典: `d3:bar4:spam3:fooi42ee`

嵌套任意。没有浮点数、没有布尔、没有 null。

## 代码结构

mndrix/bencode 核心是 `bencode.pl`，用 DCG 实现完整解析器。

```
File: bencode.pl
:- module(bencode, [bencode/2, bdecode/2, bdecode/3]).

bencode(Data, Encoded)  → 编码
bdecode(Encoded, Data)  → 解码
bdecode(Encoded, Data, Rest)  → 带余量的解码
```

看签名就明白了：`bencode/2` 是编码，`bdecode/2` 是解码。典型的双射 API。

## DCG 解析：解码

解码是 DCG 的天然主战场。先看入口：

```prolog
bdecode(A, B) :-
    bdecode(A, B, []).

bdecode(A, B, C) :-
    phrase(value(B), A, C).
```

`phrase/3` 将 `A（输入）` 交给 DCG 规则 `value//1`，`C` 是剩余未消费的部分。

`value//1` 类型分发：

```prolog
value(X) -->
    integer(X).
value(X) -->
    byte_string(X).
value(X) -->
    list(X).
value(X) -->
    dict(X).
```

Prolog 的回溯机制在这里自然形成了类型选择：尝试 integer，失败就回溯试 byte_string，一层层下去。不用 if-elif-else，不用 switch，回溯即控制流。

整数解析：

```prolog
integer(X) -->
    "i",
    number_codes(X),
    "e".
```

`number_codes/2` 是 SWI-Prolog 内置，将数字 ↔ 字符编码列表互转。DCG 直接消费 `"i"` 和 `"e"` 两个字面量。

字节串：

```prolog
byte_string(S) -->
    length_codes(L),
    ":",
    length_codes(S, L).
```

有意思的地方：先解析长度（`length_codes//1`），然后精确读取 L 个字节。`length_codes//1` 实现：

```prolog
length_codes(L) -->
    digit_codes(Digits),
    { number_codes(L, Digits) }.
```

`{}` 包裹的是纯 Prolog 目标，DCG 不转换它。这里用 `number_codes/2` 把数字字符列表转成整数。

列表：

```prolog
list(X) -->
    "l",
    items(X),
    "e".
```

`items//1` 递归解析任意数量的元素：

```prolog
items([X|Xs]) -->
    value(X),
    items(Xs).
items([]) -->
    [].
```

终止条件是空 DCG（`[]`），匹配空输入。与递归规则构成自然的递归数据结构映射。

字典：

```prolog
dict(Pairs) -->
    "d",
    dict_pairs(Pairs),
    "e".
```

键值对解析：

```prolog
dict_pairs([K-V|Ps]) -->
    byte_string(K),
    value(V),
    dict_pairs(Ps).
dict_pairs([]) -->
    [].
```

Bencode 的字典要求键是字节串（byte string），键必须是字符串且按字典序排序。这里用 `K-V` 结构表示键值对。

## DCG 编码

编码走另一个方向：把 Prolog 项序列化成 bencode 格式。

```prolog
bencode(X, S) :-
    phrase(encode(X), S).
```

```prolog
encode(i(I)) -->             % 编码整数
    "i", number_codes(I), "e".
encode(s(S)) -->             % 编码字节串
    length_codes(L), ":", S,
    { length(S, L) }.
encode(l(L)) -->             % 编码列表
    "l", encode_items(L), "e".
encode(d(D)) -->             % 编码字典
    "d", encode_dict(D), "e".
```

注意到编码和解码的类型标签不同：编码时 `s(S)` 表示字节串，`i(I)` 表示整数，`l(L)` 表示列表，`d(D)` 表示字典。解码时直接返回 Prolog 原生类型（整数、原子、列表、键值对列表）。

`encode_dict//1`：

```prolog
encode_dict([K-V|Ps]) -->
    encode(s(K)),
    encode(V),
    encode_dict(Ps).
encode_dict([]) -->
    [].
```

## 与传统命令式解析对比

Python 的标准 bencode 实现（来自 BitTorrent 官方）大致长这样：

```python
def decode(s, i=0):
    if s[i:i+1] == b'i':
        i += 1
        j = s.index(b'e', i)
        return int(s[i:j]), j+1
    elif s[i:i+1].isdigit():
        j = s.index(b':', i)
        n = int(s[i:j])
        return s[j+1:j+1+n], j+1+n
    elif s[i:i+1] == b'l':
        result = []
        i += 1
        while s[i:i+1] != b'e':
            v, i = decode(s, i)
            result.append(v)
        return result, i+1
    elif s[i:i+1] == b'd':
        result = {}
        i += 1
        while s[i:i+1] != b'e':
            k, i = decode(s, i)
            v, i = decode(s, i)
            result[k] = v
        return result, i+1
```

关键区别：

| 维度 | 命令式 | DCG |
|------|--------|-----|
| 状态传递 | 显式 `i` 下标 | 隐式差异表参数 |
| 分支 | `if/elif` | 回溯 + 子句选择 |
| 递归结构 | `while` 循环 | 递归 DCG 规则 |
| 输入消费 | 手动 `i += n` | 自动匹配后剩余 |
| 正确性证明 | 运行时断言 | 声明式语义 |

DCG 版本的核心优势：**差异表参数是 Prolog 编译器自动生成的**。你写 `value(X)`，编译器补成 `value(X, A, B)`，`A` 是当前输入，`B` 是消费后的剩余。零样板代码。

## 正确性分析

DCG 版本的逻辑正确性来自几个层面：

1. **类型标记保证结构一致性**：编码时 `i(I)` / `s(S)` / `l(L)` / `d(D)` 四个函子确保不会把整数当字节串编码。

2. **DCG 的终结保证**：递归规则的终止条件是 `items([]) --> []` 或 `dict_pairs([]) --> []`，与输入空列表匹配。输入不对时自动失败，不会无限循环。

3. **不对称性**：解码不要求输入完全消耗（`bdecode/3` 返回余量），编码则要求完全匹配。这种不对称是合理的——解码时可能有尾部填充，编码时必须精确。

潜在风险：

```prolog
encode(s(S)) -->
    length_codes(L), ":", S,
    { length(S, L) }.
```

这里 `{ length(S, L) }` 是运行时检查，确保声明的长度和实际一致。如果 `S` 是未实例化的变量，`length(S,L)` 会生成一个未初始化的列表——但 `encode/2` 不会用未实例化的输入调用，所以实际不会触发。

## 小结

mndrix/bencode 这段代码展示了 DCG 的经典用法模式：

- DCG 规则结构与 BNF 文法一一对应
- 递归规则映射递归数据结构
- `phrase/3` 的三参数形式天然适合"消费输入，返回剩余"
- 回溯替代控制流分支

代码短（约 80 行核心逻辑），但覆盖了编码解码的全功能。作为庖丁解牛的第一篇，恰如其分——小、完整、可用。

> 去 https://github.com/mndrix/bencode 看源码，再回来看这篇分析，效果更好。

## 参考

- [The Power of Prolog — Meta-interpreters](https://www.metalevel.at/acomip/)
- [The Power of Prolog — DCGs](https://www.metalevel.at/prolog/dcg)