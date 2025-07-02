# Kubernetes マニフェスト - 学習用アプリケーション

このディレクトリには、Kubernetes認定試験（KCNA、KCSA、CKAD、CKA、CKS）の学習用アプリケーションのマニフェストファイルが含まれています。

## 📁 ファイル構成

### 個別マニフェストファイル
- `01-namespace.yaml` - Namespace、ServiceAccount、RBAC設定
- `02-config.yaml` - ConfigMap、Secret設定
- `03-deployment.yaml` - Deployment設定（セキュリティ強化版）
- `04-service.yaml` - Service、Ingress設定
- `05-hpa.yaml` - HorizontalPodAutoscaler設定
- `06-network-policy.yaml` - NetworkPolicy設定
- `07-pod-disruption-budget.yaml` - PodDisruptionBudget設定
- `08-pod-security-policy.yaml` - PodSecurityStandards設定
- `09-resource-quota.yaml` - ResourceQuota、LimitRange設定
- `10-all-in-one.yaml` - 全マニフェスト統合版
- `11-minikube-setup.yaml` - Minikube環境用追加設定
- `deploy-minikube.sh` - Minikube環境用デプロイスクリプト

## 🚀 デプロイ手順

### 1. 前提条件
```bash
# Dockerイメージのビルド
cd ../api
make docker-build

# Minikubeクラスターの準備
minikube start
```

### 2. Minikube環境でのデプロイ（推奨）
```bash
# 自動デプロイスクリプトを使用
./deploy-minikube.sh

# または、クリーンインストール
./deploy-minikube.sh --clean
```

### 3. 手動デプロイ
```bash
# Ingressアドオンの有効化
minikube addons enable ingress

# Dockerイメージの読み込み
minikube image load api-nodejs-k8s:latest

# マニフェストの適用
kubectl apply -f 10-all-in-one.yaml
kubectl apply -f 11-minikube-setup.yaml
```

### 4. 個別デプロイ
```bash
# 順番に適用
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-config.yaml
kubectl apply -f 03-deployment.yaml
kubectl apply -f 04-service.yaml
kubectl apply -f 05-hpa.yaml
kubectl apply -f 06-network-policy.yaml
kubectl apply -f 07-pod-disruption-budget.yaml
kubectl apply -f 09-resource-quota.yaml
kubectl apply -f 11-minikube-setup.yaml
```

## 🔍 動作確認

### 基本的な確認
```bash
# Podの状態確認
kubectl get pods -n express-app

# Serviceの確認
kubectl get svc -n express-app

# Ingressの確認
kubectl get ingress -n express-app

# HPAの確認
kubectl get hpa -n express-app
```

### アプリケーションアクセス
```bash
# 方法1: Port-forwardでアクセス
kubectl port-forward svc/express-svc 8080:80 -n express-app

# 方法2: NodePort Serviceを使用
kubectl port-forward svc/express-svc-nodeport 8080:80 -n express-app

# 方法3: Minikube IPを使用
minikube service express-svc-nodeport -n express-app

# ブラウザで http://localhost:8080 にアクセス
```

### ヘルスチェック
```bash
# ヘルスチェック
curl http://localhost:8080/healthz

# レディネスチェック
curl http://localhost:8080/readyz

# メトリクス
curl http://localhost:8080/metrics

# 設定確認
curl http://localhost:8080/config
```

## 🛠️ トラブルシューティング

### よくある問題と解決方法

#### 1. Podが起動しない
```bash
# Podの詳細確認
kubectl describe pod <pod-name> -n express-app

# ログ確認
kubectl logs <pod-name> -n express-app

# イベント確認
kubectl get events -n express-app --sort-by='.lastTimestamp'
```

#### 2. イメージが見つからない
```bash
# ローカルイメージをMinikubeに読み込み
minikube image load api-nodejs-k8s:latest

# または、Dockerビルドから直接
eval $(minikube docker-env)
docker build -t api-nodejs-k8s:latest ../api
```

#### 3. Service IPエラー
```bash
# 既存のServiceを削除して再作成
kubectl delete svc express-svc -n express-app
kubectl apply -f 04-service.yaml
```

#### 4. Ingressが動作しない
```bash
# Ingressアドオンの確認
minikube addons list | grep ingress

# Ingressアドオンの有効化
minikube addons enable ingress

# Ingress Controllerの確認
kubectl get pods -n ingress-nginx
```

#### 5. セキュリティポリシー違反
```bash
# PodSecurityStandardsの確認
kubectl get events -n express-app --sort-by='.lastTimestamp'

# 一時的にセキュリティ設定を緩和
kubectl patch deployment express-deploy -n express-app -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":false}}}}}'
```

#### 6. ネットワーク接続問題
```bash
# NetworkPolicyの確認
kubectl get networkpolicy -n express-app

# 一時的にNetworkPolicyを無効化
kubectl delete networkpolicy express-default-deny -n express-app
```

## 📚 学習ポイント

### KCNA（基礎）
- Pod、Deployment、Service、Ingressの基本概念
- コンテナイメージの理解
- kubectlコマンドの基本操作

### KCSA（クラウド・セキュリティ基礎）
- イメージスキャン（Trivy等）
- Secretの保護
- 最小権限RBAC
- ネットワーク境界

### CKAD（アプリケーション開発）
- Liveness/Readiness/Startup Probe
- ConfigMap/Secretの活用
- Resource Limits & Requests
- HPA（Horizontal Pod Autoscaler）
- 観測性（/metrics）

### CKA（運用）
- Namespace運用
- ServiceAccount設定
- RBAC詳細設定
- トラブルシューティング
- クラスター操作

### CKS（セキュリティ）
- PodSecurityContext
- NetworkPolicy
- 非root実行
- セキュリティツール連携
- コンテナセキュリティ

## 🔧 カスタマイズ

### 環境変数の変更
`02-config.yaml`のConfigMapとSecretを編集して環境変数を変更できます。

### リソース制限の調整
`03-deployment.yaml`のresourcesセクションを編集してCPU/メモリ制限を調整できます。

### レプリカ数の変更
```bash
# レプリカ数を変更
kubectl scale deployment express-deploy --replicas=3 -n express-app
```

## 🧪 負荷テスト

### 負荷注入ツール（hey）を使用
```bash
# 負荷テスト実行
hey -z 2m -c 50 http://localhost:8080/

# HPAの動作確認
kubectl get hpa -n express-app -w
```

## 📊 監視とメトリクス

### Prometheusメトリクス
アプリケーションは`/metrics`エンドポイントでPrometheusメトリクスを提供します。

### ログ確認
```bash
# リアルタイムログ
kubectl logs -f deployment/express-deploy -n express-app

# 特定のPodのログ
kubectl logs <pod-name> -n express-app
```

## 🧹 クリーンアップ

### 個別削除
```bash
kubectl delete -f 10-all-in-one.yaml
kubectl delete -f 11-minikube-setup.yaml
```

### 完全削除
```bash
kubectl delete namespace express-app
```

### Minikubeリセット
```bash
# 提供されたスクリプトを使用
../reset-hard.sh
```

## 📖 参考資料

- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

---

このマニフェストセットを使用して、Kubernetes認定試験の実践的な学習を進めてください！ 