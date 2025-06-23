#!/bin/bash
# ファイル名リファクタリングスクリプト
# 日本語で分かりやすいファイル名に変更（小文字統一）

set -e

echo "=== ファイル名リファクタリング開始（小文字統一） ==="

# ルートディレクトリのファイル
echo "ルートディレクトリのファイルをリファクタリング中..."

mv "KCNA-advanced-learning-topics.md" "kcna-追加学習テーマ.md" 2>/dev/null || echo "ファイルが存在しません: KCNA-advanced-learning-topics.md"
mv "KCNA-CKA-domain-comparison-2025-06.md" "kcna-cka-ドメイン対比表.md" 2>/dev/null || echo "ファイルが存在しません: KCNA-CKA-domain-comparison-2025-06.md"
mv "Kubernetes試験-ドメイン早見表.md" "kubernetes試験-ドメイン早見表.md" 2>/dev/null || echo "ファイルが存在しません: Kubernetes試験-ドメイン早見表.md"
mv "Udemy講座-最適章一覧.md" "udemy講座-最適章一覧.md" 2>/dev/null || echo "ファイルが存在しません: Udemy講座-最適章一覧.md"
mv "アソシエイト系-学習教材一覧.md" "アソシエイト系-学習教材一覧.md" 2>/dev/null || echo "ファイルが存在しません: アソシエイト系-学習教材一覧.md"
mv "アソシエイト系-資格一覧.md" "アソシエイト系-資格一覧.md" 2>/dev/null || echo "ファイルが存在しません: アソシエイト系-資格一覧.md"

# KCNA-JPディレクトリのファイル
echo "KCNA-JPディレクトリのファイルをリファクタリング中..."
cd kcna-jp 2>/dev/null && {
    mv "KCNA-不足トピック補完方法.md" "kcna-不足トピック補完方法.md" 2>/dev/null || echo "ファイルが存在しません: KCNA-不足トピック補完方法.md"
    mv "KCNA-最小ハンズオン.md" "kcna-最小ハンズオン.md" 2>/dev/null || echo "ファイルが存在しません: KCNA-最小ハンズオン.md"
    mv "KCNA-対策直結章.md" "kcna-対策直結章.md" 2>/dev/null || echo "ファイルが存在しません: KCNA-対策直結章.md"
    mv "KCNA-推奨視聴章.md" "kcna-推奨視聴章.md" 2>/dev/null || echo "ファイルが存在しません: KCNA-推奨視聴章.md"
    cd ..
} || echo "KCNA-JPディレクトリが見つかりません"

# KCSAディレクトリのファイル
echo "KCSAディレクトリのファイルをリファクタリング中..."
cd kcsa 2>/dev/null && {
    mv "KCSA-Istio講座評価.md" "kcsa-istio講座評価.md" 2>/dev/null || echo "ファイルが存在しません: KCSA-Istio講座評価.md"
    mv "KCSA-最小ハンズオン.md" "kcsa-最小ハンズオン.md" 2>/dev/null || echo "ファイルが存在しません: KCSA-最小ハンズオン.md"
    mv "KCSA-対策直結章.md" "kcsa-対策直結章.md" 2>/dev/null || echo "ファイルが存在しません: KCSA-対策直結章.md"
    cd ..
} || echo "KCSAディレクトリが見つかりません"

# Data Pipelineディレクトリのファイル
echo "Data Pipelineディレクトリのファイルをリファクタリング中..."
cd data-pipiline 2>/dev/null && {
    mv "Databricks-Snowflake-dbt-パイプライン構成.md" "databricks-snowflake-dbt-パイプライン構成.md" 2>/dev/null || echo "ファイルが存在しません: Databricks-Snowflake-dbt-パイプライン構成.md"
    cd ..
} || echo "Data Pipelineディレクトリが見つかりません"

echo "=== リファクタリング完了（小文字統一） ==="
echo "変更後のファイル一覧:"
ls -la *.md 2>/dev/null || echo "ルートディレクトリに.mdファイルがありません"

echo ""
echo "サブディレクトリのファイル一覧:"
for dir in kcna-jp kcsa data-pipiline; do
    if [ -d "$dir" ]; then
        echo "--- $dir ---"
        ls -la "$dir"/*.md 2>/dev/null || echo "  .mdファイルがありません"
    fi
done 