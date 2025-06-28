#!/usr/bin/env bash
# optimize-highspec.sh : 高スペック環境でのパフォーマンス最適化
set -Eeuo pipefail
IFS=$'\n\t'

log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m[WARN]\033[0m %s\n' "$*"; }
error(){ printf '\033[31m[ERROR]\033[0m %s\n' "$*"; }

###############################################################################
# 1) Minikube の状態チェック
###############################################################################
log "▶ checking minikube status..."
if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
  warn "▶ minikube is not running. Please start minikube first."
  exit 1
fi

###############################################################################
# 2) リソース制限の最適化
###############################################################################
log "▶ optimizing resource limits..."

# ノードのリソース情報を表示
log "▶ current node resources:"
kubectl describe node minikube | grep -E "(Capacity|Allocatable)" | head -6

# デフォルトのリソース制限を設定
log "▶ setting default resource limits..."
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# LimitRange を作成してデフォルトのリソース制限を設定
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: default
spec:
  limits:
  - default:
      cpu: 1000m
      memory: 1Gi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
EOF

###############################################################################
# 3) ストレージ最適化
###############################################################################
log "▶ optimizing storage..."

# ストレージクラスの確認
log "▶ available storage classes:"
kubectl get storageclass

# デフォルトストレージクラスの設定
if kubectl get storageclass local-path >/dev/null 2>&1; then
  log "▶ setting local-path as default storage class..."
  kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi

###############################################################################
# 4) ネットワーク最適化
###############################################################################
log "▶ optimizing network..."

# DNS 設定の最適化
log "▶ checking DNS configuration..."
kubectl get configmap kube-dns -n kube-system --ignore-not-found

# ネットワークポリシーの確認
log "▶ checking network policies..."
kubectl get networkpolicy --all-namespaces

###############################################################################
# 5) パフォーマンス監視の設定
###############################################################################
log "▶ setting up performance monitoring..."

# メトリクスサーバーの確認
if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  log "▶ enabling metrics server..."
  minikube addons enable metrics-server
fi

# ダッシュボードの確認
if ! kubectl get deployment kubernetes-dashboard -n kubernetes-dashboard >/dev/null 2>&1; then
  log "▶ enabling dashboard..."
  minikube addons enable dashboard
fi

###############################################################################
# 6) 最適化完了
###############################################################################
log "✅ high-spec optimization completed!"
log "▶ available commands:"
log "   kubectl top nodes    - ノードのリソース使用量を表示"
log "   kubectl top pods     - ポッドのリソース使用量を表示"
log "   minikube dashboard   - ダッシュボードを開く"
log "   kubectl get events   - イベントを確認" 