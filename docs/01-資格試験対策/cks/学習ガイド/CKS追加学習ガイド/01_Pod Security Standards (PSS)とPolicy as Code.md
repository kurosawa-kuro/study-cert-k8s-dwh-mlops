# 第1章: Pod Security Standards (PSS)とPolicy as Code

## 学習目的

- PodSecurityPolicyの廃止後の代替となるPod Security Standards（PSS）の理解
- OPA/Gatekeeper、Kyvernoを用いた動的ポリシー管理の実装
- Policy as Codeによるセキュリティガバナンスの自動化

## 学習手順

### 1. Pod Security Standards (PSS)の実装

#### 1.1 PSSの概要と設定
```yaml
# privileged-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: privileged-ns
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
```

```yaml
# restricted-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-ns
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

#### 1.2 PSSレベルの理解
- **Privileged**: 制限なし
- **Baseline**: 最小限のセキュリティ制約
- **Restricted**: 厳格なセキュリティ制約

### 2. Open Policy Agent (OPA) Gatekeeper

#### 2.1 Gatekeeperのインストール
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
```

#### 2.2 ConstraintTemplateの作成
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        properties:
          labels:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("You must provide labels: %v", [missing])
        }
```

#### 2.3 Constraintの適用
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-owner
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    labels: ["owner", "environment"]
```

### 3. Kyverno Policy Engine

#### 3.1 Kyvernoのインストール
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

#### 3.2 ClusterPolicyの作成
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged-containers
spec:
  validationFailureAction: enforce
  background: true
  rules:
  - name: disallow-privileged
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Privileged containers are not allowed"
      pattern:
        spec:
          =(securityContext):
            =(privileged): "false"
          containers:
          - name: "*"
            =(securityContext):
              =(privileged): "false"
```

#### 3.3 Generate Policyの実装
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-network-policy
spec:
  rules:
  - name: default-deny-ingress
    match:
      resources:
        kinds:
        - Namespace
    generate:
      kind: NetworkPolicy
      name: default-deny-ingress
      namespace: "{{request.object.metadata.name}}"
      data:
        spec:
          podSelector: {}
          policyTypes:
          - Ingress
```

### 4. Policy Validation Tools

#### 4.1 Conftest
```bash
# Conftest インストール
curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz | tar xz
sudo mv conftest /usr/local/bin

# ポリシーファイル作成
cat << EOF > security-policy.rego
package kubernetes.security

deny[msg] {
  input.kind == "Pod"
  input.spec.containers[_].securityContext.privileged == true
  msg := "Privileged containers are not allowed"
}

deny[msg] {
  input.kind == "Pod"
  input.spec.containers[_].securityContext.runAsRoot == true
  msg := "Running as root is not allowed"
}
EOF

# テスト実行
conftest test --policy security-policy.rego pod-manifest.yaml
```

#### 4.2 Polaris
```bash
# Polaris インストール
kubectl apply -f https://github.com/FairwindsOps/polaris/releases/latest/download/dashboard.yaml

# カスタム設定
kubectl create configmap polaris-config -n polaris --from-file=config.yaml
```

### 5. 実践演習

#### 演習1: PSSによるNamespace制御
1. 3つのNamespaceを作成（privileged, baseline, restricted）
2. 各レベルでPodの動作確認
3. 違反時の動作確認

#### 演習2: Gatekeeperによる動的ポリシー
1. 必須ラベルを強制するConstraintTemplate作成
2. リソース制限を強制するポリシー作成
3. 違反時の動作とログ確認

#### 演習3: Kyvernoによる自動化
1. NetworkPolicyの自動生成
2. セキュリティコンテキストの自動設定
3. イメージスキャン結果による許可/拒否

## 参照ドキュメント

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Kyverno Documentation](https://kyverno.io/)
- [Conftest](https://www.conftest.dev/)
- [Polaris](https://polaris.docs.fairwinds.com/)

## 検証コマンド

```bash
# PSSの確認
kubectl get ns -o yaml | grep pod-security

# Gatekeeperの状態確認
kubectl get constrainttemplates
kubectl get constraints

# Kyvernoの状態確認
kubectl get cpol
kubectl get pol

# 違反の確認
kubectl get events --field-selector type=Warning
```

## 学習時間目安

- 概念理解: 2時間
- 実装・演習: 4時間
- 検証・トラブルシューティング: 2時間

**合計: 8時間**