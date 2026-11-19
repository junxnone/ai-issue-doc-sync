---
name: issue-doc-sync
description: 当用户想要完善/修改 docs/ 下某篇由 GitHub issue 同步生成的文档内容，或想新增一篇文档时使用。更新走编辑对应 GitHub issue 的 body，新增走创建新 GitHub issue，而不是直接改/新建本地 .md 文件——本地文件由 sync_issues.yml workflow 自动从 issue 生成/覆盖。触发词：完善文档、更新 issue 内容、改一下 0531 这篇、新增一篇文章、同步到 repo。
---

# Issue → Doc 同步 Skill

## 背景

`docs/NNNN_Title.md`（`NNNN` 是 4 位 issue 编号）由 [.github/workflows/sync_issues.yml](../../../.github/workflows/sync_issues.yml) 在 issue `opened`/`edited`/`labeled` 时，通过第三方 action `junxnone/wiki_issue2md@main` 自动从对应 GitHub issue 生成，并在 `docs/bk/` 写一份格式化备份，再由 `junxnone/autosidebar@main` 重建 `_sidebar.md`。

**这是单向同步：issue → repo。没有反向同步。** 直接编辑 `docs/*.md` 的内容部分是无效的——下次该 issue 被编辑时会被覆盖。所有内容完善/新增都必须通过编辑或创建 GitHub issue 来完成，让现有 workflow 把结果同步回 repo。

**File 内容 ≠ issue body**：`docs/NNNN_*.md` 开头的表格（`Title` / `Created @` / `Updated @` / `Labels` / `Edit @`）是 action 根据 issue 的 title/labels/时间戳自动生成的 front matter，**不是** issue body 的一部分。只有第二个 `---` 分隔线之后的内容才是真正的 issue body。回写 issue 时只能提交正文，不要把 front matter 表格也写进去。

## 0. 公共准备

1. 探测 `gh` 可执行文件：
   ```bash
   GH=$(command -v gh || true)
   if [ -z "$GH" ] && [ -f "/c/Program Files/GitHub CLI/gh.exe" ]; then
     GH="/c/Program Files/GitHub CLI/gh.exe"
   fi
   ```
   后续所有 `gh` 调用都用 `"$GH"`，不要假设它在 PATH 里。
2. 确定目标仓库（不要硬编码）：
   ```bash
   REPO=$("$GH" repo view --json nameWithOwner -q .nameWithOwner)
   ```
3. 判断这次是「模式 A：完善已有文档」还是「模式 B：新增文章」：
   - 用户给了 issue 编号或 `docs/`、`docs/bk/` 下的文件名/路径 → 模式 A。
   - 用户给了一个新标题/新主题，且 `docs/` 下找不到对应文件 → 模式 B。
   - 不确定就直接问用户。
4. 准备仓库内的临时预览目录，后面用来展示 Markdown 渲染效果和改动 diff（纯文本贴在对话里既看不出渲染效果也看不出增删对比）：
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   TMPDIR="$REPO_ROOT/.claude/tmp/issue-doc-sync"
   mkdir -p "$TMPDIR"
   grep -qxF '.claude/tmp/' "$REPO_ROOT/.gitignore" 2>/dev/null || echo '.claude/tmp/' >> "$REPO_ROOT/.gitignore"
   ```
   这个目录只放草稿文件、不会被提交；`.gitignore` 里没有对应规则时自动补一行。

## 公共约束（模式 A、B 都必须遵守）

### 不使用多 agent 模式

整个流程（拉取 issue、改写/撰写正文、diff 预览、写回/创建 issue、收尾同步）都由当前会话独立完成：不调用任何 Agent / fork / Workflow 类工具，长文章也不拆给多个 agent 并行写，正文由当前会话顺序完成。

### 标题命名

- **issue title**：用**空格**间隔的词汇由大到小逐级描述所属分类，最后一级是主题本身，不用下划线、连字符或句子，例如 `ML Tasks TimeSeries Deep TCN`（同步后文件名为 `NNNN_ML_Tasks_TimeSeries_Deep_TCN.md`）。新增前先看 `docs/` 里已有文章的 title，沿用现有的分类层级和词汇写法。
- **文章 title**（正文开头的 `# 标题`）：只用简短名称，即 title 的最后一级，例如 `# TCN`，不重复前面的分类路径。

### 公式书写

正文（改写或新增）中的数学公式一律使用 GitHub 支持的 LaTeX 语法，不要用纯文本、Unicode 拼凑或图片：

- 行内公式：`$...$`，例如 `$E = mc^2$`。
- 独立公式块：`$$...$$` 单独成段（前后各空一行），或使用 ` ```math ` 代码块。
- 行内公式含 `_`、`\`、`*` 等易被 Markdown 先行解析的字符时，用 `` $`...`$ `` 形式（美元号内侧包反引号，如 `` $`a_b^2`$ ``），或改在 `$$` / ` ```math ` 块中书写。
- 正文里要出现字面美元符号（如价格）时写成 `\$`，避免被误识别为公式起止。
- 只使用 GitHub MathJax 支持的命令；不确定的写法用更基础的等价写法。
- 改写已有正文时，如遇不符合上述格式的公式，一并改为 GitHub LaTeX 格式。
- **每个公式后必须紧跟变量解说**：列完公式后，用「其中：」列表逐个说明公式里出现的每个符号——含义、取值范围/维度/单位（如适用），必要时说明它在直觉上起什么作用。不允许只贴公式不解释；同一文章中前面已解释过的符号再次出现时可简述或指回前文，但首次出现必须详细说明。示例：

  ```markdown
  $$
  y_t = \sum_{i=0}^{k-1} w_i \, x_{t-d\cdot i}
  $$

  其中：

  - $y_t$：时刻 $t$ 的输出
  - $w_i$：第 $i$ 个卷积核权重，$k$ 个权重共享于所有时刻
  - $x_{t-d\cdot i}$：向过去回溯、间隔为 $d$ 的输入采样点
  - $k$：卷积核大小；$d$：膨胀系数，决定感受野跨度
  ```

### 正文落盘方式

正文含大量 `$`、`\`，**不要**把它放进 shell 变量再 `printf`/`echo`（`$x`、`\n` 会被展开或吃掉，公式被破坏）。一律用带引号的 heredoc 直接写文件：

```bash
cat > "$TMPDIR/xxx.md" <<'EOF'
……正文原文……
EOF
```

后续 diff 预览、`--body-file` 提交都直接用这个文件。

### 图表说明

正文中的图（mermaid 流程图/结构图、示意图、图片等）和表格都不能孤立出现，必须配说明：

- **图前**：用一句话交代这张图要表达什么（图的主题/想让读者看出什么）。
- **图后**：紧跟「图中：」列表，逐个解释图里的元素——节点/模块/箭头/坐标轴/颜色/图例各代表什么，数据流或阅读顺序是怎样的，并点出图的关键结论。
- **表格**：表后说明各列（或行）的含义、单位和对比的结论；缩写和符号首次出现时给出全称。
- 图里出现的变量/符号，同样遵守上面「每个公式后必须紧跟变量解说」的要求。
- 优先使用 GitHub 原生渲染的 mermaid 代码块（` ```mermaid `）作图；用图片时必须写有意义的 alt 文本。

## 模式 A：完善已有文档

1. **解析 issue 编号**：接受 issue 编号（如 `531`）或文件名（如 `0531_Tools_OV_OPs_GPUImpl.md`）。文件名取前 4 位数字、去掉前导零得到编号 `N`。

2. **拉取当前 issue 内容**：
   ```bash
   "$GH" issue view N --repo "$REPO" --json number,title,body,url,labels
   ```
   这里的 `body` 才是要编辑的内容；不要去读 `docs/*.md` 里的 front matter 当作待编辑内容。

3. **结合用户诉求改写正文**：在对话中生成新的 Markdown body（公式遵守「公共约束」中的公式书写规则）。

4. **编辑前确认**：
   ```bash
   "$GH" issue view N --repo "$REPO" --json body -q .body > "$TMPDIR/N_old.md"
   cat > "$TMPDIR/N_new.md" <<'EOF'
   ……新正文……
   EOF
   diff -u "$TMPDIR/N_old.md" "$TMPDIR/N_new.md"
   ```
   - 把 `diff -u` 的输出用 ` ```diff ` 代码块贴出来，直观展示增删。
   - 把 `$TMPDIR/N_new.md` 的相对路径作为 Markdown 链接发给用户（例如 `[0531_new.md](.claude/tmp/issue-doc-sync/0531_new.md)`），方便在编辑器里点开看渲染后的效果。
   - 等待用户**明确确认**后才能继续——这是对共享状态（GitHub issue）的写操作，不能跳过确认自动执行。
   - 不论用户确认还是取消，收尾时都删除本次用到的临时文件（`$TMPDIR/N_old.md` / `$TMPDIR/N_new.md`）。

5. **写回 issue**（用户确认后）：
   ```bash
   "$GH" issue edit N --repo "$REPO" --body-file "$TMPDIR/N_new.md"
   ```
   提交完成后再删除临时文件（见上一步的收尾要求）。

## 模式 B：新增文章

1. **收集标题/主题**：向用户确认文章标题（即未来 issue title，也是文件名 slug 的来源，按「公共约束」中的标题命名规则拟定）和要覆盖的内容方向。

2. **生成正文草稿**：按用户诉求撰写 Markdown 正文。不要手写 front matter 表格，sync 时会自动生成。公式遵守「公共约束」中的公式书写规则。

3. **创建前确认**：全新内容没有旧版本可 diff，但同样需要能看到 Markdown 渲染效果：
   ```bash
   cat > "$TMPDIR/draft_<slug>.md" <<'EOF'
   ……正文……
   EOF
   ```
   - 把标题 + 正文全文贴在对话里，同时把 `$TMPDIR/draft_<slug>.md` 的相对路径作为 Markdown 链接发给用户，方便在编辑器里点开预览渲染效果。
   - 等待用户**明确确认**后才能继续。
   - 不论确认还是取消，收尾时都删除该草稿文件。

4. **创建 issue**（用户确认后）：
   ```bash
   "$GH" issue create --repo "$REPO" --title "$TITLE" --body-file "$TMPDIR/draft_<slug>.md"
   ```
   记录返回的新 issue 编号/URL，之后删除草稿文件。

## 公共收尾（两种模式都要做）

1. 告知用户这会触发 `sync_issues.yml`（`issues: edited` 或 `issues: opened`），由 bot 直接 commit 到 `main`，一般几十秒内完成。可选轮询：
   ```bash
   "$GH" run list --repo "$REPO" --workflow=sync_issues.yml --limit 1 --json status,conclusion
   ```
2. `git pull` 前先 `git status` 检查工作区是否干净。如果有未提交的本地改动，提醒用户先处理（commit/stash），**不要自作主张 stash 或丢弃**。
3. `git pull` 获取 bot 的提交。
4. 展示同步结果：
   - 模式 A：对比 `docs/NNNN_*.md` 的新内容，确认改动已落地。
   - 模式 B：确认 `docs/` 下出现了新的 `NNNN_Title.md`，编号与新建的 issue 一致（文件名 slug 规则由第三方 action 决定，中文/特殊字符标题以实际生成的文件名为准）。

## 边界

- 模式 A 只处理 body 内容，不处理改标题（会触发文件重命名，逻辑更复杂，暂不支持）。
- 没有反向同步：不要直接编辑或新建 `docs/*.md` 来完善内容，一律通过 issue 走。
