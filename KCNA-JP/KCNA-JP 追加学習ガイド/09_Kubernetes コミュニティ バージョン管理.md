### `k8s-community-versioning.md` — Kubernetes コミュニティ & バージョン管理ガイド

*CKA／KCNA／KCSA で問われる “誰がどうやって Kubernetes を進化させているか” を 1 ファイルにまとめました。*

---

## 1. CNCF ↔ Kubernetes プロジェクトの関係図

```
CNCF (Linux Foundation)
  └─ TOC (Technical Oversight Committee)
        └─ Kubernetes Steering Committee (方向性)
              ├─ SIG-* (Special Interest Groups)
              └─ WG-*  (Working Groups, 横串課題)
```

* **CNCF**：財団・商標管理
* **Steering**：憲章・ガバナンス
* **SIG**：日常開発の実働部隊
* **WG**：タイムボックスで課題解決

---

## 2. 主要 SIG 一覧（試験で名前を見かけるもの）

| SIG             | 主担当領域                           | 代表成果物                                |
| --------------- | ------------------------------- | ------------------------------------ |
| **SIG-Apps**    | Deployment/Job/DaemonSet コントローラ | `kubectl rollout`, cron improvements |
| **SIG-Node**    | kubelet, cgroup, CRI            | cgroup v2 / MemoryQoS                |
| **SIG-Auth**    | RBAC, OIDC, Admission           | Pod Security Standards               |
| **SIG-Storage** | CSI, Snapshot, Resize           | VolumeSnapshot API                   |
| **SIG-Network** | Service/EndpointSlice/CNI       | IPv6 Dual-Stack, kube-proxy IPVS     |
| **SIG-Release** | リリースサイクル、CI                     | krel, patch releases                 |

---

## 3. Kubernetes Enhancement Proposal (KEP) ワークフロー

```
PR to k/enhancements/keps/NNNN-my-feature.md
      │
      ├─➔ [stage: provisional]
      │     SIG discussion / reviewers
      │
      ├─➔ [stage: implementable]
      │     Feature flag / alpha code lands
      │
      ├─➔ [stage: beta]
      │     Enabled-by-default, docs & tests
      │
      └─➔ [stage: stable]
            Flag removal, API v1
```

> **試験覚え方**： ***P-I-B-S***（Provisional → Implementable → Beta → Stable）

---

## 4. リリースサイクル & Version Skew Policy

| 項目                | 値                                                                              | 備考                        |
| ----------------- | ------------------------------------------------------------------------------ | ------------------------- |
| **リリース頻度**        | **4 ヵ月**（年 3 回）                                                                | v1.30 → v1.31 → v1.32 …   |
| **サポート期間**        | **1 年**（N-3）                                                                   | v1.32 最新なら v1.29 まで patch |
| **Version Skew**  | kube-apiserver ≥ kubelet by ≤ 1 minor<br>kubectl ≥ kube-apiserver by ≤ 1 minor | CKA 模試で頻出                 |
| **Patch Tuesday** | 毎月第二火曜 (Asia 時間水曜)                                                             | CVE 修正                    |

---

## 5. Feature Gates & API Deprecation

| 状態              | FeatureGate 値                                  | API 寿命                |
| --------------- | ---------------------------------------------- | --------------------- |
| **Alpha**       | `--feature-gates=X=true` (disabled by default) | 0.9 cycles 保証なし       |
| **Beta**        | Enabled by default, can disable                | ≥1 リリース               |
| **GA / Stable** | 常時 ON, Flag removed                            | Deprecation 約束 (≥1 年) |

---

## 6. コントリビューション最小ステップ

1. **Fork & Branch**
2. `git commit -s`（DCO署名必須）
3. `/assign @reviewer` `/ok-to-test` via prow bot
4. CI (Prow + TestGrid) green → `/lgtm` `/approve` でマージ

> ★ **Good First Issue** ラベルから始めると 1 ～ 2 週間で初 PR 成功しやすい。

---

## 7. 試験チート

| 試験       | よく出るワード                                     | 一言回答                                  |
| -------- | ------------------------------------------- | ------------------------------------- |
| **KCNA** | *“N-3 support”*                             | 最新 1.32 → 1.29 まで patch 対象            |
| **KCSA** | *“Who maintains PodSecurity?”*              | SIG-Auth                              |
| **CKA**  | *“Kubelet skew allowed?”*                   | ≤1 minor below apiserver              |
| **CKS**  | *“Feature gate to enable seccomp default?”* | `--feature-gates=SeccompDefault=true` |

---

## 8. Hands-On — Version Skew Check

```bash
# Current components
kubectl version --short
# Cluster support window
curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt
# Kubelet skew validation
kubelet --version
```

---

## 9. Self-Quiz (○×)

1. v1.31 が最新時、v1.27 は公式パッチを受け取れる。
2. Beta API は通知なく削除され得る。
3. SIG-Release が毎月 patch バージョンを切る。

<details><summary>解答</summary>1:× (N-3 = 1.28まで) 2:× (1リリース猶予) 3:○ </details>

---

## 10. まとめ

* **SIG → KEP → FeatureGate → Release** の流れを辿れば「新機能いつ安定？」が予測できる
* 実務でバージョン選定する際は **N-2** を最低ラインに
* コントリビューションは **Issue→KEP→PR** の順を守ればスムーズ

> さらに “KEP テンプレを埋める演習” や “自前 CI で k/k PR テスト” が必要なら続編をリクエストしてください！
