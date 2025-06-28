#!/usr/bin/env bash
# reset-hard.sh : Minikube を残したままユーザーリソースを完全クリア
set -Eeuo pipefail
IFS=$'\n\t'

# 環境変数の設定（デフォルト値）
MINIKUBE_CPUS="${MINIKUBE_CPUS:-8}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-10000}"
MINIKUBE_DISK_SIZE="${MINIKUBE_DISK_SIZE:-20000}"

KEEP_NS_REGEX='^(kube-|default$|local-path-storage$)'   # ← default は残す
log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }

###############################################################################
# 0) 設定の表示
###############################################################################
log "▶ Minikube 設定:"
log "   CPU: ${MINIKUBE_CPUS} cores"
log "   Memory: ${MINIKUBE_MEMORY} MiB"
log "   Disk: ${MINIKUBE_DISK_SIZE} MiB"

###############################################################################
# 1) Minikube の状態チェックと起動
###############################################################################
log "▶ checking minikube status..."
if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
  log "▶ minikube not running, starting..."
  # 環境変数が設定されている場合は高スペック設定を適用
  if [[ "$MINIKUBE_CPUS" != "8" ]] || [[ "$MINIKUBE_MEMORY" != "10000" ]] || [[ "$MINIKUBE_DISK_SIZE" != "20000" ]]; then
    log "▶ applying high-spec configuration..."
    minikube start \
      --cpus "$MINIKUBE_CPUS" \
      --memory "$MINIKUBE_MEMORY" \
      --disk-size "$MINIKUBE_DISK_SIZE"
  else
    minikube start
  fi
else
  log "▶ minikube is already running"
fi

# kubectl の設定を更新（バージョン警告を回避）
log "▶ updating kubectl context..."
minikube kubectl -- get nodes >/dev/null 2>&1 || true

###############################################################################
# 2) default"以外"のユーザー NS を削除
###############################################################################
log "▶ wipe non-system, non-default namespaces..."
for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  [[ $ns =~ $KEEP_NS_REGEX ]] && continue
  kubectl delete ns "$ns" --wait=false
done

###############################################################################
# 3) default 名前空間を空にする
###############################################################################
log "▶ purge resources inside <default>..."
kubectl api-resources --verbs=list --namespaced -o name \
| xargs -r -n1 kubectl -n default delete --all --wait=false --ignore-not-found

###############################################################################
# 4) Cluster-scoped のユーザーリソースを削除
###############################################################################
log "▶ delete cluster-scoped *user* resources..."
KEEP_CLUSTER='^(nodes?|namespaces?|customresourcedefinitions?|storageclasses?|csidrivers?|csinodes?|clusterrolebindings?|clusterroles?|apiservices?|flowschemas?|prioritylevelconfigurations?|componentstatuses?)(\.|$)'
kubectl api-resources --verbs=list --namespaced=false -o name \
| grep -Ev "$KEEP_CLUSTER" \
| xargs -r -n1 kubectl delete --all --wait=false --ignore-not-found 2>/dev/null || true

log "✅ reset-hard completed with high-spec configuration (≈15 s)"
