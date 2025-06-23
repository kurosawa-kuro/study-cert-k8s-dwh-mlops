#!/bin/bash
# ファイル名リファクタリングスクリプト
# 日本語で分かりやすいファイル名に変更

set -e

echo "=== ファイル名リファクタリング開始 ==="

# ルートディレクトリのファイル
echo "ルートディレクトリのファイルをリファクタリング中..."

mv "CKAD経験者向け_KCNA追加学習テーマ.md" "KCNA-追加学習テーマ.md" 2>/dev/null || echo "ファイルが存在しません: CKAD経験者向け_KCNA追加学習テーマ.md"
mv "KCNA_CKA_ドメイン対比シート_2025-06.md" "KCNA-CKA-ドメイン対比表.md" 2>/dev/null || echo "ファイルが存在しません: KCNA_CKA_ドメイン対比シート_2025-06.md"
mv "Kubernetes試験_ドメイン早見シート.md" "Kubernetes試験-ドメイン早見表.md" 2>/dev/null || echo "ファイルが存在しません: Kubernetes試験_ドメイン早見シート.md"
mv "★Udemy講座_知識穴埋め最適章_一覧.md" "Udemy講座-最適章一覧.md" 2>/dev/null || echo "ファイルが存在しません: ★Udemy講座_知識穴埋め最適章_一覧.md"
mv "アソシエイト系_学習教材一覧.md" "アソシエイト系-学習教材一覧.md" 2>/dev/null || echo "ファイルが存在しません: アソシエイト系_学習教材一覧.md"
mv "アソシエイト系_資格一覧.md" "アソシエイト系-資格一覧.md" 2>/dev/null || echo "ファイルが存在しません: アソシエイト系_資格一覧.md"

# KCNA-JPディレクトリのファイル
echo "KCNA-JPディレクトリのファイルをリファクタリング中..."
cd kcna-jp 2>/dev/null && {
    mv "KCNA_不足トピック_補完方法.md" "KCNA-不足トピック補完方法.md" 2>/dev/null || echo "ファイルが存在しません: KCNA_不足トピック_補完方法.md"
    mv "KCNA_最小ハンズオンメニュー.md" "KCNA-最小ハンズオン.md" 2>/dev/null || echo "ファイルが存在しません: KCNA_最小ハンズオンメニュー.md"
    mv "KCNA対策_直結章_抜粋.md" "KCNA-対策直結章.md" 2>/dev/null || echo "ファイルが存在しません: KCNA対策_直結章_抜粋.md"
    mv "KCNA特化_視聴すべき章.md" "KCNA-推奨視聴章.md" 2>/dev/null || echo "ファイルが存在しません: KCNA特化_視聴すべき章.md"
    cd ..
} || echo "KCNA-JPディレクトリが見つかりません"

# KCSAディレクトリのファイル
echo "KCSAディレクトリのファイルをリファクタリング中..."
cd kcsa 2>/dev/null && {
    mv "Istio講座_KC系対策評価.md" "KCSA-Istio講座評価.md" 2>/dev/null || echo "ファイルが存在しません: Istio講座_KC系対策評価.md"
    mv "KCSA_最小ハンズオンメニュー.md" "KCSA-最小ハンズオン.md" 2>/dev/null || echo "ファイルが存在しません: KCSA_最小ハンズオンメニュー.md"
    mv "KCSA対策_直結章_抜粋.md" "KCSA-対策直結章.md" 2>/dev/null || echo "ファイルが存在しません: KCSA対策_直結章_抜粋.md"
    cd ..
} || echo "KCSAディレクトリが見つかりません"

# Data Pipelineディレクトリのファイル
echo "Data Pipelineディレクトリのファイルをリファクタリング中..."
cd data-pipiline 2>/dev/null && {
    mv "Databricks_Snowflake_dbt_パイプライン構成.md" "Databricks-Snowflake-dbt-パイプライン構成.md" 2>/dev/null || echo "ファイルが存在しません: Databricks_Snowflake_dbt_パイプライン構成.md"
    cd ..
} || echo "Data Pipelineディレクトリが見つかりません"

echo "=== リファクタリング完了 ==="
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