# 06_GitOpsとテンプレート管理

## CKAD合格者向け GitOps・テンプレート管理理解ガイド

### 視点の転換

| 観点 | CKADでの理解 | CKAでの追加理解 |
|------|--------------|----------------|
| デプロイ方法 | kubectl apply による直接適用 | Git を信頼できる唯一の情報源とする運用 |
| 設定管理 | YAML ファイルの個別管理 | テンプレートエンジンによる効率化 |
| 環境管理 | 手動での環境差分管理 | 宣言的な環境構成の自動同期 |
| 変更管理 | アドホックな変更適用 | Pull Request ベースの変更プロセス |

### 重点学習内容

| CKAD では触れない部分 | CKA での理解 |
|---------------------|-------------|
| GitOps の原則と実装 | 宣言的、Git による版管理、自動同期、継続的な調整 |
| Helm チャートの管理 | パッケージング、リポジトリ、依存関係管理 |
| Kustomize の高度な活用 | 環境別カスタマイズ、パッチ戦略 |
| ArgoCD/Flux の運用 | 継続的デリバリーの自動化 |

### 学習目的

1. **GitOps ワークフローの実装**
   - Git を中心とした運用プロセス
   - 自動同期と drift 検出
   - ロールバックとディザスタリカバリ

2. **テンプレート管理の最適化**
   - Helm と Kustomize の使い分け
   - 再利用可能なコンポーネント設計
   - 環境差分の効率的な管理

3. **エンタープライズでの GitOps 実践**
   - マルチテナント・マルチクラスタ対応
   - セキュリティとコンプライアンス
   - 監査証跡の自動化

### 学習手順

#### 1. Helm による高度なパッケージ管理

```bash
# Helm チャートの作成
helm create microservice-chart

# values.yaml の構造化
cat << 'EOF' > microservice-chart/values.yaml
global:
  environment: production
  domain: example.com

replicaCount: 3

image:
  repository: myregistry/myapp
  tag: ""  # Overridden by CI/CD
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: "{{ .Values.global.environment }}.{{ .Values.global.domain }}"
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 1000m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

env:
  - name: ENVIRONMENT
    value: "{{ .Values.global.environment }}"
  - name: LOG_LEVEL
    value: "{{ .Values.logLevel | default \"info\" }}"
EOF

# 環境別の values ファイル
cat << 'EOF' > environments/production-values.yaml
global:
  environment: production
  
replicaCount: 5

resources:
  limits:
    cpu: 2000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

logLevel: warn
EOF

# Helm テンプレートの検証
helm template myapp ./microservice-chart \
  -f environments/production-values.yaml \
  --debug

# 依存関係の管理
cat << 'EOF' > microservice-chart/Chart.yaml
apiVersion: v2
name: microservice
version: 1.0.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
EOF
```

#### 2. Kustomize による宣言的カスタマイズ

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app.kubernetes.io/name: myapp
  app.kubernetes.io/instance: myapp-instance
  app.kubernetes.io/component: backend

configMapGenerator:
  - name: app-config
    files:
      - config.yaml
    options:
      disableNameSuffixHash: false

images:
  - name: myapp
    newName: myregistry/myapp
    newTag: latest

replicas:
  - name: myapp-deployment
    count: 2
---
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml

patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp-deployment
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: ENVIRONMENT
          value: production

configMapGenerator:
  - name: app-config
    behavior: merge
    files:
      - config.prod.yaml=config.yaml

secretGenerator:
  - name: app-secrets
    envs:
      - secrets.env

images:
  - name: myapp
    newTag: v1.2.3

resources:
  - ingress.yaml
  - network-policy.yaml
```

#### 3. ArgoCD による GitOps 実装

```yaml
# ArgoCD Application 定義
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: production-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: production
  source:
    repoURL: https://github.com/myorg/k8s-configs
    targetRevision: main
    path: applications/myapp/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
---
# ArgoCD AppProject 定義
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  description: Production applications
  sourceRepos:
    - 'https://github.com/myorg/*'
  destinations:
    - namespace: 'production'
      server: https://kubernetes.default.svc
    - namespace: 'production-*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
  roles:
    - name: admin
      policies:
        - p, proj:production:admin, applications, *, production/*, allow
      groups:
        - myorg:platform-team
```

#### 4. Flux による GitOps 実装

```yaml
# Flux GitRepository 定義
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: k8s-configs
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/myorg/k8s-configs
  ref:
    branch: main
  secretRef:
    name: github-auth
---
# Flux Kustomization 定義
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: production-apps
  namespace: flux-system
spec:
  interval: 10m
  path: ./applications/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: k8s-configs
  validation: client
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: cluster-config
      - kind: Secret
        name: cluster-secrets
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: myapp
      namespace: production
```

### 演習アイデア

#### 演習1: マルチ環境 GitOps パイプライン

1. Git リポジトリ構造の設計
2. 環境別ブランチ戦略
3. 自動プロモーション設定

```bash
# リポジトリ構造
k8s-configs/
├── base/
│   ├── applications/
│   └── infrastructure/
├── overlays/
│   ├── development/
│   ├── staging/
│   └── production/
└── clusters/
    ├── dev-cluster/
    ├── staging-cluster/
    └── prod-cluster/
```

#### 演習2: Helm + ArgoCD の統合

```yaml
# ArgoCD での Helm アプリケーション
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: helm-app
  namespace: argocd
spec:
  source:
    repoURL: https://charts.myorg.com
    chart: microservice
    targetRevision: 1.2.3
    helm:
      releaseName: myapp
      valueFiles:
        - values-prod.yaml
      parameters:
        - name: image.tag
          value: v1.2.3
```

#### 演習3: Progressive Delivery の実装

```yaml
# Flagger による Canary デプロイメント
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  progressDeadlineSeconds: 60
  service:
    port: 80
    targetPort: 8080
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
      - name: request-success-rate
        thresholdRange:
          min: 99
        interval: 1m
```

### CKA試験での出題パターン

| パターン | 問題例 | 対策 |
|---------|--------|------|
| Helm 基本操作 | 「Helm チャートをインストール・アップグレード」 | helm install/upgrade コマンドの習熟 |
| Kustomize 適用 | 「Kustomization を使用してリソースをデプロイ」 | kubectl apply -k の理解 |
| テンプレート化 | 「環境変数を使用した設定の動的生成」 | ConfigMapGenerator の活用 |

### CKAD経験者が陥りがちな誤解

| 誤解 | 正しい理解 |
|------|-----------|
| 「kubectl apply で十分」 | GitOps により運用の自動化と監査性が向上 |
| 「Helm は複雑すぎる」 | 適切に使えば管理が大幅に効率化 |
| 「Git に秘密情報を保存できない」 | Sealed Secrets や SOPS で暗号化可能 |
| 「手動変更の方が速い」 | 長期的には GitOps の方が安全で効率的 |

### 学習優先順位

| 優先度 | 項目 | 理由 |
|--------|------|------|
| 高 | Kustomize の基本操作 | kubectl に統合済み、試験で出題可能 |
| 高 | Helm の基本的なチャート管理 | 実務で広く使用される |
| 中 | GitOps の概念理解 | 運用のベストプラクティス |
| 低 | ArgoCD/Flux の詳細設定 | 基本概念の理解で十分 |

### セルフチェック

- [ ] Helm で values.yaml を使用してチャートをカスタマイズできるか？
- [ ] Kustomize で base と overlay の構造を作成できるか？
- [ ] GitOps の4原則を説明できるか？
- [ ] 環境別の設定管理方法を3つ以上挙げられるか？
- [ ] Git を唯一の信頼できる情報源とする利点を説明できるか？

### まとめ

**学習のポイント**
- 手動運用から宣言的・自動化された運用への移行
- テンプレート化による設定の再利用性向上
- Git による変更履歴とロールバックの実現

**CKA合格の鍵**
- Helm と Kustomize の基本コマンド習得
- 環境差分管理の基本パターン理解
- GitOps 概念の理解（ツールの詳細は不要）