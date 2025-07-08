# 04_CRDとOperatorパターン

## CKAD合格者向け CRD・Operatorパターン理解ガイド

### 視点の転換

| 観点 | CKADでの理解 | CKAでの追加理解 |
|------|--------------|----------------|
| カスタムリソース | CRD の基本的な作成と使用 | Operator による自動化された運用 |
| コントローラー | 組み込みコントローラーの利用 | カスタムコントローラーの設計思想 |
| 状態管理 | 宣言的な設定の適用 | 調整ループによる継続的な状態維持 |
| 拡張性 | API リソースの基本理解 | Kubernetes の拡張メカニズム全体像 |

### 重点学習内容

| CKAD では触れない部分 | CKA での理解 |
|---------------------|-------------|
| Operator パターンの設計原則 | レベル1〜5の成熟度モデル |
| コントローラーの調整ループ | Observe → Analyze → Act サイクル |
| Finalizer による削除制御 | リソースのライフサイクル管理 |
| ステータスサブリソース | 期待状態と実際状態の分離 |

### 学習目的

1. **Operator パターンの本質的理解**
   - Kubernetes の拡張哲学の理解
   - ステートフルアプリケーションの自動運用
   - 人間のオペレーションの自動化

2. **CRD の高度な活用**
   - バリデーション・デフォルト値の設定
   - バージョニングとスキーマ進化
   - サブリソースの活用

3. **実践的な Operator の利用**
   - 既存 Operator の評価と選定
   - Operator のトラブルシューティング
   - カスタム Operator の必要性判断

### 学習手順

#### 1. CRD の高度な定義

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.example.com
spec:
  group: example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: ["engine", "version", "replicas"]
            properties:
              engine:
                type: string
                enum: ["mysql", "postgres", "mongodb"]
              version:
                type: string
                pattern: '^\d+\.\d+\.\d+$'
              replicas:
                type: integer
                minimum: 1
                maximum: 9
                default: 3
              backup:
                type: object
                properties:
                  enabled:
                    type: boolean
                    default: true
                  schedule:
                    type: string
                    default: "0 2 * * *"
          status:
            type: object
            properties:
              phase:
                type: string
                enum: ["Pending", "Creating", "Running", "Failed"]
              replicas:
                type: integer
              lastBackup:
                type: string
                format: date-time
    subresources:
      status: {}
      scale:
        specReplicasPath: .spec.replicas
        statusReplicasPath: .status.replicas
    additionalPrinterColumns:
    - name: Engine
      type: string
      jsonPath: .spec.engine
    - name: Version
      type: string
      jsonPath: .spec.version
    - name: Replicas
      type: integer
      jsonPath: .spec.replicas
    - name: Status
      type: string
      jsonPath: .status.phase
    - name: Age
      type: date
      jsonPath: .metadata.creationTimestamp
  scope: Namespaced
  names:
    plural: databases
    singular: database
    kind: Database
    shortNames:
    - db
```

#### 2. カスタムリソースの作成と管理

```yaml
apiVersion: example.com/v1
kind: Database
metadata:
  name: prod-db
  namespace: production
  finalizers:
  - example.com/database-protection
spec:
  engine: postgres
  version: "14.2.0"
  replicas: 3
  backup:
    enabled: true
    schedule: "0 */6 * * *"
```

#### 3. Operator の成熟度レベル理解

```bash
# レベル1: 基本インストール
kubectl apply -f postgres-operator-install.yaml

# レベル2: アップグレード対応
kubectl patch database prod-db --type='merge' -p '{"spec":{"version":"14.3.0"}}'

# レベル3: ライフサイクル管理（バックアップ・リストア）
kubectl create -f database-backup.yaml

# レベル4: 詳細な洞察（メトリクス・アラート）
kubectl get database prod-db -o jsonpath='{.status}'

# レベル5: 自動パイロット（自動スケーリング・自動修復）
kubectl describe database prod-db
```

#### 4. 既存 Operator の活用例

```yaml
# Prometheus Operator によるモニタリング設定
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: database-metrics
  namespace: production
spec:
  selector:
    matchLabels:
      app: database
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
---
# Strimzi Kafka Operator による Kafka クラスタ
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: event-streaming
  namespace: production
spec:
  kafka:
    version: 3.5.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
    storage:
      type: persistent-claim
      size: 100Gi
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 10Gi
```

### 演習アイデア

#### 演習1: CRD のバージョン管理

1. v1alpha1 から v1beta1 へのスキーマ進化
2. 変換 Webhook の実装
3. 後方互換性の維持

```yaml
# バージョン間の変換設定
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: applications.example.com
spec:
  conversion:
    strategy: Webhook
    webhook:
      clientConfig:
        service:
          name: conversion-webhook
          namespace: kube-system
          path: "/convert"
      conversionReviewVersions: ["v1", "v1beta1"]
```

#### 演習2: Finalizer による安全な削除

```go
// 擬似コード: Finalizer の処理
if object.DeletionTimestamp != nil {
    if contains(object.Finalizers, "example.com/cleanup") {
        // クリーンアップ処理
        err := cleanupExternalResources(object)
        if err != nil {
            return err
        }
        
        // Finalizer を削除
        object.Finalizers = remove(object.Finalizers, "example.com/cleanup")
        update(object)
    }
}
```

#### 演習3: Operator の動作確認とデバッグ

```bash
# Operator のログ確認
kubectl logs -n operators deployment/postgres-operator -f

# リソースの調整状況確認
kubectl get events --field-selector involvedObject.name=prod-db

# Operator のメトリクス確認
kubectl port-forward -n operators svc/postgres-operator-metrics 8080:8080
curl http://localhost:8080/metrics | grep reconcile
```

### CKA試験での出題パターン

| パターン | 問題例 | 対策 |
|---------|--------|------|
| CRD の作成 | 「指定されたスキーマで CRD を作成」 | OpenAPI スキーマの基本を理解 |
| CR の操作 | 「カスタムリソースの作成・更新・削除」 | kubectl の標準操作が適用可能 |
| Operator の利用 | 「既存 Operator を使用してアプリケーションをデプロイ」 | 主要 Operator の基本的な使い方 |

### CKAD経験者が陥りがちな誤解

| 誤解 | 正しい理解 |
|------|-----------|
| 「CRD は高度すぎて試験に出ない」 | 基本的な CRD 操作は試験範囲 |
| 「Operator は開発者向けツール」 | 運用自動化の重要な要素 |
| 「標準リソースで十分」 | 複雑なアプリケーションには Operator が効果的 |
| 「全て自作する必要がある」 | 既存 Operator の活用が現実的 |

### 主要 Operator の紹介

| Operator | 用途 | 成熟度 |
|----------|------|--------|
| Prometheus Operator | モニタリング基盤 | レベル5 |
| Strimzi | Apache Kafka | レベル4 |
| PostgreSQL Operator | PostgreSQL DB | レベル4 |
| Elastic Cloud on K8s | Elasticsearch | レベル5 |
| ArgoCD | GitOps CD | レベル4 |

### 学習優先順位

| 優先度 | 項目 | 理由 |
|--------|------|------|
| 高 | CRD の基本的な作成と管理 | CKA 試験で出題可能性あり |
| 高 | 主要 Operator の基本操作 | 実務で即活用可能 |
| 中 | OpenAPI スキーマの理解 | バリデーション設定に必要 |
| 低 | カスタム Operator の開発 | 高度なトピック |

### セルフチェック

- [ ] CRD を作成し、バリデーションルールを設定できるか？
- [ ] カスタムリソースの CRUD 操作ができるか？
- [ ] Operator の5つの成熟度レベルを説明できるか？
- [ ] Finalizer の役割と動作を理解しているか？
- [ ] 主要な Operator を1つ以上使用した経験があるか？

### まとめ

**学習のポイント**
- Kubernetes の拡張性の本質的理解
- 宣言的管理から自動運用への進化
- 既存 Operator の効果的な活用

**CKA合格の鍵**
- CRD の基本操作の習熟
- kubectl での CR 操作は通常リソースと同じ
- Operator の概念理解（実装は不要）