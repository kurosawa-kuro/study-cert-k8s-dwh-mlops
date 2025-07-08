失礼しました。先ほどは **CKA** のロードマップを提示してしまいました。あらためて **「CKAD 合格」** に特化した最速～じっくりプランを作り直しました。
（2025 年6 月現在の公式ドメイン別ウェイトに基づいています）([training.linuxfoundation.org][1])

---

## ✅ CKAD 最速ロードマップ（7 日集中）

> 想定：
>
> * Killer Shell/KodeKloud の模擬環境を一度でも触ったことがある
> * kind + kubectl alias + vim 環境は用意済み（※ alias 例は後述）
> * YAML 記述と `kubectl run/apply/edit` 系コマンドは反射で打てる

| Day | ドメイン (公式比重)                             | 重点タスク                                                                    | 必須アウトプット                                |
| --- | --------------------------------------- | ------------------------------------------------------------------------ | --------------------------------------- |
| 1   | **Application Design & Build 20 %**     | \* multi-container（sidecar/init）パターン<br>\* `kubectl exec` での結線確認         | Deployment/Pod 6 パターンを **30 分以内** に作成   |
| 2   | **Application Deployment 20 %**         | \* Rolling / Blue-Green / Canary<br>\* Helm & Kustomize manifest パッチ     | `--record` 付き `kubectl rollout` で履歴操作   |
| 3   | **Environment, Config & Security 25 %** | \* ConfigMap/Secret マウント・変数展開<br>\* SecurityContext, SA, LimitRange      | 貼り付け禁止。**vim snippet で再現**              |
| 4   | **Services & Networking 20 %**          | \* ClusterIP → NodePort → Ingress 写経<br>\* NetworkPolicy の allow/deny 実験 | Ingress トラブルを `kubectl logs` で 5 分以内に特定 |
| 5   | **Observability 15 %**                  | \* readiness/liveness probes<br>\* `kubectl top/describe`, `logs -f` 連携  | Pod クラッシュの原因を `--previous` で特定          |
| 6   | **総合トラブルシュート**                          | 公式５ドメイン混在のミニ模試（自作 or Killer Shell）                                       | 15 問を 90 分で完答 → 60 分で解説整理               |
| 7   | **模試 ×2 (killer.sh/KK)**                | \* `.vimrc`, `~/.bashrc` alias 最終調整<br>\* 利用中キーボード配列確認                   | 実試験と同じ 2 hour ×2 セッション                  |

---

## ✅ CKAD じっくりロードマップ（14 日）

| 期間      | 目標                          | 補足ポイント                                             |
| ------- | --------------------------- | -------------------------------------------------- |
| Day 1-2 | Design & Build 徹底反復         | PodTemplateSpec を **手書き** → manifest 生成速度を上げる      |
| Day 3-4 | Deployment + Helm/Kustomize | `helm template` と `kustomize edit set image` の差異整理 |
| Day 5-6 | Config/Security 深掘り         | OPA/Gatekeeper の CRD を 1 回だけ触り概念把握                 |
| Day 7   | NetworkPolicy & Ingress 実験  | 自前の kind cluster で `curl --connect-timeout` 検証     |
| Day 8   | Volume & State Persistence  | emptyDir vs hostPath vs PVC シナリオ比較表を作る             |
| Day 9   | Observability 強化            | `stern`, `k9s` など外部ツールも試し「使わないと決める」                |
| Day 10  | API Deprecation 対策          | `kubectl explain` で v1beta1 ⇒ stable に書き換え練習       |
| Day 11  | 模試① → ギャップ洗い出し              | Killer Shell 1 周目・正答率 ≦80 % を全てメモ                  |
| Day 12  | 弱点ドメイン再学習                   | 重み 25 % の Config/Security を優先                      |
| Day 13  | 模試② → 90 %以上狙い              | 36 h 有効期間を活かし 2 回回す                                |
| Day 14  | タイムマネジメント仕上げ                | 失点が許容内か確認し本番へ                                      |

---

### 🧠 使いまわせるチートシート

```bash
# ~/.bashrc 追記例
alias k='kubectl'
alias kgp='kubectl get pods -o wide'
alias kaf='kubectl apply -f'
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# ~/.vimrc（一例）
set ts=2 sts=2 sw=2 et
nnoremap <leader>y :w !tee /tmp/ckad-$(date +%s).yaml<CR><CR>
```

**ポイント**

1. **入力補完ではなくスニペット思考**
   特定リソース（PodTemplateSpec, NetworkPolicy など）をコピペせず
   `:read ~/.ckad/snippets/np-allow-dns.yaml` のように読み込む練習を。

2. **公式ウェイトを意識**
   Config/Security (25 %) と Deployment/Build (計40 %) を落とさない。
   Observability 15 % は「掘りすぎ注意」でスコア効率を最適化。

3. **自作 mini-lab を活用**
   既に構築済みの kind + Ingress + Helm ラボを **壊して直す** 演習に流用。

---

#### 追加サポート

* **Day ごとの演習 YAML**（問題→回答例）
* **模試ログの誤答分析シート**（問題番号・原因・修正コマンド）

これらを GitHub リポジトリ形式で作成し、
**k8s-ubuntu-kind-api-02-helm** 以降のチュートリアルと並行管理も可能です。
ご希望があればいつでも声をかけてください！

---

どちらのプランがフィットしそうでしょうか？
併せて “演習セットを準備する / 模試ログを整理する” などの支援も対応できますので、遠慮なくお知らせください。

[1]: https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/ "Certified Kubernetes Application Developer (CKAD) - Linux Foundation - Education"
