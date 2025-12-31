# MCP Servers Setup

Claude Code用のMCPサーバーを一括で設定するスクリプト

## 含まれるMCPサーバー

| Server | 機能 | ソース |
|--------|------|--------|
| **filesystem** | ファイル操作（読み書き、ディレクトリ操作） | [Official](https://github.com/modelcontextprotocol/servers) |
| **git** | Gitリポジトリ操作（status, diff, commit等） | [Official](https://github.com/modelcontextprotocol/servers) |
| **github** | GitHub API（Issues, PRs, Repos操作） | [Official](https://github.com/modelcontextprotocol/servers) |
| **docker** | Dockerコンテナ管理 | [QuantGeekDev](https://github.com/QuantGeekDev/docker-mcp) |
| **pio-mcp** | PlatformIO（ビルド、アップロード、モニター） | Custom |
| **ros-mcp** | ROS1/ROS2ロボット制御、rosbag解析 | [robotmcp](https://github.com/robotmcp/ros-mcp-server) |
| **serena** | コードベース解析、シンボル検索 | [oraios](https://github.com/oraios/serena) |

## 前提条件

- Python 3.10+
- Node.js & npm
- [uv](https://docs.astral.sh/uv/): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Git
- Docker (optional, for docker MCP)
- GitHub CLI (optional, for github MCP): `gh auth login`

## インストール

```bash
git clone https://github.com/erusyadoru/mcp-setting.git
cd mcp-setting
chmod +x setup-mcp.sh
./setup-mcp.sh all
```

## 使い方

### 全体セットアップ

```bash
./setup-mcp.sh all
```

これにより:
1. 公式MCPサーバー（filesystem, git, github, docker）をセットアップ
2. pio-mcp-server をクローン＆セットアップ
3. ros-mcp-server をクローン＆セットアップ
4. `~/.claude/settings.json` にグローバル設定を生成
5. `mcp-init` ヘルパースクリプトをインストール

### 個別セットアップ

```bash
# 公式MCPサーバーのみ（filesystem, git, github, docker）
./setup-mcp.sh official

# PlatformIO MCPのみ
./setup-mcp.sh pio

# ROS MCPのみ
./setup-mcp.sh ros

# Claude設定ファイルのみ生成
./setup-mcp.sh settings

# 現在のディレクトリにプロジェクト用.mcp.jsonを生成
./setup-mcp.sh project

# 特定ディレクトリにプロジェクト用.mcp.jsonを生成
./setup-mcp.sh project /path/to/project
```

### Serena + 全MCPの有効化

任意のプロジェクトディレクトリで:

```bash
cd /path/to/your/project
mcp-init
```

これにより `.mcp.json` が作成され、以下のサーバーがそのプロジェクトで利用可能になります:
- serena
- filesystem
- git
- github
- docker
- ros-mcp

## 設定ファイル

### グローバル設定 (`~/.claude/settings.json`)

全プロジェクトで利用可能なMCPサーバー:
- filesystem, git, github, docker
- pio-mcp, ros-mcp

### プロジェクト設定 (`.mcp.json`)

プロジェクト固有のMCPサーバー:
- serena (プロジェクトパスを含むため)
- その他全てのMCPサーバー

## GitHub認証

GitHub MCPを使用するには認証が必要です:

```bash
# GitHub CLIでログイン
gh auth login

# 設定を再生成
./setup-mcp.sh settings
```

## Docker テスト

```bash
docker build -t mcp-test .
docker run --rm -it mcp-test
```

## 各MCPサーバーの機能

### filesystem
- ファイルの読み書き
- ディレクトリの作成・削除
- ファイル検索

### git
- `git status`, `git diff`, `git log`
- コミット、ブランチ操作
- リポジトリ情報取得

### github
- Issue/PR の作成・更新
- リポジトリの検索・クローン
- コードレビュー

### docker
- コンテナの一覧・起動・停止
- イメージの管理
- ログの取得

### ros-mcp
- トピック/サービス/アクション操作
- パラメータ操作
- rosbag解析（info, read, search, record）

### serena
- コードベースのシンボル検索
- リファレンス検索
- リファクタリング支援

## ライセンス

MIT License
