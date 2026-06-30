> 高阶阅读：本系列是深度代码分析，适合完成全部 Hello Prolog 章节后阅读。
> 读前须知：本章需完成 Hello Prolog 全部章节。前置依赖：[列表与递归](c3b_lists_recursion.md), [元编译器](../hello-pl/c5.md)。

# bencode

> DCG 基础请参考 Hello Prolog [c4 篇](../hello-pl/c4.md)。

> 前置：[列表与递归](../hello-pl/c3b_lists_recursion.md), [元编译器](../hello-pl/c5.md) | 难度：★★★ | 后续：—

记得曾经有人问我：Prolog 到底能干什么？我说解析二进制协议。他不信。

那我说个具体的——bencode。BitTorrent 协议用的编码格式。你可能没用过 BitTorrent 的 DHT 网络，但你一定听说过 BT 下载。它传输的所有元数据，都是 bencode 编解码的。

https://github.com/mndrix/bencode

我试过用 Python 写 bencode 解析器。编码上没觉得 Prolog 有什么优势，反倒更啰嗦。但有一个地方 Python 完全比不了——**逻辑正确性**。

纯 Python 写代码花十分时间，调试要一百分。Prolog 花九十分写代码，写完就能直接跑，基本不会有问题。

不是代码少，是正确性高。这一篇就来看为什么。

## 什么是 bencode

四种类型，嵌套任意：

- 整数：`i42e`
- 字节串：`4:spam`（长度 + 冒号 + 内容）
- 列表：`l4:spami42ee`
- 字典：`d3:bar4:spam3:fooi42ee`

没有浮点数、没有布尔、没有 null。简洁得有点原始。

## 代码结构

mndrix/bencode 的核心在 `bencode.pl`，DCG 实现编解码。

```
File: bencode.pl
:- module(bencode, [bencode/2, bdecode/2, bdecode/3]).

bencode(Data, Encoded)  →  编码
bdecode(Encoded, Data)  →  解码
bdecode(Encoded, Data, Rest)  →  解码，返回剩余
```

注意签名——`bencode/2` 和 `bdecode/2` 正好相反。典型的双射 API。

## DCG 解析：解码

解码是 DCG 的天然主场。先看入口：

```prolog
bdecode(A, B) :-
    bdecode(A, B, []).

bdecode(A, B, C) :-
    phrase(value(B), A, C).
```

`phrase/3` 把输入 `A` 交给 DCG 规则 `value//1`，`B` 拿到解析结果，`C` 是剩余部分。这是 DCG 的标准入口模式。

`value//1` 做类型分发：

```prolog
value(X) --> integer(X).
value(X) --> byte_string(X).
value(X) --> list(X).
value(X) --> dict(X).
```

等等，没有 if-elif 也没有 switch？对了——Prolog 的回溯就是控制流。先试 integer，失败了回溯试 byte_string，一层层下去。简洁得不能再简洁。

### 整数解析

```prolog
integer(X) -->
    "i",
    number_codes(X),
    "e".
```

`number_codes/2` 是 SWI-Prolog 内置——数字和字符编码列表互转。DCG 直接消费字面量 `"i"` 和 `"e"`。

### 字节串解析

```prolog
byte_string(S) -->
    length_codes(L),
    ":",
    length_codes(S, L).
```

先解析长度（`length_codes//1`），然后精确读取 L 个字节。

`length_codes//1`：

```prolog
length_codes(L) -->
    digit_codes(Digits),
    { number_codes(L, Digits) }.
```

`{}` 里的目标是纯 Prolog，DCG 不转换。这里用 `number_codes/2` 把数字字符列表转成整数。

### 列表解析

```prolog
list(X) -->
    "l",
    items(X),
    "e".
```

`items//1` 递归解析任意数量元素：

```prolog
items([X|Xs]) -->
    value(X),
    items(Xs).
items([]) --> [].
```

终止条件是空 DCG（`[]`），匹配空输入。递归规则映射递归数据结构——DCG 的经典模式。

### 字典解析

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
dict_pairs([]) --> [].
```

Bencode 的字典键必须是字节串且按字典序排序。这里用 `K-V` 结构表示键值对——Prolog 的 `-/2` 刚好作关联。

## DCG 编码

编码走反方向：Prolog 项序列化成 bencode。

```prolog
bencode(X, S) :-
    phrase(encode(X), S).
```

```prolog
encode(i(I)) -->             % 整数
    "i", number_codes(I), "e".
encode(s(S)) -->             % 字节串
    length_codes(L), ":", S,
    { length(S, L) }.
encode(l(L)) -->             % 列表
    "l", encode_items(L), "e".
encode(d(D)) -->             % 字典
    "d", encode_dict(D), "e".
```

编码和解码的类型标记不同：编码时 `s(S)` 表示字节串，`i(I)` 表示整数，`l(L)` 列表，`d(D)` 字典。解码时返回 Prolog 原生类型（整数、原子、列表、键值对列表）。

`encode_dict//1`：

```prolog
encode_dict([K-V|Ps]) -->
    encode(s(K)),
    encode(V),
    encode_dict(Ps).
encode_dict([]) --> [].
```

## 对比：命令式 vs DCG

Python 的标准 bencode 实现大致长这样：

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

区别在哪？

| 维度 | 命令式 | DCG |
|------|--------|-----|
| 状态传递 | 显式 `i` 下标 | 隐式差异表参数 |
| 分支 | `if/elif` | 回溯 + 子句选择 |
| 递归结构 | `while` 循环 | 递归 DCG 规则 |
| 输入消费 | 手动 `i += n` | 自动匹配后剩余 |
| 正确性保证 | 运行时断言 | 声明式语义 |

DCG 版本的核心优势：**差异表参数是 Prolog 编译器自动生成的**。你写 `value(X)`，编译器补成 `value(X, A, B)`。`A` 是当前输入，`B` 是消费后的剩余。零样板代码。

这就是我说的"写代码花九十分，但写完就能跑"——DCG 消除了手动管理状态的机会，也就消除了整类 bug。

## 正确性分析

DCG 版本的逻辑正确性来自几个层面：

**1. 类型标记结构一致**：编码时 `i(I)` / `s(S)` / `l(L)` / `d(D)` 四个函子确保不会把整数当字节串编码。

**2. DCG 天然终结**：递归终止条件 `items([]) --> []` 匹配空输入。输入不对就失败，不会无限循环。

**3. 不对称的剩余处理**：解码不要求完全消耗（`bdecode/3` 返回余量），编码则要求精确匹配。合理——解码时可能有尾部填充，编码必须精确。

潜在风险：

```prolog
encode(s(S)) -->
    length_codes(L), ":", S,
    { length(S, L) }.
```

`{ length(S, L) }` 是运行时检查，确保声明的长度和实际一致。如果 `S` 是未实例化的变量，`length(S, L)` 会生成未初始化的列表——但 `encode/2` 不会用未实例化的输入调用，实际不会触发。

## 小结

mndrix/bencode 大概 80 行核心代码，覆盖了编解码全功能。作为庖丁解牛的第一篇，恰如其分——小、完整、可用。

- DCG 规则结构与 BNF 文法一一对应
- 递归规则映射递归数据结构
- `phrase/3` 的三参数形式天然适合"消费输入，返回剩余"
- 回溯替代控制流分支——不需要 if-elif

> 去 https://github.com/mndrix/bencode 看源码，再回来看这篇分析，效果更好。

## 参考

- [The Power of Prolog — Meta-interpreters](https://www.metalevel.at/acomip/)
- [The Power of Prolog — DCGs](https://www.metalevel.at/prolog/dcg)
