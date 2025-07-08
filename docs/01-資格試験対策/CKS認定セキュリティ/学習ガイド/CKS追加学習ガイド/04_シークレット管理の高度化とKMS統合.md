# 第4章: シークレット管理の高度化とKMS統合

## 学習目的

- HashiCorp Vault との統合による外部シークレット管理
- AWS KMS、Azure Key Vault、Google Cloud KMS との統合
- External Secrets Operator による動的シークレット管理
- etcd の暗号化とキーローテーション

## 学習手順

### 1. HashiCorp Vault 統合

#### 1.1 Vaultのセットアップ
```bash
# Helmを使用したVaultのインストール
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace

# Vaultの初期化
kubectl exec -n vault vault-0 -- vault operator init

# Vaultのアンシール
kubectl exec -n vault vault-0 -- vault operator unseal <unseal-key>
```

#### 1.2 Kubernetes認証の設定
```bash
# Kubernetes認証メソッドの有効化
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

# 認証設定
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
    token_reviewer_jwt="$(kubectl get secret vault-token -n vault -o jsonpath='{.data.token}' | base64 -d)" \
    kubernetes_host="https://kubernetes.default.svc.cluster.local:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

#### 1.3 Vaultポリシーの作成
```bash
# ポリシーの作成
kubectl exec -n vault vault-0 -- vault policy write webapp-policy - <<EOF
path "secret/data/webapp/*" {
  capabilities = ["read"]
}
EOF

# Kubernetesロールの作成
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/webapp \
    bound_service_account_names=webapp-sa \
    bound_service_account_namespaces=production \
    policies=webapp-policy \
    ttl=24h
```

### 2. Vault Agent Injector

#### 2.1 Agent Injectorの設定
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "webapp"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/webapp/config"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/webapp/config" -}}
          export DB_PASSWORD="{{ .Data.data.password }}"
          export API_KEY="{{ .Data.data.api_key }}"
          {{- end -}}
    spec:
      serviceAccountName: webapp-sa
      containers:
      - name: webapp
        image: nginx:1.20
        command: ["/bin/sh"]
        args: ["-c", "source /vault/secrets/config && nginx -g 'daemon off;'"]
```

#### 2.2 サービスアカウントの設定
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp-sa
  namespace: production
automountServiceAccountToken: true
```

### 3. External Secrets Operator

#### 3.1 External Secrets Operatorのインストール
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

#### 3.2 SecretStoreの設定
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "webapp"
          serviceAccountRef:
            name: "webapp-sa"
```

#### 3.3 ExternalSecretの作成
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: webapp-secrets
  namespace: production
spec:
  refreshInterval: 30s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: webapp-secrets
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: webapp/config
      property: password
  - secretKey: api_key
    remoteRef:
      key: webapp/config
      property: api_key
```

### 4. AWS KMS統合

#### 4.1 KMSキーの作成
```bash
# KMSキーの作成
aws kms create-key \
    --description "Kubernetes secrets encryption key" \
    --key-usage ENCRYPT_DECRYPT \
    --key-spec SYMMETRIC_DEFAULT

# エイリアスの作成
aws kms create-alias \
    --alias-name alias/kubernetes-secrets \
    --target-key-id <key-id>
```

#### 4.2 etcd暗号化設定
```yaml
apiVersion: apiserver.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - kms:
      name: aws-kms
      endpoint: unix:///var/run/kmsplugin/socket.sock
      cachesize: 100
      timeout: 3s
  - identity: {}
```

#### 4.3 KMSプラグインの設定
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kms-plugin
  namespace: kube-system
spec:
  containers:
  - name: kms-plugin
    image: k8s.gcr.io/kms-plugin:v1.0.0
    env:
    - name: AWS_REGION
      value: "us-west-2"
    - name: KEY_ID
      value: "alias/kubernetes-secrets"
    volumeMounts:
    - name: socket
      mountPath: /var/run/kmsplugin
  volumes:
  - name: socket
    hostPath:
      path: /var/run/kmsplugin
```

### 5. CSI Secret Store Driver

#### 5.1 CSI Secret Store Driverのインストール
```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver -n kube-system
```

#### 5.2 AWS Provider設定
```bash
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
```

#### 5.3 SecretProviderClassの作成
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: webapp-aws-secrets
  namespace: production
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "webapp-db-password"
        objectType: "secretsmanager"
      - objectName: "webapp-api-key"
        objectType: "secretsmanager"
  secretObjects:
  - secretName: webapp-secrets
    type: Opaque
    data:
    - objectName: webapp-db-password
      key: password
    - objectName: webapp-api-key
      key: api_key
```

#### 5.4 Podでの使用
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  namespace: production
spec:
  serviceAccountName: webapp-sa
  containers:
  - name: webapp
    image: nginx:1.20
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets"
      readOnly: true
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: webapp-secrets
          key: password
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "webapp-aws-secrets"
```

### 6. シークレットローテーション

#### 6.1 自動ローテーション設定
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: rotating-secret
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: rotating-secret
    creationPolicy: Owner
    template:
      metadata:
        annotations:
          reloader.stakater.com/match: "true"
  data:
  - secretKey: password
    remoteRef:
      key: rotating/password
      property: current
```

#### 6.2 Reloader設定
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: reloader-config
  namespace: stakater
data:
  config.yaml: |
    reloader:
      watchGlobally: false
      ignoreSecrets: false
      ignoreConfigMaps: false
      reloadStrategy: env-vars
```

### 7. 監査とコンプライアンス

#### 7.1 シークレットアクセス監査
```bash
# 監査ログの確認
kubectl logs -n kube-system -l component=kube-apiserver | grep -i secret

# Vaultアクセスログの確認
kubectl exec -n vault vault-0 -- vault audit enable file file_path=/vault/logs/audit.log
```

#### 7.2 Falco によるシークレットアクセス監視
```yaml
# Falcoルール
- rule: Secret Access
  desc: Detect access to Kubernetes secrets
  condition: >
    ka and
    (ka.verb in (get, list, watch, create, update, patch, delete)) and
    ka.target.resource=secrets and
    not ka.user.name in (system:serviceaccount:kube-system:generic-garbage-collector,
                         system:serviceaccount:kube-system:attachdetach-controller)
  output: >
    Secret accessed (user=%ka.user.name verb=%ka.verb 
    target=%ka.target.resource reason=%ka.reason)
  priority: WARNING
```

### 8. 実践演習

#### 演習1: Vault統合セットアップ
1. Vaultクラスターのデプロイ
2. Kubernetes認証の設定
3. 動的シークレット取得の実装

#### 演習2: クラウドKMS統合
1. AWS KMS/Azure Key Vault/Google Cloud KMS選択
2. etcd暗号化の有効化
3. キーローテーションの実装

#### 演習3: External Secrets Operatorの活用
1. 複数の外部プロバイダーとの統合
2. シークレットの自動更新
3. 障害時の回復メカニズム

## 参照ドキュメント

- [HashiCorp Vault](https://www.vaultproject.io/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [CSI Secret Store Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [Kubernetes KMS](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

## 検証コマンド

```bash
# Vaultの状態確認
kubectl exec -n vault vault-0 -- vault status

# External Secretsの状態確認
kubectl get externalsecrets,secretstores -A

# シークレットの内容確認
kubectl get secret webapp-secrets -o yaml

# KMS暗号化の確認
kubectl get secret -o yaml | grep -i encrypt

# CSI ボリュームの確認
kubectl get csinode
```

## セキュリティベストプラクティス

### 1. 最小権限の原則
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["webapp-secrets"]
  verbs: ["get"]
```

### 2. ネットワークセキュリティ
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vault-access
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: webapp
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: vault
    ports:
    - protocol: TCP
      port: 8200
```

### 3. 監査ログ設定
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]
  namespaces: ["production"]
```

## 学習時間目安

- 概念理解: 4時間
- 実装・演習: 10時間
- 検証・トラブルシューティング: 4時間

**合計: 18時間**