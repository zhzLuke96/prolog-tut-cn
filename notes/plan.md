> 最后更新：2026-06-30 — Phase 1 已完成，Phase 2/3 大部分完成。详情见 notes/editor-task-breakdown.md

# 迭代计划

## 已完成（Phase 0）

| 事项 | 状态 |
|------|------|
| GitBook → HonKit 迁移 | 完成（v6.2.2, Node 22 构建通过） |
| package.json scripts/engines 更新 | 完成 |
| GitBook 插件替换为 HonKit 兼容版 | 完成 |

---

# Phase 迭代计划

## Phase 1: 紧急修复（P0）

**目标**：修复所有阻断性 bug 和构建断裂，确保教程可读可运行。

### 1.1 代码 bug 修复（~1h）

| 问题 | 位置 | 修复方式 |
|------|------|----------|
| Quicksort.pl mysort/1 实例化错误 | code/tut/Sort/Quicksort.pl | 移除 `last(P,_)`，`phrase(quicksort(L),S)` 正确调用 |
| factorial 缺乘号 | chapter9.md | `N FF` → `N * FF`，`N T` → `N * T` |
| c0_john_like.pl 注释错误 | code/tut/c0_john_like.pl | `X #> friend(X,Y)` → `friend(X,Y)` |
| c_to_f/2 缺类型检查 | chapter7.md | 添加 `number(C)` 保护 |

### 1.2 Markdown 渲染修复（~1h）

| 问题 | 位置 | 修复方式 |
|------|------|----------|
| chapter13 `*` 被斜体吃掉 | chapter13.md | 转义 `\*`，恢复 `3 * 4 + 6` 等表达式 |
| chapter13 链接语法破坏 | chapter13.md | `?-[4+(6/2)=...` 整行重写 |
| chapter7 `>=` 编码损坏 | chapter7.md | `бк>` → `>=` |
| factorial `*` 丢失 | chapter9.md | 恢复乘号 |

### 1.3 CI 修复（~30min）

- `actions/checkout@v2` → `@v4`
- `JamesIves/github-pages-deploy-action@releases/v3` → `v4`
- Node version 改为 18（HonKit 在 Node 18+ 运行，已验证）

**预估**：1.5 天

---

## Phase 2: 清理与方言统一（P0/P1）

**目标**：解决三层方言混用问题，统一以 SWI-Prolog 为主基线，精简过时内容。

### 2.1 方言统一（P0，~4h）

1. **chapter0.1 方言介绍精简**：PDC Prolog / Visual Prolog 缩为一句"历史上存在过"，篇幅给 SWI-Prolog
2. **每章增加方言说明**：README 或 chapter0.x 增加"方言指引"段落，明确「教程代码在 SWI-Prolog 8.x+ 验证」
3. **code/ 文件标注方言**：每个 `.pl` 文件首行注释标注 `% SWI-Prolog` 或 `% ISO Prolog`
4. **not/1 → \\+/1 统一**：全文替换，统一使用 ISO 标准否定
5. **Turbo Prolog 残留清理**：移除或注释文中 Turbo Prolog 特有概念（三段式 domains/predicates/clauses）

### 2.2 过时内容精简（P1，~2h）

1. **chapter0.0 "AI语言"语境更新**：
   - C++ 从"典型 AI 语言"移除
   - 补充说明符号主义 vs 神经网络两条路线，正确定位 Prolog 在现代 AI 中的角色
2. **"Prolog 无运行顺序"段落修正**：改为"Prolog 执行顺序由 SLD resolution 确定"
3. **补充 `(->;)` 控制结构**：修正"Prolog 没有控制流程"的过时表述
4. **c0.1 VSCode 插件更新**：
   - `arthurwang.vsc-prolog` 保留但标注"已停更 7 年"
   - 补充替代方案：SWISH、终端 `swipl`、Emacs+ediprolog

### 2.3 Web 服务器章节修复（P1，~1h）

- c8 websev.pl 依赖 SWI-Prolog `library(http/*)`，确认代码可用
- 补充 c8 正文内容（当前仅 3 个外链）

**预估**：3 天

---

## Phase 3: 内容补全（P1）

**目标**：补全 Hello Prolog 空缺章节（c4-c11）和理论章节，消除"读到中断"问题。

### 3.1 Hello Prolog c4-c7（P1，~2days）

| 章节 | 内容计划 | 参考来源 |
|------|----------|----------|
| c4 DCG | 配合从零开始 chapter16，提供工程视角（解析 CSV/JSON，DCG debug） | SWI-Prolog DCG docs |
| c5 元编译器 | meta-interpreter 实现（vanilla + 扩展 debug 版本） | Sterling & Shapiro |
| c6 优化 | tabling/memoization、tail-call optimization、choice point 消除 | SWI-Prolog tabling docs |
| c7 模块化 | `module/2`、`use_module/1`、library 创建与发布 | SWI-Prolog module docs |

### 3.2 Hello Prolog c9-c11（P0/P1，~1.5days）

1. **c9 AI 专家系统**（P0，~4h）
   - 完成数独：`clpfd` 实现，`label/1` 搜索
   - 完成机器人电池：路径规划 + DFS/BFS
   - 专家系统 shell（基于规则链推理）
2. **c10 单元测试**（P0，~2h）— 无实质内容，需填补
   - `plunit` 基本用法：`:- begin_tests` / `end_tests`
   - `run_tests` 自动化
   - 结合 c3 高阶谓词写实际测试
3. **c11 GUI**（P2，~2h）
   - XPCE 基础（`new/2`，`send/2`）
   - 简单示例（按钮+列表+文件选择）

### 3.3 理论章节补全（P1，~2days）

1. **logic.md**（P0 — 目前仅为大纲）：命题逻辑 → 一阶谓词逻辑 → Horn 子句 → SLD resolution

2. **puzzles.md**：补充四色地图（`clpfd`）、汉诺塔（DCG + 递归）、数独（`clpfd` 完整版）
3. **turing.md**：至少给出图灵机模拟器 Prolog 实现

**预估**：6 天

---

## Phase 4: 增强与现代化（P2）

**目标**：增加现代 Prolog 特性覆盖，提升项目质量。

### 4.1 CLP 约束编程章节（P2，~1day）

- 在 Hello Prolog 中新增 `c6.5` 或独立章节
- 覆盖：`clpfd`（`#=/<</>>`）、`clpb`（puzzles.md 已有）、`clpr`（实数域）
- 与 puzzles.md 数独/四色地图联动

### 4.2 测试框架落地（P2，~1day）

- 为 code/tut/ 和 code/hello/ 已有代码添加 `.plt` 测试文件
- CI 运行 `swipl -g run_tests -t halt` 验证全部代码
- 在 README 添加测试运行说明

### 4.3 代码质量改进（P2，~2days）

1. **member/2 冲突**：chapter15 自定义版本 → `my_member/2`
2. **get0/1 → get_char/1**：chapter16 更新推荐写法
3. **Sort.pl 标注性能说明**：permutation sort O(n!) 标注为"仅示教"
4. **入口谓词完善**：code/tut/ 中纯定义文件添加 `:- initialization` 入口或示例注释
5. **c_to_f/2**：补充 `number/1` guard

### 4.4 chapter7 扩充（P2，~4h）

- 补充 `succ/2`、算术比较谓词（`=:=`/`=\=/`/`<`/`>`）
- CLPFD 入门（`#=/<</>>`）
- 补充更多示例（如 Fibonacci、尾递归累加器）

**预估**：4 天

---

## Phase 5: 基础设施与生态（P2/P3）

**目标**：CI/CD 现代化、图片本地化、评论系统升级。

### 5.1 CI/CD 改进（P2，~1day）

- `npm ci` + `node_modules` 缓存加速构建
- 添加 PR preview label 触发器（可选）
- 添加 `workflow_dispatch` 手动触发
- 添加定时构建验证（每周）

### 5.2 图片本地化（P3，~1h）

- `f2_3.gif` 从 `https://www.cpp.edu/~jrfisher/www/prolog_tutorial/` 下载到 `src/tut/img/`
- 更新对应 Markdown 引用路径
- 检查剩余图片引用无死链

### 5.3 Disqus → Giscus（P3，~2h）

- 替换 `honkit-plugin-disqus` 为基于 GitHub Discussions 的 Giscus
- 优势：无广告、无需第三方、GitHub 登录
- 需仓库开启 Discussions

### 5.4 可选：目录结构调整（P3）

- 当前 `tut/` → `beginner/`、`hello-pl/` → `pro-engineer/` 等
- 需同步更新 SUMMARY.md 和 README
- 会影响已有外链，建议改后做 301 或不调整

**预估**：2 天

---

## 总工作量估算

| Phase | 内容 | 预估值 | 优先级 |
|-------|------|--------|--------|
| 1 | 紧急修复 | 1.5 天 | P0 |
| 2 | 清理与方言统一 | 3 天 | P0/P1 |
| 3 | 内容补全 | 6 天 | P1 |
| 4 | 增强与现代化 | 4 天 | P2 |
| 5 | 基础设施与生态 | 2 天 | P2/P3 |
| **合计** | | **~16.5 天** | |

---

## 依赖关系

- Phase 1 无依赖，可立即开始
- Phase 2 依赖 Phase 1 完成（修复后正文可读）
- Phase 3 依赖 Phase 1（修复后代码可运行）+ Phase 2（方言统一后再写新内容，避免新旧混用）
- Phase 4 可并行 Phase 3（测试/CLP 可独立编写）
- Phase 5 依赖 Phase 1（CI 修复）、建议 Phase 2 后（图片路径确认）

---

*生成于 2026-06-30，基于 notes/analysis-content.md / analysis-tech.md / analysis-infra.md 综合。*