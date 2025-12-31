# MCP Servers Setup

Claude Code用のMCPサーバーを一括で設定するスクリプト

## 含まれるMCPサーバー

| Server | 機能 |
|--------|------|
| **pio-mcp** | PlatformIO プロジェクトのビルド、アップロード、シリアルモニター |
| **ros-mcp** | ROS1/ROS2 ロボット制御、トピック/サービス操作、rosbag解析 |
| **serena** | コードベース解析、シンボル検索、リファクタリング支援 |

## 前提条件

- Python 3.10+
- [uv](https://docs.astral.sh/uv/): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Git

## インストール

```bash
git clone https://github.com/YOUR_USERNAME/mcp-setup.git
cd mcp-setup
chmod +x setup-mcp.sh
./setup-mcp.sh
```

## 使い方

### 全体セットアップ

```bash
./setup-mcp.sh all
```

これにより:
1. pio-mcp-server をクローン＆セットアップ
2. ros-mcp-server をクローン＆セットアップ
3. `~/.claude/settings.json` にグローバル設定を生成
4. `serena-init` ヘルパースクリプトをインストール

### 個別セットアップ

```bash
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

### Serenaの有効化

任意のプロジェクトディレクトリで:

```bash
cd /path/to/your/project
serena-init
```

これにより `.mcp.json` が作成され、SerenaとROS-MCPがそのプロジェクトで利用可能になります。

## 設定ファイル

### グローバル設定 (`~/.claude/settings.json`)

全プロジェクトで利用可能なMCPサーバー:
- pio-mcp
- ros-mcp

### プロジェクト設定 (`.mcp.json`)

プロジェクト固有のMCPサーバー:
- serena (プロジェクトパスを含むため)
- ros-mcp (オプション、ローカル開発用)

## カスタマイズ

環境変数で各サーバーのパスを変更できます:

```bash
export PIO_MCP_DIR="$HOME/custom/pio-mcp"
export ROS_MCP_DIR="$HOME/custom/ros-mcp"
./setup-mcp.sh all
```

## ROS-MCP機能

ros-mcp-serverは以下の機能を提供:

- **トピック操作**: subscribe, publish, list topics
- **サービス操作**: call services, list services
- **アクション操作**: send goals, get status
- **パラメータ操作**: get/set parameters
- **ノード情報**: list nodes, get node details
- **rosbag解析**: info, read, search, record (ROS1 .bag形式)

### rosbagツールの使用例

```python
# bagファイルの情報取得
rosbag_info("/path/to/recording.bag")

# 特定トピックのメッセージ読み取り
rosbag_read("/path/to/recording.bag", "/cmd_vel", limit=10)

# パターン検索
rosbag_search("/path/to/recording.bag", topic_pattern="/odom")
```

## ライセンス

MIT License
