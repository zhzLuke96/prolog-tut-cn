# 数理逻辑

> 前置：c0.2 | 难度：★★★ | 后续：—

既然是基于逻辑的语言怎么能不谈谈逻辑呢？

> 可能要打肿脸充胖子了...说实话我初中的时候是没学懂什么叫做蕴含的...

不过没关系，初中的理解不了，现在总该能理解了。毕竟手上有了 Prolog，逻辑不再只是纸上的符号——能跑。

---

## 为什么要有逻辑

程序 = 数据结构 + 算法，这句话到了 Prolog 得改成：

**程序 = 事实 + 规则 + 查询**

事实和规则描述"世界是什么样"，查询问"这个世界是否满足某个条件"。这不就是逻辑学做的事吗？

实际上，Horn 子句逻辑构成了 Prolog 的底层基础。学点数理逻辑不是为了装逼，是让你理解这些词：

- 为什么 `:-` 是"如果...则..."而不是赋值
- 为什么 Prolog 搜索失败就回溯，不抛异常
- 为什么 `not` 在 Prolog 里行为和直觉不同

## 命题逻辑

最简单的逻辑系统。命题（proposition）是一个可以判断真假的陈述句。

```
P = "今天下雨"
Q = "我带伞"
```

命题连接词（connective）：

| 符号 | 含义 | Prolog 对应 |
|------|------|-------------|
| ¬P | 非 P | `\+ P` |
| P ∧ Q | P 且 Q | `P, Q` |
| P ∨ Q | P 或 Q | `P; Q` |
| P → Q | P 蕴含 Q | `P -> Q`（控制流） |
| P ↔ Q | P 当且仅当 Q | `P =:= Q`（CLP 域） |

教科书上管这叫"真值函项连接词"——它们的真值只取决于子命题的真值。

Prolog 的 `,`（逗号）就是逻辑与。`;`（分号）就是逻辑或。这不是巧合，这是直接把命题逻辑做到语法层。

看一个简单推理：

```
P = "苏格拉底是人"
Q = "人都会死"
R = "苏格拉底会死"

如果 P 且 Q，那么 R
```

Prolog 版本：

```prolog
凡人_必死 := mortal.
human(socrates).
mortal(X) :- human(X).
```

当然，Prolog 里没有 "必然推出" 符号，只有 `:-`。它就是逻辑蕴含的"可计算版本"。

## 命题逻辑 → 谓词逻辑

命题逻辑的缺陷很明显：表达力有限。

```
"所有人都会死"
```

这不是一个命题——它谈论的是"所有"这个东西。命题逻辑没法处理量词。

一阶谓词逻辑（first-order predicate logic）在命题逻辑之上加了两样东西：

1. **谓词（predicate）**：描述对象之间的关系，如 `human(socrates)`、`mortal(X)`
2. **量词（quantifier）**：∀（全称量词，for all）和 ∃（存在量词，there exists）

```
∀X (human(X) → mortal(X))
∃X (human(X) ∧ wise(X))
```

∀ 对应 Prolog 的变量（大写字母开头），∃ 对应 Prolog 的未实例化变量在查询中的行为。

不过 Prolog 有本质简化：**不直接支持 ∀ 和 ∃**。Prolog 的变量默认是全称量化的：

```prolog
mortal(X) :- human(X).
```

这里的 `X` 是 `∀X (human(X) → mortal(X))`。查询 `?- mortal(socrates).` 是在问 `∃` 但 Prolog 是通过找实例化来证明存在性。

## 合取范式与 Horn 子句

想把任意逻辑公式用 Prolog 表达，得先转换成合取范式（CNF）：

```
(¬P ∨ Q) ∧ (P ∨ ¬Q) ∧ ...
```

CNF 中特别重要的一种形式是 **Horn 子句**——每个子句里最多只有一个肯定文字（positive literal）。

```
A ← B1 ∧ B2 ∧ ... ∧ Bn
```

这就是 Prolog 规则：

```prolog
A :- B1, B2, ..., Bn.
```

如果 n=0（没有条件），就是事实：

```prolog
a.
```

> 类比 | SQL: DDL CHECK 约束 / WHERE 条件 — Horn 子句是逻辑约束的原子单位，和 CHECK (condition) 本质相同。

这里插一句：为什么叫 Horn？因为逻辑学家 Alfred Horn 发现了这种子句的特殊性质——Horn 子句集合要么有唯一极小模型，要么无解。对应的计算性质：Horn 子句的归约（SLD resolution）是高效的，甚至可以在多项式时间内判定。

非 Horn 子句的例子：

```prolog
(P ∨ Q)
```

两个都是肯定文字。无法写成 `:-` 形式。Prolog 处理不了这种情况——你得用 `;` 在查询里手动处理或：

```prolog
?- p ; q.
```

但规则层没法表达"要么 P 要么 Q 为真"这种不确定事实。

## SLD Resolution

Resolution 是 Robinson 在 1965 年提出的定理证明方法——对 Prolog 而言就是执行引擎。

SLD = Selective Linear Definite-clause resolution。

名字拆开：
- **Selective**：每次选一个子目标
- **Linear**：目标列表线性推导
- **Definite-clause**：用的全是 Horn 子句

过程：

1. 从查询开始（比如 `?- mortal(socrates).`）
2. 找规则头匹配的规则（`mortal(X) :- human(X).`）
3. 联合（unification）：`X = socrates`
4. 把规则体替换成新目标（`human(socrates)`）
5. 重复直到目标为空

如果有多个规则匹配，Prolog 会选第一条，并在后续失败时回溯到分支点尝试下一条。

这就是你在 Prolog 中看到的搜索行为。没有魔法，只是逻辑。

> 类比 | SQL: 查询规划器枚举 join 策略 — SLD 深度优先搜索所有可能的推导路径，和数据库选择执行计划类似。

更形式化的描述：

```
给定目标 G 和规则 H :- B1, B2, ..., Bn
如果 G 和 H 能联合（θ = mgu(G, H)），
那么新目标是 (B1, B2, ..., Bn)θ
```

mgu = most general unifier（最一般合一子）。

## 现实化（grounding）

逻辑推理要接触地面——变量必须被实例化成具体的项。

Prolog 中，查询时的输入和规则的应用自动做现实化。

```prolog
?- mortal(socrates).
```

这个查询传入了一个具体值 `socrates`。规则 `mortal(X) :- human(X)` 中 `X` 被绑定为 `socrates`，然后检查 `human(socrates)`。

反过来，查询中用变量：

```prolog
?- mortal(X).
```

这不是问"是否存在一个 X 使得 mortal(X) 成立"吗？是的。Prolog 会现实化出所有可能的 X。

## 等价转换

逻辑等价式（logical equivalence）是 Prolog 代码优化的理论基础。

```
P ∨ Q  ≡  Q ∨ P                             交换律
(P ∨ Q) ∨ R  ≡  P ∨ (Q ∨ R)                 结合律
¬(P ∨ Q)  ≡  ¬P ∧ ¬Q                        德摩根律
P → Q  ≡  ¬P ∨ Q                             蕴含消去
```

在 Prolog 中，优化规则顺序就是利用交换律——规则顺序影响搜索效率但不影响语义正确性。

```prolog
% 两条规则顺序交换 —— 逻辑语义不变但搜索顺序不同
parent(X, Y) :- father(X, Y).
parent(X, Y) :- mother(X, Y).
```

上面两个版本在逻辑上完全等价，但 Prolog 执行时会按字句顺序从上到下搜索，搜索顺序不同。这就是等价转换在 Prolog 中的实际意义。

## 蕴含与逆否

蕴含 `P → Q` 等价于其逆否（contrapositive）`¬Q → ¬P`。

```
"如果下雨(P)则地湿(Q)"
等价于
"如果地不湿(¬Q)则没下雨(¬P)"
```

Prolog 的 `:-` 方向性——`Q :- P` 表示"如果 P 则 Q"，但你只能从 Q 出发去证明 P。你不能直接问"如果 Q 为假那么 P 为假吗？"——但 `\+` 加上规则可以模拟：

```prolog
wet_ground :- rained.
dry_ground :- \+ wet_ground.
```

如果 `dry_ground` 成立，那 `wet_ground` 必然不成立（假设我们知道要么湿要么干）。但 Prolog 的否定（`\+`）是 negation as failure（失败即否定）——不是经典逻辑中的强否定。

## Negation as Failure

这是 Prolog 和经典逻辑最大的分歧点。

经典逻辑：`¬P` 为真当且仅当 `P` 为假。
Prolog：`\+ P` 成功当且仅当 `P` 在有限步内推理失败。

区别：
- 经典否定需要"知道世界是完整的"
- Prolog 的否定只是"穷尽搜索没找到"

> 类比 | SQL: NOT EXISTS / NOT IN — Prolog 的 \+/1 假设"无法证明即为假"，对应 SQL 的 negation。但 SQL 的三值逻辑（NULL）引入了 Prolog 没有的复杂性。

这被称为封闭世界假设（Closed World Assumption）：

> 任何无法被证明为真的事实，都被假定为假。

> 类比 | SQL: 数据库假定未存储的事实不成立 — 和 Prolog 的 CWA 完全一致。

这就是为什么 Prolog 知识库中没有 `fly(tom)` 这个事实，查询 `?- fly(tom).` 会失败——不是因为 tom 不能飞，而是因为知识库没这么说。

#> Prolog 的计算模型正是基于 Horn 子句逻辑——SLD Resolution 构成了 Prolog 的执行引擎。
> Prolog 的表达能力上限（图灵完备性）见 [turing 篇](turing.md)。

# 集合论浅谈

逻辑和集合论是同一个硬币的两面。

- 谓词 → 集合的特征函数
- 关系 → 笛卡尔积的子集
- 规则 → 包含关系

```prolog
human(socrates).         % socrates ∈ Human
mortal(X) :- human(X).  % Human ⊆ Mortal
```

用 Prolog 的 `findall/3` 可以显式构造集合：

```prolog
?- findall(X, human(X), Humans).
Humans = [socrates].
```

> 类比 | SQL: findall≈SELECT, setof≈SELECT DISTINCT, bagof≈SELECT GROUP BY

`findall/3` 实际上做了"把所有满足条件的 X 收集成列表"的工作——这是从谓词到集合的显式转换。

## 回到 Prolog

学完这些再回头看 Prolog 的 `:-`：

```
mortal(X) :- human(X).
```

不再只是"如果 human(X) 则 mortal(X)"——它是一个 **Horn 子句**、一个 **SLD resolution 的候选规则**、一个 **定义在集合上的蕴含关系**。

Prolog 不是"像逻辑"，Prolog **就是逻辑**——用可计算的方式表达。

> 建议参考《A Mathematical Introduction to Logic》（Enderton）和《面向计算机科学的数理逻辑》（陆钟万）。
> 前者理论扎实，后者偏向计算机应用。