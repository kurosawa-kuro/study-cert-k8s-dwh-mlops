# 05_ストレージクラスとCSIドライバー

## CKAD合格者向け ストレージクラス・CSIドライバー理解ガイド

### 視点の転換

| 観点 | CKADでの理解 | CKAでの追加理解 |
|------|--------------|----------------|
| ストレージ利用 | PVC/PV の基本的な使用 | ストレージプロビジョニング戦略 |
| 永続性 | 単純なデータ永続化 | 高可用性とデータ保護の設計 |
| ストレージタイプ | 基本的な Volume タイプ | CSI による統一されたストレージ管理 |
| 管理範囲 | アプリケーション視点 | インフラストラクチャ全体の最適化 |

### 重点学習内容

| CKAD では触れない部分 | CKA での理解 |
|---------------------|-------------|
| StorageClass の詳細設計 | プロビジョナー、パラメータ、回収ポリシー |
| CSI ドライバーの仕組み | Controller と Node プラグインの役割 |
| Volume Snapshot 機能 | バックアップ・リストア戦略 |
| Storage Capacity Tracking | ストレージリソースの最適配置 |

### 学習目的

1. **動的プロビジョニングの完全理解**
   - StorageClass によるストレージの抽象化
   - プロビジョナーごとの特性理解
   - パフォーマンスとコストの最適化

2. **CSI エコシステムの理解**
   - CSI ドライバーのアーキテクチャ
   - 主要クラウドプロバイダーの CSI 実装
   - オンプレミスストレージの統合

3. **エンタープライズストレージ戦略**
   - データ保護とディザスタリカバリ
   - マルチテナンシーとセキュリティ
   - ストレージの監視と最適化

### 学習手順

#### 1. StorageClass の高度な設定

```yaml
# AWS EBS の StorageClass 例
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "16000"
  throughput: "1000"
  encrypted: "true"
  kmsKeyId: "arn:aws:kms:region:account:key/key-id"
  tagSpecification_1: "ResourceType=volume,Tags=[{Key=Environment,Value=Production}]"
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: topology.kubernetes.io/zone
    values:
    - us-east-1a
    - us-east-1b
---
# オンプレミス NFS の StorageClass 例
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs-server.example.com
  share: /kubernetes-volumes
  mountOptions: "hard,nfsvers=4.1,rsize=1048576,wsize=1048576"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - hard
  - nfsvers=4.1
  - rsize=1048576
  - wsize=1048576
```

#### 2. CSI ドライバーのデプロイと管理

```yaml
# CSI ドライバーのインストール例（AWS EBS）
# 1. CSI Driver オブジェクト
apiVersion: storage.k8s.io/v1
kind: CSIDriver
metadata:
  name: ebs.csi.aws.com
spec:
  attachRequired: true
  podInfoOnMount: false
  fsGroupPolicy: File
  volumeLifecycleModes:
  - Persistent
  - Ephemeral
---
# 2. Controller Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ebs-csi-controller
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ebs-csi-controller
  template:
    metadata:
      labels:
        app: ebs-csi-controller
    spec:
      serviceAccountName: ebs-csi-controller-sa
      priorityClassName: system-cluster-critical
      containers:
      - name: ebs-plugin
        image: k8s.gcr.io/provider-aws/aws-ebs-csi-driver:v1.20.0
        args:
        - controller
        - --endpoint=$(CSI_ENDPOINT)
        - --logtostderr
        - --v=2
        env:
        - name: CSI_ENDPOINT
          value: unix:///var/lib/csi/sockets/pluginproxy/csi.sock
        volumeMounts:
        - name: socket-dir
          mountPath: /var/lib/csi/sockets/pluginproxy/
      - name: csi-provisioner
        image: k8s.gcr.io/sig-storage/csi-provisioner:v3.5.0
        args:
        - --csi-address=$(ADDRESS)
        - --v=2
        - --feature-gates=Topology=true
        - --extra-create-metadata
        - --leader-election=true
        env:
        - name: ADDRESS
          value: /var/lib/csi/sockets/pluginproxy/csi.sock
      volumes:
      - name: socket-dir
        emptyDir: {}
```

#### 3. Volume Snapshot の活用

```yaml
# VolumeSnapshotClass の定義
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snapclass
driver: ebs.csi.aws.com
deletionPolicy: Delete
parameters:
  tagSpecification_1: "ResourceType=snapshot,Tags=[{Key=Purpose,Value=Backup}]"
---
# VolumeSnapshot の作成
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: app-snapshot
  namespace: production
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: app-data-pvc
---
# スナップショットからの PVC 作成
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restore-pvc
  namespace: production
spec:
  storageClassName: fast-ssd
  dataSource:
    name: app-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
```

#### 4. ストレージの監視と最適化

```yaml
# Storage Capacity Tracking
apiVersion: v1
kind: CSIStorageCapacity
metadata:
  name: csi-capacity-example
  namespace: default
storageClassName: fast-ssd
capacity: 10Ti
nodeTopology:
  matchLabels:
    topology.kubernetes.io/zone: us-east-1a
---
# PVC の使用状況監視
apiVersion: v1
kind: ConfigMap
metadata:
  name: storage-monitoring
  namespace: kube-system
data:
  check-pvc-usage.sh: |
    #!/bin/bash
    kubectl get pvc -A -o json | jq -r '
      .items[] | 
      select(.status.phase == "Bound") |
      {
        namespace: .metadata.namespace,
        name: .metadata.name,
        storageClass: .spec.storageClassName,
        size: .spec.resources.requests.storage,
        accessModes: .spec.accessModes
      }
    '
```

### 演習アイデア

#### 演習1: マルチテナントストレージ戦略

1. テナントごとの StorageClass 作成
2. ResourceQuota によるストレージ制限
3. 暗号化とアクセス制御の実装

```yaml
# テナント専用 StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: tenant-a-storage
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  encrypted: "true"
  kmsKeyId: "arn:aws:kms:region:account:key/tenant-a-key"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
---
# テナントのストレージクォータ
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-a-storage-quota
  namespace: tenant-a
spec:
  hard:
    persistentvolumeclaims: "10"
    requests.storage: "1Ti"
    tenant-a-storage.storageclass.storage.k8s.io/requests.storage: "500Gi"
```

#### 演習2: ストレージマイグレーション

```bash
# 1. 既存 PV のデータをバックアップ
kubectl exec -n production deployment/app -- tar czf /backup/data.tar.gz /data

# 2. 新しい StorageClass で PVC 作成
kubectl apply -f new-pvc.yaml

# 3. データの移行
kubectl exec -n production deployment/app -- tar xzf /backup/data.tar.gz -C /new-data

# 4. アプリケーションの切り替え
kubectl patch deployment app -n production --type json -p='[{"op": "replace", "path": "/spec/template/spec/volumes/0/persistentVolumeClaim/claimName", "value":"new-pvc"}]'
```

#### 演習3: CSI ドライバーのトラブルシューティング

```bash
# CSI ドライバーの状態確認
kubectl get csidrivers
kubectl get csinodes

# Controller ログの確認
kubectl logs -n kube-system deployment/ebs-csi-controller -c ebs-plugin

# Node プラグインの確認
kubectl logs -n kube-system daemonset/ebs-csi-node -c ebs-plugin

# Volume Attachment の確認
kubectl get volumeattachments

# CSI 関連イベントの確認
kubectl get events -A --field-selector reason=ProvisioningFailed
```

### CKA試験での出題パターン

| パターン | 問題例 | 対策 |
|---------|--------|------|
| StorageClass 作成 | 「特定パラメータで StorageClass を作成」 | 主要プロビジョナーのパラメータ暗記 |
| 動的プロビジョニング | 「StorageClass を使用した PVC 作成」 | volumeBindingMode の理解 |
| スナップショット | 「既存 PVC のスナップショット作成」 | VolumeSnapshot API の基本操作 |

### CKAD経験者が陥りがちな誤解

| 誤解 | 正しい理解 |
|------|-----------|
| 「PVC を作れば自動でストレージが作られる」 | StorageClass の設定が前提条件 |
| 「全てのストレージが動的プロビジョニング対応」 | プロビジョナーの実装に依存 |
| 「CSI は複雑で理解不要」 | 基本的な仕組みの理解は運用で重要 |
| 「デフォルト StorageClass で十分」 | 要件に応じた最適化が必要 |

### 主要 CSI ドライバー

| CSI ドライバー | 用途 | 特徴 |
|---------------|------|------|
| AWS EBS CSI | AWS EBS ボリューム | スナップショット、暗号化対応 |
| GCE PD CSI | GCP Persistent Disk | リージョナルディスク対応 |
| Azure Disk CSI | Azure Managed Disk | Ultra Disk 対応 |
| vSphere CSI | VMware vSphere | VSAN ポリシー統合 |
| Ceph CSI | Ceph/Rook | RBD と CephFS 対応 |

### 学習優先順位

| 優先度 | 項目 | 理由 |
|--------|------|------|
| 高 | StorageClass の作成と管理 | CKA 試験頻出トピック |
| 高 | 動的プロビジョニングの仕組み | 実務で必須の知識 |
| 中 | Volume Snapshot の基本操作 | バックアップ戦略の基礎 |
| 低 | CSI ドライバーの内部実装 | 概念理解で十分 |

### セルフチェック

- [ ] StorageClass の主要パラメータ（provisioner、reclaimPolicy、volumeBindingMode）を説明できるか？
- [ ] WaitForFirstConsumer と Immediate の違いを理解しているか？
- [ ] VolumeSnapshot を作成し、復元できるか？
- [ ] CSI ドライバーの基本的なアーキテクチャを説明できるか？
- [ ] ストレージ関連のトラブルシューティング手順を知っているか？

### まとめ

**学習のポイント**
- PVC/PV の基本から動的プロビジョニングへの理解深化
- ストレージの抽象化とプロバイダー非依存な設計
- データ保護とパフォーマンスの両立

**CKA合格の鍵**
- StorageClass の YAML 定義を素早く作成
- 主要なプロビジョナーとパラメータの暗記
- トラブルシューティングの基本手順習得