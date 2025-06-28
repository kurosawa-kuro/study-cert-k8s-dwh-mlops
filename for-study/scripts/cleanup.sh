#!/bin/bash
# クリーンアップスクリプト
# リソースの削除とクリーンアップを管理

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
DRY_RUN=false
DEBUG_MODE=false
CLEAN_TYPE="all"
FORCE_MODE=false

# ========================================
# ヘルプメッセージ
# ========================================
show_cleanup_help() {
    show_help \
        "cleanup.sh" \
        "リソースの削除とクリーンアップスクリプト" \
        "./scripts/cleanup.sh [オプション]" \
        "  ./scripts/cleanup.sh                    # すべてのリソースを削除\n  ./scripts/cleanup.sh --type k8s           # Kubernetesリソースのみ削除\n  ./scripts/cleanup.sh --type docker        # Dockerリソースのみ削除\n  ./scripts/cleanup.sh --force              # 確認なしで削除\n  ./scripts/cleanup.sh --dry-run            # ドライランモード"
}

# ========================================
# オプション解析
# ========================================
parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_cleanup_help
                exit 0
                ;;
            --type)
                CLEAN_TYPE="$2"
                shift 2
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                LOG_LEVEL="DEBUG"
                shift
                ;;
            *)
                log_error "不明なオプション: $1"
                show_cleanup_help
                exit 1
                ;;
        esac
    done
}

# ========================================
# 確認プロンプト
# ========================================
confirm_cleanup() {
    local clean_type="$1"
    
    if [[ "$FORCE_MODE" == "true" ]]; then
        return 0
    fi
    
    echo ""
    case "$clean_type" in
        "k8s")
            echo "⚠️  以下のKubernetesリソースを削除します:"
            echo "   - ネームスペース: $K8S_NAMESPACE"
            echo "   - すべてのPod、Service、Deployment等"
            ;;
        "docker")
            echo "⚠️  以下のDockerリソースを削除します:"
            echo "   - コンテナ: $DOCKER_CONTAINER_NAME"
            echo "   - イメージ: $DOCKER_FULL_IMAGE_NAME"
            ;;
        "all")
            echo "⚠️  以下のすべてのリソースを削除します:"
            echo "   - Kubernetesリソース（ネームスペース: $K8S_NAMESPACE）"
            echo "   - Dockerリソース（コンテナ、イメージ）"
            ;;
    esac
    
    echo ""
    read -p "削除を続行しますか？ (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "削除をキャンセルしました"
        exit 0
    fi
}

# ========================================
# リソース状態の表示
# ========================================
show_resource_status() {
    log_step "現在のリソース状態を確認中..."
    
    echo ""
    echo "=== Kubernetesリソース ==="
    if kubectl get namespace $K8S_NAMESPACE &>/dev/null; then
        echo "✅ ネームスペース $K8S_NAMESPACE が存在します"
        kubectl get all -n $K8S_NAMESPACE 2>/dev/null || echo "   リソースが見つかりません"
    else
        echo "❌ ネームスペース $K8S_NAMESPACE は存在しません"
    fi
    
    echo ""
    echo "=== Dockerリソース ==="
    if docker images | grep -q "$DOCKER_IMAGE_NAME"; then
        echo "✅ Dockerイメージ $DOCKER_IMAGE_NAME が存在します"
        docker images $DOCKER_IMAGE_NAME
    else
        echo "❌ Dockerイメージ $DOCKER_IMAGE_NAME は存在しません"
    fi
    
    if docker ps -a | grep -q "$DOCKER_CONTAINER_NAME"; then
        echo "✅ Dockerコンテナ $DOCKER_CONTAINER_NAME が存在します"
        docker ps -a | grep "$DOCKER_CONTAINER_NAME"
    else
        echo "❌ Dockerコンテナ $DOCKER_CONTAINER_NAME は存在しません"
    fi
}

# ========================================
# メイン処理
# ========================================
main() {
    log_info "🧹 リソースのクリーンアップを開始します..."
    
    # オプション解析
    parse_options "$@"
    
    # デバッグモードの設定
    if [[ "$DEBUG_MODE" == "true" ]]; then
        set -x
    fi
    
    # ドライランモードの確認
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "⚠️ ドライランモードで実行中（実際の変更は行われません）"
    fi
    
    # 前提条件チェック
    log_step "1. 前提条件のチェック"
    if ! check_prerequisites; then
        log_error "前提条件チェックに失敗しました"
        exit 1
    fi
    
    # 現在のリソース状態の表示
    log_step "2. 現在のリソース状態の確認"
    show_resource_status
    
    # 削除タイプの検証
    case "$CLEAN_TYPE" in
        "k8s"|"docker"|"all")
            ;;
        *)
            log_error "不明なクリーンアップタイプ: $CLEAN_TYPE"
            log_info "利用可能なタイプ: k8s, docker, all"
            exit 1
            ;;
    esac
    
    # 確認プロンプト
    if [[ "$DRY_RUN" == "false" ]]; then
        confirm_cleanup "$CLEAN_TYPE"
    fi
    
    # クリーンアップの実行
    log_step "3. リソースのクリーンアップ"
    if [[ "$DRY_RUN" == "false" ]]; then
        if ! cleanup_resources "$CLEAN_TYPE"; then
            log_error "クリーンアップに失敗しました"
            exit 1
        fi
    else
        log_info "[DRY-RUN] クリーンアップを実行します"
        case "$CLEAN_TYPE" in
            "k8s")
                log_info "[DRY-RUN] kubectl delete namespace $K8S_NAMESPACE"
                ;;
            "docker")
                log_info "[DRY-RUN] docker stop/rm $DOCKER_CONTAINER_NAME"
                log_info "[DRY-RUN] docker rmi $DOCKER_FULL_IMAGE_NAME"
                ;;
            "all")
                log_info "[DRY-RUN] すべてのリソースを削除します"
                ;;
        esac
    fi
    
    # クリーンアップ後の状態確認
    log_step "4. クリーンアップ後の状態確認"
    if [[ "$DRY_RUN" == "false" ]]; then
        show_resource_status
    else
        log_info "[DRY-RUN] クリーンアップ後の状態を確認します"
    fi
    
    # 完了メッセージ
    log_info "🎉 クリーンアップが完了しました！"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        echo ""
        echo "📱 次のステップ:"
        echo "   1. 再デプロイ: ./scripts/deploy.sh"
        echo "   2. ビルドのみ: ./scripts/build.sh"
        echo "   3. Minikubeリセット: minikube delete && minikube start"
        echo ""
        echo "🔧 便利なコマンド:"
        echo "   - 状態確認: kubectl get all --all-namespaces"
        echo "   - イメージ確認: docker images"
        echo "   - コンテナ確認: docker ps -a"
    else
        log_info "[DRY-RUN] 実際のクリーンアップは行われませんでした"
    fi
}

# ========================================
# スクリプト実行
# ========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 