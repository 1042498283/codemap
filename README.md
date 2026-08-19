# codemap

生成 `CODEMAP.md` 的 Agent 技能 —— 为项目补充**任务优先导航地图**：任务索引、调用链图（Mermaid）、核心业务模块摘要。作为 `AGENTS.md` 的补充而非替代。

## 安装

整个 `codemap` 目录（含 `SKILL.md` + `scripts/`）复制到目标位置。同一份包在 CodeBuddy / Trae / Claude Code 间通用。

### CodeBuddy

| 范围 | 目标目录 |
|------|----------|
| 全局 | `~/.codebuddy/skills/codemap/`（Windows：`%userprofile%\.codebuddy\skills\codemap\`） |
| 项目级 | `<项目>/.codebuddy/skills/codemap/` |

### Trae

| 范围 | 目标目录 |
|------|----------|
| 全局 | `~/.trae-cn/skills/codemap/`（Windows：`%userprofile%\.trae-cn\skills\codemap\`） |
| 项目级 | `<项目>/.trae/skills/codemap/` |

### Claude Code（兼容）

| 范围 | 目标目录 |
|------|----------|
| 全局 | `~/.claude/skills/codemap/` |
| 项目级 | `<项目>/.claude/skills/codemap/` |

## 使用

两种触发方式：

1. **自动触发**：AI 在任务开始前扫描技能描述，遇到「梳理代码结构」「哪里改 X」「调用链」「代码关系图」等意图时自动加载。
2. **手动指定**：直接对 AI 说「用 codemap 技能分析这个项目」或「跑一遍 codemap」。

## 输出产物

生成在**项目根目录**，与 `AGENTS.md` 平级。按项目规模分两种形态：

**单层模式**（源码 ≤50 文件 且 ≤8 模块 且顶层 ≤200 行）：

```
项目根/
├── AGENTS.md              # 会被自动写入一行 "read CODEMAP.md"（不存在则创建最小 stub）
├── CODEMAP.md             # 全部内容：模块表 + 任务索引 + 调用链 + 依赖图
└── CODEMAP-changelog.md   # 变更日志
```

**两层模式**（源码 >50 文件，或 >8 模块，或顶层将超 200 行）：

```
项目根/
├── AGENTS.md                       # 引用 CODEMAP.md
├── CODEMAP.md                      # 纯索引（≤60 行）：技术栈 + 领域目录 + 顶层任务索引 + 依赖图
└── .codemap/
    ├── README.md                   # 文档地图（链接向导）
    └── domains/
        └── <domain>/
            ├── tasks.md            # 该领域任务索引（前置条件 + 坑）
            └── flows.md            # 该领域调用链 + 该领域 Change Log
```

核心原则：**agent 先读轻量的顶层 `CODEMAP.md`，按需再钻进领域文档**，避免一次性读入大文件占用上下文。

## 脚本

跨平台双版本，按操作系统选用：

| 用途 | Unix / macOS / Git Bash | Windows PowerShell |
|------|------------------------|--------------------|
| 按「文件 + 符号名」定位行号 | `scripts/where.sh <file> <symbol>` | `scripts/where.ps1 <file> <symbol>` |
| 统计源码文件数（决定分层） | `scripts/count_sources.sh [root]` | `scripts/count_sources.ps1 [root]` |
| 报告 CODEMAP 文件是否超 200 行（扫描顶层 + `.codemap/`） | `scripts/check_size.sh [root] [200]` | `scripts/check_size.ps1 [root] [200]` |

`count_sources` 支持 `CODEMAP_EXCLUDE` 环境变量（正则）排除额外生成路径。

## 技能包结构

```
codemap/
├── SKILL.md               # 技能定义 + 完整工作流
├── README.md              # 本文件（安装说明）
└── scripts/
    ├── where.sh / where.ps1
    ├── count_sources.sh / count_sources.ps1
    └── check_size.sh / check_size.ps1
```
