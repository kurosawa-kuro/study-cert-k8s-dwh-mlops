# 第3章: 高度なRBACとAPIサーバー認証強化

## 学習目的

- RBAC（Role-Based Access Control）の高度な設計パターンの理解
- ABAC（Attribute-Based Access Control）との併用による細粒度制御
- 外部認証プロバイダーとの連携（OIDC、LDAP）
- API サーバーのセキュリティ強化設定

## 学習手順

### 1. 高度なRBAC設計パターン

#### 1.1 最小特権の原則に基づくRole設計
```yaml
# 読み取り専用Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

```yaml
# 特定リソースのみ管理可能なRole
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: deployment-manager
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

#### 1.2 階層的権限管理
```yaml
# 基本権限
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: base-reader
rules:
- apiGroups: [""]
  resources: ["namespaces", "nodes"]
  verbs: ["get", "list", "watch"]

---
# 拡張権限（基本権限を含む）
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: extended-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]

---
# 権限の組み合わせ
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: user-permissions
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: base-reader
  apiGroup: rbac.authorization.k8s.io
```

### 2. ABAC（Attribute-Based Access Control）

#### 2.1 ABAC設定の有効化
```yaml
# kube-apiserver設定
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - name: kube-apiserver
    command:
    - kube-apiserver
    - --authorization-mode=Node,RBAC,ABAC
    - --authorization-policy-file=/etc/kubernetes/abac-policy.json
    volumeMounts:
    - name: abac-policy
      mountPath: /etc/kubernetes/abac-policy.json
      readOnly: true
  volumes:
  - name: abac-policy
    hostPath:
      path: /etc/kubernetes/abac-policy.json
```

#### 2.2 ABAC ポリシーの定義
```json
{
  "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
  "kind": "Policy",
  "spec": {
    "user": "developer",
    "namespace": "*",
    "resource": "pods",
    "apiGroup": "*"
  },
  "conditions": [
    {
      "key": "metadata.labels['environment']",
      "operator": "In",
      "values": ["development", "staging"]
    }
  ]
}
```

### 3. OIDC認証プロバイダー統合

#### 3.1 APIサーバーのOIDC設定
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - name: kube-apiserver
    command:
    - kube-apiserver
    - --oidc-issuer-url=https://example.auth0.com/
    - --oidc-client-id=kubernetes
    - --oidc-username-claim=email
    - --oidc-groups-claim=groups
    - --oidc-ca-file=/etc/kubernetes/ssl/ca.crt
```

#### 3.2 kubeconfig設定
```yaml
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    server: https://kubernetes.example.com
    certificate-authority-data: LS0tLS1CRUdJTi...
users:
- name: oidc-user
  user:
    auth-provider:
      name: oidc
      config:
        issuer-url: https://example.auth0.com/
        client-id: kubernetes
        client-secret: your-client-secret
        refresh-token: your-refresh-token
        id-token: your-id-token
contexts:
- name: kubernetes
  context:
    cluster: kubernetes
    user: oidc-user
current-context: kubernetes
```

### 4. Webhook認証の実装

#### 4.1 Webhook設定
```yaml
apiVersion: v1
kind: Config
clusters:
- name: auth-webhook
  cluster:
    server: https://auth-webhook.example.com/authenticate
    certificate-authority-data: LS0tLS1CRUdJTi...
users:
- name: webhook-user
  user:
    token: webhook-token
contexts:
- name: auth-webhook
  context:
    cluster: auth-webhook
    user: webhook-user
current-context: auth-webhook
```

#### 4.2 Webhookサーバーの実装例
```go
package main

import (
    "encoding/json"
    "net/http"
    "k8s.io/api/authentication/v1beta1"
)

type WebhookServer struct{}

func (ws *WebhookServer) authenticate(w http.ResponseWriter, r *http.Request) {
    var tokenReview v1beta1.TokenReview
    
    if err := json.NewDecoder(r.Body).Decode(&tokenReview); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // トークンの検証ロジック
    if validateToken(tokenReview.Spec.Token) {
        tokenReview.Status.Authenticated = true
        tokenReview.Status.User = v1beta1.UserInfo{
            Username: "validated-user",
            Groups:   []string{"developers", "viewers"},
        }
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(tokenReview)
}

func validateToken(token string) bool {
    // 実際の認証ロジック
    return token == "valid-token"
}
```

### 5. サービスアカウント管理

#### 5.1 自動マウント無効化
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted-sa
  namespace: production
automountServiceAccountToken: false
```

#### 5.2 カスタムサービスアカウント
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-sa
  namespace: monitoring
secrets:
- name: monitoring-token

---
apiVersion: v1
kind: Secret
metadata:
  name: monitoring-token
  namespace: monitoring
  annotations:
    kubernetes.io/service-account.name: monitoring-sa
type: kubernetes.io/service-account-token
```

### 6. Admission Controller設定

#### 6.1 PodSecurityPolicy（参考）
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
```

#### 6.2 ValidatingAdmissionWebhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: security-webhook
webhooks:
- name: security.example.com
  clientConfig:
    service:
      name: security-webhook
      namespace: default
      path: /validate
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1", "v1beta1"]
```

### 7. 実践演習

#### 演習1: 部門別権限管理
1. 開発、テスト、本番環境別のNamespace作成
2. 各部門向けRoleとRoleBindingの設計
3. 権限のテストと検証

#### 演習2: OIDC認証設定
1. Auth0/Keycloakとの連携設定
2. グループベースのアクセス制御
3. トークンの更新メカニズム

#### 演習3: 複合認証システム
1. RBAC + ABAC の組み合わせ
2. Webhook認証の実装
3. エラーハンドリングとロギング

## 参照ドキュメント

- [RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [ABAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/abac/)
- [OIDC Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)
- [Webhook Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#webhook-token-authentication)
- [ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

## 検証コマンド

```bash
# 権限の確認
kubectl auth can-i create pods --as=system:serviceaccount:default:test-sa

# RoleBindingの確認
kubectl get rolebindings,clusterrolebindings --all-namespaces

# サービスアカウントの確認
kubectl get serviceaccounts --all-namespaces

# 権限の詳細確認
kubectl describe clusterrole cluster-admin
```

## セキュリティ監査

### 1. 権限監査スクリプト
```bash
#!/bin/bash
# rbac-audit.sh

echo "=== RBAC Audit Report ==="
echo "Date: $(date)"
echo ""

echo "1. Cluster Admin Users:"
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[]?.name' | sort | uniq

echo ""
echo "2. Service Accounts with Cluster Admin:"
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[] | select(.kind=="ServiceAccount") | "\(.namespace)/\(.name)"'

echo ""
echo "3. Roles with Dangerous Permissions:"
kubectl get roles,clusterroles -o json | jq -r '.items[] | select(.rules[]?.verbs[]? == "*") | .metadata.name'
```

### 2. 自動化されたセキュリティチェック
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: rbac-audit
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: rbac-audit
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              kubectl get clusterrolebindings -o json | \
              jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[]?.name' | \
              tee /tmp/admin-users.txt
          restartPolicy: OnFailure
```

## 学習時間目安

- 概念理解: 4時間
- 実装・演習: 8時間
- 検証・トラブルシューティング: 4時間

**合計: 16時間**