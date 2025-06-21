### `storage-csi-overview.md` — Kubernetes Storage & CSI 深掘りガイド

*Pod→Volume がマウントされる舞台裏を 1 ファイルで把握。
CKA／CKS／KCNA (KCSA) のストレージ設計 & トラブルシュート対策に。*

---

## 0. Big Picture — “PVC ⇒ PV ⇒ CSI Driver” の3段ギア

```
┌─────────────┐       ┌────────────┐      ┌────────────┐
│  Pod.spec   │  ──►  │ Persistent │  ──► │  CSI       │
│ volumes:    │       │ VolumeClaim│       │ Controller │
│  - pvc-abc  │       │ (PVC)      │       │ + Node     │
└─────────────┘       └────────────┘      └────────────┘
       (Mount)              (Bind)               (Provision / Attach / Mount)
```

1. **Pod** で `claimName` を宣言
2. **PVC** が **StorageClass** を参照し **PV** にバインド
3. **CSI Driver** が外部ストレージを実体化 → Node Plugin が `mount`

---

## 1. WHY — 公式ドメイン別に重要性を整理

| 試験       | 出題ポイント                                                   |
| -------- | -------------------------------------------------------- |
| **KCNA** | “PVC→PV ライフサイクル” ⬆ “StorageClass の役割”                    |
| **CKAD** | Pod YAML に `volumeMounts` / `persistentVolumeClaim`      |
| **CKA**  | Dynamic Provisioning, Resize, AccessModes, ReclaimPolicy |
| **CKS**  | Secret-encrypted PV、FSGroup、ReadOnlyRootFilesystem       |

---

## 2. WHAT — 用語クイック対比

| オブジェクト                          | 最小フィールド                                            | 説明                  |
| ------------------------------- | -------------------------------------------------- | ------------------- |
| **StorageClass**                | `provisioner`, `parameters.*`                      | “どの CSI でどう作る？”     |
| **PersistentVolume (PV)**       | `spec.capacity`, `accessModes`, `storageClassName` | 実体ストレージのメタ          |
| **PersistentVolumeClaim (PVC)** | `spec.resources.requests.storage`, `accessModes`   | Pod 側要求＝“Ticket”    |
| **VolumeSnapshot**              | `volumeSnapshotClassName`                          | CSI Snapshotter CRD |

---

## 3. CSI (Container Storage Interface) アーキ

| コンポーネント               | 動く場所                         | 役割                                               |
| --------------------- | ---------------------------- | ------------------------------------------------ |
| **Controller Plugin** | Controller Node (Deployment) | CreateVolume / DeleteVolume / ControllerExpand   |
| **Node Plugin**       | 各 Worker Node (DaemonSet)    | NodeStage / NodePublish / NodeExpand             |
| **CSI Sidecars**      | 併設 Pod                       | `external-provisioner`, `snapshotter`, `resizer` |

> **覚え方**： Controller＝“クラウド API 呼ぶ係”、Node＝“mount する係”。

---

## 4. 代表 CSI ドライバ比較

| ドライバ                   | 典型クラウド / オンプレ | 特徴                            | 試験Tip                           |
| ---------------------- | ------------- | ----------------------------- | ------------------------------- |
| **aws-ebs-csi-driver** | EKS           | Zonal EBS, `gp3` / `io2`      | Resize 要 `allowVolumeExpansion` |
| **csi-hostpath**       | kind / 学習用    | 擬似ストレージ、All-in-One            | 模試環境で頻出                         |
| **rook-ceph-csi**      | オンプレ / Edge   | RBD (block) + CephFS (shared) | RWX AccessMode 問題               |
| **longhorn**           | k3s / Rancher | UI あり、冗長レプリカ                  | シンプル RWX                        |

---

## 5. HOW — 30 分ハンズオン

### 5-1. Dynamic Provisioning

```yaml
# storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: {name: gp3}
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
allowVolumeExpansion: "true"
```

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: data}
spec:
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 5Gi}}
  storageClassName: gp3
```

```bash
kubectl apply -f storageclass.yaml -f pvc.yaml
kubectl get pvc,pv
```

### 5-2. Online Resize

```bash
kubectl patch pvc data -p '{"spec":{"resources":{"requests":{"storage":"8Gi"}}}}'
kubectl get pvc data -w   # STATUS → FileSystemResizePending → Bound
```

### 5-3. Snapshot & Restore (CSI Snapshotter)

```yaml
# snapshotclass.yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata: {name: ebs-snap}
driver: ebs.csi.aws.com
deletionPolicy: Delete
```

```bash
kubectl apply -f snapshotclass.yaml
kubectl create volumesnapshot snap1 --source-pvc=data --volume-snapshot-class=ebs-snap
kubectl get volumesnapshots
```

---

## 6. トラブルシュート “三段階”

| 症状                    | 切り分けポイント                          | コマンド                                              |
| --------------------- | --------------------------------- | ------------------------------------------------- |
| PVC Pending           | StorageClass name typo?           | `kubectl describe pvc …`                          |
| Pod ContainerCreating | Node plugin mount 失敗？             | `kubectl logs -l app=ebs-csi-node -n kube-system` |
| Resize stuck          | allowVolumeExpansion? Filesystem? | `kubectl describe pvc …` → Conditions             |

---

## 7. 試験チートシート

| 試験       | コマンド暗記2個                                                                                           |
| -------- | -------------------------------------------------------------------------------------------------- |
| **KCNA** | `kubectl get sc` / `kubectl explain pvc.spec.accessModes`                                          |
| **CKAD** | `kubectl run app --image nginx --dry-run=client -o yaml --restart=Never > pod.yaml` → 手で PVC Mount |
| **CKA**  | `kubectl patch sc gp3 -p '{"allowVolumeExpansion":true}'`                                          |
| **CKS**  | `kubectl annotate pvc data secret/…` (Secret-based encryption)                                     |

---

## 8. Self-Quiz (○×)

1. `ReadWriteMany` は **EBS** でサポートされる。
2. PVC を削除するとデフォルトで PV も削除される。
3. VolumeSnapshot は **CSI Driver が snapshotter sidecarを持つ場合のみ**利用可。

<details><summary>解答</summary>1:× (EFS/Rook-Ceph)  2:× (ReclaimPolicy 次第、Default=Delete ではない) 3:○</details>

---

## 9. まとめ & Next Up

* **StorageClass = 設計指針**, **PVC = チケット**, **PV = 実体**
* **CSI Sidecars** がないと機能欠如 (Snapshot/Resize) → クラウド Add-on を確認
* 実務 PoC は **hostPath → Rook-Ceph → Cloud Block** の順でレイヤを上げると理解が定着。

> “StatefulSet / Database on k8s” の設計ポイントや、PV 暗号化の詳細が必要な場合はお気軽に！
