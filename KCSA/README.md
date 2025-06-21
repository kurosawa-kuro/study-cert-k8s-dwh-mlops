## KCSA ― 学習順ロードマップ

> *“何から学ぶと理解が積み重なりやすいか” を意識した **10 フェーズ**。
> 1 ブロック学んだら「公式ドキュメント参照 → 小さな Lab で確認 → 20 行メモ」で回すと効率的です。*

| 学習フェーズ                      | 重点テーマ                              | 押さえる項目                                         | ハンズオン例                                 |
| --------------------------- | ---------------------------------- | ---------------------------------------------- | -------------------------------------- |
| **0. 前提確認**                 | k8s コア概念の復習                        | Pod / Deployment / Service / RBAC              | `kubectl auth can-i` で権限チェック           |
| **1. 4 C’s セキュリティモデル**      | Cloud / Cluster / Container / Code | 境界と責任分担                                        | A4 に 4 層図を描き、各層ベストプラクティスを 1 行ずつ書く      |
| **2. クラウド基盤ハードニング**         | IAM・ネットワーク分離・Audit                 | IAM 最小権限 / VPC PrivateLink / CloudTrail        | AWS IAM Policy Simulator で過剰権限を検出      |
| **3. Cluster Hardening 基礎** | RBAC・PodSecurity・Admission         | PSS (baseline/restricted)・OPA/Kyverno          | `kubectl run` で Privileged Pod → 拒否を確認 |
| **4. ネットワーク & 暗号化**         | NetworkPolicy・TLS・etcd Encryption  | Allow/deny ルール・TLS 証明書・EncryptionConfiguration | Calico で `default-deny` → 特定ポートのみ許可    |
| **5. コンテナランタイム保護**          | seccomp・AppArmor・rootless          | DefaultProfile・RuntimeClass                    | `run --security-opt seccomp=...`       |
| **6. サプライチェーン & イメージ**      | SBOM・署名・脆弱性スキャン                    | Cosign・Trivy・in-toto                           | `cosign sign && cosign verify`         |
| **7. 実行時脅威検知**              | Falco / eBPF                       | Syscall 監視・Falco ルール                           | Falco が `/etc/shadow` 読取を検出するかテスト      |
| **8. 監査 & ロギング**            | Audit Policy・Centralized Logs      | `audit-policy.yaml` レベル設定・Fluent Bit           | `kubectl exec` を AuditLog で確認          |
| **9. Secrets & 暗号化管理**      | KMS・External Secrets Operator      | at-rest KMS、in-cluster Secret sync             | ESO で Vault → Secret 自動同期              |
| **10. 模試 & 復習**             | KillerShell / Udemy 模試             | 70 % 以上 × 2 回                                  | 間違えた問題をフェーズに紐付け再学習                     |

### 進め方 Tips

1. **図解→CLI→ポリシー適用** の順に手を動かすと理解が定着。
2. **Falco ルール → Prometheus Alert → Slack** の一連パスを作ると複数フェーズを横断で復習できる。
3. 公式ドキュメントを必ず試験中と同じ検索手順で読む（`site:kubernetes.io` 検索など）。

この順番で学べば、**インフラ外周 → Cluster 内側 → ランタイム → サプライチェーン → 監査・Secrets** と “攻撃面を狭める順” に進めるため、概念が自然に積み上がります。

‘‘‘‘‘‘‘‘‘‘‘‘‘‘‘‘
CKAD 85% CKAD Killer.sh70%前提のプログラマーがKCSA試験対策に下記の基本技術テーマを学ぶ基礎学習教材を新しいドキュメントで作成依頼
‘‘‘‘‘‘‘‘‘‘‘‘‘‘‘‘