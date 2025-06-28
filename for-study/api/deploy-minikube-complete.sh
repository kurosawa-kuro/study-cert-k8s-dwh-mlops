#!/bin/bash
# Minikube環境での完全デプロイスクリプト（ビルドからデプロイまで）

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

log_step() {
    echo -e "\033[36m[STEP]\033[0m $1"
}

# 設定
IMAGE_NAME="api-nodejs-k8s"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
MANIFEST_DIR="../manifest"

log_info "🚀 Minikube環境での完全デプロイを開始します..."

# 1. Minikubeの状態確認
log_step "1. Minikubeの状態確認"
if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
    log_error "Minikubeが起動していません。起動してください。"
    echo "   minikube start"
    exit 1
fi
log_info "✅ Minikubeが起動しています"

# 2. MinikubeのDocker環境を設定
log_step "2. MinikubeのDocker環境を設定"
eval $(minikube docker-env)
log_info "✅ Docker環境を設定しました"

# Docker buildxの権限問題を回避
log_info "Docker buildxの権限問題を回避中..."
export DOCKER_BUILDKIT=0
log_info "✅ Docker buildxを無効化しました（権限問題回避）"

# 3. 既存リソースの削除（オプション）
if [ "$1" = "--clean" ]; then
    log_step "3. 既存リソースの削除"
    log_info "既存のリソースを削除中..."
    kubectl delete namespace express-app --ignore-not-found=true
    docker rmi ${FULL_IMAGE_NAME} 2>/dev/null || true
    sleep 5
fi

# 4. Dockerイメージのビルド
log_step "4. Dockerイメージのビルド"
log_info "Minikube環境でイメージをビルド中..."
BUILD_START=$(date +%s)

# BuildKitを使用したdocker build
docker build \
    --target minikube-local \
    --tag ${FULL_IMAGE_NAME} \
    .

BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))
log_info "✅ ビルド完了！ (${BUILD_TIME}秒)"

# 5. イメージの動作確認
log_step "5. イメージの動作確認"
log_info "イメージの動作を確認中..."
docker run --rm ${FULL_IMAGE_NAME} node -e "console.log('✅ Node.js version:', process.version)"

# 6. マニフェストの適用
log_step "6. マニフェストの適用"
log_info "Kubernetesマニフェストを適用中..."

# メインマニフェストの適用
log_info "メインマニフェストを適用中..."
kubectl apply -f ${MANIFEST_DIR}/10-all-in-one.yaml

# Minikube用の追加設定を適用
log_info "Minikube用の追加設定を適用中..."
kubectl apply -f ${MANIFEST_DIR}/11-minikube-setup.yaml

# 7. デプロイ完了待機
log_step "7. デプロイ完了待機"
log_info "デプロイ完了を待機中..."
kubectl wait --for=condition=available --timeout=300s deployment/express-deploy -n express-app
log_info "✅ デプロイが完了しました！"

# 8. 状態確認
log_step "8. デプロイ状態の確認"
echo ""
echo "=== Pod の状態 ==="
kubectl get pods -n express-app

echo ""
echo "=== Service の状態 ==="
kubectl get svc -n express-app

echo ""
echo "=== HPA の状態 ==="
kubectl get hpa -n express-app

echo ""
echo "=== 全体的なリソース状態 ==="
kubectl get all -n express-app

# 9. ヘルスチェック
log_step "9. アプリケーションのヘルスチェック"
log_info "アプリケーションの動作確認中..."

# Port-forwardを一時的に起動してヘルスチェック
log_info "Port-forwardを起動してヘルスチェックを実行..."
kubectl port-forward svc/express-svc 8080:80 -n express-app &
PF_PID=$!

# 少し待ってからヘルスチェック
sleep 5

# ヘルスチェック実行
if curl -f http://localhost:8080/healthz >/dev/null 2>&1; then
    log_info "✅ ヘルスチェック成功"
else
    log_warn "⚠️ ヘルスチェック失敗（アプリケーションの起動に時間がかかっている可能性があります）"
fi

# Port-forwardを停止
kill $PF_PID 2>/dev/null || true

# 10. 完了メッセージ
log_info "🎉 完全デプロイが完了しました！"
echo ""
echo "📱 アクセス方法:"
echo "   1. Port-forward:"
echo "      kubectl port-forward svc/express-svc 8080:80 -n express-app"
echo "      ブラウザで http://localhost:8080 にアクセス"
echo ""
echo "   2. NodePort Service:"
echo "      kubectl port-forward svc/express-svc-nodeport 8080:80 -n express-app"
echo ""
echo "   3. Minikube IP:"
echo "      minikube service express-svc-nodeport -n express-app"
echo ""
echo "🔍 ヘルスチェック:"
echo "   curl http://localhost:8080/healthz"
echo "   curl http://localhost:8080/readyz"
echo "   curl http://localhost:8080/metrics"
echo "   curl http://localhost:8080/config"
echo ""
echo "📝 ログ確認:"
echo "   kubectl logs -f deployment/express-deploy -n express-app"
echo ""
echo "🔧 便利なコマンド:"
echo "   - 状態確認: kubectl get all -n express-app"
echo "   - イベント確認: kubectl get events -n express-app --sort-by='.lastTimestamp'"
echo "   - リソース使用量: kubectl top pods -n express-app"
echo ""
echo "🧹 クリーンアップ:"
echo "   kubectl delete namespace express-app"
echo "   docker rmi ${FULL_IMAGE_NAME}"
echo ""
echo "🔧 トラブルシューティング:"
echo "   - Podが起動しない場合:"
echo "     kubectl describe pod <pod-name> -n express-app"
echo "     kubectl logs <pod-name> -n express-app"
echo "   - イメージの問題の場合:"
echo "     docker rmi ${FULL_IMAGE_NAME}"
echo "     ./deploy-minikube-complete.sh --clean" 