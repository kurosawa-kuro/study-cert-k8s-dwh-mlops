#!/usr/bin/env bash
# reset-soft.sh : Kind クラスターを残したままユーザーリソースを完全クリア
set -Eeuo pipefail
IFS=$'\n\t'

# Kindクラスター名（デフォルト）
KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-"kind"}
KEEP_NS_REGEX='^(kube-|default$|local-path-storage$)'   # ← default は残す
log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }

###############################################################################
# 0) Kind クラスターの状態チェックと起動
###############################################################################
log "▶ checking kind cluster status..."
if ! kind get clusters | grep -q "^${KIND_CLUSTER_NAME}$"; then
  log "▶ kind cluster '${KIND_CLUSTER_NAME}' not found, creating..."
  kind create cluster --name "${KIND_CLUSTER_NAME}"
else
  log "▶ kind cluster '${KIND_CLUSTER_NAME}' exists"
  # クラスターが起動しているかチェック
  if ! kind get nodes --name "${KIND_CLUSTER_NAME}" >/dev/null 2>&1; then
    log "▶ starting kind cluster '${KIND_CLUSTER_NAME}'..."
    kind start cluster --name "${KIND_CLUSTER_NAME}"
  else
    log "▶ kind cluster '${KIND_CLUSTER_NAME}' is already running"
  fi
fi

# kubectl の設定を更新（Kindクラスターのコンテキストを設定）
log "▶ updating kubectl context..."
kind export kubeconfig --name "${KIND_CLUSTER_NAME}" >/dev/null 2>&1 || true
kubectl get nodes >/dev/null 2>&1 || true

###############################################################################
# 1) default"以外"のユーザー NS を削除
###############################################################################
log "▶ wipe non-system, non-default namespaces..."
for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  [[ $ns =~ $KEEP_NS_REGEX ]] && continue
  kubectl delete ns "$ns" --wait=false
done

###############################################################################
# 2) default 名前空間を空にする
###############################################################################
log "▶ purge resources inside <default>..."
kubectl api-resources --verbs=list --namespaced -o name \
| xargs -r -n1 kubectl -n default delete --all --wait=false --ignore-not-found

###############################################################################
# 3) Cluster-scoped のユーザーリソースを削除
###############################################################################
log "▶ delete cluster-scoped *user* resources..."
KEEP_CLUSTER='^(nodes?|namespaces?|customresourcedefinitions?|storageclasses?|csidrivers?|csinodes?|clusterrolebindings?|clusterroles?|apiservices?|flowschemas?|prioritylevelconfigurations?|componentstatuses?)(\.|$)'
kubectl api-resources --verbs=list --namespaced=false -o name \
| grep -Ev "$KEEP_CLUSTER" \
| xargs -r -n1 kubectl delete --all --wait=false --ignore-not-found 2>/dev/null || true

log "✅ reset-soft completed for kind cluster '${KIND_CLUSTER_NAME}' (≈10 s)"
