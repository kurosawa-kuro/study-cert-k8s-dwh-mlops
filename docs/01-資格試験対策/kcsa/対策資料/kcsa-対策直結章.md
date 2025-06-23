### まず KCSA （Kubernetes and Cloud‑Native **Security** Associate）試験のドメインを整理

| ドメイン                                         | 出題比率 |                                     |
| -------------------------------------------- | ---- | ----------------------------------- |
| 1. **Overview of Cloud‑Native Security**     | 14 % |                                     |
| 2. **Kubernetes Cluster Component Security** | 22 % |                                     |
| 3. **Kubernetes Security Fundamentals**      | 22 % |                                     |
| 4. **Kubernetes Threat Model**               | 16 % |                                     |
| 5. **Platform Security**                     | 16 % |                                     |
| 6. **Compliance & Security Frameworks**      | 10 % | ([training.linuxfoundation.org][1]) |

---

## ご購入済み 8 講座 ― KCSA対策に直結する章（またはキーワード）

| 講座                                          | 推奨セクション／キーワード                                                                                                                        | 対応ドメイン  |                  |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------- | ---------------- |
| **Docker + Kubernetesで構築するWebアプリ実践講座**      | *「Kubernetesリソース」章* で Pod/Deployment/Service YAML 基礎を確認（後で Pod Security Standards を理解する足場）                                           | 3       |                  |
| **Kubernetes入門（2024/06更新）**                 | *「マネージドKubernetesクラスタの構築（EKS）」* でコントロールプレーン構成を把握<br>*「GitHub Actions+Argo CD」* で宣言的 CD の流れを確認（Admission Controller/Policy の位置付けが分かる） | 1, 5    |                  |
| **AWS x Kubernetes 実践！EKS 編**               | *IAM / IRSA / Secrets Manager 連携*（認証・認可）<br>*ALB Ingress + external‑dns*（接面における攻撃対象領域理解）                                             | 2, 3, 5 | ([udemy.com][2]) |
| **AWS EKS ハンズオン Best Practices**            | *RBAC & IRSA*（AuthN/AuthZ）<br>*Helm で Ingress + SSL*（TLS 終端）<br>*Prometheus/Grafana 監視*（Audit & Observability）                       | 2, 3, 5 | ([udemy.com][3]) |
| **手を動かして学ぶ Kubernetes on EKS**              | *eksctl でクラスタ作成 → Service 公開 (NodePort/LB)* を復習しつつ「ユーザ管理」節で `aws-auth` ConfigMap を確認                                                 | 2       | ([udemy.com][4]) |
| **実践！Kubernetes入門〜ローカル環境〜**                 | *ConfigMap / Secret ハンズオン*（静的シークレット管理）<br>*HPA 体験*（DoS 耐性の観点から負荷試験を兼ねる）                                                              | 3, 4    | ([udemy.com][5]) |
| **Amazon EKSではじめるKubernetes入門（Go×Next.js）** | *kustomize 導入* → 環境ごとに PSA/NetworkPolicy を差し込む演習に転用可                                                                                 | 5       | ([udemy.com][6]) |
| **超 Kubernetes 完全入門**                       | *Pod/Service/Ingress 基礎* の図解で Trust Boundary を整理<br>*命令的 vs 宣言的* の差異を理解し Admission Controller の意義を把握                                 | 1, 3    | ([udemy.com][7]) |

> **補足**
> *Threat Model* & *Compliance* ドメイン（計 26 %）は上記講座だけでは薄めです。
>  - \[CNCF/Kubernetes Threat Matrix ガイド] と \[NIST SP‑800‑190] を各自ざっと読んでおく
>  - 供給チェーンは **sig‑store / Cosign** の公式ブログを 30 分で流し読み
>  - PCI‑DSS, SOC2 等は「何を保護し、どの制御がマッピングされるか」を一枚図に出来れば十分

---

## 4 週間の学習モデル（1 日 1–1.5 h 平日＋週末ブースト）

| 週     | ゴール                         | 学習素材 & 演習                                                                                                                    |
| ----- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **1** | Pod Security & AuthN 基礎を固める | Docker+K8s講座 → ローカル入門（ConfigMap/Secret, RBAC の雰囲気を掴む）                                                                        |
| **2** | EKS コンポーネントをセキュアに組み立て       | EKS 入門2 講座で `eksctl` → IAM / IRSA / ALB / Secrets Manager 連携を一通りハンズオン                                                        |
| **3** | ポリシー適用 & 監視                 | Best Practices 講座で PSA レベル設定 → NetworkPolicy → Prometheus/Grafana/Audit 設定                                                   |
| **4** | 供給チェーン & ガバナンス              | kustomize + Helm (Argo CD optional) で署名済みイメージのデプロイ<br>Cosign 署名 → Policy Controller で拒否テスト<br>最後に模擬試験 60 問×2 周で 75 % 以上を安定確保 |

---

### 最後に ― KCSA 直前チェックリスト

1. **AuthN/AuthZ**: `ServiceAccount + IRSA`, `Role/RoleBinding`, `aws‑auth` ConfigMap を口頭説明できるか
2. **Pod Security**: “restricted/privileged/baseline” レベルと PSA フローを図で描けるか
3. **Network Policy**: Ingress/Egress 両方向のデフォルト挙動と `podSelector / namespaceSelector` の違い
4. **Supply‑Chain**: SBOM → Image signing (Cosign) → Admission Controller での検証ステップ
5. **Threat Scenarios**: DoS, Priv‑Esc, Etcd 直接アクセスを問われたら “隔離・監査・最小権限” で切り返す
6. **Frameworks**: CIS Benchmark / NIST‑SP‑800 系を “推奨構成ガイドライン vs 規制準拠” の対比で覚える

この順序で各講座の該当章だけを拾えば、**日本語だけで KCSA の 90 分択一を安全圏で突破** できます。健闘を祈ります！

[1]: https://training.linuxfoundation.org/certification/kubernetes-and-cloud-native-security-associate-kcsa/ "Kubernetes and Cloud Native Security Associate (KCSA) - Linux Foundation - Education"
[2]: https://www.udemy.com/course/kubernetes-eks/ "〖AWS x Kubernetes〗実践！Kubernetes入門〜Amazon EKS 編〜（DevOps入門） | Udemy"
[3]: https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/ "米シリコンバレーエンジニア監修！AWS EKS KubernetesハンズオンBest Practices | Udemy"
[4]: https://www.udemy.com/course/kubernetes-on-amazon-eks/ "手を動かして学ぶKubernetes on Amazon EKS | Udemy"
[5]: https://www.udemy.com/course/getting-started-kubernetes/ "〖Kubernetes初心者歓迎〗実践！Kubernetes入門〜ローカル環境で基礎から実践力を習得（DevOps入門） | Udemy"
[6]: https://www.udemy.com/course/kohekohe-eks-lesson/ "Amazon EKSではじめるKubernetes入門 〖Go×Next.js/コンテナで構築するフルスタックアプリ〗 | Udemy"
[7]: https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/ "米シリコンバレーDevOps監修！超Kubernetes完全入門〖優しい図解説とハンズオン〗 | Udemy"
