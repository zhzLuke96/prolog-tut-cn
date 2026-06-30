> 高阶阅读：本系列是深度代码分析，适合完成全部 Hello Prolog 章节后阅读。

> 读前须知：本章需先理解 c5 中 clause/2 和 vanilla MI 的工作原理。JavaScript 读者注意——Prolog 的 closure 基于 fact 实现（通过 asserta 存储，回溯不撤销），和 JS 的 lexical scope capture 完全不同。

# lisprolog

> 如果说用 Prolog 实现 JSON 解析（cs1 的 bencode）是牛刀小试
> 那用 Prolog 实现一个 Lisp 解释器就是真正意义上的"用逻辑写程序"

> 前置：[元编译器](../hello-pl/c5.md) | 难度：★★★ | 后续：—

https://github.com/triska/lisprolog

作者 Markus Triska，SWI-Prolog 的 CLP(FD) 库维护者，Prolog 社区的顶级大佬。他的代码可能是 Prolog 社区里最值得读的。

---

## 为什么要读这个

Lisp 解释器是元编程的经典练习。用 Prolog 实现 Lisp 解释器，本质上是在 Prolog 中实现一个元解释器（meta-interpreter）——用 Prolog 的执行引擎驱动另一个语言的执行。

Triska 的 lisprolog 大概 200 行，实现了一个完整的 Lisp 方言：
- S 表达式的表示与解析
- 环境（environment）的建立与查找
- 闭包、函数调用
- 算术、列表操作
- 递归

## 数据结构：S 表达式

Lisp 的核心数据结构是 S 表达式（Symbolic Expression）。lisprolog 中用 Prolog 项直接表达：

```prolog
% 原子 → Prolog 原子（小写开头）
% 列表 → Prolog 列表
% 点对 → cons(A, B)
% 函数调用 → [fun, arg1, arg2, ...]
```

具体映射：

| Lisp | Prolog |
|------|--------|
| `42` | `42` |
| `foo` | `foo` |
| `(a . b)` | `cons(a, b)` |
| `(a b c)` | `[a, b, c]` |
| `(f a b)` | `[f, a, b]` |

S 表达式的解析用 DCG：

```prolog
s_expression(E) --> atom(E).
s_expression(E) --> integer(E).
s_expression(cons(A, B)) --> "(", s_expression(A), ".", s_expression(B), ")".
s_expression([E|Es]) --> "(", s_expression(E), s_expressions(Es), ")".
```

`cons/2` 表示点对（dotted pair），列表是点对的语法糖。Prolog 的列表结构恰好能直接表示 Lisp 列表，这是 Prolog 做 Lisp 解释器的天然优势。

## 解析器细节

lisprolog 的解析器是纯 DCG，入口：

```prolog
read(E) -->
    blanks,
    s_expression(E),
    blanks.
```

`blanks//0` 跳过空白，`s_expression//1` 递归解析。典型的 DCG 顶层设计。

注意到 `read/1` 的命名——覆盖了 SWI-Prolog 内置的 `read/1`，所以文件通过 `module(lisprolog, [lisp/1])` 导出唯一入口 `lisp/1`。模块化隔离做得好。

## 环境模型

Lisp 的执行依赖环境（变量绑定）。lisprolog 的环境用 Prolog 事实（fact）实现：

```prolog
:- dynamic env/2.

env_init :-
    retractall(env(_, _)),
    asserta(env(\'nil\', \'nil\')).

env_lookup(Name, Value) :-
    env(Name, Value).

env_bind(Name, Value) :-
    asserta(env(Name, Value)).
```

使用 `asserta/1`（插入到事实库最前面）实现变量遮蔽（shadowing）——同名变量最新的绑定会最先被 `env/2` 匹配到。

这是 Prolog 式的符号表：不用哈希表、不用关联列表，直接用数据库事实充当。查表就是查询，插入就是 assert。

## 求值器：元解释器模式

求值器是 lisprolog 的核心：

```prolog
eval(Env, Val) :-
    atom(Env),
    env_lookup(Env, Val).
eval([quote, X], X).
eval([if, C, T, E], Val) :-
    eval(C, V),
    (   V == \'nil\'
    ->  eval(E, Val)
    ;   eval(T, Val)
    ).
eval([lambda, Args, Body], closure(Args, Body)).
eval([fun, Name], closure(Args, Body)) :-
    env_lookup(Name, closure(Args, Body)).
eval([Op|Args], Val) :-
    maplist(eval, Args, EArgs),
    apply(Op, EArgs, Val).
```

这是 vanilla meta-interpreter 的变体。解释 Prolog 的 meta-interpreter：

```prolog
% 经典的 vanilla meta-interpreter
true --> true.
(Goal1, Goal2) --> mi(Goal1), mi(Goal2).
Goal --> {Goal}.
```

lisprolog 的 eval 结构与之类似——每个 Lisp 形式的求值对应一个 `eval/2` 子句。

关键设计：

1. **引用（quote）**：`[quote, X]` 不 eval X，直接返回。相当于 Lisp 的 `\'X`。

2. **条件（if）**：Lisp 中只有 `nil` 是假，其他都是真。Prolog 中用 `(->;)` 控制结构实现条件分支。

3. **Lambda 和闭包**：`[lambda, Args, Body]` 求值为 `closure(Args, Body)`，不立即求值 Body。这是词法作用域的关键——闭包捕获当前环境。

4. **函数应用**：先 `maplist(eval, Args, EArgs)` 对所有参数求值，再调用 `apply/3`。

## Apply 函数

```prolog
apply(closure([Arg], Body), [Val], Result) :-
    env_bind(Arg, Val),
    eval(Body, Result).
apply(closure([Arg|Args], Body), [Val|Vals], Result) :-
    env_bind(Arg, Val),
    apply(closure(Args, Body), Vals, Result).
apply(+, [X, Y], Z) :- Z is X + Y.
apply(-, [X, Y], Z) :- Z is X - Y.
apply(car, [cons(X, _)], X).
apply(cdr, [cons(_, X)], X).
apply(cons, [X, Y], cons(X, Y)).
apply(list, Args, Args).
apply(eq, [X, X], t) :- !.
apply(eq, [_, _], \'nil\').
```

闭包应用的过程就是环境扩展的过程：将参数绑定到形式参数，然后 eval body。

原始函数（+、-、car、cdr 等）直接映射到 Prolog 内置运算——这是元解释器的"地面层"（ground layer），链接触摸到 Prolog 运行时。

## 自举能力

lisprolog 中定义的 Lisp 函数可以互相调用，构成递归：

```prolog
% 在 Lisp 中定义阶乘
lisp("
    (defun fact (n)
        (if (eq n 0)
            1
            (* n (fact (- n 1)))))
    (fact 5)
").
```

`defun` 的实现：

```prolog
eval([defun, Name, Args, Body], Name) :-
    env_bind(Name, closure(Args, Body)).
```

就是往环境里装一个闭包。没有宏、没有特殊形式——`defun` 就是 `eval` 的一个子句。

## 与 Prolog 的天然映射

读完 lisprolog 会发现一个模式：**Lisp 的特性恰好都有 Prolog 的对应物**。

| Lisp 概念 | Prolog 对应 |
|-----------|-------------|
| S 表达式 | Prolog 项（term） |
| 点对 | `cons(A, B)` 结构 |
| eval | meta-interpreter |
| 环境 | database fact |
| 变量绑定 | `asserta/1` |
| 函数调用 | `call/1` + maplist |
| 递归 | 递归子句 |

这不是巧合。Prolog 和 Lisp 都是符号处理语言（symbolic computation），共享同一个祖先——John McCarthy 的 Lisp 和 Alan Robinson 的 resolution 原则，都是 1960 年代的产物。

## 注意事项

> 闭包环境中 `env_bind` 用 `asserta` 实现遮蔽，但闭包返回后绑定不会自动撤销。这是 toy interpreter 的简化方案，生产环境需要 save/restore。

## 小结

lisprolog 是 Prolog 元编程的绝佳示例：用 200 行代码展示了如何在一个逻辑语言中嵌入另一个符号语言。读这段代码的最佳方式是：

1. 把 lisprolog 的 Lisp 代码跑起来
2. 用 `trace` 跟踪 `eval/2` 的调用链
3. 理解每个 Lisp 形式如何对应到 Prolog 子句
4. 尝试加一个自定义原始函数看看

> 去 https://github.com/triska/lisprolog 看源码。
> 在 SWI-Prolog 中 `use_module(lisprolog)`，然后 `lisp("(+ 1 2)").`

## 参考

- [The Power of Prolog — Meta-interpreters](https://www.metalevel.at/acomip/)
- [The Power of Prolog — DCGs](https://www.metalevel.at/prolog/dcg)