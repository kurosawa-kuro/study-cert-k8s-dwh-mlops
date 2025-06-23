#!/usr/bin/env bash
# reset.sh : CKAD 用 Minikube クラスターを作り直すユーティリティ
set -Eeuo pipefail
IFS=$'\n\t'

###############################################################################
# ✨ 設定（環境変数で上書き可）
###############################################################################
CLUSTER_NAME="${CLUSTER_NAME:-ckad-cluster}"
NAMESPACE="${NAMESPACE:-ckad-ns}"
ECR_REGISTRY="${ECR_REGISTRY:-986154984217.dkr.ecr.ap-northeast-1.amazonaws.com}"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
DEPLOYMENT_FILE="${DEPLOYMENT_FILE:-deployment.yaml}"
MINIKUBE_DRIVER="docker"   # 既定：docker（containerd の場合でも可）
CONTAINER_RUNTIME=""       # 空なら Minikube 既定（最新版は containerd）

# Minikube リソース設定（環境変数で上書き可）
MINIKUBE_CPUS="${MINIKUBE_CPUS:-8}"           # 推奨: 6-8 cores
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-10000}"   # 推奨: 10 GiB (MiB単位)
MINIKUBE_DISK_SIZE="${MINIKUBE_DISK_SIZE:-20000}"  # 20 GiB

# ホスト公開設定（Windows側からのアクセス用）
APISERVER_PORT="${APISERVER_PORT:-}"          # 空なら自動割り当て
LISTEN_ADDRESS="${LISTEN_ADDRESS:-}"          # 空なら内部IPのみ
KUBECONFIG_EXPORT="${KUBECONFIG_EXPORT:-}"    # Windows側の出力パス

###############################################################################
# 🖍️  ログ用装飾
###############################################################################
# 端末が no-color の場合を考慮
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"; NC="$(tput sgr0)"
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi
log()   { printf '%b\n' "${GREEN}[INFO]${NC} $*"; }
warn()  { printf '%b\n' "${YELLOW}[WARN]${NC} $*"; }
error() { printf '%b\n' "${RED}[ERROR]${NC} $*" >&2; }

###############################################################################
# 🛠️  共通ユーティリティ
###############################################################################
needs() {
  command -v "$1" >/dev/null 2>&1 || {
    error "'$1' が見つかりません。インストールしてください。"
    exit 1; }
}

get_windows_user() {
  # Windows側のユーザー名を取得（複数の方法を試行）
  local windows_user
  
  # 1. WSL2環境変数から取得
  if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    windows_user="$WSL_DISTRO_NAME"
    echo "$windows_user"
    return 0
  fi
  
  # 2. Windows側のwhoamiコマンドを使用
  if command -v whoami.exe >/dev/null 2>&1; then
    windows_user="$(whoami.exe 2>/dev/null | tr -d '\r\n')"
    if [[ -n "$windows_user" ]]; then
      echo "$windows_user"
      return 0
    fi
  fi
  
  # 3. 一般的なユーザー名を試行
  for user in owner administrator admin; do
    if [[ -d "/mnt/c/Users/$user" ]]; then
      windows_user="$user"
      echo "$windows_user"
      return 0
    fi
  done
  
  # 4. 見つからない場合は現在のWSLユーザー名を使用
  windows_user="$(whoami)"
  echo "$windows_user"
  return 0
}

run() {
  log "実行: $*"
  "$@" || warn "'$*' が非ゼロ終了しました（続行）"
}

trap 'error "想定外のエラーで終了 (#$LINENO)"; exit 1' ERR

###############################################################################
# 🧹  1) クリーンアップ
###############################################################################
cleanup() {
  log "Minikubeの権限を修正"
  run sudo chown -R "$USER" "$HOME/.minikube"
  run chmod -R u+wrx "$HOME/.minikube"

  log "クリーンアップを開始"
  [[ -f $DEPLOYMENT_FILE ]] \
    && run kubectl delete -f "$DEPLOYMENT_FILE" --ignore-not-found

  run kubectl delete secret ecr-registry-secret \
      --namespace "$NAMESPACE" --ignore-not-found
  run kubectl delete namespace "$NAMESPACE" --ignore-not-found

  if minikube profile list | grep -q "$CLUSTER_NAME"; then
    run minikube delete --profile "$CLUSTER_NAME"
  else
    log "Minikube クラスター '$CLUSTER_NAME' は存在しません"
  fi
  log "クリーンアップ完了"
}

###############################################################################
# 🚜  2) クラスター起動
###############################################################################
start_cluster() {
  log "Minikube クラスターを起動"
  local args=(
    start
    --profile "$CLUSTER_NAME"
    --driver "$MINIKUBE_DRIVER"
    --cpus "$MINIKUBE_CPUS"
    --memory "$MINIKUBE_MEMORY"
    --disk-size "$MINIKUBE_DISK_SIZE"
    --cache-images
    --disable-optimizations  # 不要なアドオンを無効化して起動を高速化
  )
  [[ -n $CONTAINER_RUNTIME ]] && args+=(--container-runtime "$CONTAINER_RUNTIME")
  
  # ホスト公開設定を追加
  [[ -n $APISERVER_PORT ]] && args+=(--apiserver-port "$APISERVER_PORT")
  [[ -n $LISTEN_ADDRESS ]] && args+=(--listen-address "$LISTEN_ADDRESS")
  
  run minikube "${args[@]}"

  # containerd の場合、docker-env は不要
  if minikube -p "$CLUSTER_NAME" docker-env >/dev/null 2>&1; then
    eval "$(minikube -p "$CLUSTER_NAME" docker-env)"
    log "docker-env を適用しました"
  else
    warn "containerd ランタイムのため docker-env をスキップ"
  fi
  log "クラスター起動完了"
}

###############################################################################
# ✨  3) 名前空間 & ECR シークレット
###############################################################################
setup_namespace() {
  log "名前空間 '$NAMESPACE' を作成"
  kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || \
    run kubectl create namespace "$NAMESPACE"
  # run kubectl config set-context --current --namespace="$NAMESPACE"
}

setup_ecr_auth() {
  log "ECR 認証をセットアップ"
  local pw
  pw="$(aws ecr get-login-password --region "$AWS_REGION")"
  echo "$pw" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

  # --dry-run=client + -o yaml にすれば apply で idempotent にできる
  kubectl delete secret ecr-registry-secret \
      --namespace "$NAMESPACE" --ignore-not-found
  run kubectl create secret docker-registry ecr-registry-secret \
    --docker-server="$ECR_REGISTRY" \
    --docker-username=AWS \
    --docker-password="$pw" \
    --namespace="$NAMESPACE"
}

###############################################################################
# 🔍  4) 確認表示
###############################################################################
verify() {
  log "設定状態を確認"
  kubectl config current-context
  kubectl cluster-info
  
  # ホスト公開情報を表示
  if [[ -n $APISERVER_PORT ]]; then
    log "ホスト公開設定:"
    log "  - APIサーバーポート: $APISERVER_PORT"
    log "  - リッスンアドレス: ${LISTEN_ADDRESS:-0.0.0.0}"
    log "  - Windows側アクセス: https://127.0.0.1:$APISERVER_PORT"
    
    # テストコマンドを表示
    log "📋 Windows側でテスト:"
    log "  curl.exe -k https://127.0.0.1:$APISERVER_PORT/version"
  fi
  
  # kubeconfig書き出し情報を表示
  if [[ -n $KUBECONFIG_EXPORT ]]; then
    log "📁 kubeconfig 書き出し先: $KUBECONFIG_EXPORT"
  fi
  
  kubectl get ns
  kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'; echo
}

###############################################################################
# 📁  5) kubeconfig 書き出し
###############################################################################
export_kubeconfig() {
  if [[ -n $KUBECONFIG_EXPORT ]]; then
    log "kubeconfig を Windows 側に書き出し: $KUBECONFIG_EXPORT"
    
    # ディレクトリが存在しない場合は作成
    local dir
    dir="$(dirname "$KUBECONFIG_EXPORT")"
    if [[ ! -d "$dir" ]]; then
      log "ディレクトリを作成: $dir"
      # Windows側のディレクトリ作成は権限エラーが発生する可能性があるため、
      # 親ディレクトリが存在するかチェックしてから作成
      if [[ "$dir" =~ ^/mnt/c/ ]]; then
        # Windows側の場合、親ディレクトリの存在確認
        local parent_dir
        parent_dir="$(dirname "$dir")"
        if [[ -d "$parent_dir" ]]; then
          mkdir -p "$dir" 2>/dev/null || {
            warn "ディレクトリ作成に失敗しました: $dir"
            warn "手動でディレクトリを作成してください: mkdir -p $dir"
            return 1
          }
        else
          warn "親ディレクトリが存在しません: $parent_dir"
          warn "手動でディレクトリを作成してください: mkdir -p $dir"
          return 1
        fi
      else
        # Linux側の場合は通常通り作成
        mkdir -p "$dir"
      fi
    fi
    
    # kubeconfig を取得して IP アドレスを置換
    if [[ -n $APISERVER_PORT ]]; then
      # ホスト公開時は 127.0.0.1 に置換
      log "kubeconfig を生成中..."
      
      # まず現在のkubeconfigを確認
      if ! kubectl config view --minify --flatten --raw >/dev/null 2>&1; then
        warn "kubectl config view が失敗しました"
        warn "代替方法でkubeconfigを生成します"
        
        # minikube kubeconfig を使用
        if minikube -p "$CLUSTER_NAME" kubeconfig > "$KUBECONFIG_EXPORT" 2>/dev/null; then
          # IPアドレスを置換
          sed -i "s#192\.168\.[0-9]\+\.[0-9]\+#127.0.0.1#g" "$KUBECONFIG_EXPORT"
          sed -i "s#:[0-9]\+$#:$APISERVER_PORT#g" "$KUBECONFIG_EXPORT"
          log "✅ minikube kubeconfig で書き出し完了"
          log "📁 ファイル: $KUBECONFIG_EXPORT"
          return 0
        else
          warn "minikube kubeconfig も失敗しました"
          return 1
        fi
      fi
      
      # 通常の方法で書き出し
      kubectl config view --minify --flatten --raw \
        | sed "s#192\.168\.[0-9]\+\.[0-9]\+#127.0.0.1#g" \
        | sed "s#:[0-9]\+$#:$APISERVER_PORT#g" \
        > "$KUBECONFIG_EXPORT" 2>/dev/null || {
        warn "kubeconfig 書き出しに失敗しました: $KUBECONFIG_EXPORT"
        warn "権限を確認してください: ls -la $(dirname "$KUBECONFIG_EXPORT")"
        return 1
      }
    else
      # 通常時はそのまま
      kubectl config view --minify --flatten --raw > "$KUBECONFIG_EXPORT" 2>/dev/null || {
        warn "kubeconfig 書き出しに失敗しました: $KUBECONFIG_EXPORT"
        warn "権限を確認してください: ls -la $(dirname "$KUBECONFIG_EXPORT")"
        return 1
      }
    fi
    
    log "✅ kubeconfig 書き出し完了"
    log "📁 ファイル: $KUBECONFIG_EXPORT"
  fi
}

###############################################################################
# 🎛️  CLI オプション
###############################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --driver)          MINIKUBE_DRIVER="$2"; shift 2 ;;
    --containerd)      CONTAINER_RUNTIME="containerd"; shift ;;
    --runtime)         CONTAINER_RUNTIME="$2"; shift 2 ;;
    --cpus)            MINIKUBE_CPUS="$2"; shift 2 ;;
    --memory)          MINIKUBE_MEMORY="$2"; shift 2 ;;
    --disk-size)       MINIKUBE_DISK_SIZE="$2"; shift 2 ;;
    --apiserver-port)  APISERVER_PORT="$2"; shift 2 ;;
    --listen-address)  LISTEN_ADDRESS="$2"; shift 2 ;;
    --host-expose)     APISERVER_PORT="8443"; LISTEN_ADDRESS="0.0.0.0"; shift ;;
    --export-kubeconfig) KUBECONFIG_EXPORT="$2"; shift 2 ;;
    --export-windows)  
      # Windows側のユーザー名を取得（複数の方法を試行）
      windows_user="$(get_windows_user)"
      
      # どの方法で取得したかを判定して表示
      if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        log "WSL_DISTRO_NAME から取得: $windows_user"
      elif command -v whoami.exe >/dev/null 2>&1 && [[ -n "$(whoami.exe 2>/dev/null | tr -d '\r\n')" ]]; then
        log "whoami.exe から取得: $windows_user"
      elif [[ -d "/mnt/c/Users/$windows_user" ]]; then
        log "ディレクトリ確認から取得: $windows_user"
      else
        log "WSLユーザー名を使用: $windows_user"
      fi
      
      # より安全なパスを設定
      KUBECONFIG_EXPORT="/mnt/c/Users/$windows_user/Desktop/kubeconfig-minikube.yaml"
      log "kubeconfig書き出し先: $KUBECONFIG_EXPORT"
      shift 
      ;;
    --help|-h)
      cat <<EOF
usage: $(basename "$0") [options]

--driver <docker|kvm2|...>     Minikube ドライバ（既定: docker）
--runtime <docker|containerd>  コンテナランタイム
--containerd                   同上（ショートカット）
--cpus <number>               Minikube に割り当てる CPU コア数（既定: 8）
--memory <number>             Minikube に割り当てるメモリ量（MiB単位、既定: 10000）
--disk-size <number>          Minikube のディスクサイズ（MiB単位、既定: 20000）
--apiserver-port <port>       APIサーバーのホスト側ポート（例: 8443）
--listen-address <ip>         APIサーバーのリッスンアドレス（例: 0.0.0.0）
--host-expose                 ホスト公開を有効化（--apiserver-port 8443 --listen-address 0.0.0.0）
--export-kubeconfig <path>    kubeconfig を指定パスに書き出し
--export-windows              kubeconfig を Windows 側に書き出し（/mnt/c/Users/<user>/Desktop/kubeconfig-minikube.yaml）
EOF
      exit 0
      ;;
    *) error "未知のオプション: $1"; exit 1 ;;
  esac
done

###############################################################################
# 🚀  メイン処理
###############################################################################
main() {
  for cmd in minikube kubectl aws docker; do needs "$cmd"; done

  log "=== Minikube リセットスクリプト開始 ==="
  cleanup
  start_cluster
  # setup_namespace
  # setup_ecr_auth
  verify
  export_kubeconfig
  log "=== スクリプト完了 🎉 ==="
}

main "$@"
