#!/bin/bash
# Dockerビルドスクリプト
# Dockerイメージのビルドとテストを管理

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
SCAN_MODE=false
TARGET="minikube-local"
BUILD_ARGS=""

# ========================================
# ヘルプメッセージ
# ========================================
show_build_help() {
    show_help \
        "build.sh" \
        "Dockerイメージのビルドとテストスクリプト" \
        "./scripts/build.sh [オプション]" \
        "  ./scripts/build.sh                    # 通常のビルド\n  ./scripts/build.sh --clean               # 既存イメージを削除してビルド\n  ./scripts/build.sh --scan               # セキュリティスキャン付きビルド\n  ./scripts/build.sh --target production  # 本番用ターゲットでビルド\n  ./scripts/build.sh --dry-run            # ドライランモード"
}

# ========================================
# オプション解析
# ========================================
parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_build_help
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
            --scan)
                SCAN_MODE=true
                shift
                ;;
            --target)
                TARGET="$2"
                shift 2
                ;;
            --build-arg)
                BUILD_ARGS="$BUILD_ARGS --build-arg $2"
                shift 2
                ;;
            *)
                log_error "不明なオプション: $1"
                show_build_help
                exit 1
                ;;
        esac
    done
}

# ========================================
# セキュリティスキャン
# ========================================
perform_security_scan() {
    log_step "セキュリティスキャンを実行中..."
    
    if command -v trivy &> /dev/null; then
        log_info "Trivyを使用してセキュリティスキャンを実行中..."
        if trivy image $DOCKER_FULL_IMAGE_NAME --severity HIGH,CRITICAL; then
            log_info "✅ セキュリティスキャンが完了しました"
        else
            log_warn "⚠️ セキュリティスキャンで問題が見つかりました"
        fi
    elif command -v docker &> /dev/null; then
        log_info "Docker scanを使用してセキュリティスキャンを実行中..."
        if docker scan $DOCKER_FULL_IMAGE_NAME; then
            log_info "✅ セキュリティスキャンが完了しました"
        else
            log_warn "⚠️ セキュリティスキャンで問題が見つかりました"
        fi
    else
        log_warn "⚠️ セキュリティスキャンツールが見つかりません"
        log_info "推奨: Trivy または Docker scan をインストールしてください"
    fi
}

# ========================================
# メイン処理
# ========================================
main() {
    log_info "🔨 Dockerイメージのビルドを開始します..."
    
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
    
    # Minikubeの状態チェック（Minikube環境の場合）
    if [[ "$TARGET" == "minikube-local" ]]; then
        if ! check_minikube_status; then
            log_error "Minikubeの状態チェックに失敗しました"
            exit 1
        fi
    fi
    
    # クリーンアップ（オプション）
    if [[ "$CLEAN_MODE" == "true" ]]; then
        log_step "2. 既存イメージのクリーンアップ"
        if [[ "$DRY_RUN" == "false" ]]; then
            cleanup_resources "docker"
        else
            log_info "[DRY-RUN] 既存イメージを削除します"
        fi
    fi
    
    # Docker環境の設定（Minikube環境の場合）
    if [[ "$TARGET" == "minikube-local" ]]; then
        log_step "3. Docker環境の設定"
        if [[ "$DRY_RUN" == "false" ]]; then
            setup_docker_environment
        else
            log_info "[DRY-RUN] Docker環境を設定します"
        fi
    fi
    
    # Dockerイメージのビルド
    log_step "4. Dockerイメージのビルド"
    log_info "ターゲット: $TARGET"
    log_info "イメージ名: $DOCKER_FULL_IMAGE_NAME"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        if ! build_docker_image "$TARGET" "$BUILD_ARGS"; then
            log_error "Dockerイメージのビルドに失敗しました"
            exit 1
        fi
    else
        log_info "[DRY-RUN] Dockerイメージをビルドします"
    fi
    
    # Dockerイメージのテスト
    log_step "5. Dockerイメージのテスト"
    if [[ "$DRY_RUN" == "false" ]]; then
        if ! test_docker_image; then
            log_error "Dockerイメージのテストに失敗しました"
            exit 1
        fi
    else
        log_info "[DRY-RUN] Dockerイメージをテストします"
    fi
    
    # セキュリティスキャン（オプション）
    if [[ "$SCAN_MODE" == "true" ]]; then
        log_step "6. セキュリティスキャン"
        if [[ "$DRY_RUN" == "false" ]]; then
            perform_security_scan
        else
            log_info "[DRY-RUN] セキュリティスキャンを実行します"
        fi
    fi
    
    # イメージ情報の表示
    log_step "7. イメージ情報の表示"
    if [[ "$DRY_RUN" == "false" ]]; then
        echo ""
        echo "=== イメージ情報 ==="
        docker images $DOCKER_FULL_IMAGE_NAME
        echo ""
        echo "=== イメージ詳細 ==="
        docker inspect $DOCKER_FULL_IMAGE_NAME --format='{{.Config.Env}}' | head -5
    else
        log_info "[DRY-RUN] イメージ情報を表示します"
    fi
    
    # 完了メッセージ
    log_info "🎉 Dockerイメージのビルドが完了しました！"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        echo ""
        echo "📱 次のステップ:"
        echo "   1. デプロイ: ./scripts/deploy.sh"
        echo "   2. ローカル実行: docker run -p 8000:8000 $DOCKER_FULL_IMAGE_NAME"
        echo "   3. イメージ削除: docker rmi $DOCKER_FULL_IMAGE_NAME"
        echo ""
        echo "🔧 便利なコマンド:"
        echo "   - イメージ確認: docker images $DOCKER_IMAGE_NAME"
        echo "   - コンテナ実行: docker run --rm $DOCKER_FULL_IMAGE_NAME"
        echo "   - セキュリティスキャン: ./scripts/build.sh --scan"
    else
        log_info "[DRY-RUN] 実際のビルドは行われませんでした"
    fi
}

# ========================================
# スクリプト実行
# ========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 