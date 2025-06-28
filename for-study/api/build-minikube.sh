#!/bin/bash
# Minikube環境でのローカルビルドスクリプト

set -e

# 色付きログ関数
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

# 設定
IMAGE_NAME="api-nodejs-k8s"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

log_info "🚀 Minikube環境でのローカルビルドを開始します..."

# 1. Minikubeの状態確認
log_info "📋 Minikubeの状態を確認中..."
if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
    log_error "Minikubeが起動していません。起動してください。"
    echo "   minikube start"
    exit 1
fi

# 2. MinikubeのDocker環境を設定
log_info "🔧 MinikubeのDocker環境を設定中..."
eval $(minikube docker-env)

# 3. 既存イメージの削除（オプション）
if [ "$1" = "--clean" ]; then
    log_info "🧹 既存イメージを削除中..."
    docker rmi ${FULL_IMAGE_NAME} 2>/dev/null || true
fi

# 4. Dockerイメージのビルド
log_info "📦 Dockerイメージをビルド中..."
log_info "   ターゲット: minikube-local"
log_info "   イメージ名: ${FULL_IMAGE_NAME}"

# ビルド時間の計測開始
BUILD_START=$(date +%s)

docker build \
    --target minikube-local \
    --tag ${FULL_IMAGE_NAME} \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    .

# ビルド時間の計測終了
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

log_info "✅ ビルド完了！ (${BUILD_TIME}秒)"

# 5. イメージサイズの確認
log_info "📊 イメージ情報:"
IMAGE_SIZE=$(docker images ${FULL_IMAGE_NAME} --format "table {{.Size}}" | tail -n 1)
log_info "   サイズ: ${IMAGE_SIZE}"

# 6. セキュリティスキャン（オプション）
if [ "$1" = "--scan" ] || [ "$2" = "--scan" ]; then
    log_info "🔍 セキュリティスキャンを実行中..."
    if command -v trivy &> /dev/null; then
        trivy image ${FULL_IMAGE_NAME} --severity HIGH,CRITICAL
    else
        log_warn "Trivyがインストールされていません。スキャンをスキップします。"
    fi
fi

# 7. イメージの動作確認
log_info "🧪 イメージの動作確認中..."
docker run --rm ${FULL_IMAGE_NAME} node -e "console.log('Node.js version:', process.version)"

# 8. 完了メッセージ
log_info "🎉 ローカルビルドが完了しました！"
echo ""
echo "📱 次のステップ:"
echo "   1. マニフェストの適用:"
echo "      kubectl apply -f ../manifest/10-all-in-one.yaml"
echo "      kubectl apply -f ../manifest/11-minikube-setup.yaml"
echo ""
echo "   2. または、自動デプロイスクリプトを使用:"
echo "      cd ../manifest && ./deploy-minikube.sh"
echo ""
echo "   3. アクセス確認:"
echo "      kubectl port-forward svc/express-svc 8080:80 -n express-app"
echo "      curl http://localhost:8080/healthz"
echo ""
echo "🔧 便利なコマンド:"
echo "   - イメージ再ビルド: ./build-minikube.sh --clean"
echo "   - セキュリティスキャン付き: ./build-minikube.sh --scan"
echo "   - 両方: ./build-minikube.sh --clean --scan" 