# 03_Podセキュリティ基準

## CKAD合格者向け Podセキュリティ基準理解ガイド

### 視点の転換

| 観点 | CKADでの理解 | CKAでの追加理解 |
|------|--------------|----------------|
| セキュリティコンテキスト | 基本的な runAsUser、capabilities | Pod Security Standards の包括的適用 |
| 権限管理 | コンテナレベルの設定 | クラスタ全体のセキュリティポリシー |
| 実行制御 | securityContext の個別設定 | Policy as Code による統一管理 |
| コンプライアンス | 開発者視点の設定 | 組織全体のガバナンス実装 |

### 重点学習内容

| CKAD では触れない部分 | CKA での理解 |
|---------------------|-------------|
| Pod Security Standards (PSS) | Restricted、Baseline、Privileged の3段階モデル |
| Pod Security Admission | 名前空間レベルでの強制実行 |
| OPA (Open Policy Agent) | 柔軟なポリシーエンジンによる制御 |
| Gatekeeper | Kubernetes ネイティブなポリシー管理 |

### 学習目的

1. **Pod Security Standards の完全理解**
   - 3つのプロファイル（Privileged、Baseline、Restricted）の使い分け
   - 段階的なセキュリティ強化の実装
   - 既存ワークロードの移行戦略

2. **ポリシーエンジンの活用**
   - OPA/Gatekeeper によるカスタムポリシーの実装
   - 違反検出とレポーティング
   - CI/CD パイプラインへの統合

3. **エンタープライズセキュリティの実装**
   - ゼロトラストコンテナ実行環境
   - コンプライアンス要件への対応
   - セキュリティ監査の自動化

### 学習手順

#### 1. Pod Security Standards の適用

```yaml
# 名前空間への PSS ラベル適用
apiVersion: v1
kind: Namespace
metadata:
  name: secure-app
  labels:
    # 強制モード
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: v1.30
    # 警告モード
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.30
    # 監査モード
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.30
```

#### 2. Restricted プロファイルに準拠した Pod 定義

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: secure-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-cache
    emptyDir: {}
  - name: var-run
    emptyDir: {}
```

#### 3. Gatekeeper によるカスタムポリシー実装

```yaml
# Gatekeeper のインストール
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

---
# ConstraintTemplate の定義
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: requiresecuritycontext
spec:
  crd:
    spec:
      names:
        kind: RequireSecurityContext
      validation:
        openAPIV3Schema:
          type: object
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package requiresecuritycontext
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.runAsNonRoot
          msg := sprintf("Container %v must set runAsNonRoot", [container.name])
        }
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.allowPrivilegeEscalation == false
          msg := sprintf("Container %v must set allowPrivilegeEscalation=false", [container.name])
        }
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.readOnlyRootFilesystem
          msg := sprintf("Container %v must set readOnlyRootFilesystem=true", [container.name])
        }
---
# Constraint の適用
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: RequireSecurityContext
metadata:
  name: pod-must-have-security-context
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces: ["production", "staging"]
```

#### 4. 違反検出とレポーティング

```bash
# PSS 違反の確認
kubectl get events -n secure-app --field-selector reason=FailedCreate

# Gatekeeper 違反の確認
kubectl describe requiresecuritycontext pod-must-have-security-context

# 違反 Pod の一覧取得
kubectl get pods -A -o json | jq -r '
  .items[] | 
  select(.spec.containers[].securityContext.runAsNonRoot != true) | 
  "\(.metadata.namespace)/\(.metadata.name)"
'
```

### 演習アイデア

#### 演習1: 既存アプリケーションの段階的移行

1. 既存の Pod を Baseline プロファイルに準拠させる
2. 警告モードで Restricted プロファイルをテスト
3. 完全な Restricted プロファイルへの移行

```bash
# 現状の評価
kubectl label namespace default \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=v1.30

# テストデプロイメント
kubectl apply -f legacy-app.yaml

# 警告の確認と修正
kubectl get events -n default --field-selector type=Warning
```

#### 演習2: カスタムポリシーの実装

1. 特定のレジストリからのイメージのみ許可
2. 特定のユーザー ID での実行を強制
3. リソース制限の必須化

```yaml
# イメージレジストリ制限の例
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: allowedregistries
spec:
  crd:
    spec:
      names:
        kind: AllowedRegistries
      validation:
        openAPIV3Schema:
          type: object
          properties:
            registries:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package allowedregistries
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          satisfied := [good | registry = input.parameters.registries[_]; good = startswith(container.image, registry)]
          not any(satisfied)
          msg := sprintf("Container %v uses disallowed registry", [container.name])
        }
```

#### 演習3: セキュリティ監査の自動化

```bash
# 全 Pod のセキュリティ設定を監査
cat << 'EOF' > security-audit.sh
#!/bin/bash

echo "=== Pod Security Audit Report ==="
echo "Generated: $(date)"
echo ""

for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  echo "Namespace: $ns"
  kubectl get pods -n $ns -o json | jq -r '
    .items[] | 
    {
      name: .metadata.name,
      runAsNonRoot: .spec.containers[0].securityContext.runAsNonRoot,
      readOnlyRootFilesystem: .spec.containers[0].securityContext.readOnlyRootFilesystem,
      allowPrivilegeEscalation: .spec.containers[0].securityContext.allowPrivilegeEscalation
    }
  ' | jq -s '.' 
  echo ""
done
EOF

chmod +x security-audit.sh
./security-audit.sh > security-audit-report.json
```

### CKA試験での出題パターン

| パターン | 問題例 | 対策 |
|---------|--------|------|
| PSS の適用 | 「名前空間に Restricted プロファイルを適用」 | ラベルの正確な記述を暗記 |
| セキュリティコンテキスト修正 | 「既存 Pod を PSS 準拠に修正」 | 必須フィールドのチェックリスト作成 |
| ポリシー違反の調査 | 「なぜ Pod が起動しないか調査」 | イベントとログの確認手順を習得 |

### CKAD経験者が陥りがちな誤解

| 誤解 | 正しい理解 |
|------|-----------|
| 「securityContext だけで十分」 | PSS による包括的な管理が推奨 |
| 「root 実行が必要なアプリは対象外」 | 適切な設計で多くは非 root 化可能 |
| 「パフォーマンスへの影響が大きい」 | 適切な実装では影響は最小限 |
| 「開発環境では不要」 | 早期からの適用が移行を容易に |

### 学習優先順位

| 優先度 | 項目 | 理由 |
|--------|------|------|
| 高 | Pod Security Standards の3プロファイル | CKA試験の重要トピック |
| 高 | 名前空間への PSS ラベル適用 | 実践的な実装方法 |
| 中 | Gatekeeper の基本的な使用 | カスタムポリシーの理解 |
| 低 | OPA Rego 言語の詳細 | 基礎理解後の発展的内容 |

### セルフチェック

- [ ] PSS の3つのプロファイルの違いを説明できるか？
- [ ] 名前空間に PSS を適用する3つのモード（enforce、warn、audit）を理解しているか？
- [ ] Restricted プロファイルに準拠した Pod を作成できるか？
- [ ] Gatekeeper でシンプルなカスタムポリシーを実装できるか？
- [ ] PSS 違反で Pod が起動しない場合のトラブルシューティングができるか？

### まとめ

**学習のポイント**
- 個別設定から統一ポリシーへの移行理解
- 段階的なセキュリティ強化のアプローチ
- Policy as Code による自動化とガバナンス

**CKA合格の鍵**
- PSS の適用方法と必須設定の暗記
- トラブルシューティング手順の習熟
- 実践的なシナリオでの適用練習