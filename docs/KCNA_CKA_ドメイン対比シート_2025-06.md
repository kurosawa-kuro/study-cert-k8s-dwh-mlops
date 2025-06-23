# KCNA‑JP ⇄ CKA‑JP 詳細ドメイン対比シート (2025‑06)

> **目的** : 管理者コース (CKA‑JP) にジャンプする際、KCNA‑JP で学んだ内容がどこまで通用し、どこが新規ドメインになるかを粒度細かく把握する。
>
> ✔︎ = 出題比率 10 % 以上の主要トピック △ = 軽く登場 / 準備知識 ✖︎ = KCNA 非出題

| #     | ドメイン / サブトピック                              | KCNA |   CKA   | **CKA で追加される深掘り**                                      | 参考 CLI / YAML コマンド例                              |
| ----- | ------------------------------------------ | :--: | :-----: | ------------------------------------------------------ | ------------------------------------------------ |
| **1** | **クラスタセットアップ**                             |  ✖︎  | ✔︎ 10 % | kubeadm init / join、control‑plane フラグ、etcd 証明書、サブネット設計 | `kubeadm init --pod-network-cidr=10.244.0.0/16`  |
| **2** | **トラブルシューティング**<br>Pod/Node/ControlPlane   |   △  | ✔︎ 30 % | ①node status、②core‑DNS、③kubelet 設定、④etcd restore       | `kubectl get events -A`, `etcdctl snapshot save` |
| **3** | **API オブジェクト基礎**<br>Pod/Deployment/Service |  ✔︎  |    ✔︎   | CKA では                                                 |                                                  |

* `kubectl patch`
* リソース更新履歴 (`kubectl rollout`) | `kubectl rollout history deploy nginx`
  `kubectl patch svc x -p '{"spec":...}'` |
  \| **4** | **RBAC & 認証認可** | △ 基本用語 | ✔︎ | ClusterRoleBinding, OIDC, TLS bootstrapping | `kubectl certificate approve csr-abc` |
  \| **5** | **ネットワーク**<br>CNIs / NetworkPolicy / Ingress | △ | ✔︎ | Cilium vs Calico 比較、CoreDNS 再構成、kube-proxy モード | `kubectl edit cm coredns -n kube-system` |
  \| **6** | **ストレージ**<br>PVC / StorageClass | △ | ✔︎ | CSI プラグイン、Dynamic Provisioning, etcd backup | `kubectl get sc`, `ETCDCTL_API=3 etcdctl snapshot save` |
  \| **7** | **リソース管理**<br>Quota / LimitRange / HPA | △ | ✔︎ | PriorityClass & Preemption、VerticalPodAutoscaler | `kubectl top pods`, `kubectl describe quota` |
  \| **8** | **セキュリティ基礎**<br>ConfigMap / Secret / PSS | ✔︎ | △ (**CKS で本格**) | kube‑api auditPolicy, PodSecurityAdmission enforced | `kubectl get podsecurityadmission` |
  \| **9** | **Observability**<br>Logs / Metrics / Events | △ | ✔︎ | journalctl, etcd & kubelet logs, `kubectl drain` 作業 | `journalctl -u kubelet`, `kubectl drain nodeX --ignore-daemonsets` |
  \| **10** | **アドオン / ツール**<br>Helm / Kustomize | △ | ✔︎ | Backup & upgrade via Helm chart、kustomize patches | `kustomize build . | kubectl apply -f -` |

---

## KCNA 知識 → CKA ハンズオン拡張の勉強ルート

1. **kubectl 基本コマンド再演習** (KCNA CLIベース)
2. **kubeadm Quick Lab** (Kind / Vagrant) で Control Plane 起動 → `kubectl get cs` でヘルス確認
3. **トラブルシュート模試** (killer.sh) を 1 周 → 失敗ログを KCNA ノートに追記

---

### 推奨学習リソース

| フェーズ              | リソース                                   | 理由                         |
| ----------------- | -------------------------------------- | -------------------------- |
| KCNA 基礎           | *KCNA-JP Crash Course*                 | 用語 & CLI 入門を 4 h で網羅       |
| CKA 深掘り           | *CKA Crash Course 2025* + killer.sh 模試 | ドメイン 1〜10 を短時間で回し本番形式チェック  |
| etcd/ControlPlane | Kubernetes the Hard Way (抜粋)           | kube‑api / etcd 証明書経路を図で理解 |

---

> 📝 **メモ欄** — ドキュメント内でさらに項目追加したい場合は「`❑` 未レビュー」とマークしてください。

### KCNA → CKAD 学習マッピング

*「CKAD Scope」カラムを追加しました。*

| 学習フェーズ            | 具体的に押さえる技術要素                                           | ゴールチェック例                       | **CKAD Scope**\*                              |
| ----------------- | ------------------------------------------------------ | ------------------------------ | --------------------------------------------- |
| 0. 前提ツール準備        | kind / minikube / kubectl CLI                          | `kubectl version --client` が通る | ─（準備のみ）                                       |
| 1. Kubernetes 全体像 | Control Plane / etcd / CoreDNS …                       | “宣言的に理想状態を保つ” を説明              | 🔶（前提知識）                                      |
| 2. 最小リソース         | **Pod** マニフェスト・ライフサイクル                                 | `kubectl explain pod …`        | ✔️                                            |
| 3. ワークロード定義       | **Deployment**, **Job / CronJob**, `kubectl rollout …` | イメージ更新→ロールバック                  | ✔️                                            |
| 4. サービス抽象化        | **Service**, **Ingress**, CoreDNS                      | Pod→Service 名解決                | ✔️                                            |
| 5. リソース構成         | **ConfigMap / Secret**, emptyDir / hostPath / **PVC**  | マウントと環境変数を確認                   | ✔️                                            |
| 6. 基本セキュリティ       | RBAC 用語, **ServiceAccount**, PSS 概念                    | SA 切替を実演                       | 🔶<br>- SA は出題対象<br>- RBAC/PSS は CKAD では原則出題外 |
| 7. リソース監視         | `kubectl get/describe/logs/top`                        | CrashLoop 原因特定                 | ✔️（Observability 15 %）                        |
| 8. アーキテクチャ選択肢     | Helm・Kustomize・ArgoCD など位置づけ                           | OSS 連携図示                       | ✖️                                            |
| 9. クラウドネイティブ原則    | Immutable Infra / GitOps …                             | “ペット vs 家畜” を説明                | ✖️                                            |
| 10. 簡易模試で仕上げ      | JP 模試 70 %↑                                            | 5 回平均 75 %                     | ─（学習手段）                                       |

\* **CKAD Scope:**
✔️ = 公式ドメインに含まれ直接出題対象 🔶 = 前提知識・部分的に活用 ✖️ = CKAD では原則問われない

---

### 使い方ヒント

* **✔️ 行**を重点的に再演習 → `kubectl run/apply`, probes, ConfigMap/Secret マウントなどは“反射で打てる”レベルへ。
* **🔶 行**は「用語理解＋軽い実演」で十分。
* **✖️ 行**は KCNA の概念理解用と割り切り、CKAD 直前は復習コストを掛けない。

これで「KCNA のどの学習が CKAD の時短に直結するか」を一目で把握できます。追加で深掘りしたいフェーズがあれば知らせてください！
