# Secrets & 暗号化管理 基礎 — KMS・External Secrets Operator

> **対象:** CKAD 85 %・Killer.sh 70 % のスキルを持つエンジニアが **KCSA** 試験対策として押さえる “Secrets & 暗号化管理” の要点。
> **範囲:** at‑rest KMS 暗号化 / in‑cluster Secret Sync / External Secrets Operator (ESO) × HashiCorp Vault
> **キーワード:** EncryptionConfiguration + KMS, ESO CRD, `ExternalSecret`, `SecretStore`

---

## 1. 図解：Secret ライフサイクルと責任境界

```
        ┌─────────────┐   write    ┌────────────────┐   sync    ┌───────────────┐
Developer│  Vault UI  │──────────▶│  Vault KV v2   │──────────▶│  ExternalSecret│
        └─────────────┘            └────────────────┘           │   Controller  │
                                   ▲            │              └───────────────┘
                                   │ AES‑256/KMS│                       │ create
                                   ▼            ▼                       ▼
                            ┌─────────────────────────┐         ┌────────────────┐
                            │   etcd (Encrypted)      │◀───────│  k8s Secret     │
                            └─────────────────────────┘  mount  └────────────────┘
```

---

## 2. 1 行ベストプラクティス

| 領域                  | ベストプラクティス                                                             |
| ------------------- | --------------------------------------------------------------------- |
| **at‑rest KMS**     | *`EncryptionConfiguration` で `kms` プロバイダーを使用し、キーは年 1 回ローテーション*        |
| **in‑cluster Sync** | *ESO を使い **GitOps で `ExternalSecret` 管理**、Secret 変更は自動ローリング*          |
| **RBAC**            | *ESO Controller に最小限 (`get`, `watch`, `update`) のみ付与、Vault Role も最小化* |

---

## 3. Hands‑on ラボ（45 分で完走）

### 3.1 etcd at‑rest KMS 暗号化 (kind + KMS Plugin Mock)

> **注意:** kind では本物の KMS Provider を使いづらいので、`aescbc` 例で流れを確認。EKS/GKE ではクラウド KMS と置き換え。

```bash
# 1) 32 バイトキー生成
head -c 32 /dev/urandom | base64 > key.b64

# 2) encryption‑kms.yaml
cat <<EOF > encryption-kms.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(cat key.b64)
  - identity: {}
EOF

# 3) kind クラスタを encryption-config 付きで再作成 (略)
```

### 3.2 HashiCorp Vault & ESO セットアップ

```bash
# 0) Helm Repos
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# 1) Vault (dev) 起動
helm install vault hashicorp/vault --namespace vault --create-namespace \
  --set "server.dev.enabled=true" --set "injector.enabled=false"
export VAULT_ADDR=http://$(kubectl get svc vault-ui -n vault -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8200
export VAULT_TOKEN=root

# 2) KV パスにシークレット投入
vault kv put secret/db PASSWORD="s3cr3tP@ss"

# 3) Kubernetes Auth & Policy (簡易)
vault auth enable kubernetes
vault write auth/kubernetes/role/eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=eso \
  policies=default \
  ttl=24h

# 4) ESO Controller デプロイ
helm install eso external-secrets/external-secrets --namespace eso --create-namespace
```

### 3.3 SecretStore & ExternalSecret CR で同期

```bash
# 1) SecretStore 定義 (Vault)
cat <<'EOF' | kubectl apply -f -
apiVersion: external-secrets.io/v1alpha1
kind: SecretStore
metadata:
  name: vault-store
  namespace: eso
spec:
  provider:
    vault:
      server: "http://vault.vault:8200"
      path: ""
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "eso"
EOF

# 2) ExternalSecret
cat <<'EOF' | kubectl apply -f -
apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: db-secret
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-store
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: secret/db
      property: PASSWORD
EOF

# 3) 同期確認
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d  # → s3cr3tP@ss
```

---

## 4. チェックリスト ✅ / ❌

* [ ] etcd at‑rest 暗号化が `EncryptionConfiguration` で有効化された
* [ ] Vault → k8s Secret が ESO により自動同期された
* [ ] Secret 更新で Deployment がローリングした (`kubectl rollout history`)
* [ ] KMS キー/Token のアクセス権限を IAM & Vault で最小化した

---

## 5. 推奨リソース

* Kubernetes Docs — **Encrypting Secret Data at Rest**
* External Secrets Operator — Official Docs & Samples
* HashiCorp Vault — Kubernetes Auth Method Guide
* AWS Secrets Manager / GCP Secret Manager ESO Providers

---

### エンドノート

この 1 枚で **KMS での at‑rest 保護 × ESO での in‑cluster 自動同期** を体験できます。実環境ではクラウド KMS、Vault エンタープライズ、Secrets Manager などへ置き換え、CI パイプラインで `ExternalSecret` テンプレートを GitOps 管理すると万全です。
