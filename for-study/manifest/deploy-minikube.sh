#!/bin/bash
# Minikube環境用デプロイスクリプト

set -e

echo "🚀 Minikube環境用デプロイスクリプトを開始します..."

# 1. Minikubeの状態確認
echo "📋 Minikubeの状態を確認中..."
if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
    echo "❌ Minikubeが起動していません。起動してください。"
    echo "   minikube start"
    exit 1
fi

# 2. Ingressアドオンの有効化
echo "🔧 Ingressアドオンを有効化中..."
minikube addons enable ingress

# 3. Dockerイメージの読み込み
echo "📦 Dockerイメージを読み込み中..."
if docker images | grep -q "api-nodejs-k8s:latest"; then
    echo "✅ イメージが見つかりました。Minikubeに読み込み中..."
    minikube image load api-nodejs-k8s:latest
else
    echo "⚠️  イメージが見つかりません。先にビルドしてください。"
    echo "   cd ../api && make docker-build"
    exit 1
fi

# 4. 既存リソースの削除（オプション）
if [ "$1" = "--clean" ]; then
    echo "🧹 既存リソースを削除中..."
    kubectl delete namespace express-app --ignore-not-found=true
    sleep 5
fi

# 5. マニフェストの適用
echo "📄 マニフェストを適用中..."
kubectl apply -f 10-all-in-one.yaml

# 6. 追加のMinikube設定を適用
echo "🔧 Minikube用の追加設定を適用中..."
kubectl apply -f 11-minikube-setup.yaml

# 7. デプロイ完了待機
echo "⏳ デプロイ完了を待機中..."
kubectl wait --for=condition=available --timeout=300s deployment/express-deploy -n express-app

# 8. 状態確認
echo "📊 デプロイ状態を確認中..."
echo ""
echo "=== Pod の状態 ==="
kubectl get pods -n express-app

echo ""
echo "=== Service の状態 ==="
kubectl get svc -n express-app

echo ""
echo "=== Ingress の状態 ==="
kubectl get ingress -n express-app

# 9. アクセス情報の表示
echo ""
echo "🎉 デプロイが完了しました！"
echo ""
echo "📱 アクセス方法:"
echo "   1. Port-forward:"
echo "      kubectl port-forward svc/express-svc 8080:80 -n express-app"
echo "      ブラウザで http://localhost:8080 にアクセス"
echo ""
echo "   2. NodePort:"
echo "      kubectl port-forward svc/express-svc-nodeport 8080:80 -n express-app"
echo "      ブラウザで http://localhost:8080 にアクセス"
echo ""
echo "   3. Minikube IP:"
echo "      minikube service express-svc-nodeport -n express-app"
echo ""
echo "🔍 ヘルスチェック:"
echo "   curl http://localhost:8080/healthz"
echo "   curl http://localhost:8080/readyz"
echo "   curl http://localhost:8080/metrics"
echo ""
echo "📝 ログ確認:"
echo "   kubectl logs -f deployment/express-deploy -n express-app"
echo ""
echo "🧹 クリーンアップ:"
echo "   kubectl delete namespace express-app" 