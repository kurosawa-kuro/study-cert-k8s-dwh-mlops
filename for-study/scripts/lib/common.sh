#!/bin/bash
# 共通ライブラリファイル
# すべてのスクリプトで使用する関数を一元管理

# ========================================
# 設定ファイルの読み込み
# ========================================
load_config() {
    local config_file="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/config.sh"
    
    if [[ ! -f "$config_file" ]]; then
        echo "エラー: 設定ファイルが見つかりません: $config_file" >&2
        return 1
    fi
    
    source "$config_file"
    
    # 設定の検証
    if ! validate_config; then
        echo "エラー: 設定の検証に失敗しました" >&2
        return 1
    fi
    
    return 0
}

# ========================================
# ログ関数
# ========================================
log_info() {
    if [[ "$LOG_COLORS" == "true" ]]; then
        echo -e "\033[32m[INFO]\033[0m $1"
    else
        echo "[INFO] $1"
    fi
}

log_warn() {
    if [[ "$LOG_COLORS" == "true" ]]; then
        echo -e "\033[33m[WARN]\033[0m $1"
    else
        echo "[WARN] $1"
    fi
}

log_error() {
    if [[ "$LOG_COLORS" == "true" ]]; then
        echo -e "\033[31m[ERROR]\033[0m $1"
    else
        echo "[ERROR] $1"
    fi
}

log_step() {
    if [[ "$LOG_COLORS" == "true" ]]; then
        echo -e "\033[36m[STEP]\033[0m $1"
    else
        echo "[STEP] $1"
    fi
}

log_debug() {
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        if [[ "$LOG_COLORS" == "true" ]]; then
            echo -e "\033[90m[DEBUG]\033[0m $1"
        else
            echo "[DEBUG] $1"
        fi
    fi
}

# ========================================
# エラーハンドリング
# ========================================
set_error_handling() {
    set -euo pipefail
    trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
}

error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_stack=$5
    
    log_error "エラーが発生しました"
    log_error "終了コード: $exit_code"
    log_error "行番号: $line_no"
    log_error "コマンド: $last_command"
    log_error "関数スタック: $func_stack"
    
    # クリーンアップ処理
    cleanup_on_error
    
    exit $exit_code
}

cleanup_on_error() {
    log_info "エラー時のクリーンアップを実行中..."
    
    # Port-forwardの停止
    local pf_pid=$(pgrep -f "kubectl port-forward" || true)
    if [[ -n "$pf_pid" ]]; then
        log_info "Port-forwardを停止中 (PID: $pf_pid)..."
        kill $pf_pid 2>/dev/null || true
    fi
    
    # 一時ファイルの削除
    rm -f /tmp/k8s-*.tmp 2>/dev/null || true
}

# ========================================
# 前提条件チェック
# ========================================
check_prerequisites() {
    local missing_tools=()
    
    # 必須ツールのチェック
    local required_tools=("docker" "kubectl" "minikube")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "以下のツールがインストールされていません:"
        printf '  - %s\n' "${missing_tools[@]}"
        return 1
    fi
    
    return 0
}

check_minikube_status() {
    if ! minikube status --format='{{.Host}}' >/dev/null 2>&1; then
        log_error "Minikubeが起動していません"
        log_info "起動方法: minikube start --driver=$MINIKUBE_DRIVER --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY"
        return 1
    fi
    
    log_info "✅ Minikubeが起動しています"
    return 0
}

# ========================================
# Docker関連関数
# ========================================
setup_docker_environment() {
    log_info "Docker環境を設定中..."
    
    # MinikubeのDocker環境を設定
    eval $(minikube docker-env)
    
    # BuildKitの無効化（権限問題回避）
    if [[ "$DOCKER_BUILDKIT_DISABLE" == "true" ]]; then
        export DOCKER_BUILDKIT=0
        log_info "✅ Docker BuildKitを無効化しました"
    fi
    
    log_info "✅ Docker環境を設定しました"
}

build_docker_image() {
    local target="${1:-minikube-local}"
    local build_args="${2:-}"
    
    log_step "Dockerイメージをビルド中..."
    log_info "ターゲット: $target"
    log_info "イメージ名: $DOCKER_FULL_IMAGE_NAME"
    
    # APIディレクトリに移動
    cd "$API_DIR"
    
    # ビルド時間の計測開始
    local build_start=$(date +%s)
    
    # Dockerビルドコマンドの構築
    local build_cmd="docker build --target $target --tag $DOCKER_FULL_IMAGE_NAME"
    
    if [[ -n "$build_args" ]]; then
        build_cmd="$build_cmd $build_args"
    fi
    
    build_cmd="$build_cmd ."
    
    # ビルド実行
    if ! eval "$build_cmd"; then
        log_error "Dockerビルドに失敗しました"
        # プロジェクトルートに戻る
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    # ビルド時間の計測終了
    local build_end=$(date +%s)
    local build_time=$((build_end - build_start))
    
    log_info "✅ ビルド完了！ (${build_time}秒)"
    
    # イメージサイズの表示
    local image_size=$(docker images $DOCKER_FULL_IMAGE_NAME --format "table {{.Size}}" | tail -n 1)
    log_info "イメージサイズ: $image_size"
    
    # プロジェクトルートに戻る
    cd "$PROJECT_ROOT"
    
    return 0
}

test_docker_image() {
    log_info "Dockerイメージの動作確認中..."
    
    if ! docker run --rm $DOCKER_FULL_IMAGE_NAME node -e "console.log('✅ Node.js version:', process.version)"; then
        log_error "Dockerイメージの動作確認に失敗しました"
        return 1
    fi
    
    log_info "✅ Dockerイメージの動作確認が完了しました"
    return 0
}

# ========================================
# Kubernetes関連関数
# ========================================
apply_kubernetes_manifests() {
    log_step "Kubernetesマニフェストを適用中..."
    
    # メインマニフェストの適用
    log_info "メインマニフェストを適用中..."
    if ! kubectl apply -f "$MANIFEST_ALL_IN_ONE"; then
        log_error "メインマニフェストの適用に失敗しました"
        return 1
    fi
    
    # Minikube用の追加設定を適用
    log_info "Minikube用の追加設定を適用中..."
    if ! kubectl apply -f "$MANIFEST_MINIKUBE_SETUP"; then
        log_error "Minikube用設定の適用に失敗しました"
        return 1
    fi
    
    log_info "✅ Kubernetesマニフェストの適用が完了しました"
    return 0
}

wait_for_deployment() {
    local deployment_name="${1:-$K8S_DEPLOYMENT_NAME}"
    local namespace="${2:-$K8S_NAMESPACE}"
    local timeout="${3:-$DEPLOYMENT_TIMEOUT}"
    
    log_info "デプロイメントの完了を待機中..."
    log_info "デプロイメント: $deployment_name"
    log_info "ネームスペース: $namespace"
    log_info "タイムアウト: ${timeout}秒"
    
    if ! kubectl wait --for=condition=available --timeout="${timeout}s" deployment/$deployment_name -n $namespace; then
        log_error "デプロイメントの完了待機に失敗しました"
        return 1
    fi
    
    log_info "✅ デプロイメントが完了しました"
    return 0
}

show_kubernetes_status() {
    log_step "Kubernetesリソースの状態を確認中..."
    
    echo ""
    echo "=== Pod の状態 ==="
    kubectl get pods -n $K8S_NAMESPACE
    
    echo ""
    echo "=== Service の状態 ==="
    kubectl get svc -n $K8S_NAMESPACE
    
    echo ""
    echo "=== HPA の状態 ==="
    kubectl get hpa -n $K8S_NAMESPACE
    
    echo ""
    echo "=== 全体的なリソース状態 ==="
    kubectl get all -n $K8S_NAMESPACE
}

# ========================================
# ヘルスチェック関数
# ========================================
perform_health_check() {
    local port="${1:-8080}"
    local timeout="${2:-$HEALTH_CHECK_TIMEOUT}"
    
    log_step "アプリケーションのヘルスチェックを実行中..."
    
    # Port-forwardを一時的に起動
    log_info "Port-forwardを起動してヘルスチェックを実行..."
    kubectl port-forward svc/$K8S_SERVICE_NAME $port:80 -n $K8S_NAMESPACE &
    local pf_pid=$!
    
    # 少し待ってからヘルスチェック
    sleep 5
    
    # ヘルスチェック実行
    local health_endpoints=("/healthz" "/readyz" "/metrics" "/config")
    local all_healthy=true
    
    for endpoint in "${health_endpoints[@]}"; do
        if curl -f --max-time $timeout "http://localhost:$port$endpoint" >/dev/null 2>&1; then
            log_info "✅ $endpoint: 正常"
        else
            log_warn "⚠️ $endpoint: 失敗"
            all_healthy=false
        fi
    done
    
    # Port-forwardを停止
    kill $pf_pid 2>/dev/null || true
    
    if [[ "$all_healthy" == "true" ]]; then
        log_info "✅ すべてのヘルスチェックが成功しました"
        return 0
    else
        log_warn "⚠️ 一部のヘルスチェックが失敗しました"
        return 1
    fi
}

# ========================================
# クリーンアップ関数
# ========================================
cleanup_resources() {
    local clean_type="${1:-all}"
    
    log_step "リソースのクリーンアップを実行中..."
    
    case "$clean_type" in
        "k8s")
            log_info "Kubernetesリソースを削除中..."
            kubectl delete namespace $K8S_NAMESPACE --ignore-not-found=true
            ;;
        "docker")
            log_info "Dockerリソースを削除中..."
            docker stop $DOCKER_CONTAINER_NAME 2>/dev/null || true
            docker rm $DOCKER_CONTAINER_NAME 2>/dev/null || true
            docker rmi $DOCKER_FULL_IMAGE_NAME 2>/dev/null || true
            ;;
        "all")
            log_info "すべてのリソースを削除中..."
            kubectl delete namespace $K8S_NAMESPACE --ignore-not-found=true
            docker stop $DOCKER_CONTAINER_NAME 2>/dev/null || true
            docker rm $DOCKER_CONTAINER_NAME 2>/dev/null || true
            docker rmi $DOCKER_FULL_IMAGE_NAME 2>/dev/null || true
            ;;
        *)
            log_error "不明なクリーンアップタイプ: $clean_type"
            return 1
            ;;
    esac
    
    log_info "✅ クリーンアップが完了しました"
    return 0
}

# ========================================
# ユーティリティ関数
# ========================================
show_access_info() {
    cat << EOF

🎉 デプロイが完了しました！

📱 アクセス方法:
   1. Port-forward:
      kubectl port-forward svc/$K8S_SERVICE_NAME 8080:80 -n $K8S_NAMESPACE
      ブラウザで http://localhost:8080 にアクセス

   2. NodePort Service:
      kubectl port-forward svc/$K8S_SERVICE_NODEPORT_NAME 8080:80 -n $K8S_NAMESPACE

   3. Minikube IP:
      minikube service $K8S_SERVICE_NODEPORT_NAME -n $K8S_NAMESPACE

🔍 ヘルスチェック:
   curl http://localhost:8080/healthz
   curl http://localhost:8080/readyz
   curl http://localhost:8080/metrics
   curl http://localhost:8080/config

📝 ログ確認:
   kubectl logs -f deployment/$K8S_DEPLOYMENT_NAME -n $K8S_NAMESPACE

🔧 便利なコマンド:
   - 状態確認: kubectl get all -n $K8S_NAMESPACE
   - イベント確認: kubectl get events -n $K8S_NAMESPACE --sort-by='.lastTimestamp'
   - リソース使用量: kubectl top pods -n $K8S_NAMESPACE

🧹 クリーンアップ:
   kubectl delete namespace $K8S_NAMESPACE
   docker rmi $DOCKER_FULL_IMAGE_NAME

EOF
}

show_help() {
    local script_name="${1:-スクリプト}"
    local description="${2:-}"
    local usage="${3:-}"
    local examples="${4:-}"
    
    cat << EOF
$script_name

$description

使用方法:
  $usage

例:
$examples

オプション:
  --help, -h     このヘルプメッセージを表示
  --clean        既存リソースを削除してから実行
  --debug        デバッグモードで実行
  --dry-run      実際の変更を行わずに実行

EOF
}

# ========================================
# 初期化
# ========================================
# 設定ファイルの読み込み
if [[ -f "${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/config.sh" ]]; then
    load_config
fi 