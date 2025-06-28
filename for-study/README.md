# Kubernetes学習用アプリケーション - リファクタリング版

このプロジェクトは、Kubernetes認定試験（KCNA、KCSA、CKAD、CKA、CKS）の学習用アプリケーションです。スクリプトのリファクタリングにより、より保守性が高く、使いやすい構造に改善されました。

## 🚀 主な改善点

### ✅ 解決された問題
1. **重複するスクリプト**: 複数の類似スクリプトを統合
2. **分散した設定**: 設定を一元化した`config.sh`
3. **一貫性のない命名**: 統一されたスクリプト名と構造
4. **エラーハンドリング不足**: 包括的なエラーハンドリング
5. **設定の重複**: 共通設定ファイルによる一元管理

### 🔧 新しい機能
1. **統合デプロイスクリプト**: ビルドからデプロイまで一元管理
2. **共通ライブラリ**: 再利用可能な関数群
3. **ドライランモード**: 安全なテスト実行
4. **詳細なログ**: 色付きログとステップ表示
5. **包括的なヘルプ**: 各スクリプトの詳細なヘルプ機能

## 📁 新しいディレクトリ構造

```
study-cert-k8s-dwh-mlops/for-study/
├── config.sh                    # 共通設定ファイル（新規）
├── scripts/                     # スクリプトディレクトリ（新規）
│   ├── lib/
│   │   └── common.sh           # 共通ライブラリ（新規）
│   ├── deploy.sh               # 統合デプロイスクリプト（新規）
│   ├── build.sh                # Dockerビルドスクリプト（新規）
│   ├── cleanup.sh              # クリーンアップスクリプト（新規）
│   ├── status.sh               # ステータス確認スクリプト（新規）
│   ├── legacy-migration.sh     # 移行支援スクリプト（新規）
│   └── README.md               # スクリプト説明書（新規）
├── api/                        # アプリケーションコード
│   ├── Dockerfile
│   ├── package.json
│   └── ...
├── manifest/                   # Kubernetesマニフェスト
│   ├── 10-all-in-one.yaml
│   ├── 11-minikube-setup.yaml
│   └── ...
└── README.md                   # メインREADME
```

## 🎯 クイックスタート

### 1. 初回セットアップ
```bash
# プロジェクトディレクトリに移動
cd study-cert-k8s-dwh-mlops/for-study

# 設定の確認
source config.sh --show

# 設定の検証
source config.sh --validate

# 完全デプロイ（推奨）
./scripts/deploy.sh --clean
```

### 2. 日常的な使用
```bash
# 状態確認
./scripts/status.sh

# ヘルスチェック
./scripts/status.sh --health-check

# 詳細な状態確認
./scripts/status.sh --detailed

# リアルタイム監視
./scripts/status.sh --watch
```

### 3. 開発ワークフロー
```bash
# コード変更後の再デプロイ
./scripts/deploy.sh --clean

# ビルドのみ
./scripts/build.sh

# セキュリティスキャン付きビルド
./scripts/build.sh --scan

# クリーンアップ
./scripts/cleanup.sh
```

## 📋 スクリプト詳細

### 🚀 deploy.sh - 統合デプロイスクリプト
**機能**: ビルドからデプロイまでを一元管理

```bash
# 基本的な使用
./scripts/deploy.sh

# オプション付き
./scripts/deploy.sh --clean --debug
./scripts/deploy.sh --dry-run
./scripts/deploy.sh --skip-build
./scripts/deploy.sh --skip-health-check
```

**オプション**:
- `--clean`: 既存リソースを削除してからデプロイ
- `--dry-run`: 実際の変更を行わずに実行
- `--debug`: デバッグモードで実行
- `--skip-build`: ビルドをスキップ
- `--skip-deploy`: デプロイをスキップ
- `--skip-health-check`: ヘルスチェックをスキップ

### 🔨 build.sh - Dockerビルドスクリプト
**機能**: Dockerイメージのビルドとテスト

```bash
# 基本的な使用
./scripts/build.sh

# オプション付き
./scripts/build.sh --clean --scan
./scripts/build.sh --target production
./scripts/build.sh --build-arg NODE_ENV=production
```

**オプション**:
- `--clean`: 既存イメージを削除してビルド
- `--scan`: セキュリティスキャン付きビルド
- `--target <target>`: ビルドターゲットを指定
- `--build-arg <key=value>`: ビルド引数を指定

### 🧹 cleanup.sh - クリーンアップスクリプト
**機能**: リソースの削除とクリーンアップ

```bash
# 基本的な使用
./scripts/cleanup.sh

# オプション付き
./scripts/cleanup.sh --type k8s
./scripts/cleanup.sh --type docker
./scripts/cleanup.sh --force
```

**オプション**:
- `--type <type>`: クリーンアップタイプ（k8s/docker/all）
- `--force`: 確認なしで削除
- `--dry-run`: ドライランモード

### 📊 status.sh - ステータス確認スクリプト
**機能**: アプリケーションとリソースの状態確認

```bash
# 基本的な使用
./scripts/status.sh

# オプション付き
./scripts/status.sh --detailed
./scripts/status.sh --health-check
./scripts/status.sh --watch
```

**オプション**:
- `--detailed`: 詳細な状態確認
- `--health-check`: ヘルスチェック実行
- `--watch`: リアルタイム監視

## 🔧 設定管理

### config.sh - 共通設定ファイル
すべてのスクリプトで使用する設定を一元管理します。

```bash
# 設定の表示
source config.sh --show

# 設定の検証
source config.sh --validate

# ヘルプ表示
source config.sh --help
```

**主要設定項目**:
- アプリケーション設定（名前、バージョン等）
- Docker設定（イメージ名、タグ等）
- Kubernetes設定（ネームスペース、リソース名等）
- 環境設定（Minikube、タイムアウト等）

## 🔄 レガシースクリプトからの移行

### 移行支援スクリプト
既存のスクリプトから新しいスクリプトへの移行を支援します。

```bash
# 移行の実行
./scripts/legacy-migration.sh

# バックアップのみ
./scripts/legacy-migration.sh --type backup

# 移行のみ
./scripts/legacy-migration.sh --type migration

# バックアップなしで移行
./scripts/legacy-migration.sh --no-backup
```

### コマンド対応表
| レガシーコマンド | 新しいコマンド | 説明 |
|----------------|---------------|------|
| `api/deploy-minikube-complete.sh` | `scripts/deploy.sh` | 完全デプロイ |
| `api/build-minikube.sh` | `scripts/build.sh` | Dockerビルド |
| `manifest/deploy-minikube.sh` | `scripts/deploy.sh --skip-build` | デプロイのみ |

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

# 2. リアルタイム監視
./scripts/status.sh --watch

# 3. 必要に応じてクリーンアップ
./scripts/cleanup.sh --type k8s

# 4. 再デプロイ
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

### よくある問題と解決方法

#### 1. スクリプトが実行できない
```bash
# 実行権限を付与
chmod +x scripts/*.sh scripts/lib/*.sh config.sh

# 個別に付与
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

# 設定の編集
vim config.sh

# 変更後の検証
source config.sh --validate
```

### 新しいスクリプトの追加
新しいスクリプトを作成する際は、共通ライブラリを活用してください：

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

## 🎉 改善効果

### 保守性の向上
- 共通ライブラリによるコードの再利用
- 統一された設定管理
- 一貫したエラーハンドリング

### 使いやすさの向上
- 直感的なスクリプト名
- 詳細なヘルプ機能
- ドライランモードによる安全なテスト

### 機能の拡張
- セキュリティスキャンの統合
- リアルタイム監視機能
- 包括的な状態確認

---

このリファクタリングにより、Kubernetes学習がより効率的で楽しいものになりました！新しいスクリプトを使用して、認定試験の準備を進めてください。 