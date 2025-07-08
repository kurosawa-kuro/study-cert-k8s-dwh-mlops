# CKS 追加学習ガイド

## 概要

このガイドは、CKAD 試験で 75 点以上を取得できるレベルの受験者を対象とした、CKS（Certified Kubernetes Security Specialist）向けの追加学習教材です。

CKAD の試験範囲と重複しない高度なセキュリティ技術をカバーし、CKS 試験範囲に含まれないセキュリティ高度化技術を習得することを目的としています。

## 対象者

- **CKAD 試験で 75 点以上を取得できる知識・スキルを有する人材**
- Kubernetes の基本操作（Pod、Service、ConfigMap、Secret、Volume など）に習熟している
- kubectl コマンドによる基本的な操作が可能
- YAML マニフェストの読み書きができる

## 学習ガイド構成

### [第1章: Pod Security Standards (PSS)とPolicy as Code](./01_Pod%20Security%20Standards%20(PSS)とPolicy%20as%20Code.md)
- **学習時間**: 8時間
- **内容**: PodSecurityPolicy廃止後の代替技術、OPA/Gatekeeper、Kyverno
- **重要度**: ★★★★★

### [第2章: コンテナイメージセキュリティと署名検証](./02_コンテナイメージセキュリティと署名検証.md)
- **学習時間**: 12時間
- **内容**: Cosign、Notary v2、Trivy、サプライチェーンセキュリティ
- **重要度**: ★★★★☆

### [第3章: 高度なRBACとAPIサーバー認証強化](./03_高度なRBACとAPIサーバー認証強化.md)
- **学習時間**: 16時間
- **内容**: RBAC設計パターン、ABAC、OIDC、Webhook認証
- **重要度**: ★★★★★

### [第4章: シークレット管理の高度化とKMS統合](./04_シークレット管理の高度化とKMS統合.md)
- **学習時間**: 18時間
- **内容**: HashiCorp Vault、External Secrets Operator、KMS統合
- **重要度**: ★★★★☆

### [第5章: セキュリティ監査とコンプライアンス](./05_セキュリティ監査とコンプライアンス.md)
- **学習時間**: 22時間
- **内容**: Falco、CIS Kubernetes Benchmark、SIEM連携
- **重要度**: ★★★★★

## 学習の進め方

### 推奨学習順序

1. **第1章** → **第3章** → **第5章** → **第2章** → **第4章**

この順序により、基本的なセキュリティ概念から段階的に高度な技術へと進むことができます。

### 学習スケジュール例

#### 12週間プラン（週7-8時間）
- **1-2週目**: 第1章（8時間）
- **3-4週目**: 第3章（16時間）
- **5-7週目**: 第5章（22時間）
- **8-9週目**: 第2章（12時間）
- **10-12週目**: 第4章（18時間）

#### 16週間プラン（週5-6時間）
- **1-2週目**: 第1章（8時間）
- **3-5週目**: 第3章（16時間）
- **6-9週目**: 第5章（22時間）
- **10-12週目**: 第2章（12時間）
- **13-16週目**: 第4章（18時間）

## 前提知識の確認

学習開始前に以下の知識・スキルを確認してください：

### 必須スキル ✅
- [ ] kubectl基本コマンド（get, create, apply, delete, describe）
- [ ] YAML マニフェストの読み書き
- [ ] Pod、Service、ConfigMap、Secret の基本操作
- [ ] Namespace の理解と操作
- [ ] Volume と PersistentVolume の基本概念

### 推奨スキル 🔄
- [ ] Helm の基本操作
- [ ] Docker コンテナの基本知識
- [ ] Linux コマンドラインの基本操作
- [ ] Git の基本操作
- [ ] CI/CD パイプラインの基本概念

## 実習環境

### 最小構成
- **Kubernetes クラスター**: v1.25以上
- **ノード数**: 3ノード以上（master 1台、worker 2台以上）
- **メモリ**: 各ノード 4GB以上
- **ストレージ**: 各ノード 20GB以上

### 推奨クラウドサービス
- **Amazon EKS**
- **Google Kubernetes Engine（GKE）**
- **Azure Kubernetes Service（AKS）**

### ローカル環境
- **minikube**: テスト用途のみ
- **kind**: 軽量なテスト環境
- **k3s**: エッジ環境での検証

## 学習効果の測定

### 章別チェックポイント

各章の学習完了後、以下の項目を確認してください：

#### 第1章完了後
- [ ] Pod Security Standards の3つのレベルを説明できる
- [ ] OPA/Gatekeeper の基本的な ConstraintTemplate が作成できる
- [ ] Kyverno の基本的な ClusterPolicy が作成できる

#### 第2章完了後
- [ ] Cosign を使用したイメージの署名・検証ができる
- [ ] Trivy を使用した脆弱性スキャンができる
- [ ] Policy Controller の基本設定ができる

#### 第3章完了後
- [ ] 最小特権の原則に基づいた RBAC 設計ができる
- [ ] OIDC 認証の基本設定ができる
- [ ] Webhook 認証の仕組みを理解している

#### 第4章完了後
- [ ] HashiCorp Vault との基本的な統合ができる
- [ ] External Secrets Operator の基本設定ができる
- [ ] KMS を使用した etcd 暗号化の仕組みを理解している

#### 第5章完了後
- [ ] Falco を使用したランタイム監視ができる
- [ ] CIS Kubernetes Benchmark の基本的な実行ができる
- [ ] セキュリティログの基本的な分析ができる

## 補足資料

### 公式ドキュメント
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [CKS Exam Curriculum](https://github.com/cncf/curriculum/blob/master/CKS_Curriculum_%20v1.25.pdf)
- [CNCF Security Whitepaper](https://github.com/cncf/sig-security/blob/master/security-whitepaper/CNCF_cloud-native-security-whitepaper-Nov2020.pdf)

### 関連認定資格
- **CKS (Certified Kubernetes Security Specialist)**: 本ガイドの対象資格
- **CKA (Certified Kubernetes Administrator)**: インフラ運用観点
- **CKAD (Certified Kubernetes Application Developer)**: アプリケーション開発観点

## 注意事項

### セキュリティ上の注意
- 本ガイドの内容は**防御的セキュリティ**の学習を目的としています
- 攻撃手法の詳細説明は含まれていません
- 実環境での実習時は、セキュリティポリシーを遵守してください

### 実習環境の管理
- クラウドリソースの使用には費用が発生します
- 不要なリソースは速やかに削除してください
- 機密情報を含むマニフェストは適切に管理してください

## 学習サポート

### トラブルシューティング
各章に「検証コマンド」セクションを設けています。期待する動作にならない場合は、まずこれらのコマンドで状態を確認してください。

### 学習の記録
学習進捗を記録するために、以下のテンプレートを活用してください：

```markdown
## 学習記録

### 第X章: タイトル
- **開始日**: YYYY/MM/DD
- **完了日**: YYYY/MM/DD
- **学習時間**: X時間
- **理解度**: ★★★☆☆
- **メモ**: 
  - 理解できた点
  - 課題として残った点
  - 今後の学習計画
```

## 更新履歴

- **v1.0.0** (2024/XX/XX): 初版リリース
- 各章の詳細な学習内容を追加
- 実習環境の構築ガイドを追加
- 学習進捗管理テンプレートを追加

---

**総学習時間**: 92時間（各章の学習時間合計）
**対象レベル**: CKAD 75点以上取得者
**最終更新**: 2024年XX月XX日