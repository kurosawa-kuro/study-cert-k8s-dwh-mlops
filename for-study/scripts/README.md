# Kubernetes学習用スクリプト

このディレクトリには、Kubernetes学習用アプリケーションの管理に使用するスクリプトが含まれています。

## 📁 ファイル構成

```
scripts/
├── lib/
│   └── common.sh          # 共通ライブラリ（ログ、エラーハンドリング等）
├── deploy.sh              # 統合デプロイスクリプト
├── build.sh               # Dockerビルドスクリプト
├── cleanup.sh             # クリーンアップスクリプト
├── status.sh              # ステータス確認スクリプト
└── README.md              # このファイル
```

## 🚀 クイックスタート

### 1. 完全デプロイ（推奨）
```bash
# ビルドからデプロイまで一括実行
./scripts/deploy.sh

# クリーンアップ後にデプロイ
./scripts/deploy.sh --clean
```

### 2. 個別実行
```bash
# Dockerイメージのビルド
./scripts/build.sh

# Kubernetesへのデプロイ
./scripts/deploy.sh --skip-build

# 状態確認
./scripts/status.sh

# クリーンアップ
./scripts/cleanup.sh
```

## 📋 スクリプト詳細

### deploy.sh - 統合デプロイスクリプト

ビルドからデプロイまでを一元管理するメインスクリプトです。

**使用方法:**
```bash
./scripts/deploy.sh [オプション]
```

**オプション:**
- `--clean`: 既存リソースを削除してからデプロイ
- `--dry-run`: 実際の変更を行わずに実行
- `--debug`: デバッグモードで実行
- `--skip-build`: ビルドをスキップ
- `--skip-deploy`: デプロイをスキップ
- `--skip-health-check`: ヘルスチェックをスキップ

**例:**
```bash
# 通常のデプロイ
./scripts/deploy.sh

# クリーンアップ後にデプロイ
./scripts/deploy.sh --clean

# ドライランモード
./scripts/deploy.sh --dry-run

# ビルドのみスキップ
./scripts/deploy.sh --skip-build
```

### build.sh - Dockerビルドスクリプト

Dockerイメージのビルドとテストを管理します。

**使用方法:**
```bash
./scripts/build.sh [オプション]
```

**オプション:**
- `--clean`: 既存イメージを削除してビルド
- `--scan`: セキュリティスキャン付きビルド
- `--target <target>`: ビルドターゲットを指定（default: minikube-local）
- `--build-arg <key=value>`: ビルド引数を指定
- `--dry-run`: ドライランモード
- `--debug`: デバッグモード

**例:**
```bash
# 通常のビルド
./scripts/build.sh

# セキュリティスキャン付きビルド
./scripts/build.sh --scan

# 本番用ターゲットでビルド
./scripts/build.sh --target production

# クリーンアップ後にビルド
./scripts/build.sh --clean
```

### cleanup.sh - クリーンアップスクリプト

リソースの削除とクリーンアップを管理します。

**使用方法:**
```bash
./scripts/cleanup.sh [オプション]
```

**オプション:**
- `--type <type>`: クリーンアップタイプ（k8s/docker/all, default: all）
- `--force`: 確認なしで削除
- `--dry-run`: ドライランモード
- `--debug`: デバッグモード

**例:**
```bash
# すべてのリソースを削除
./scripts/cleanup.sh

# Kubernetesリソースのみ削除
./scripts/cleanup.sh --type k8s

# Dockerリソースのみ削除
./scripts/cleanup.sh --type docker

# 確認なしで削除
./scripts/cleanup.sh --force
```

### status.sh - ステータス確認スクリプト

アプリケーションとリソースの状態を確認します。

**使用方法:**
```bash
./scripts/status.sh [オプション]
```

**オプション:**
- `--detailed`: 詳細な状態確認
- `--health-check`: ヘルスチェック実行
- `--watch`: リアルタイム監視
- `--debug`: デバッグモード

**例:**
```bash
# 基本的な状態確認
./scripts/status.sh

# 詳細な状態確認
./scripts/status.sh --detailed

# ヘルスチェック実行
./scripts/status.sh --health-check

# リアルタイム監視
./scripts/status.sh --watch
```

## 🔧 共通ライブラリ (lib/common.sh)

すべてのスクリプトで使用する共通機能を提供します。

### 主要機能
- **ログ関数**: `log_info`, `log_warn`, `log_error`, `log_step`, `log_debug`
- **エラーハンドリング**: 自動エラー検出とクリーンアップ
- **前提条件チェック**: 必須ツールの存在確認
- **Docker関連**: 環境設定、ビルド、テスト
- **Kubernetes関連**: マニフェスト適用、デプロイ待機、状態確認
- **ヘルスチェック**: アプリケーションの動作確認
- **クリーンアップ**: リソースの削除

### 使用例
```bash
# 共通ライブラリを読み込み
source "./scripts/lib/common.sh"

# 設定ファイルを読み込み
load_config

# ログ出力
log_info "処理を開始します"
log_step "ステップ1: 前提条件チェック"

# 前提条件チェック
if ! check_prerequisites; then
    log_error "前提条件チェックに失敗しました"
    exit 1
fi
```

## 🎯 ワークフロー例

### 開発ワークフロー
```bash
# 1. アプリケーションの変更
# ... コードを編集 ...

# 2. ビルドとデプロイ
./scripts/deploy.sh --clean

# 3. 状態確認
./scripts/status.sh --detailed

# 4. ヘルスチェック
./scripts/status.sh --health-check
```

### トラブルシューティングワークフロー
```bash
# 1. 現在の状態を確認
./scripts/status.sh --detailed

# 2. ログを確認
kubectl logs -f deployment/express-deploy -n express-app

# 3. イベントを確認
kubectl get events -n express-app --sort-by='.lastTimestamp'

# 4. 必要に応じてクリーンアップ
./scripts/cleanup.sh --type k8s

# 5. 再デプロイ
./scripts/deploy.sh
```

### 本番環境準備ワークフロー
```bash
# 1. セキュリティスキャン付きビルド
./scripts/build.sh --scan --target production

# 2. ドライランデプロイ
./scripts/deploy.sh --dry-run

# 3. 実際のデプロイ
./scripts/deploy.sh
```

## 🔍 トラブルシューティング

### よくある問題

#### 1. スクリプトが実行できない
```bash
# 実行権限を付与
chmod +x scripts/*.sh

# または個別に
chmod +x scripts/deploy.sh
```

#### 2. 設定ファイルが見つからない
```bash
# 設定ファイルの存在確認
ls -la config.sh

# 設定の検証
source config.sh --validate
```

#### 3. 前提条件チェックに失敗
```bash
# 必須ツールの確認
which docker kubectl minikube

# バージョン確認
docker --version
kubectl version --client
minikube version
```

#### 4. Minikubeが起動していない
```bash
# Minikubeの状態確認
minikube status

# Minikubeの起動
minikube start --driver=docker --cpus=2 --memory=4096
```

#### 5. Dockerビルドに失敗
```bash
# Docker環境の確認
docker info

# MinikubeのDocker環境を設定
eval $(minikube docker-env)

# ビルドの再実行
./scripts/build.sh --clean
```

## 📚 学習ポイント

### KCNA（基礎）
- スクリプトの基本構造と実行方法
- 設定ファイルの管理
- 基本的なエラーハンドリング

### KCSA（クラウド・セキュリティ基礎）
- セキュリティスキャンの実行
- 設定の検証と確認
- 安全なクリーンアップ

### CKAD（アプリケーション開発）
- ビルドプロセスの自動化
- ヘルスチェックの実装
- デプロイメントの管理

### CKA（運用）
- リソースの監視と管理
- トラブルシューティング
- ログの確認と分析

### CKS（セキュリティ）
- セキュリティスキャンの統合
- 安全な設定管理
- 最小権限の原則

## 🔧 カスタマイズ

### 設定の変更
`config.sh`を編集して設定を変更できます：

```bash
# 設定の表示
source config.sh --show

# 設定の検証
source config.sh --validate

# 設定の編集
vim config.sh
```

### 新しいスクリプトの追加
新しいスクリプトを作成する際は、以下のテンプレートを使用してください：

```bash
#!/bin/bash
# スクリプト名
# スクリプトの説明

# 初期化
set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 共通ライブラリの読み込み
source "$SCRIPT_DIR/lib/common.sh"

# 設定ファイルの読み込み
load_config

# エラーハンドリングの設定
set_error_handling

# メイン処理
main() {
    log_info "処理を開始します..."
    
    # 処理内容
    
    log_info "処理が完了しました！"
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 📖 参考資料

- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Bash Scripting Guide](https://tldp.org/LDP/abs/html/)

---

これらのスクリプトを使用して、Kubernetes学習を効率的に進めてください！ 