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
