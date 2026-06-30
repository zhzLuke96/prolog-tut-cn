 # 基础设施分析报告：prolog-tut-cn

 ## 1. 旧版 GitBook 生态分析

 ### 1.1 当前栈

 - **GitBook 3.2.3** — 上游 2018 年归档，不再维护
 - **gitbook-cli 2.3.2** — 插件下载依赖已失效（`gitbook install` 从 S3 拉取插件，部分插件 404）
 - **Node 10 / npm 6** — 均为 EOL，npm 6 2021 年停更
 - **30+ MD 源文件**，4 个章节目录，8 张本地图片 + 1 张远程外链图
 - **8 个 GitBook 插件**：search-pro, prism, disqus, github, splitter, copy-code-button, anchor-navigation-ex, tbfed-pagefooter
 - **自定义 CSS**：`src/styles/website.css`
 - **构建输出**：`docs/`，gitignored，含完整静态 HTML

 ### 1.2 不可维护性

 | 问题 | 影响 |
 |------|------|
 | Node 10 限制 | 现代 CI runner（ubuntu-22.04+）原生不支持 Node 10，`setup-node@v4` 虽能下载旧二进制但不保证长期可用；本地开发无法在 Node 18+ 跑 `gitbook` |
 | `gitbook install` 失败 | 插件 registry（`plugins.gitbook.com`）部分已下线，新机器装插件大概率失败 |
 | 插件无人维护 | `search-pro` 依赖 `nodejieba`（C++ addon），Node 10 之后编译困难；`disqus` 接入需 JS embed，GitBook 老旧 embed 方式可能被 Disqus 弃用 |
 | `actions/checkout@v2` | 过期，v3/v4 有 breaking change；当前 piped 到 Node 10 的构建随时因 runner 更新断裂 |
 | package.json engines 限制 | 写死了 Node 10 和 npm 6，无法在较新环境 `npm install` |

 ### 1.3 CI 断裂风险

 当前 `.github/workflows/main.yml`：
 - `actions/setup-node@v4` + node-version:10 是目前唯一还能跑的点，但 GitHub 已宣布 ubuntu-latest 将切换至 ubuntu-24.04，Node 10 二进制兼容性未知
 - `JamesIves/github-pages-deploy-action@releases/v3` 也过期（当前 v4），v3 使用 GITHUB_TOKEN 方式即将被 GitHub 废弃
 - **结论：CI 处于"还能用但随时断"的状态**

 ## 2. 现代化方案对比

 | 工具 | 语言 | 中文搜索 | 复杂度 | 迁移成本 | 社区活跃度 | 备注 |
 |------|------|---------|--------|---------|-----------|------|
 | **HonKit** | Node | 好（可插拔） | 低 | 低 | 低 | GitBook fork，`book.json` 几乎兼容，SUMMARY.md 直接复用 |
 | **mdBook** | Rust | 弱（默认不支持中文分词） | 低 | 中 | 中 | 纯静态，无 Disqus/评论插件，需手写搜索替代方案 |
 | **VuePress 2** | Node/Vue | 好（vuepress-plugin-search-pro） | 中 | 中高 | 高 | 需写 Vue 配置、适配 frontmatter，部分 GitBook 语法不兼容 |
 | **Docusaurus 3** | Node/React | 好（Algolia DocSearch） | 中 | 中高 | 高 | Meta 维护，插件生态成熟，需适配 sidebar |
 | **Next.js** | Node/React | 自定义 | 高 | 高 | 最高 | 静态站点杀鸡用牛刀，除非计划长期扩展 |

 ### 2.1 推荐首选：HonKit

 **理由**：
 - `book.json` 和 `SUMMARY.md` 零改动直接迁移
 - 支持自定义 CSS（直接搬 `styles/website.css`）
 - npm 安装，Node 18+ 下可运行（`honkit` 包）
 - 中文搜索可通过 `search-pro` 或 `lunr` 的 expanded 语言支持解决
 - 保留 Disqus 评论集成能力
 - 可逐步迁移，不需要一次重写所有内容

 **迁移成本**：1-2 小时（改 `package.json` scripts、换 `book.json` 字段、更新 CI）

 ### 2.2 备选：mdBook（纯静态极致）

 **理由**：
 - Rust 单二进制，零运行时依赖，构建极快
 - `SUMMARY.md` 格式几乎兼容
 - 无需 Node 环境

 **缺点**：
 - 默认搜索不支持中文分词（需额外配置 elasticlunr 或付费工具）
 - 无 Disqus/GitHub 等评论插件
 - 自定义 CSS 有限（mdBook 主题可调但不灵活）
 - **适合纯文档项目，不适合带评论和交互的教程站**

 ### 2.3 保留 GitBook（不推荐）

 风险过高。即便强行固定 GitHub Actions runner 版本，本地开发者也难以复现构建环境。Node 10 的安全漏洞无人修补。

 ## 3. 部署方案改进

 ### 3.1 当前流程

 master push → GitHub Actions → Node 10 build → deploy to gh-pages

 ### 3.2 改进建议

 1. **升级 Actions 版本**：
    - `actions/checkout@v4`
    - `JamesIves/github-pages-deploy-action@v4`
    - `actions/setup-node@v4` 的 node-version 改为 18 或 20（迁移后）

 2. **添加构建缓存**：
    - 缓存 `~/.honkit` 或 `node_modules`，减少 `npm install` 时间

 3. **自动化部署**：
    - 保持 gh-pages 分支策略
    - 可选：添加 `workflow_dispatch` 触发器允许手动触发

 4. **Preview Deploy**：
    - PR 打 `preview` label 时自动构建并部署到临时 subpath（需要 Pages 多环境 support）
    - 当前 GitHub Free 方案不支持多环境 Pages，可暂缓

 5. **自定义域名**：
    - 如有域名可配置 `CNAME`，在 gh-pages 根放入 `CNAME` 文件

 ## 4. 内容格式分析

 ### 4.1 Markdown 兼容性

 源站 `src/` 下所有 `.md` 文件为**标准 GitBook Markdown**：
 - 目录结构由 `SUMMARY.md` 定义
 - 图片引用方式：`<img src="./img/c3i1.png"/>`（HTML tag）或 `![](url)`
 - 代码块使用标准 ```prolog 围栏
 - 无特殊 frontmatter

 **结论**：迁移到 HonKit 无需修改正文内容。迁移到 mdBook/Docusaurus 需要少量调整（frontmatter、sidebar 配置、图片路径）。

 ### 4.2 图片管理

 - 10 张本地 PNG：`src/tut/img/`，GitBook 构建时复制到 `docs/tut/img/` ✅
 - 1 张远程 GIF：`https://www.cpp.edu/~jrfisher/www/prolog_tutorial/f2_3.gif`，外链 ❌（可能失效）

 **建议**：将远程 GIF 下载到本地 `src/tut/img/` 统一管理。

 ### 4.3 自定义样式

 `src/styles/website.css` 只有 5 条规则。迁移时可直接复制到新工具的 CSS 配置。

 ### 4.4 Disqus 评论系统

 Disqus 集成需要：
 - 如果迁移到 HonKit：有社区插件 `honkit-plugin-disqus`
 - 如果迁移到 mdBook：无原生支持，需手动嵌入 HTML（hacky）
 - 如果迁移到 Docusaurus/VuePress：有官方插件
 - 替代方案：考虑 Giscus（基于 GitHub Discussions）、utterances（基于 GitHub Issues），更轻量无广告

 ## 5. 分步迁移计划

 ### Phase 1：紧急修复（1 天）

 1. 将 CI 中的 `actions/setup-node@v4` 的 node-version 从 10 改为 **18**
 2. 升级 `actions/checkout@v4` 和 `JamesIves/github-pages-deploy-action@v4`
 3. 验证构建是否成功
 4. **结果**：CI 不再依赖 Node 10，当前构建链延长寿命

 ### Phase 2：迁移到 HonKit（2 天）

 1. `npm uninstall gitbook gitbook-cli`
 2. `npm install honkit`
 3. 更新 `package.json` scripts：
    - `"build": "honkit build src docs"`
    - `"dev": "honkit serve src docs"`
 4. 删除 `node_modules` 和 `package-lock.json`，重新 `npm install`
 5. 更新 `src/book.json`：
    - 移除 `plugins` 中 GitBook 3 特有插件
    - 替换为 HonKit 兼容插件（如 `honkit-plugin-search-pro`、`-highlight` + `prism` 不变）
 6. 验证本地构建、serve 正常
 7. 更新 CI

 **优先级**：高。这是 core 迁移，解决所有 Node 版本和插件兼容问题。

 ### Phase 3：改进 CI/CD（1 天）

 1. 添加 `npm ci` 或缓存步骤加速构建
 2. 添加构建验证（检查 HTML 输出是否缺失）
 3. 添加 `workflow_dispatch` 触发器
 4. 考虑加 `schedule` 每周自动构建验证

 ### Phase 4：内容优化（按需）

 1. 将远程 GIF 下载到本地
 2. 考虑从 Disqus 迁移到 Giscus（GitHub Discussions 驱动，无需广告）
 3. 清理 `docs/` 中过时构建产物（先 git rm，然后重新构建）
 4. 添加 `.gitkeep` 确保空目录不被 git 忽略

 ## 6. 总结

 | 维度 | 现状 | 推荐 | 收益 |
 |------|------|------|------|
 | 构建工具 | GitBook 3 (dead) | HonKit | 向后兼容，迁移成本最低 |
 | Node 版本 | 10 (EOL) | 18 LTS | 安全更新，CI 稳定 |
 | CI/CD | 3 个过时 action | v4 系列 | 减少断裂风险 |
 | 评论 | Disqus | Giscus（可选） | 隐私、无广告、免费 |
 | 图片 | 1 张外链 | 全部本地化 | 避免死链 |

 **核心建议**：先做 Phase 1（紧急修 CI），再做 Phase 2（迁移 HonKit）。这是风险最低、ROI 最高的路径。Phase 3 和 4 看时间和意愿。

 ---
 *生成时间：2026-06-30*
 *分析工具：manual inspection*
