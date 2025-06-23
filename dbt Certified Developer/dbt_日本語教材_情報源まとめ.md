dbt Certified Developer
dbt Certified Developer
| ✅ 5  | **dbt Certified Developer**            | モデル構築／バージョン管理／CI/CD運用            | ★☆☆☆☆ | 7〜10時間  | 約3〜4日                | Git／SQL経験者なら短期取得可         |
| ---- | -------------------------------------- | -------------------------------- | ----- | ------- | -------------------- | ------------------------- |

 **dbt Certified Developer** ### dbt Certified Developer（Analytics Engineering Certification）向け

**“日本語で学べる” 主な教材・情報源まとめ**

|種別|タイトル／リンク|特色・試験対策で活かせるポイント|
|---|---|---|
|**ブログ連載**|**DevelopersIO：試験概要と必須スキル解説**（Analytics Engineering Exam）([dev.classmethod.jp](https://dev.classmethod.jp/articles/point-of-dbt-analytics-engineering-certification-exam/ "dbt認定試験「dbt Analytics Engineering Certification Exam」概要を読んで何を理解しておくべきか、どんなスキルが求められるのかを把握する #dbt \| DevelopersIO"))|本番 Blueprint を日本語で整理。出題領域ごとのキーワードを把握できる。|
||**DevelopersIO：Cloud Admin Exam 概要**（言語は英語のみ）([dev.classmethod.jp](https://dev.classmethod.jp/articles/point-of-dbt-cloud-administrator-certification-exam/ "dbt認定試験「dbt Cloud Administrator Certification Exam」概要を読んで何を理解しておくべきか、どんなスキルが求められるのかを把握する #dbt \| DevelopersIO"))|Developer 試験と重複する “環境構築・ジョブ運用” 知識を補完。|
|**ハンズオン記事**|**「ケチケチ dbt ハンズオン！（超入門編）」**（Athena×CloudShell）([dev.classmethod.jp](https://dev.classmethod.jp/articles/the-first-kechi-kechi-dbt-hands-on-for-beginers/?utm_source=chatgpt.com "第一回ケチケチ dbtハンズオン！（超入門編） - DevelopersIO"))|無料 AWS リソースだけで dbt Core を動かすチュートリアル。`dbt init / run / test / docs` の一連操作を体験。|
||**Snowflake & dbt Cloud Hands-On シリーズ**（Quickstarts 写経）([dev.classmethod.jp](https://dev.classmethod.jp/articles/snowflake-dbt-cloud-handson-challenge-vol4/?utm_source=chatgpt.com "Snowflake & dbt Cloudハンズオン実践 #4: 『実践編1(ソース設定 ..."))|dbt Cloud GUI でモデル ↔ DAG ↔ ジョブまで通し学習。|
|**書籍／Zenn**|**Zenn ブック「dbt 入門」**（日本語連載）([zenn.dev](https://zenn.dev/foursue/books/31456a86de5bb4/viewer/82447e?utm_source=chatgpt.com "ドキュメント(document)機能を使おう｜dbt 入門 - Zenn"))|モデル・マクロ・ドキュメント機能の概念＋サンプル SQL。|
||**Qiita：ローカルで dbt を試す**([qiita.com](https://qiita.com/coitate/items/1671959fdfa3fe3e0dbc?utm_source=chatgpt.com "dbt をローカルでいろいろ試してみる #ETL - Qiita"))|`profiles.yml` の書き方や CLI コマンドを実例で解説。|
|**公式系 JP ドキュメント**|**Databricks Docs（dbt Cloud 接続手順／ジョブタスク）**([docs.databricks.com](https://docs.databricks.com/gcp/ja/partners/prep/dbt-cloud?utm_source=chatgpt.com "dbt Cloudに接続する - Databricks Documentation"))|接続設定・ワークスペース権限など GUI 画面を日本語で確認可。|
|**YouTube**|**dbt Tokyo Meetup 録画**（例：Athena×Iceberg×dbt セッションなど）([youtube.com](https://www.youtube.com/watch?v=XyrccCDbKu0&utm_source=chatgpt.com "Amazon Athena (Iceberg) x dbt ではじめるデータ分析！ - YouTube"))|日本語セッションで実務ノウハウを吸収。実装デモが多く理解しやすい。|
|**その他**|**Monstar-lab 技術ブログ「dbt の魅力と基本」**([engineering.monstar-lab.com](https://engineering.monstar-lab.com/jp/post/2024/11/04/introduction-to-dbt/?utm_source=chatgpt.com "データエンジニアリング初心者でも分かる！dbtの魅力と基本"))|ベストプラクティス（DRY・CI/CD 等）の背景を日本語で整理。|

---

#### 使い方のヒント

1. **Concept → Hands-on → Blueprint 照合**
    
    - _Zenn／Monstar-lab_ で概念を掴む
        
    - _ケチケチ dbt_ or _Snowflake Hands-On_ で CLI/Git ワークフローを反復
        
    - _DevelopersIO 試験解説_ で “どの操作がどの試験ドメインに当たるか” を確認
        
2. **英語公式コースと組み合わせる**  
    試験教材（dbt Learn → _Developer Path_）は英語のみ。上記日本語記事で下地を作り、英語動画は 1.25〜1.5 × 倍速で聴くと負荷が少ない。([learn.getdbt.com](https://learn.getdbt.com/learning-paths/dbt-certified-developer?utm_source=chatgpt.com "dbt Certified Developer Path - dbt Learn"))
    
3. **模擬問題／サンプル SQL 集め**  
    連載記事のサンプル `model.sql` や `schema.yml` を GitHub に溜めておくと、試験直前に “`run + test + build` が通るか” をワンコマンドで再確認できる。
    

---

> **注意点**  
> _dbt Certified Developer 試験自体は現状 “英語のみ”_（日本語試験／公式 JP テキストは未提供）です。教材で日本語インプットを増やしつつ、最後は英語 UI とエラーメッセージに慣れるため、**CLI を常に英語ロケールで操作**する習慣を付けるのがおすすめです。