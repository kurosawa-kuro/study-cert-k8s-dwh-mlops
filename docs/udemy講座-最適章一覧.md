以下では **KCNA‑JP／KCSA／CKA‑JP／CKAD‑JP／CKS‑JP** の５資格について、  
(1) 試験ブループリントの主要ドメイン（2025‑02改訂版）  
(2) ユーザーが既に購入済みの Udemy 日本語講座の中で、そのドメインの “知識の穴埋め” に最適な **コース名と該当章（セクション）**  
――を対応付けて整理しました。  
章タイトルは Udemy の公開カリキュラムや受講者メモから取得したものを和訳・要約しています（番号はコース側のセクション番号）。

---

## 1. KCNA‑JP（Kubernetes & Cloud Native Associate）

|ブループリント・ドメイン|重み|おすすめ講座 & 章|
|---|---|---|
|Kubernetes Fundamentals|46 %|**Kubernetes入門**  1. 「Kubernetesの役割・概念」  2. 「kubectl 基本操作」([udemy.com](https://www.udemy.com/course/kubernetes-basics-2021/?srsltid=AfmBOooj5QlmEyEKsJG2j42lnXm39dy-dFjgCDbmgTNU9hFP6QSqcZ-b&utm_source=chatgpt.com "Kubernetes入門 - Udemy"))**Docker + Kubernetes 実践講座**  1. 「Docker 基礎」  3. 「Minikube と Pod / Deployment / Service」([udemy.com](https://www.udemy.com/course/web-application-with-docker-kubernetes/?srsltid=AfmBOopfwmoqCi9OpJOv39CrY8IuXavc0AqY-o_3-XHPbrbyc-LuCLm6&utm_source=chatgpt.com "Docker + Kubernetes で構築する Webアプリケーション 実践講座"))|
|Container Orchestration|22 %|**Getting Started Kubernetes**  2. 「minikube でローカルクラスタ」  3. 「Deployment / Service / Ingress」([udemy.com](https://www.udemy.com/course/getting-started-kubernetes/?srsltid=AfmBOorVS26hU1QmENzJJV6kR6h1MB-1FQ2NqIrsl0FujyAImJpLJe5z&utm_source=chatgpt.com "ローカル環境で基礎から実践力を習得（DevOps入門） \| Udemy"))|
|Cloud Native Architecture|16 %|**Kubernetes入門** 5. 「EKS クラスタ構築」＋ 6. 「GitHub Actions & Argo CD で CI/CD」([udemy.com](https://www.udemy.com/course/kubernetes-basics-2021/?srsltid=AfmBOooj5QlmEyEKsJG2j42lnXm39dy-dFjgCDbmgTNU9hFP6QSqcZ-b&utm_source=chatgpt.com "Kubernetes入門 - Udemy"))|
|Observability|8 %|**Kubernetes入門** 3. 「デバッグ&ログ取得」([udemy.com](https://www.udemy.com/course/kubernetes-basics-2021/?srsltid=AfmBOooj5QlmEyEKsJG2j42lnXm39dy-dFjgCDbmgTNU9hFP6QSqcZ-b&utm_source=chatgpt.com "Kubernetes入門 - Udemy"))|
|Application Delivery (GitOps/CI‑CD)|8 %|**Jenkins CICD Pipeline in Kubernetes AWS EKS** 全章（パイプライン構築と ArgoCD 連携）|

> **学習順の推奨**：Docker→Kubernetes入門→Getting Started→Jenkins CI/CD で KCNA 範囲をひと通り網羅。

---

## 2. KCSA（Kubernetes & Cloud Native Security Associate）

| ブループリント・ドメイン                           | 重み   | おすすめ講座 & 章                                                                                                                                                                                                                                                                                                                           |
| -------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ① Cloud Native Security 概論             | 14 % | **Kubernetes Docker/Container DevOps 完全入門**  1. 「4C のセキュリティモデルと Linux 基本」([udemy.com](https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/?srsltid=AfmBOoqvR3wU7vCfRqwhdcgLv0SqxYimdeQ1aMn_EM_gGo2bINX-Mpvl&utm_source=chatgpt.com "米シリコンバレーDevOps監修！超Kubernetes完全入門【優しい図 ..."))                           |
| ② Cluster Component Security           | 22 % | **AWS EKS Kubernetes DevOps Best Practices**  3. 「EKS クラスタ設定と IAM / OIDC」([udemy.com](https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/?srsltid=AfmBOoqS9RdTziA0CrmIMPYvt42XznanNcnUs22eYY8ymqgY10XLBl7P&utm_source=chatgpt.com "米シリコンバレーエンジニア監修！AWS EKS Kubernetes ... - Udemy"))                  |
| ③ Kubernetes Security Fundamentals     | 22 % | **Advanced Terraform AWS EKS VPC**  4. 「NetworkPolicy / RBAC / Secrets 管理」([udemy.com](https://www.udemy.com/course/advanced-terraform-aws-eks-vpc-devops-iac-best-practices-japanese/?srsltid=AfmBOorg364Ydi_YW1aCsojEukg2-craZJsXAlk1izjtBoPD_X8vE55K&utm_source=chatgpt.com "米シリコンバレーDevOps監修！上級編Terraform + AWS EKS + VPC ...")) |
| ④ Threat Model                         | 16 % | **Istio Service Mesh ハンズオン**  5. 「Fault Injection & Circuit Breaker」  6. 「mTLS / JWT 認証」([udemy.com](https://www.udemy.com/course/istio-service-mesh-kubernetes-aws-eks-2020-handson/?srsltid=AfmBOooDz0dtph9KRNuTSzkcxROGPz_b1gmVArXl9UFQ9KoCKGf5KRKF&utm_source=chatgpt.com "米シリコンバレーDevOps監修！Istio Service Mesh ハンズオン+ ..."))     |
| ⑤ Platform Security（SCM/Observability） | 16 % | 同上 Istio コース＋ Jenkins CICD コースの SBOM 生成章                                                                                                                                                                                                                                                                                             |
| ⑥ Compliance & Frameworks              | 10 % | **AWS 入門 (Cloud Practitioner)** で AWS Well‑Architected / CIS Benchmark ギャップを整理                                                                                                                                                                                                                                                       |

---

## 3. CKA‑JP（Administrator）

|ドメイン|重み|おすすめ講座 & 章|
|---|---|---|
|Cluster Arch., Install & Config|25 %|**Kubernetes on Amazon EKS**  4. 「kubeadm ベースの HA Control Plane」([udemy.com](https://www.udemy.com/course/kubernetes-eks/?srsltid=AfmBOoraI1bOHAfCFGb25spHAtTgR75CVmETyth_MPLi4AFB_Iz2rrTJ&utm_source=chatgpt.com "【AWS x Kubernetes】実践！Kubernetes入門〜Amazon EKS 編"))**Advanced Terraform AWS EKS VPC** 全般|
|Workloads & Scheduling|15 %|**Kubernetes入門** 2.「Deployment と Rolling Update」([udemy.com](https://www.udemy.com/course/kubernetes-basics-2021/?srsltid=AfmBOooj5QlmEyEKsJG2j42lnXm39dy-dFjgCDbmgTNU9hFP6QSqcZ-b&utm_source=chatgpt.com "Kubernetes入門 - Udemy"))|
|Services & Networking|20 %|**Istio Service Mesh ハンズオン** 1–3 章（Service, Ingress, Gateway）([udemy.com](https://www.udemy.com/course/istio-service-mesh-kubernetes-aws-eks-2020-handson/?srsltid=AfmBOooDz0dtph9KRNuTSzkcxROGPz_b1gmVArXl9UFQ9KoCKGf5KRKF&utm_source=chatgpt.com "米シリコンバレーDevOps監修！Istio Service Mesh ハンズオン+ ..."))|
|Storage|10 %|**Docker + Kubernetes 実践講座** 5. 「永続ボリュームと StatefulSet」([udemy.com](https://www.udemy.com/course/web-application-with-docker-kubernetes/?srsltid=AfmBOopfwmoqCi9OpJOv39CrY8IuXavc0AqY-o_3-XHPbrbyc-LuCLm6&utm_source=chatgpt.com "Docker + Kubernetes で構築する Webアプリケーション 実践講座"))|
|Troubleshooting|30 %|**AWS EKS Kubernetes DevOps Best Practices** 終盤「CloudWatch & Prometheus 監視」([udemy.com](https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/?srsltid=AfmBOoqS9RdTziA0CrmIMPYvt42XznanNcnUs22eYY8ymqgY10XLBl7P&utm_source=chatgpt.com "米シリコンバレーエンジニア監修！AWS EKS Kubernetes ... - Udemy"))|

---

## 4. CKAD‑JP（Application Developer）

|ドメイン|重み|おすすめ講座 & 章|
|---|---|---|
|Application Design & Build|20 %|**Docker + Kubernetes 実践講座** 2. 「Dockerfile 最適化と multi‑stage ビルド」([udemy.com](https://www.udemy.com/course/web-application-with-docker-kubernetes/?srsltid=AfmBOopfwmoqCi9OpJOv39CrY8IuXavc0AqY-o_3-XHPbrbyc-LuCLm6&utm_source=chatgpt.com "Docker + Kubernetes で構築する Webアプリケーション 実践講座"))|
|Application Deployment|20 %|**CKAD Certification Kubernetes**（日本語字幕付き）セクション 3–5|
|Observability & Maintenance|15 %|**Kubernetes入門** 3. 「プローブ & ロギング」|
|Env., Config & Security|25 %|**Kubernetes入門** 2‑B. 「ConfigMap / Secret / ServiceAccount」([udemy.com](https://www.udemy.com/course/kubernetes-basics-2021/?srsltid=AfmBOooj5QlmEyEKsJG2j42lnXm39dy-dFjgCDbmgTNU9hFP6QSqcZ-b&utm_source=chatgpt.com "Kubernetes入門 - Udemy"))|
|Services & Networking|20 %|**Getting Started Kubernetes** 3‑B. 「Ingress と NetworkPolicy」([udemy.com](https://www.udemy.com/course/getting-started-kubernetes/?srsltid=AfmBOorVS26hU1QmENzJJV6kR6h1MB-1FQ2NqIrsl0FujyAImJpLJe5z&utm_source=chatgpt.com "ローカル環境で基礎から実践力を習得（DevOps入門） \| Udemy"))|

---

## 5. CKS‑JP（Security Specialist）

|ドメイン|重み|おすすめ講座 & 章|
|---|---|---|
|Cluster Setup & Hardening|30 %|**Advanced Terraform AWS EKS VPC** 5. 「CIS Benchmarks 適用」([udemy.com](https://www.udemy.com/course/advanced-terraform-aws-eks-vpc-devops-iac-best-practices-japanese/?srsltid=AfmBOorg364Ydi_YW1aCsojEukg2-craZJsXAlk1izjtBoPD_X8vE55K&utm_source=chatgpt.com "米シリコンバレーDevOps監修！上級編Terraform + AWS EKS + VPC ..."))|
|System Hardening|10 %|**AWS EKS Kubernetes DevOps Best Practices** 4–6. 「ノード OS Hardening & seccomp/apparmor」([udemy.com](https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/?srsltid=AfmBOoqS9RdTziA0CrmIMPYvt42XznanNcnUs22eYY8ymqgY10XLBl7P&utm_source=chatgpt.com "米シリコンバレーエンジニア監修！AWS EKS Kubernetes ... - Udemy"))|
|Minimize Micro‑service Vulnerabilities|20 %|**Istio Service Mesh ハンズオン** 6. 「mTLS で Pod‑to‑Pod 暗号化」([udemy.com](https://www.udemy.com/course/istio-service-mesh-kubernetes-aws-eks-2020-handson/?srsltid=AfmBOooDz0dtph9KRNuTSzkcxROGPz_b1gmVArXl9UFQ9KoCKGf5KRKF&utm_source=chatgpt.com "米シリコンバレーDevOps監修！Istio Service Mesh ハンズオン+ ..."))|
|Supply‑Chain Security|20 %|**Jenkins CICD Pipeline in Kubernetes** 終盤「Image Scanning, SBOM, Sign」|
|Incident Response & Observability|20 %|**Kubernetes Docker/Container DevOps 完全入門** 後半「Audit Logging & Falco 入門」|

---

### 補足と学習戦略

1. **試験順序**  
    KCNA → CKAD → CKA → KCSA → CKS の順に進むと、運用より開発よりセキュリティへとスムーズに深掘りできます。
    
2. **反復用メモレポ**  
    それぞれの Udemy 章が終わったら `~/KCNA-notes`, `~/CKA-labs` などディレクトリを分けて _kubectl コマンド集_ と _manifests_ を Git 管理すると再現性◎。
    
3. **公式ハンドブック併読**  
    Linux Foundation の Candidate Handbook（KCNA/CKA など）を必ず並行チェックし、ブループリントが更新された場合は上表の “重み” を再計算してください。([training.linuxfoundation.org](https://training.linuxfoundation.org/certification/kubernetes-cloud-native-associate/ "Kubernetes and Cloud Native Associate (KCNA) - Linux Foundation - Education"), [training.linuxfoundation.org](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/ "Certified Kubernetes Administrator (CKA) - Linux Foundation - Education"), [training.linuxfoundation.org](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/ "Certified Kubernetes Application Developer (CKAD) - Linux Foundation - Education"), [training.linuxfoundation.org](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/ "Certified Kubernetes Security Specialist (CKS) - Linux Foundation - Education"), [training.linuxfoundation.org](https://training.linuxfoundation.org/certification/kubernetes-and-cloud-native-security-associate-kcsa/ "Kubernetes and Cloud Native Security Associate (KCSA) - Linux Foundation - Education"))
    

これで手持ち講座の **どこを見ればどの資格のどのドメインを補完できるか** 一目で分かります。  
ハンズオンをこなしつつ、章末クイズや模擬試験のスコアが 90 % を切る領域を中心に上表を往復復習すると効率良く合格ラインに到達できます。

### KCNA - JP 向けに参照している Udemy コース

| # | コース名                                          | URL                                                                                                                                                                  |
| - | --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1 | Kubernetes入門                                  | [https://www.udemy.com/course/kubernetes-basics-2021/](https://www.udemy.com/course/kubernetes-basics-2021/)                                                         |
| 2 | Docker + Kubernetes で構築する Webアプリケーション 実践講座    | [https://www.udemy.com/course/web-application-with-docker-kubernetes/](https://www.udemy.com/course/web-application-with-docker-kubernetes/)                         |
| 3 | Getting Started Kubernetes（ローカル環境で基礎から実践力を習得） | [https://www.udemy.com/course/getting-started-kubernetes/](https://www.udemy.com/course/getting-started-kubernetes/)                                                 |
| 4 | Jenkins CICD Pipeline in Kubernetes AWS EKS   | [https://www.udemy.com/course/jenkins-cicd-pipeline-in-kubernetes-aws-eks-devops/](https://www.udemy.com/course/jenkins-cicd-pipeline-in-kubernetes-aws-eks-devops/) |

---

### KCSA 向けに参照している Udemy コース

| # | コース名                                                | URL                                                                                                                                                                                                      |
| - | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1 | Kubernetes Docker/Container DevOps 完全入門             | [https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/](https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/)                                         |
| 2 | AWS EKS Kubernetes DevOps Best Practices            | [https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/](https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/)                                 |
| 3 | Advanced Terraform AWS EKS VPC (IaC Best Practices) | [https://www.udemy.com/course/advanced-terraform-aws-eks-vpc-devops-iac-best-practices-japanese/](https://www.udemy.com/course/advanced-terraform-aws-eks-vpc-devops-iac-best-practices-japanese/)       |
| 4 | Istio Service Mesh ハンズオン（Kubernetes × AWS EKS）      | [https://www.udemy.com/course/istio-service-mesh-kubernetes-aws-eks-2020-handson/](https://www.udemy.com/course/istio-service-mesh-kubernetes-aws-eks-2020-handson/)                                     |
| 5 | AWS 入門 – AWS Certified Cloud Practitioner 対策        | [https://www.udemy.com/course/aws-nyumon-beginner-cloud-practitioner-ec2-vpc-rds-s3-elb-lambda-iam/](https://www.udemy.com/course/aws-nyumon-beginner-cloud-practitioner-ec2-vpc-rds-s3-elb-lambda-iam/) |

---

上記９コースが **KCNA と KCSA の学習ロードマップ** で引用している Udemy 講座です。
ブックマークや学習メモ整理の際にご活用ください。

### 9 コース “実装難易度” ランキング

*(左ほど **やさしい** → 右ほど **手ごわい**／事前知識が多く必要)*

| 順位    | コース名                                                                                                                                                       | おおまかな理由・前提                                                       |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **1** | [**AWS 入門 – AWS Certified Cloud Practitioner 対策**](https://www.udemy.com/course/aws-nyumon-beginner-cloud-practitioner-ec2-vpc-rds-s3-elb-lambda-iam/)     | クラウド慣れしていない人向けに概念中心。AWSコンソール操作が主で、コードも k8s も不要。                  |
| **2** | [**Kubernetes入門**](https://www.udemy.com/course/kubernetes-basics-2021/)                                                                                   | 「Pod／Service とは？」という超基礎と `kubectl` 基本操作が中心。ローカルPCだけで完結。          |
| **3** | [**Getting Started Kubernetes（ローカル環境で基礎から実践力を習得）**](https://www.udemy.com/course/getting-started-kubernetes/)                                              | Minikube でマニフェストを手書きしながら学ぶ実践編。基本概念を掘り下げつつも単一ノード。                 |
| **4** | [**Kubernetes Docker/Container DevOps 完全入門**](https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/)                              | Docker→K8s→CI の流れを網羅。Linux コマンドや Dockerfile 最適化など、前提がやや増える。      |
| **5** | [**Docker + Kubernetes で構築する Webアプリケーション 実践講座**](https://www.udemy.com/course/web-application-with-docker-kubernetes/)                                     | フロント／バック複数コンテナを組み合わせ、K8s へデプロイ。アプリ開発＋運用の両視点が必要。                  |
| **6** | [**AWS EKS Kubernetes DevOps Best Practices**](https://www.udemy.com/course/aws-eks-kubernetes-docker-devops-best-practices-2020/)                         | VPC, ALB, IAM/OIDC 等 “EKS 本番運用” を想定。AWS 基礎と k8s 基礎が分かった前提で進む。    |
| **7** | [**Jenkins CICD Pipeline in Kubernetes AWS EKS**](https://www.udemy.com/course/jenkins-cicd-pipeline-in-kubernetes-aws-eks-devops/)                        | Jenkinsfile や GitOps まで組むため、パイプライン思考と EKS ネットワーク理解が必須。           |
| **8** | [**Advanced Terraform AWS EKS VPC (IaC Best Practices)**](https://www.udemy.com/course/advanced-terraform-aws-eks-vpc-devops-iac-best-practices-japanese/) | HCL で VPC／EKS をフルコード化。モジュール設計・State 管理など IaC 実戦力が問われる。           |
| **9** | [**Istio Service Mesh ハンズオン（Kubernetes × AWS EKS）**](https://www.udemy.com/course/istio-service-mesh-kubernetes-aws-eks-2020-handson/)                     | Envoy, mTLS, トラフィックシフト、Policies… ネットワークとセキュリティの深い知識＋EKS操作が同時に必要。 |

これでリンク付きの難易度順リストが完成です。ブックマークや学習計画にご活用ください！
