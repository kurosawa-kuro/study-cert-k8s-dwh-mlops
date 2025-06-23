### KCNAの出題領域をまず整理

KCNA (Kubernetes and Cloud‑Native Associate) は、5 つのドメインから多肢選択問題が出題されます ※括弧内は出題比率 ([training.linuxfoundation.org][1])

1. **Kubernetes Fundamentals (46 %)** – Pod/Deployment/Service などリソース操作と API／アーキテクチャの基礎
2. **Container Orchestration (22 %)** – ランタイム、ネットワーク、ストレージ、Service Mesh、セキュリティ
3. **Cloud‑Native Architecture (16 %)** – オートスケール、サーバーレス、コミュニティとガバナンス、OSS 標準
4. **Cloud‑Native Observability (8 %)** – Prometheus 系のメトリクス収集、コスト管理など
5. **Cloud‑Native Application Delivery (8 %)** – GitOps、CI/CD、Helm/Kustomize など

---

## ご購入済み 8 講座から「KCNA対策に直結する章」の抜粋

| 講座                                                                | KCNAドメインと合致する主な章（実際のセクション名／見出し）                                                                                                                                 | 補足                               |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| **Docker + Kubernetesで構築するWebアプリ実践講座** ([udemy.com][2])           | *「Kubernetesリソース」セクション*（Fundamentals）<br>*「Kubernetes開発時のデバッグ」*（Fundamentals＋Observability）                                                                     | Docker 基礎パートは試験対象外なので流し読みで可      |
| **Kubernetes入門（2024/06更新）** ([udemy.com][3])                      | *「Kubernetesの役割・概念」*（Fundamentals）<br>*「マネージドKubernetesクラスタの構築（EKS）」*（Cloud‑Native Arch.）<br>*「GitHub Actions+Argo CD CI/CD 例」*（App Delivery）                   | Mac 前提ですが内容は OS 非依存              |
| **AWS x Kubernetes　実践！Kubernetes入門〜Amazon EKS編** ([udemy.com][4]) | *「IAM / IRSA / ALB 連携」*（Container Orchestration ＋ Security）<br>*「external‑dns／Autoscaler」*（Cloud‑Native Arch.）<br>*「terraform/kustomize による IaC」*（App Delivery） | KCNA のクラウド実務系問に備えるのに最適           |
| **AWS EKS Kubernetes ハンズオン Best Practices** ([udemy.com][5])      | *「Prometheus/Grafana 監視」*（Observability）<br>*「Helm で Ingress + SSL 設定」*（App Delivery＋Orchestration）<br>*「RBAC / IRSA / HPA / CA」*（Security & Autoscaling）       | セキュリティ・監視比重が高く KCNA 後半ドメインを網羅    |
| **手を動かして学ぶ Kubernetes on Amazon EKS** ([udemy.com][6])            | *「eksctl でクラスター作成と公開」*（Cloud‑Native Arch.）<br>*「サービス公開 NodePort / LB」*（Orchestration）                                                                           | 基本操作の復習用。時間がなければ流し読みでも可          |
| **実践！Kubernetes入門〜ローカル環境で基礎から実践力を習得** ([udemy.com][7])            | *「Architecture をざっくり理解」*（Fundamentals）<br>*「HPA でスケーリング」*（Cloud‑Native Arch.）<br>*「Ingress・ConfigMap／Secret ハンズオン」*（Orchestration）                              | Minikube で集中して手を動かすと理解が早い        |
| **Amazon EKSではじめる Kubernetes入門 (Go×Next.js)** ([udemy.com][8])    | *「kustomize 導入」*（App Delivery）<br>*「EKS 概要／構築」*（Cloud‑Native Arch.）                                                                                             | Kustomize が KCNA の GitOps 出題に対応  |
| **超 Kubernetes 完全入門（図解とハンズオン）** ([udemy.com][9])                  | *「Kubernetes 基本リソース (Pod/Service/Ingress etc.)」*（Fundamentals）<br>*「Volume/PV/PVC」*（Orchestration・Storage）<br>*「命令的 vs 宣言的 (kubectl⇔YAML)」*（App Delivery）       | 図解が多く、用語整理に最適。Fundamentals の穴埋めに |

---

## 具体的な進め方（4 週間モデル）

| 週 | 学習リズム       | 使う講座／章                                               | ゴール                                                      |
| - | ----------- | ---------------------------------------------------- | -------------------------------------------------------- |
| 1 | 毎日1.5h      | 完全入門 → Docker+K8s 講座の K8s 章                          | リソース操作と API 用語を暗記レベルに                                    |
| 2 | 平日1h + 週末3h | Kubernetes入門(2024)＋ローカル入門                            | Pod ↔ Service ↔ Ingress の一連を Minikube で再現                |
| 3 | 平日1h + 週末4h | EKS入門 (2 講座)                                         | IRSA, ALB, external‑dns, Autoscaler を通しで手順書化             |
| 4 | 平日1h + 週末4h | EKS Best Practices 講座の Prometheus／Helm 章＋各講座 CI/CD 章 | Observability と GitOps (Argo CD / Helm / kustomize) を動かす |

> **演習メモ**
>
> * 各章を終えたら `kubectl get all -A` の実行結果をスクショ保存しておくと復習が容易。
> * KCNA は **CLI 実技は出ません** が、CLI を打てるレベルで用語を覚えると択一問題の選択肢判断が速くなります。

---

## 重要ポイントまとめ

* **Docker 部分は深入り不要** – KCNA では「コンテナとは何か」を説明できれば十分。
* **マネージドサービス (EKS) の基礎を 2 講座で押さえる** と Cloud‑Native Architecture ドメインの出題（Autoscaling／IAM 統合）が手堅い。
* **Observability は Prometheus/Grafana だけでも必ず手を動かす** – スクレイプ対象や ServiceMonitor などの単語がそのまま出るケースあり。
* **GitOps／CI/CD は Argo CD と kustomize/Helm に触る** – 出題は概念問題だが、実操作で覚えると複合設問に強い。
* **日本語資料が乏しい「Community & Governance」「Service Mesh」** は CNCF 公式ブログや Istio/Linkerd の概要記事でカバーすれば十分。

この順序で各講座の指定章を進めれば、日本語ベースで KCNA の全範囲を効率良くカバーできます。試験直前は **模擬試験 50 問×2 周** で得点感覚を掴み、60 分で 90 問を解くペースを体に覚えさせましょう。健闘を祈っています！

[1]: https://training.linuxfoundation.org/certification/kubernetes-cloud-native-associate/ "Kubernetes and Cloud Native Associate (KCNA) - Linux Foundation - Education"
[2]: https://www.udemy.com/course/web-application-with-docker-kubernetes/?srsltid=AfmBOopcRxO6XyJbf-0Vgq-d8u9_PhcR2I0JkLLYKaXOv5k7FryHmf44 "Docker + Kubernetes で構築する Webアプリケーション 実践講座 | Udemy"
[3]: https://www.udemy.com/course/kubernetes-basics-2021/ "Kubernetes入門 | Udemy"
[4]: https://www.udemy.com/course/kubernetes-eks/ "〖AWS x Kubernetes〗実践！Kubernetes入門〜Amazon EKS 編〜（DevOps入門） | Udemy"
[5]: https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/ "米シリコンバレーエンジニア監修！AWS EKS KubernetesハンズオンBest Practices | Udemy"
[6]: https://www.udemy.com/course/kubernetes-on-amazon-eks/ "手を動かして学ぶKubernetes on Amazon EKS | Udemy"
[7]: https://www.udemy.com/course/getting-started-kubernetes/ "〖Kubernetes初心者歓迎〗実践！Kubernetes入門〜ローカル環境で基礎から実践力を習得（DevOps入門） | Udemy"
[8]: https://www.udemy.com/course/kohekohe-eks-lesson/ "Amazon EKSではじめるKubernetes入門 〖Go×Next.js/コンテナで構築するフルスタックアプリ〗 | Udemy"
[9]: https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/ "米シリコンバレーDevOps監修！超Kubernetes完全入門〖優しい図解説とハンズオン〗 | Udemy"
