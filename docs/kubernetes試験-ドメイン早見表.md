# Kubernetes 試験ドメイン早見シート (KCNA‑JP → CKS‑JP)

> **目的** : KCNA‑JP／KCSA が後続の CKAD‑JP／CKA‑JP／CKS‑JP で “どのトピックの予習” になるかを一目で把握する。
>
> * ✔︎ = 試験範囲に含まれる（主要ドメイン）
> * △ = 軽く登場／周辺知識として理解必須

| 技術トピック (公式ドメイン)                                    | KCNA | KCSA | CKAD | CKA | CKS | **重複ポイント / 予習効果**                                             |
| -------------------------------------------------- | :--: | :--: | :--: | :-: | :-: | ------------------------------------------------------------- |
| **k8s API オブジェクト基礎**<br>Pod / Deployment / Service |  ✔︎  |   △  |  ✔︎  |  ✔︎ |  △  | KCNA で用語と YAML 構造を学ぶ → CKAD/CKA で CLI 操作が時短                   |
| **CNCF Landscape 概論**                              |  ✔︎  |   △  |   △  |  △  |  △  | KCNA のエコシステム知識が上位試験のツール選定問題で役立つ                               |
| **Pod Security Standards / PSS**                   |   △  |  ✔︎  |   △  |  △  |  ✔︎ | KCSA で“restricted”等級を習得 → CKS の PSP/PSS 演習で即応用                |
| **RBAC / ServiceAccount**                          |   △  |  ✔︎  |   △  |  ✔︎ |  ✔︎ | KCSA で原理 → CKA で管理タスク → CKS の強制ポリシー設定へ発展                      |
| **NetworkPolicy & Ingress**                        |   △  |  ✔︎  |  ✔︎  |  ✔︎ |  ✔︎ | KCSA で allow/deny 概念 → CKAD/CKA で YAML 手書き → CKS で監査強化        |
| **ConfigMap / Secret**                             |  ✔︎  |  ✔︎  |  ✔︎  |  ✔︎ |  ✔︎ | KCNA の基礎 + KCSA の暗号化 at‑rest → CKAD/CKA で Volume/Env 実装       |
| **Observability (Probe / Logs / Metrics)**         |   △  |   △  |  ✔︎  |  ✔︎ |  ✔︎ | KCNA 用語 → CKAD readiness/liveness → CKS で Falco/Trivy メトリクス連携 |
| **Cluster Setup / kubeadm**                        |  ✖︎  |  ✖︎  |  ✖︎  |  ✔︎ |  ✔︎ | KCNA 無。CKA/CKS で初出。                                           |
| **etcd Backup / Restore**                          |  ✖︎  |  ✖︎  |  ✖︎  |  ✔︎ |  △  | CKA が初出。KCSA のセキュリティ原理は背景知識として有効。                             |
| **Supply‑Chain Security (cosign, SBOM)**           |  ✖︎  |  ✔︎  |  ✖︎  |  △  |  ✔︎ | KCSA で概念 → CKS で実コマンド (cosign sign/verify)                    |
| **Application Design (Sidecar / Init)**            |   △  |  ✖︎  |  ✔︎  |  △  |  △  | KCNA の multi‑container を CKAD で実装深掘り                          |
| **Resource Quota / LimitRange**                    |   △  |  ✔︎  |  ✔︎  |  ✔︎ |  ✔︎ | KCSA で制限理由 → CKAD/CKA で YAML & CLI 作業                         |

---

## 予習チェーンまとめ

* **KCNA → CKAD/CKA** : API 基礎・用語・マニフェスト構造がそのまま時間短縮。
* **KCSA → CKS** : セキュリティ系（PSS/RBAC/NetworkPolicy/Supply‑Chain）が 80 % 以上重複。KCSA で “何を守るか” を押さえ、CKS で “どう守るか（コマンド）” を習得。
* **KCSA → CKAD/CKA** : ConfigMap/Secret/RBAC の概念が先取りされているため YAML 作業で迷いにくい。

> 🔍 **使い方**
>
> 1. KCNA/KCSA 学習時に ✔︎ 行を**単語帳**へ反映。
> 2. CKAD/CKA のハンズオンで「これ KCNA で見た！」という項目を**時短パターン**に登録。
> 3. CKS 直前に KCSA 資料をリフレッシュし **Supply‑Chain** と **PSS** セクションを重点復習。

---

### 参考：出題比率 quick look

* **KCNA** : Design 46 % / Observability 10 % / Services 10 % / etc.
* **KCSA** : Cluster Security 23 % / Supply‑Chain 17 % / Workload 25 % / ...
* **CKAD** : Design+Build 40 % / Services+Networking 20 % / ...
* **CKA** : Cluster Setup 10 % / Troubleshoot 30 % / ...
* **CKS** : Cluster Hardening 15 % / Runtime 20 % / Supply‑Chain 20 %

取りこぼし防止に活用してください。
