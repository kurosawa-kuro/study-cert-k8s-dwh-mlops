# 🔧 Databricks / Snowflake / dbt パイプ構成ドキュメント

## 目的

* AWS/GCP/ローカル環境で同一パイプラインを再現可
* PoCで実試したものを少ない差分で本番に移行する
* データの修造、数値確認、MLパイプラインへの連携

---

## 【🌎 本番構成】

```text
[アプリ] → Fluent Bit → Firehose → S3
     ↓
[Databricks Enterprise]
     ↓
[Snowflake (RAW)]
     ↓
[dbt: staging → marts]
     ↓
[BI / ML / API]
```

---

## 【🌐 ローカルPoC構成】

```text
[アプリ] → MinIO (S3互換)
     ↓
[Databricks CE or PySpark CLI]
     ↓
[DuckDB]
     ↓
[dbt-duckdb]
     ↓
[BentoML / Go + ONNX]
```

---

## 【🔢 dbt の profiles.yml 切替例】

### ○ ローカル (DuckDB)

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: ./local.duckdb
```

### ○ 本番 (Snowflake)

```yaml
my_project:
  target: prod
  outputs:
    prod:
      type: snowflake
      account: your_account
      user: your_user
      password: your_pass
      database: PROD_DB
      warehouse: ANALYTICS_WH
      schema: STAGING
```

---

## 【🌍 クラウド変更に対応した設計】

| レイヤー                          | 辺揉性                  |
| ----------------------------- | -------------------- |
| MinIO → S3 / GCS              |  `endpoint` 切り替えで対応  |
| DuckDB → Snowflake / BigQuery |  `profiles.yml` 切り替え |
| Databricks CE → AWS/GCP版      | ノートブックは共通            |
| dbt CLI → dbt Cloud           | CI/CD体系に続けて移行可       |

---

## 【🎓 練習プロセス】

1. `MinIO` に JSONL / CSV を送信 (Express or Go)
2. `Databricks CE` で Auto Loader 読み込み → Delta変換
3. `.write.format("snowflake")` で Snowflake に Push
4. `dbt run` で staging → marts 構築
5. ML: `LightGBM + onnx export` / `Go側で接続`

---

## 【🏑 Kaggle対応】

* EDA, 次元の分割, 特徴量をSQLでとらえる
* dbtのモデル分割:

  * `staging/` : 基本取り込み
  * `features/` : 特徴量SQL
  * `splits/` : train/test 分割
* DuckDB なら notebookの合間にテストできる

---

## 【🚀 提供テンプレート (必要なら)】

* `databricks_snowflake_dbt_demo.ipynb`
* `minio_event_logs.jsonl`
* `dbt_project/` の staging.sql + marts.sql
* `profiles.yml` (複数target切替)

---

【🏆 この構成は PoC, 本番, Kaggle, CI/CD, マルチクラウド のすべてを輝かせる底力の椅子になります。
