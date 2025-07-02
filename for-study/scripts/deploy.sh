#!/bin/bash
# 統合デプロイスクリプト
# ビルドからデプロイまでを一元管理

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
CLEAN_MODE=false
DEBUG_MODE=false
SKIP_BUILD=false
SKIP_DEPLOY=false
SKIP_HEALTH_CHECK=false

# ========================================
# ヘルプメッセージ
# ========================================
show_deploy_help() {
    show_help \
        "deploy.sh" \
        "Kubernetes学習用Express.jsアプリケーションの統合デプロイスクリプト" \
        "./scripts/deploy.sh [オプション]" \
        "  ./scripts/deploy.sh                    # 通常のデプロイ\n  ./scripts/deploy.sh --clean               # クリーンアップ後にデプロイ\n  ./scripts/deploy.sh --dry-run             # ドライランモード\n  ./scripts/deploy.sh --skip-build          # ビルドをスキップ\n  ./scripts/deploy.sh --skip-health-check   # ヘルスチェックをスキップ"
}

# ========================================
# オプション解析
# ========================================
parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_deploy_help
                exit 0
                ;;
            --clean)
                CLEAN_MODE=true
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
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --skip-health-check)
                SKIP_HEALTH_CHECK=true
                shift
                ;;
            *)
                log_error "不明なオプション: $1"
                show_deploy_help
                exit 1
                ;;
        esac
    done
}

# ========================================
# メイン処理
# ========================================
main() {
    log_info "🚀 Kubernetes学習用アプリケーションのデプロイを開始します..."
    
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
    
    if ! check_minikube_status; then
        log_error "Minikubeの状態チェックに失敗しました"
        exit 1
    fi
    
    # クリーンアップ（オプション）
    if [[ "$CLEAN_MODE" == "true" ]]; then
        log_step "2. 既存リソースのクリーンアップ"
        if [[ "$DRY_RUN" == "false" ]]; then
            cleanup_resources "all"
        else
            log_info "[DRY-RUN] クリーンアップを実行します"
        fi
    fi
    
    # Docker環境の設定
    log_step "3. Docker環境の設定"
    if [[ "$DRY_RUN" == "false" ]]; then
        setup_docker_environment
    else
        log_info "[DRY-RUN] Docker環境を設定します"
    fi
    
    # Dockerイメージのビルド
    if [[ "$SKIP_BUILD" == "false" ]]; then
        log_step "4. Dockerイメージのビルド"
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! build_docker_image "minikube-local"; then
                log_error "Dockerイメージのビルドに失敗しました"
                exit 1
            fi
            
            if ! test_docker_image; then
                log_error "Dockerイメージのテストに失敗しました"
                exit 1
            fi
        else
            log_info "[DRY-RUN] Dockerイメージをビルドします"
        fi
    else
        log_info "⚠️ ビルドをスキップしました"
    fi
    
    # Kubernetesマニフェストの適用
    if [[ "$SKIP_DEPLOY" == "false" ]]; then
        log_step "5. Kubernetesマニフェストの適用"
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! apply_kubernetes_manifests; then
                log_error "Kubernetesマニフェストの適用に失敗しました"
                exit 1
            fi
        else
            log_info "[DRY-RUN] Kubernetesマニフェストを適用します"
        fi
        
        # デプロイメントの完了待機
        log_step "6. デプロイメントの完了待機"
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! wait_for_deployment; then
                log_error "デプロイメントの完了待機に失敗しました"
                exit 1
            fi
        else
            log_info "[DRY-RUN] デプロイメントの完了を待機します"
        fi
        
        # Kubernetesリソースの状態表示
        log_step "7. Kubernetesリソースの状態確認"
        if [[ "$DRY_RUN" == "false" ]]; then
            show_kubernetes_status
        else
            log_info "[DRY-RUN] Kubernetesリソースの状態を確認します"
        fi
    else
        log_info "⚠️ デプロイをスキップしました"
    fi
    
    # ヘルスチェック
    if [[ "$SKIP_HEALTH_CHECK" == "false" && "$SKIP_DEPLOY" == "false" ]]; then
        log_step "8. アプリケーションのヘルスチェック"
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! perform_health_check; then
                log_warn "⚠️ ヘルスチェックに一部失敗がありました"
            fi
        else
            log_info "[DRY-RUN] ヘルスチェックを実行します"
        fi
    else
        log_info "⚠️ ヘルスチェックをスキップしました"
    fi
    
    # 完了メッセージ
    log_info "🎉 デプロイが完了しました！"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        show_access_info
    else
        log_info "[DRY-RUN] 実際のデプロイは行われませんでした"
    fi
}

# ========================================
# スクリプト実行
# ========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 