#!/usr/bin/env bash
# reset-soft.sh : Kubernetes クラスターのユーザーリソースを完全クリア (Minikube/kubeadm対応)
set -Eeuo pipefail
IFS=$'\n\t'

# 環境設定
KEEP_NS_REGEX='^(kube-|default$|local-path-storage$|kubeadm-|kube-system$)'   # kubeadm対応
log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }
error(){ printf '\033[31m[ERROR]\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m[WARN]\033[0m %s\n' "$*"; }

###############################################################################
# 0) 環境検出とクラスター状態チェック
###############################################################################
detect_environment() {
    log "▶ detecting Kubernetes environment..."
    
    # kubectl が利用可能かチェック
    if ! command -v kubectl >/dev/null 2>&1; then
        error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # クラスター接続チェック
    if ! kubectl cluster-info >/dev/null 2>&1; then
        error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # 環境タイプの検出
    if command -v minikube >/dev/null 2>&1 && minikube status --format='{{.Host}}' >/dev/null 2>&1; then
        ENV_TYPE="minikube"
        log "▶ detected Minikube environment"
        
        # Minikube の状態チェックと起動
        if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
            log "▶ minikube not running, starting..."
            minikube start
        else
            log "▶ minikube is already running"
        fi
        
        # kubectl の設定を更新（バージョン警告を回避）
        log "▶ updating kubectl context..."
        minikube kubectl -- get nodes >/dev/null 2>&1 || true
        
    else
        ENV_TYPE="kubeadm"
        log "▶ detected kubeadm environment"
        
        # kubeadm環境での追加チェック
        if kubectl get nodes -o name | grep -q "node/"; then
            log "▶ kubeadm cluster is accessible"
        else
            error "Cannot access kubeadm cluster nodes"
            exit 1
        fi
    fi
}

###############################################################################
# 1) システム以外のユーザー NS を削除
###############################################################################
cleanup_namespaces() {
    log "▶ wipe non-system, non-default namespaces..."
    
    # 削除対象の名前空間を取得
    namespaces=$(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || echo "")
    
    if [[ -z "$namespaces" ]]; then
        warn "No namespaces found or cannot access namespaces"
        return
    fi
    
    deleted_count=0
    for ns in $namespaces; do
        if [[ $ns =~ $KEEP_NS_REGEX ]]; then
            log "▶ keeping system namespace: $ns"
            continue
        fi
        
        log "▶ deleting namespace: $ns"
        if kubectl delete ns "$ns" --wait=false --ignore-not-found >/dev/null 2>&1; then
            ((deleted_count++))
        else
            warn "Failed to delete namespace: $ns"
        fi
    done
    
    log "▶ deleted $deleted_count user namespaces"
}

###############################################################################
# 2) default 名前空間を空にする
###############################################################################
cleanup_default_namespace() {
    log "▶ purge resources inside <default> namespace..."
    
    # namespaced resources を取得して削除
    namespaced_resources=$(kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null || echo "")
    
    if [[ -n "$namespaced_resources" ]]; then
        echo "$namespaced_resources" | while read -r resource; do
            if [[ -n "$resource" ]]; then
                log "▶ cleaning $resource in default namespace"
                kubectl -n default delete "$resource" --all --wait=false --ignore-not-found >/dev/null 2>&1 || true
            fi
        done
    fi
    
    log "▶ default namespace cleanup completed"
}

###############################################################################
# 3) Cluster-scoped のユーザーリソースを削除
###############################################################################
cleanup_cluster_resources() {
    log "▶ delete cluster-scoped *user* resources..."
    
    # kubeadm環境での追加保護リソース
    KEEP_CLUSTER='^(nodes?|namespaces?|customresourcedefinitions?|storageclasses?|csidrivers?|csinodes?|clusterrolebindings?|clusterroles?|apiservices?|flowschemas?|prioritylevelconfigurations?|componentstatuses?|persistentvolumes?|persistentvolumeclaims?|events?|events\.events\.k8s\.io)(\.|$)'
    
    cluster_resources=$(kubectl api-resources --verbs=list --namespaced=false -o name 2>/dev/null || echo "")
    
    if [[ -n "$cluster_resources" ]]; then
        echo "$cluster_resources" | grep -Ev "$KEEP_CLUSTER" | while read -r resource; do
            if [[ -n "$resource" ]]; then
                log "▶ cleaning cluster resource: $resource"
                kubectl delete "$resource" --all --wait=false --ignore-not-found >/dev/null 2>&1 || true
            fi
        done
    fi
    
    log "▶ cluster-scoped resources cleanup completed"
}

###############################################################################
# 4) 環境固有の後処理
###############################################################################
post_cleanup() {
    if [[ "$ENV_TYPE" == "minikube" ]]; then
        log "▶ minikube post-cleanup..."
        # Minikube固有の後処理があれば追加
    else
        log "▶ kubeadm post-cleanup..."
        # kubeadm固有の後処理があれば追加
    fi
}

###############################################################################
# メイン実行
###############################################################################
main() {
    log "🚀 Starting Kubernetes cluster reset (soft mode)..."
    
    detect_environment
    cleanup_namespaces
    cleanup_default_namespace
    cleanup_cluster_resources
    post_cleanup
    
    log "✅ reset-soft completed successfully (environment: $ENV_TYPE)"
}

# スクリプト実行
main "$@"
