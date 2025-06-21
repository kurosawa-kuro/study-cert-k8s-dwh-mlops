### `cncf-landscape-overview.md` — CNCF Landscape 全体俯瞰ガイド

*KCNA／KCSA／CKA で「プロジェクト名をカテゴリで即答できる」状態を目指すサマリー。
A4 2 枚で印刷しやすいよう、カテゴリ表＋暗記フレーム付き。*

---

## 1. Why ― なぜ Landscape を知るべきか

| 試験             | 典型出題パターン                                 |
| -------------- | ---------------------------------------- |
| **KCNA**       | *「Prometheus はどのカテゴリ？」* のような“分類クイズ”      |
| **KCSA / CKS** | *「Istio と Cilium の違いは？」* → セキュリティ特性を語る   |
| **CKA**        | 運用課題で *「CNI を Calico→Cilium に置換」* 等の設計判断 |

---

## 2. 公式カテゴリ早見表（主要 OSS 例のみ）

| #     | カテゴリ                           | 代表 OSS (5 つ以内)                                      |
| ----- | ------------------------------ | --------------------------------------------------- |
| **A** | **App Definition & Dev**       | Helm, Kustomize, Argo CD, Cloud-Native Buildpacks   |
| **B** | **Orchestration & Management** | Kubernetes, K3s, Crossplane, OpenShift              |
| **C** | **Runtime**                    | containerd, CRI-O, gVisor, WasmEdge                 |
| **D** | **Provisioning**               | Terraform, Pulumi, Cluster-API                      |
| **E** | **Observability & Analysis**   | Prometheus, Loki, OpenTelemetry, Jaeger, Grafana    |
| **F** | **DB & Messaging**             | Vitess, TiDB, Kafka, NATS                           |
| **G** | **Network & Service Mesh**     | Cilium, Calico, Istio, Linkerd, Envoy               |
| **H** | **Storage**                    | Rook-Ceph, OpenEBS, Longhorn                        |
| **I** | **Security & Compliance**      | Falco, Trivy, Kyverno, OPA Gatekeeper, cert-manager |
| **J** | **Edge & IoT**                 | KubeEdge, OpenYurt                                  |
| **K** | **Chaos & Reliability**        | LitmusChaos, Chaos Mesh                             |

> **覚え方：**
> A→K の “アルファベット順” を目で追いながら、**K8s ワークフロー**に沿って思い浮かべると定着が早い。
> *例:* ①Dev→②Provision→③Runtime→④O\&M→⑤Obs→⑥Sec の順にアプリが流れるイメージ。

---

## 3. 暗記フレーム：6 ステップでフル Landscape を頭に入れる

1. **印刷 & 指差し** 公式 PNG を A3 で印刷。
2. **カバーチャート法** カテゴリ名を紙で隠し、OSS を見て逆当て。
3. **1 日 1 カテゴリ** Slack などで「今日は Networking」など宣言してアウトプット。
4. **OSS⇆ユースケースで接続** *Prometheus = Metrics 時系列* と短語で紐付ける。
5. **“3+1” ルール** カテゴリごとに **必修 3 つ + 補欠 1 つ** だけ覚える。
6. **白紙スケッチ** 全カテゴリと代表 OSS を 5 分で手書き → 90 % 埋まれば OK。

---

## 4. Hands-on ミニ演習（カテゴリ→CLI 体感）

| カテゴリ           | 体験コマンド                                                            | 何が分かるか                     |
| -------------- | ----------------------------------------------------------------- | -------------------------- |
| Observability  | `kubectl exec -it <prom-pod> -- promtool tsdb status /prometheus` | TSDB 内部を可視化                |
| Network & Mesh | `cilium status` → `cilium monitor`                                | Pod-to-Pod Flow をリアルタイム観察  |
| Security       | `trivy image nginx:latest`                                        | CVE スキャンの結果フォーマット          |
| Storage        | `kubectl get sc` → `kubectl describe sc rook-ceph-block`          | CSI Driver がどう PV を動的生成するか |

---

## 5. 90 秒セルフチェック（○×形式）

1. Kyverno は **Security** カテゴリである。
2. containerd は **Runtime** に属する。
3. Crossplane は **Provisioning** ではなく **Orchestration** に分類される。
4. OpenTelemetry は **Tracing** だけを扱うプロジェクトである。

<details><summary>回答</summary>1:○ 2:○ 3:× 4:×（Metrics/Logs/Trace 全部）</details>

---

## 6. まとめ & 次アクション

* **KCNA 受験前に “3+1” ルール** を必ず完了 → 出題の 90 % をカバー。
* **KCSA/CKS では Security カテゴリを掘り下げ**：Trivy DB、OPA Rego、Falco Rules の理解へ。
* **CKA/CKAD 持ちなら** Helm・Kustomize・Argo CD といった **App Definition & Dev** カテゴリを実務で触り、CLI 操作を身体で覚える。

> さらに詳細な OSS ごとの比較表や、あなたの案件に合わせた“組み合わせ設計図”が必要であれば遠慮なくリクエストしてください！
