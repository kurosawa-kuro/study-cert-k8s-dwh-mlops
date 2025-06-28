#!/bin/bash
# ステータス確認スクリプト
# アプリケーションとリソースの状態を確認

# ========================================
# 初期化
# ========================================
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

# ========================================
# 変数定義
# ========================================
DEBUG_MODE=false
DETAILED_MODE=false
HEALTH_CHECK_MODE=false
WATCH_MODE=false

# ========================================
# ヘルプメッセージ
# ========================================
show_status_help() {
    show_help \
        "status.sh" \
        "アプリケーションとリソースの状態確認スクリプト" \
        "./scripts/status.sh [オプション]" \
        "  ./scripts/status.sh                    # 基本的な状態確認\n  ./scripts/status.sh --detailed           # 詳細な状態確認\n  ./scripts/status.sh --health-check       # ヘルスチェック実行\n  ./scripts/status.sh --watch              # リアルタイム監視\n  ./scripts/status.sh --debug              # デバッグモード"
}

# ========================================
# オプション解析
# ========================================
parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_status_help
                exit 0
                ;;
            --detailed)
                DETAILED_MODE=true
                shift
                ;;
            --health-check)
                HEALTH_CHECK_MODE=true
                shift
                ;;
            --watch)
                WATCH_MODE=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                LOG_LEVEL="DEBUG"
                shift
                ;;
            *)
                log_error "不明なオプション: $1"
                show_status_help
                exit 1
                ;;
        esac
    done
}

# ========================================
# Minikube状態確認
# ========================================
check_minikube_detailed() {
    log_step "Minikubeの詳細状態を確認中..."
    
    echo ""
    echo "=== Minikube基本情報 ==="
    minikube status
    
    echo ""
    echo "=== Minikube設定 ==="
    minikube config view
    
    echo ""
    echo "=== Minikubeアドオン ==="
    minikube addons list
    
    echo ""
    echo "=== Minikubeリソース使用量 ==="
    minikube ssh "df -h /" 2>/dev/null || echo "リソース使用量の取得に失敗しました"
}

# ========================================
# Kubernetes状態確認
# ========================================
check_kubernetes_detailed() {
    log_step "Kubernetesの詳細状態を確認中..."
    
    echo ""
    echo "=== ネームスペース一覧 ==="
    kubectl get namespaces
    
    echo ""
    echo "=== クラスター情報 ==="
    kubectl cluster-info
    
    echo ""
    echo "=== ノード情報 ==="
    kubectl get nodes -o wide
    
    echo ""
    echo "=== アプリケーションリソース詳細 ==="
    if kubectl get namespace $K8S_NAMESPACE &>/dev/null; then
        echo "--- Pod詳細 ---"
        kubectl get pods -n $K8S_NAMESPACE -o wide
        
        echo ""
        echo "--- Service詳細 ---"
        kubectl get svc -n $K8S_NAMESPACE -o wide
        
        echo ""
        echo "--- Deployment詳細 ---"
        kubectl get deployment -n $K8S_NAMESPACE -o wide
        
        echo ""
        echo "--- HPA詳細 ---"
        kubectl get hpa -n $K8S_NAMESPACE -o wide
        
        echo ""
        echo "--- ConfigMap詳細 ---"
        kubectl get configmap -n $K8S_NAMESPACE
        
        echo ""
        echo "--- Secret詳細 ---"
        kubectl get secret -n $K8S_NAMESPACE
        
        echo ""
        echo "--- NetworkPolicy詳細 ---"
        kubectl get networkpolicy -n $K8S_NAMESPACE
        
        echo ""
        echo "--- ResourceQuota詳細 ---"
        kubectl get resourcequota -n $K8S_NAMESPACE
        
        echo ""
        echo "--- LimitRange詳細 ---"
        kubectl get limitrange -n $K8S_NAMESPACE
    else
        echo "❌ ネームスペース $K8S_NAMESPACE は存在しません"
    fi
}

# ========================================
# Docker状態確認
# ========================================
check_docker_detailed() {
    log_step "Dockerの詳細状態を確認中..."
    
    echo ""
    echo "=== Docker基本情報 ==="
    docker version
    
    echo ""
    echo "=== Dockerイメージ詳細 ==="
    if docker images | grep -q "$DOCKER_IMAGE_NAME"; then
        docker images $DOCKER_IMAGE_NAME
        echo ""
        echo "--- イメージ詳細 ---"
        docker inspect $DOCKER_FULL_IMAGE_NAME --format='{{.Config.Env}}' | head -10
    else
        echo "❌ Dockerイメージ $DOCKER_IMAGE_NAME は存在しません"
    fi
    
    echo ""
    echo "=== Dockerコンテナ詳細 ==="
    if docker ps -a | grep -q "$DOCKER_CONTAINER_NAME"; then
        docker ps -a | grep "$DOCKER_CONTAINER_NAME"
        echo ""
        echo "--- コンテナ詳細 ---"
        docker inspect $DOCKER_CONTAINER_NAME --format='{{.State.Status}} {{.State.Running}} {{.State.StartedAt}}' 2>/dev/null || echo "コンテナ詳細の取得に失敗しました"
    else
        echo "❌ Dockerコンテナ $DOCKER_CONTAINER_NAME は存在しません"
    fi
    
    echo ""
    echo "=== Dockerシステム情報 ==="
    docker system df
}

# ========================================
# イベント確認
# ========================================
check_events() {
    log_step "Kubernetesイベントを確認中..."
    
    echo ""
    echo "=== 最近のイベント ==="
    if kubectl get namespace $K8S_NAMESPACE &>/dev/null; then
        kubectl get events -n $K8S_NAMESPACE --sort-by='.lastTimestamp' | tail -20
    else
        echo "❌ ネームスペース $K8S_NAMESPACE は存在しません"
    fi
}

# ========================================
# ログ確認
# ========================================
check_logs() {
    log_step "アプリケーションログを確認中..."
    
    echo ""
    echo "=== アプリケーションログ ==="
    if kubectl get namespace $K8S_NAMESPACE &>/dev/null; then
        local pods=$(kubectl get pods -n $K8S_NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        if [[ -n "$pods" ]]; then
            for pod in $pods; do
                echo "--- Pod: $pod ---"
                kubectl logs $pod -n $K8S_NAMESPACE --tail=10 2>/dev/null || echo "ログの取得に失敗しました"
                echo ""
            done
        else
            echo "❌ Podが見つかりません"
        fi
    else
        echo "❌ ネームスペース $K8S_NAMESPACE は存在しません"
    fi
}

# ========================================
# リソース使用量確認
# ========================================
check_resource_usage() {
    log_step "リソース使用量を確認中..."
    
    echo ""
    echo "=== Podリソース使用量 ==="
    if kubectl get namespace $K8S_NAMESPACE &>/dev/null; then
        kubectl top pods -n $K8S_NAMESPACE 2>/dev/null || echo "リソース使用量の取得に失敗しました（metrics-serverが必要）"
    else
        echo "❌ ネームスペース $K8S_NAMESPACE は存在しません"
    fi
    
    echo ""
    echo "=== ノードリソース使用量 ==="
    kubectl top nodes 2>/dev/null || echo "ノードリソース使用量の取得に失敗しました（metrics-serverが必要）"
}

# ========================================
# リアルタイム監視
# ========================================
watch_status() {
    log_info "リアルタイム監視を開始します... (Ctrl+Cで終了)"
    
    # 複数のターミナルで監視を実行
    if command -v tmux &> /dev/null; then
        log_info "tmuxを使用してマルチペイン監視を開始します..."
        
        # tmuxセッションを作成
        tmux new-session -d -s k8s-monitor
        
        # ペインを分割して各監視を開始
        tmux split-window -h -t k8s-monitor
        tmux split-window -v -t k8s-monitor
        tmux select-pane -t 0
        tmux split-window -v -t k8s-monitor
        
        # 各ペインで監視コマンドを実行
        tmux send-keys -t k8s-monitor:0.0 "kubectl get pods -n $K8S_NAMESPACE -w" Enter
        tmux send-keys -t k8s-monitor:0.1 "kubectl get events -n $K8S_NAMESPACE -w" Enter
        tmux send-keys -t k8s-monitor:0.2 "kubectl logs -f deployment/$K8S_DEPLOYMENT_NAME -n $K8S_NAMESPACE" Enter
        tmux send-keys -t k8s-monitor:0.3 "watch -n 5 'kubectl get all -n $K8S_NAMESPACE'" Enter
        
        # tmuxセッションにアタッチ
        tmux attach-session -t k8s-monitor
    else
        log_warn "tmuxが見つかりません。シンプルな監視を開始します..."
        log_info "Pod状態の監視を開始します... (Ctrl+Cで終了)"
        kubectl get pods -n $K8S_NAMESPACE -w
    fi
}

# ========================================
# メイン処理
# ========================================
main() {
    log_info "📊 アプリケーションとリソースの状態確認を開始します..."
    
    # オプション解析
    parse_options "$@"
    
    # デバッグモードの設定
    if [[ "$DEBUG_MODE" == "true" ]]; then
        set -x
    fi
    
    # 前提条件チェック
    log_step "1. 前提条件のチェック"
    if ! check_prerequisites; then
        log_error "前提条件チェックに失敗しました"
        exit 1
    fi
    
    # リアルタイム監視モード
    if [[ "$WATCH_MODE" == "true" ]]; then
        watch_status
        return 0
    fi
    
    # 基本的な状態確認
    log_step "2. 基本的な状態確認"
    show_kubernetes_status
    
    # 詳細モード
    if [[ "$DETAILED_MODE" == "true" ]]; then
        check_minikube_detailed
        check_kubernetes_detailed
        check_docker_detailed
        check_events
        check_logs
        check_resource_usage
    fi
    
    # ヘルスチェックモード
    if [[ "$HEALTH_CHECK_MODE" == "true" ]]; then
        log_step "3. アプリケーションのヘルスチェック"
        if ! perform_health_check; then
            log_warn "⚠️ ヘルスチェックに一部失敗がありました"
        fi
    fi
    
    # 完了メッセージ
    log_info "✅ 状態確認が完了しました！"
    
    echo ""
    echo "🔧 便利なコマンド:"
    echo "   - 詳細確認: ./scripts/status.sh --detailed"
    echo "   - ヘルスチェック: ./scripts/status.sh --health-check"
    echo "   - リアルタイム監視: ./scripts/status.sh --watch"
    echo "   - ログ確認: kubectl logs -f deployment/$K8S_DEPLOYMENT_NAME -n $K8S_NAMESPACE"
    echo "   - イベント確認: kubectl get events -n $K8S_NAMESPACE --sort-by='.lastTimestamp'"
}

# ========================================
# スクリプト実行
# ========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 