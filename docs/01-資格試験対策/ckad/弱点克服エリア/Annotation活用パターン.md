## CKAD Annotation Quick Sheet（試験範囲だけに絞った決定版）

> **狙い** ― CKAD 本番で _annotation_ が絡む設問に出会った瞬間、  
> “手が勝手に動く” レベルで最低限のコマンドと発想を思い出せるようにする。

---

### 0. まず暗記する 3 コマンド

|操作|雛形|覚えるポイント|
|---|---|---|
|**追加**|`k annotate <kind>/<name> key=value`|そのまま実行で即反映|
|**上書き**|`k annotate <kind>/<name> key=newVal --overwrite`|**--overwrite** を忘れない|
|**削除**|`k annotate <kind>/<name> key-`|末尾ハイフンで削除|

---

### 1. CKAD に「必要十分」な 4 パターン

|シーン|キー（＝annotation）|1 行コマンド例|効果・用途|
|---|---|---|---|
|**① 手動ローリング更新**（最速ロールアウト）|`kubectl.kubernetes.io/restartedAt`|`k annotate deploy/api kubectl.kubernetes.io/restartedAt="$(date +%s)" --overwrite`|タイムスタンプ変更→新 ReplicaSet が生成|
|**② CM/Secret 変更トリガ**（ハッシュで自動ローリング）|任意キー例：`checksum/config`|```bash||
|k annotate deploy/web \||||
|checksum/config="$(sha256sum cm.yaml|cut -d' ' -f1)" --overwrite|||

```|
| **③ ヒューマン向け説明コメント** | `kubernetes.io/description` | `k annotate svc/db kubernetes.io/description="PostgreSQL primary" --overwrite` | `kubectl get` 一覧で意味が通る |
| **④ CronJob 旧 API 互換**<br>（同時実行可否） | `cronjob.kubernetes.io/allow-concurrency` | `k annotate cj/report-runner cronjob.kubernetes.io/allow-concurrency="false"` | v1 移行絡みの“互換性”小問対策 |

> **暗記キーワード**  
> * restartedAt → “即ローリング”  
> * checksum/* → “ハッシュトリガ”  
> * description → “ただの説明”  
> * cronjob.* → “旧 API 互換”

<br>

---

### 2. 本番“安全運転”フロー

1. 問題文に **annotate** を見つけたら `k annotate -h | less` で書式を 5 秒確認。  
2. **--dry-run=client -o yaml** を付け試し打ち → 差分を目視。  
3. OK なら `--dry-run` を外し本番実行 → `k describe … | grep -A1 "Annotations:"` で反映確認。

<br>

---

### 3. よくあるハマりどころ 3 つ

| 罠 | 即対応 |
|----|--------|
| **同じキーが既に存在** → `annotation XYZ exists` | `--overwrite` を追加 |
| **値に空白・記号** | かならず `"ダブルクォート"` |
| **リソース名/Namespace ミス** | `k get <kind> -A` で事前確認 |

<br>

---

### 4. まとめ（TL;DR）

* **追加／上書き／削除** の 3 雛形を反射で打てるようにする。  
* 迷ったら **`kubectl annotate -h` → `--dry-run`** で即確認。  
* エラーが出たら **--overwrite とクォート** をまず疑う。

この手順だけで Annotation が絡む CKAD 問題はほぼ攻略できます。がんばってください 💪
```