# ai-issue-doc-sync

Claude Code skill：把「完善 / 新增 wiki 文档」这件事，转换成「编辑 / 创建 GitHub issue」，交给仓库里已有的 `sync_issues.yml` workflow 把结果同步回 `docs/*.md`。

适用于这样的仓库约定：

- `docs/NNNN_Title.md`（`NNNN` 为 4 位 issue 编号）由某个 workflow 在 issue `opened` / `edited` / `labeled` 时自动生成或覆盖（例如用 [`junxnone/wiki_issue2md`](https://github.com/junxnone/wiki_issue2md) action）。
- 这是**单向同步**：issue → repo。直接编辑 `docs/*.md` 的内容部分在下次 issue 被编辑时会被覆盖，所以内容维护必须走 issue。

如果你的仓库是这种「issue 驱动文档」模式（不一定是 `junxnone/wiki_issue2md`，只要同步逻辑类似），这个 skill 都适用。

## 它做什么

- **模式 A：完善已有文档** — 给一个 issue 编号或 `docs/` 下的文件名，skill 会拉取对应 issue 的当前 body，结合你的诉求改写正文，确认后写回 issue（`gh issue edit`）。
- **模式 B：新增文章** — 给一个新标题和内容方向，skill 会生成 Markdown 正文，确认后创建新 issue（`gh issue create`）。
- **公共收尾** — 提示 workflow 会被触发、可选轮询 workflow 状态、提醒 `git pull` 前检查工作区干净、拉取 bot commit 后展示同步结果。

详细规则见 [`SKILL.md`](SKILL.md)。

## 前置条件

1. 已安装并登录 [GitHub CLI](https://cli.github.com/)（`gh auth login`），且对目标仓库有 issue 读写权限。
2. 目标仓库里有一个类似 `sync_issues.yml` 的 workflow，监听 issue 事件并把内容同步到 `docs/`。
3. 本地已 clone 该仓库（收尾步骤要 `git pull` 同步结果）。

## 安装

本仓库只包含 skill 本体（`SKILL.md`），用安装脚本把它放到 Claude Code 能发现的位置：

- **项目级**：复制到目标仓库的 `.claude/skills/issue-doc-sync/`，只在该项目里可用，可随仓库一起提交共享给团队。
- **全局**：复制到 `~/.claude/skills/issue-doc-sync/`，所有项目都能用。

### Windows (PowerShell)

```powershell
# 安装到某个项目（推荐，仓库约定可能各不相同）
.\install.ps1 -Target "C:\path\to\your-repo"

# 安装到全局 (~/.claude/skills)
.\install.ps1
```

### Linux / macOS (bash)

```bash
# 安装到某个项目
./install.sh /path/to/your-repo

# 安装到全局 (~/.claude/skills)
./install.sh
```

两个脚本都是幂等的：重复运行会覆盖已安装的旧版本。

## 使用

安装后在对应项目里对 Claude Code 说类似的话即可触发：

- 「帮我完善一下 0531 这篇文档，补充 xxx」（模式 A）
- 「新增一篇文章，介绍 xxx 的用途用法」（模式 B）

Claude 会在真正写 GitHub issue 之前展示完整内容并等待你确认。

## 边界

- 只处理 issue body 内容，不处理改标题（会触发文件重命名，逻辑更复杂，暂不支持）。
- 没有反向同步：不会直接新建或编辑目标仓库 `docs/*.md` 的内容部分。
