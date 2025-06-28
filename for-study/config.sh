#!/bin/bash
# 共通設定ファイル
# すべてのスクリプトで使用する設定を一元管理

# ========================================
# アプリケーション設定
# ========================================
export APP_NAME="express-app"
export APP_VERSION="1.0.0"
export APP_DESCRIPTION="Kubernetes学習用Express.jsアプリケーション"

# ========================================
# Docker設定
# ========================================
export DOCKER_IMAGE_NAME="api-nodejs-k8s"
export DOCKER_IMAGE_TAG="latest"
export DOCKER_FULL_IMAGE_NAME="${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
export DOCKER_CONTAINER_NAME="${DOCKER_IMAGE_NAME}-container"
export DOCKER_PORT="8000"

# ========================================
# Kubernetes設定
# ========================================
export K8S_NAMESPACE="express-app"
export K8S_DEPLOYMENT_NAME="express-deploy"
export K8S_SERVICE_NAME="express-svc"
export K8S_SERVICE_NODEPORT_NAME="express-svc-nodeport"
export K8S_HPA_NAME="express-hpa"

# ========================================
# ディレクトリ設定
# ========================================
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export API_DIR="${PROJECT_ROOT}/api"
export MANIFEST_DIR="${PROJECT_ROOT}/manifest"
export SCRIPTS_DIR="${PROJECT_ROOT}/scripts"

# ========================================
# ファイル設定
# ========================================
export MANIFEST_ALL_IN_ONE="${MANIFEST_DIR}/10-all-in-one.yaml"
export MANIFEST_MINIKUBE_SETUP="${MANIFEST_DIR}/11-minikube-setup.yaml"
export DOCKERFILE="${API_DIR}/Dockerfile"
export PACKAGE_JSON="${API_DIR}/package.json"

# ========================================
# 環境設定
# ========================================
export NODE_ENV="production"
export NODE_PORT="8000"
export MINIKUBE_DRIVER="docker"
export MINIKUBE_CPUS="2"
export MINIKUBE_MEMORY="4096"
export MINIKUBE_DISK_SIZE="20g"

# ========================================
# タイムアウト設定
# ========================================
export DEPLOYMENT_TIMEOUT="300"
export HEALTH_CHECK_TIMEOUT="30"
export BUILD_TIMEOUT="600"

# ========================================
# ログ設定
# ========================================
export LOG_LEVEL="INFO"
export LOG_COLORS="true"

# ========================================
# セキュリティ設定
# ========================================
export DOCKER_BUILDKIT_DISABLE="true"
export DOCKER_SCAN_SUGGEST="false"

# ========================================
# ヘルプメッセージ
# ========================================
show_config_help() {
    cat << EOF
設定ファイル: config.sh

利用可能な設定:
  - APP_NAME: アプリケーション名
  - DOCKER_IMAGE_NAME: Dockerイメージ名
  - K8S_NAMESPACE: Kubernetesネームスペース
  - PROJECT_ROOT: プロジェクトルートディレクトリ

設定の確認:
  source config.sh && echo "Docker Image: \$DOCKER_FULL_IMAGE_NAME"
  source config.sh && echo "K8S Namespace: \$K8S_NAMESPACE"

設定の変更:
  このファイルを編集して設定を変更してください。
EOF
}

# ヘルプオプションの処理
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_config_help
    exit 0
fi

# 設定の検証
validate_config() {
    local errors=0
    
    # 必須ディレクトリの存在確認
    if [[ ! -d "$API_DIR" ]]; then
        echo "エラー: APIディレクトリが見つかりません: $API_DIR" >&2
        ((errors++))
    fi
    
    if [[ ! -d "$MANIFEST_DIR" ]]; then
        echo "エラー: マニフェストディレクトリが見つかりません: $MANIFEST_DIR" >&2
        ((errors++))
    fi
    
    # 必須ファイルの存在確認
    if [[ ! -f "$DOCKERFILE" ]]; then
        echo "エラー: Dockerfileが見つかりません: $DOCKERFILE" >&2
        ((errors++))
    fi
    
    if [[ ! -f "$PACKAGE_JSON" ]]; then
        echo "エラー: package.jsonが見つかりません: $PACKAGE_JSON" >&2
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo "設定エラーが $errors 件見つかりました。" >&2
        return 1
    fi
    
    return 0
}

# 設定の表示
show_config() {
    echo "=== アプリケーション設定 ==="
    echo "APP_NAME: $APP_NAME"
    echo "APP_VERSION: $APP_VERSION"
    echo ""
    echo "=== Docker設定 ==="
    echo "DOCKER_IMAGE_NAME: $DOCKER_IMAGE_NAME"
    echo "DOCKER_IMAGE_TAG: $DOCKER_IMAGE_TAG"
    echo "DOCKER_FULL_IMAGE_NAME: $DOCKER_FULL_IMAGE_NAME"
    echo "DOCKER_PORT: $DOCKER_PORT"
    echo ""
    echo "=== Kubernetes設定 ==="
    echo "K8S_NAMESPACE: $K8S_NAMESPACE"
    echo "K8S_DEPLOYMENT_NAME: $K8S_DEPLOYMENT_NAME"
    echo "K8S_SERVICE_NAME: $K8S_SERVICE_NAME"
    echo ""
    echo "=== ディレクトリ設定 ==="
    echo "PROJECT_ROOT: $PROJECT_ROOT"
    echo "API_DIR: $API_DIR"
    echo "MANIFEST_DIR: $MANIFEST_DIR"
    echo ""
    echo "=== 環境設定 ==="
    echo "NODE_ENV: $NODE_ENV"
    echo "MINIKUBE_DRIVER: $MINIKUBE_DRIVER"
    echo "MINIKUBE_CPUS: $MINIKUBE_CPUS"
    echo "MINIKUBE_MEMORY: $MINIKUBE_MEMORY"
}

# 設定表示オプションの処理
if [[ "${1:-}" == "--show" ]]; then
    show_config
    exit 0
fi

# 設定検証オプションの処理
if [[ "${1:-}" == "--validate" ]]; then
    if validate_config; then
        echo "✅ 設定は正常です"
        exit 0
    else
        echo "❌ 設定に問題があります"
        exit 1
    fi
fi 