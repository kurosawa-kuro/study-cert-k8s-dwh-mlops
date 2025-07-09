CKSで必要な、CKADを超える追加のK8sセキュリティ基礎知識を整理します。

## CKSで追加必要なK8sセキュリティ知識

### **1. Pod Security Standards/Policies**
```yaml
# Pod Security Standards (PSS) - CKADでは軽く触れる程度
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-ns
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

# Pod Security Policy (PSP) - より詳細な制御
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### **2. Certificate Management & TLS**
```bash
# 証明書の詳細管理 - CKADでは触れない領域
# kubeconfig証明書確認
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -text

# API Server証明書確認
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# 証明書更新
kubeadm certs check-expiration
kubeadm certs renew all

# TLS設定
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...
  tls.key: LS0tLS1CRUdJTi...
```

### **3. Admission Controllers**
```yaml
# ImagePolicyWebhook
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/imagepolicy/kubeconfig
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false

# ValidatingAdmissionWebhook
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: image-policy
webhooks:
- name: image-policy.example.com
  clientConfig:
    service:
      name: image-policy
      namespace: default
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

### **4. Service Accounts & Token Management**
```yaml
# Service Account詳細設定 - CKADより高度
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  annotations:
    kubernetes.io/enforce-mountable-secrets: "true"
automountServiceAccountToken: false

# Projected Service Account Token
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: my-service-account
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: token
      mountPath: /var/run/secrets/tokens
  volumes:
  - name: token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600
          audience: api
```

### **5. Secrets Management (高度な利用)**
```yaml
# External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"

# Sealed Secrets
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: mysecret
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
```

### **6. Network Security (詳細設定)**
```yaml
# 高度なNetwork Policy - CKADより複雑
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: advanced-netpol
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    - podSelector:
        matchLabels:
          role: client
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: backend
    ports:
    - protocol: TCP
      port: 5978
```

### **7. Audit Logging**
```yaml
# Audit Policy - CKADでは学習しない
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  namespaces: ["default"]
  verbs: ["create", "update", "delete"]
  resources:
  - group: ""
    resources: ["pods", "services"]
- level: Request
  namespaces: ["kube-system"]
  verbs: ["create", "update", "delete"]
  users: ["admin"]
```

### **8. Supply Chain Security**
```yaml
# Image signing/verification
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: registry.example.com/myapp:v1.0@sha256:abc123...
    imagePullPolicy: Always
  imagePullSecrets:
  - name: registry-secret

# Resource constraints for security
resources:
  limits:
    cpu: "500m"
    memory: "512Mi"
    ephemeral-storage: "1Gi"
  requests:
    cpu: "250m"
    memory: "256Mi"
```

## CKADから追加で必要な学習領域

**CKADでは軽く触れる → CKSで深く学習：**
1. **Pod Security Standards** の詳細実装
2. **Certificate Management** の実践的操作
3. **Admission Controllers** の設定と運用
4. **Audit Logging** の設定と分析
5. **Supply Chain Security** の実装

**CKADでは触れない → CKSで新規学習：**
1. **ImagePolicyWebhook** の設定
2. **Service Account Token** の高度な管理
3. **外部シークレット管理** の統合
4. **ネットワークセキュリティ** の詳細設定

これらの知識をセキュリティツールと組み合わせることで、CKSレベルのセキュリティ実装が可能になります。