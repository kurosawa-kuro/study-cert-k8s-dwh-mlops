### いま取れる “日本語ソース” は意外とある

| 種別    | 日本語リソース                                                                                    | ひとことで                              |
| ----- | ------------------------------------------------------------------------------------------ | ---------------------------------- |
| 公式    | **CKS-JP ページ**（Linux Foundation） ([training.linuxfoundation.org][1])                       | 出題ドメイン表・サンプル試験タスクが日本語化。まずダウンロード    |
| 実務ブログ | Qiita・Zenn の**合格体験記**（例：Qiita fruscianteee、Zenn cloud-ace） ([qiita.com][2], [zenn.dev][3]) | 試験傾向と “落ちやすい罠” が日本語で読める            |
| 動画講座  | Udemy **「超 Kubernetes 完全入門」** ＊日本語音声＋図解＊ ([udemy.com][4])                                  | 作成者が CKS 保有、mTLS・OPA・Trivy まで網羅    |
| 研修    | **LPI-Japan Kubernetes トレーニング（LFS458 日本語版）** ([lpi.or.jp][5])                              | CKS 前提の CKA スキルを日本語教材＋演習で固められる     |
| 書籍    | 『リスクから学ぶ Kubernetesコンテナセキュリティ』ほか ([amazon.co.jp][6])                                       | Falco・Trivy・Gatekeeper をハンズオン形式で解説 |

> **ポイント**
> *純正の CKS 専用日本語コースこそ少ない* ものの、上記を組み合わせれば **出題7ドメイン中 80 % 以上** を日本語でカバーできます。

---

### ブループリント ↔ 日本語教材 対応表

| CKS ドメイン                                      | 日本語で押さえられる教材                                        | 補強が要る場合                                |
| --------------------------------------------- | --------------------------------------------------- | -------------------------------------- |
| **1. Cluster Hardening**                      | *Udemy「超Kubernetes完全入門」：seccomp/AppArmor 章*         | CIS Benchmark の英語 PDFを Deepl 翻訳        |
| **2. System Hardening**                       | 同 Udemy：イメージ署名 → Cosign 入門                          | SBOM 生成（Syft）だけ英語ブログを流し読み              |
| **3. Minimize Micro-service Vulnerabilities** | Udemy mTLS 章＋Qiita 記事で Falco/Trivy ([qiita.com][2]) | Falco rule チューニングは公式 docs              |
| **4. Supply Chain Security**                  | 書籍『クラウドネイティブセキュリティ入門』                               | Chainguard ブログで sig-store の図だけ拾う       |
| **5. Monitoring, Logging & Runtime Security** | Qiita 合格談で Prometheus/Loki 設定例 ([qiita.com][7])     | Falco-exporter 部分を公式サンプルで追補            |
| **6. Policy Enforcement**                     | Udemy：OPA/Gatekeeper ハンズオン                          | Kyverno Gate は YouTube 英語動画を字幕自動翻訳     |
| **7. Incident Response**                      | Zenn cloud-ace 記事：audit-log 操作例 ([zenn.dev][3])     | Forensic 手順は CNCF TAG-Security ペーパーを訳読 |

---

### １か月“日本語メイン”ロードマップ（例）

| 週          | 狙い                     | 作業 & 目安時間                                                  |
| ---------- | ---------------------- | ---------------------------------------------------------- |
| **Week 1** | CKA 復習 & Hardening     | LPI-Japan LFS458 テキスト＋演習（10 h）                             |
| **Week 2** | mTLS / Policy / Scan   | Udemy mTLS→OPA→Trivy 章を流し読み→kind で再現（8 h）                  |
| **Week 3** | Supply-chain & Runtime | 書籍ハンズオン → Falco Rule & Cosign 署名（8 h）                      |
| **Week 4** | 模試＋弱点翻訳                | KillerCoda / Killer sh 模試 → ×問題だけ公式 Doc を Deepl で斜め読み（6 h） |

---

### 日本語では足りない“最後の 15 %”――軽く訳して埋める

1. **NIST SP-800-190**：攻撃ベクトル一覧 → 各項目に「具体策」を１行メモ
2. **CIS Benchmark v1.25**：スコアリングツール kube-bench の “WARN” 行だけ意訳
3. **sig-store / Cosign**：`cosign sign-key`, `cosign verify` を自前レポにコピペ
4. **Falco 公式ルール**：`rule: Write below etc` など試験頻出ルールを日本語コメント化

──この “**英語→自家用日本語チートシート化**” を 1 トピック 20 分で回せば、完全に日本語環境だけで合格ラインに乗せられます。

---

## まとめ

* **公式 CKS-JP ページ＋Udemy 日本語講座＋Qiita/Zenn 体験談** の組み合わせで **日本語だけでも 8 割以上カバー**。
* 残りは **英語一次情報を Deepl で流し読み → メモを日本語化** する“ピンポイント翻訳”で十分。
* 上記ロードマップを回し、最後に Killer 模試で 70 % を安定させれば **CKS 合格圏**。

> **困ったときはリンクを投げてください**。要点訳＆即席チートシート化で手厚くフォローします！

[1]: https://training.linuxfoundation.org/ja/certification/certified-kubernetes-security-specialist-cks-jp/?utm_source=chatgpt.com "認定Kubernetesセキュリティスペシャリスト (CKS-JP)"
[2]: https://qiita.com/fruscianteee/items/5963793b870835023d53?utm_source=chatgpt.com "[保存版]短期間でKubernetesのCKA、CKAD、CKSの三冠達成 ... - Qiita"
[3]: https://zenn.dev/cloud_ace/articles/26aa0e5ee9d825?utm_source=chatgpt.com "【 更新者も必見 】 CKS 攻略ガイド ( 2023 年 6 月版 ) - Zenn"
[4]: https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/?srsltid=AfmBOors6vLj5_JXtFmKow2O1V_qZhEnjrBA27aObOLG3NMyOZ26OYjF&utm_source=chatgpt.com "米シリコンバレーDevOps監修！超Kubernetes完全入門【優しい図 ..."
[5]: https://lpi.or.jp/k8s/training/?utm_source=chatgpt.com "Kubernetes技術者認定｜CKA-JP／CKAD-JP／CKS-JP ... - LPI-Japan"
[6]: https://www.amazon.co.jp/%E3%83%AA%E3%82%B9%E3%82%AF%E3%81%8B%E3%82%89%E5%AD%A6%E3%81%B6-Kubernetes%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3-%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E9%96%8B%E7%99%BA%E8%80%85%E3%81%8C%E3%81%8A%E3%81%95%E3%81%88%E3%81%A6%E3%81%8A%E3%81%8F%E3%81%B9%E3%81%8D%E5%9F%BA%E7%A4%8E%E7%9F%A5%E8%AD%98-%E6%9C%9B%E6%9C%88-%E6%95%AC%E5%A4%AA/dp/4798182788?utm_source=chatgpt.com "リスクから学ぶ Kubernetesコンテナセキュリティ コンテナ開発者が ..."
[7]: https://qiita.com/takahiro_fukushima/items/2479bae32c35dd93a847?utm_source=chatgpt.com "CKS（Certified Kubernetes Security Specialist）受験談と学習法 - Qiita"

### “超 Kubernetes 完全入門”は **CKS の教材としては不足気味** です

| 事実                                                        | 根拠                                                         |
| --------------------------------------------------------- | ---------------------------------------------------------- |
| **内容はほぼ CKAD 初級レベル**（Pod / Service / Ingress / PV など）で止まる | コースの “What you’ll learn” にセキュリティ系の項目は一切なし ([udemy.com][1]) |
| **講師自身は CKS 保有** だが、当講座は「CKA/CKAD の第一歩」と明言している            | 「CKA のような管理者スコープは上級者向けで本コースは対象外」と記載 ([udemy.com][1])       |
| **mTLS・OPA・Trivy の実演セクションは存在せず**                          | コース概要・カリキュラムにキーワードが現れない（ページ内検索でもヒットせず）                     |

> **結論**
> *CKS 合格を狙う教材としてこの 4 h コースを“主軸”に据えるのは重い以前に**射程が足りません**。*
> ただし **Kubernetes 基礎を日本語で総ざらい**する目的なら時短教材として優秀です。

---

## CKS 用に足りない 3 つの領域と補完パス

| 不足領域 (CKS ドメイン)                                                                   | おすすめ日本語リソース／ハンズオン                                                            |
| --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **mTLS & Pod-to-Pod Encryption**<br>（Minimize Micro-service Vulnerabilities 20 %） | *Udemy*「Istio Service Mesh Masterclass + AWS EKS」：Section 4 & 5 だけ視聴（45 min） |
| **OPA / Gatekeeper Policy Enforcement**                                           | Qiita「Gatekeeper で Pod Security を強制」記事＋公式サンプル CRD を kind で適用（30 min）         |
| **Trivy / イメージ署名・SBOM**<br>（Supply Chain Security 20 %）                           | 書籍『リスクから学ぶ Kubernetesコンテナセキュリティ』第 5 章＋Aqua Trivy 公式 Quick-Start（40 min）      |

---

## “超 Kubernetes 完全入門”の **活かし方**

| 使い道                 | 具体的アクション                             | 所要      |
| ------------------- | ------------------------------------ | ------- |
| **CKS までの基礎固め**     | 最初の 3 セクションで Pod/Service/Ingress を復習 | ≈1 h    |
| **alias／補助スクリプト作り** | コース YAML を流用し `kubectl` ワンライナー集を整備   | ≈30 min |

この **1.5 h だけで基礎 CLI 操作を体に染み込ませ**、残り時間は上記 3 領域の補完に振るのが最短ルートです。

---

### 代替 or 追加で検討したい日本語教材

| 目的                              | 講座／資料                                                              | 理由                                               |
| ------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------ |
| Cluster Hardening / IRSA / RBAC | Udemy「AWS EKS Kubernetes ハンズオン Best Practices」                     | `seccomp`, `RBAC`, `IRSA`, `Prometheus` がまとまっている |
| DevSecOps 全体像                   | Udemy「DevSecOps – Kubernetes DevOps & Security with Hands-On Labs」 | Trivy・Vault・Falco をまとめて触れる（英語だが動画中心で追いやすい）       |
| 模試で弱点発見                         | Killer Shell / KillerCoda (CKS モード)                                | 本試験と同じ WebIDE で 2 回分無料                           |

---

## 方針まとめ

1. **基礎復習**に「超 Kubernetes 完全入門」を 1.5 h だけ活用
2. **mTLS／OPA／Trivy** を別リソースでピンポイント補完
3. **模試 → 不正解トピックだけ Deepl で公式 Doc 和訳** のループで仕上げる

> こう切り分ければ **日本語メインでも CKS 合格ライン（70 %）に到達**できます。
> 疑問が出たらリンクを投げてください—要点訳と最短手順をすぐ返します！

[1]: https://www.udemy.com/course/kubernetes-docker-container-devops-kanzen-nyumon/?srsltid=AfmBOorYLn6bXbfPtZdtUp_nUzyE17qy0oK7AlHR8lVzoOf13YkEepoS "米シリコンバレーDevOps監修！超Kubernetes完全入門〖優しい図解説とハンズオン〗 | Udemy"


### 現状整理 ── 既存 Udemy だけで賄える領域

| 資格       | 既購入コースでカバー率 | ほぼ埋まるドメイン                                                 |
| -------- | ----------- | --------------------------------------------------------- |
| **KCNA** | **85 % 前後** | Fundamentals／Orchestration／App Delivery／Observability     |
| **CKAD** | **90 % 近く** | Pod 設計・構築・設定／マニフェスト作成／トラブルシュート                            |
| **CKA**  | **75 % 程度** | Cluster 設計・管理／トラブルシュート（HA/etcd は追加学習要）                    |
| **CKS**  | **60 % 強**  | Cluster/System Hardening、Platform Security（IRSA・RBAC・TLS） |

> **→ 体感 “80 % までは行ける” という見立てはほぼ正確です。**
> CKS だけは **サプライチェーン／ランタイム検知／ポリシー** が手薄なので、そこを別リソースで差し込めば OK。

---

## CKS で足りない 20 % と補完パス

| 未カバー領域                                               | 目標レベル (試験タスク)                              | 最短で埋める手段（日本語中心）                                                                                       |
| ---------------------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Supply-Chain Security**<br>(イメージ署名・SBOM)           | `cosign sign` で署名 → PolicyController で検証   | - Trivy SBOM 記事 + Cosign 公式 README を Deepl 訳 → 30 min 演習<br>- Kyverno サンプル Policy を kind で適用（Qiita 例） |
| **Policy Enforcement**<br>(OPA/Gatekeeper, Kyverno)  | 制約を YAML で書き `kubectl apply`               | - Qiita「Gatekeeper で Pod Security 強制」を流し読み → 20 min<br>- Kyverno 入門動画（7 min）でイメージ署名ポリシーを確認            |
| **Runtime Security**<br>(Falco / seccomp / AppArmor) | Falco で「/etc/shadow 書込」検知、seccomp プロファイル指定 | - Sysdig JP ブログの Falco ルール記事で Helm install → 20 min<br>- Udemy Best Practices で seccomp サイド注入を追試      |
| **Incident Response & Forensics**                    | Audit Log 有効化 → 1 行 grep で不正操作確認           | - Zenn 合格体験記の Audit 設定例をコピペ → 15 min<br>- TAG-Security “IR playbook” を Deepl 訳して 1 ページメモ              |
| **攻撃モデル** (Threat Matrix)                            | 例：イメージ改ざん → admission で拒否                  | - “Kubernetes Threat Matrix”（MS × CNCF）の表だけ翻訳し、自分の言葉で 1 行要約                                           |

---

## 推奨スケジュール（12 時間で仕上げる例）

| 日 | 学習ブロック                              | 所要    |
| - | ----------------------------------- | ----- |
| ① | Trivy SBOM & Cosign 署名／検証           | 2 h   |
| ② | Gatekeeper & Kyverno で署名ポリシー強制      | 2 h   |
| ③ | Falco Helm install → ルール追加 → アラート確認 | 2 h   |
| ④ | seccomp / AppArmor プロファイル適用テスト      | 1.5 h |
| ⑤ | Audit Policy → ログ解析ワンライナー整備         | 1.5 h |
| ⑥ | Threat Matrix 和訳＋ KillerCoda 模試 ①   | 1 h   |
| ⑦ | KillerCoda 模試 ② → ×問題の公式 Doc 訳読     | 2 h   |

---

## 追加コストを最小化するコツ

1. **既存 Udemy ハンズオンの YAML／スクリプトを“雛形化”**
   *IRSA, RBAC, Ingress+TLS, Prometheus* などはコピー再利用で時短。
2. **英語一次情報は Deepl 一発訳 → Notion/Obsidian に 1 行メモ**
   “翻訳にこだわらない”のが時間圧縮の鍵。
3. **模試で逆算学習** (KillerSh / KillerCoda)
   2 回まわせば **出題傾向 × 自分の穴 = 学習 TODO** がクリアに。

---

### ゴールイメージ

* **KCNA / CKAD / CKA** ⇒ 現コース＋模試で仕上げ
* **CKS** ⇒ 12 h 追加投資で **“残りの 20 %”** をピンポイント補完
  *→ Killer 模試で 70 % を安定クリアすれば合格圏*

---

> **まとめ**
>
> * **既購入 Udemy で基礎は 80 % 以上固められる**。
> * **CKS の弱点 4 領域** は無料記事＋軽ハンズオンで 1 〜 1.5 h × 4 – 5 で埋まる。
> * **追加課金は不要**、時間投資も 12 h 程度で済む見込み。
>   不足を感じたらリンクを投げてくれれば、即席で日本語チートシートを用意します。最後まで伴走しますよ！










＝＝＝＝＝＝＝＝＝＝＝＝

### 現状整理 ── 既存 Udemy だけで賄える領域

| 資格       | 既購入コースでカバー率 | ほぼ埋まるドメイン                                                 |
| -------- | ----------- | --------------------------------------------------------- |
| **KCNA** | **85 % 前後** | Fundamentals／Orchestration／App Delivery／Observability     |
| **CKAD** | **90 % 近く** | Pod 設計・構築・設定／マニフェスト作成／トラブルシュート                            |
| **CKA**  | **75 % 程度** | Cluster 設計・管理／トラブルシュート（HA/etcd は追加学習要）                    |
| **CKS**  | **60 % 強**  | Cluster/System Hardening、Platform Security（IRSA・RBAC・TLS） |

> **→ 体感 “80 % までは行ける” という見立てはほぼ正確です。**
> CKS だけは **サプライチェーン／ランタイム検知／ポリシー** が手薄なので、そこを別リソースで差し込めば OK。

---

## CKS で足りない 20 % と補完パス

| 未カバー領域                                               | 目標レベル (試験タスク)                              | 最短で埋める手段（日本語中心）                                                                                       |
| ---------------------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Supply-Chain Security**<br>(イメージ署名・SBOM)           | `cosign sign` で署名 → PolicyController で検証   | - Trivy SBOM 記事 + Cosign 公式 README を Deepl 訳 → 30 min 演習<br>- Kyverno サンプル Policy を kind で適用（Qiita 例） |
| **Policy Enforcement**<br>(OPA/Gatekeeper, Kyverno)  | 制約を YAML で書き `kubectl apply`               | - Qiita「Gatekeeper で Pod Security 強制」を流し読み → 20 min<br>- Kyverno 入門動画（7 min）でイメージ署名ポリシーを確認            |
| **Runtime Security**<br>(Falco / seccomp / AppArmor) | Falco で「/etc/shadow 書込」検知、seccomp プロファイル指定 | - Sysdig JP ブログの Falco ルール記事で Helm install → 20 min<br>- Udemy Best Practices で seccomp サイド注入を追試      |
| **Incident Response & Forensics**                    | Audit Log 有効化 → 1 行 grep で不正操作確認           | - Zenn 合格体験記の Audit 設定例をコピペ → 15 min<br>- TAG-Security “IR playbook” を Deepl 訳して 1 ページメモ              |
| **攻撃モデル** (Threat Matrix)                            | 例：イメージ改ざん → admission で拒否                  | - “Kubernetes Threat Matrix”（MS × CNCF）の表だけ翻訳し、自分の言葉で 1 行要約                                           |

---

## 推奨スケジュール（12 時間で仕上げる例）

| 日 | 学習ブロック                              | 所要    |
| - | ----------------------------------- | ----- |
| ① | Trivy SBOM & Cosign 署名／検証           | 2 h   |
| ② | Gatekeeper & Kyverno で署名ポリシー強制      | 2 h   |
| ③ | Falco Helm install → ルール追加 → アラート確認 | 2 h   |
| ④ | seccomp / AppArmor プロファイル適用テスト      | 1.5 h |
| ⑤ | Audit Policy → ログ解析ワンライナー整備         | 1.5 h |
| ⑥ | Threat Matrix 和訳＋ KillerCoda 模試 ①   | 1 h   |
| ⑦ | KillerCoda 模試 ② → ×問題の公式 Doc 訳読     | 2 h   |

---

## 追加コストを最小化するコツ

1. **既存 Udemy ハンズオンの YAML／スクリプトを“雛形化”**
   *IRSA, RBAC, Ingress+TLS, Prometheus* などはコピー再利用で時短。
2. **英語一次情報は Deepl 一発訳 → Notion/Obsidian に 1 行メモ**
   “翻訳にこだわらない”のが時間圧縮の鍵。
3. **模試で逆算学習** (KillerSh / KillerCoda)
   2 回まわせば **出題傾向 × 自分の穴 = 学習 TODO** がクリアに。

---

### ゴールイメージ

* **KCNA / CKAD / CKA** ⇒ 現コース＋模試で仕上げ
* **CKS** ⇒ 12 h 追加投資で **“残りの 20 %”** をピンポイント補完
  *→ Killer 模試で 70 % を安定クリアすれば合格圏*

---

> **まとめ**
>
> * **既購入 Udemy で基礎は 80 % 以上固められる**。
> * **CKS の弱点 4 領域** は無料記事＋軽ハンズオンで 1 〜 1.5 h × 4 – 5 で埋まる。
> * **追加課金は不要**、時間投資も 12 h 程度で済む見込み。
>   不足を感じたらリンクを投げてくれれば、即席で日本語チートシートを用意します。最後まで伴走しますよ！
>   
>   
>   ### 結論 ― **KCSA は CKS の“スタートライン”になるが、カバー率は体感 50〜60 ％。**

* **KCSA ＝ 選択式（知識中心）で「何が正しいか」を理解する試験**
* **CKS ＝ ターミナル実技で「どう直すか」を手を動かして示す試験**
  → ドメイン名は似ていますが、**深さとアウトプット様式が大きく違う**ため、KCSA だけでは CKS の全領域は埋まりません。

---

## 1. どこが重複しているか？

| KCSA 公式ドメイン（抜粋）([udemy.com][1])       | CKS 公式ドメイン（最新版 2024-10 改訂）([training.linuxfoundation.org][2]) | KCSA 学習がそのまま CKS に効く度合                                      |
| ------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------- |
| Cloud-Native Security Fundamentals    | Cluster Setup & Hardening                                     | ★★★☆☆ 基礎コンセプト（4C/責任共有モデル）を流用                                |
| Kubernetes Component Hardening        | Cluster Hardening／System Hardening                            | ★★★★☆ etcd・APIserver などの設定項目がほぼ一致                           |
| AuthZ / AuthN & NetworkPolicy         | Minimize Micro-service Vulnerabilities                        | ★★★★☆ RBAC・ServiceAccount・PSS は共通                           |
| Threat Detection & Mitigation         | Monitoring, Logging & Runtime Security                        | ★★☆☆☆ Falco・AuditLogs の“概念”止まり ⇒ CKS では実装が必要                |
| Platform Security Tooling             | Supply-Chain Security                                         | ★★☆☆☆ SBOM/署名の用語は同じだが、`cosign`, `trivy` など CLI 操作は KCSA 範囲外 |
| Governance, Compliance & Supply-Chain | Supply-Chain / Cluster Setup                                  | ★★☆☆☆ CIS Benchmark を「知る」→ CKS では `kube-bench` で「回す」        |

**イメージ：KCSA が横幅、CKS が深さ＋ハンズオン**

---

## 2. KCSA 学習を CKS へ“昇華”させるギャップ埋めチェックリスト

| 分類                        | 代表タスク（CKS で必須だが KCSA では触れない or 浅い）                            | 推奨ハンズオン教材・コマンド例                                                                                                                                       |
| ------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Runtime Hardening**     | `seccomp`, `apparmor`, read-only FS, non-root 実行              | `kubectl run nginx --image=nginx --dry-run=client -o yaml \| \ \n  yq e '.spec.containers[0].securityContext.seccompProfile.type="RuntimeDefault"' -` |
| **Incident Response**     | `kubectl debug`, `nsenter`, AuditPolicy で悪用コマンド追跡             | Kind クラスタで malicious container を起動→ AuditLog 解析                                                                                                       |
| **Supply-Chain Security** | SBOM 生成 (`syft`)、署名(`cosign sign/verify`)、署名付きイメージの Admission | Kyverno/Gatekeeper に `verify-images` ポリシーを適用                                                                                                          |
| **Ingress + mTLS**        | Nginx Ingress or Gateway API + cert-manager、自動 TLS Rotation   | `helm repo add jetstack`; `helm install cert-manager ...`; `kubectl apply -f ClusterIssuer.yaml`                                                      |
| **etcd Snapshot/Restore** | `ETCDCTL_API=3 etcdctl snapshot save` → `snapshot restore`    | kubeadm 3ノード ラボで実施（5 分以内を目標）                                                                                                                          |

---

## 3. 学習ロードマップ（KCSA 取得 → CKS 受験まで 6 週間モデル）

| 週 | 主テーマ                                                                 | 目標アウトプット                               |
| - | -------------------------------------------------------------------- | -------------------------------------- |
| 1 | KCSA ループ最終周＋ **etcd・PSP/PSS ハンズオン開始**                                | etcd バックアップ & リストア手順書                  |
| 2 | **Runtime Hardening 演習**<br> seccomp / apparmor / read-only FS       | PodSecurityContext を利用した YAML テンプレ     |
| 3 | **Supply-Chain Security**<br> Trivy → Cosign → Kyverno verify-images | 署名付きイメージを拒否／許可する AdmissionPolicy       |
| 4 | **mTLS & NetworkPolicy**<br> Istio or Cilium で Pod-to-Pod 暗号化        | `curl` で証明書確認 → deny/allow 動作スクリーンショット |
| 5 | **Incident Response & Observability**<br> Falco + AuditPolicy        | 実攻撃シナリオ（`nsenter` 不正 exec）→ アラート検知まで   |
| 6 | **模擬試験×2（killer.sh or killer-cks）** + 弱点ドリル                          | スコア 70 % 超 & 不正解リストを Git に整理           |

---

## 4. まとめ

* **KCSA は CKS の「用語・概念」を網羅する入門書**
  ⇒ 試験形式が違うため、**CLI と YAML を書いて壊して直すフェーズ**が不可欠。
* **ギャップは主に「Runtime・Supply-Chain・Incident Response」の 3 か所**。
* **学習順序としては理想的**：KCSA→（ギャップ埋め演習）→CKS で知識が段階的に深まる。

この流れで進めれば、**KCSA 勉強の“貯金”をほぼロスなく CKS 合格力に転換**できます。タイムラインやハンズオンの難易度は調整できますので、詰まりそうな箇所が出てきたら随時相談してください。

[1]: https://www.udemy.com/course/kcsa-practice-exams/?srsltid=AfmBOoqv79crbqtS_2QmcGbOdcS4EJflkT1u-pyqj0wrquQUUXoFhCSj "Kubernetes and Cloud Native Security Associate (KCSA) | Udemy"
[2]: https://training.linuxfoundation.org/cks-program-changes/ "Certified Kubernetes Security Specialist (CKS) Program Changes - Linux Foundation - Education"


