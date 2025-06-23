### 「Istio Service Mesh Masterclass + AWS EKS」講座は KC 系対策に“重い”か？

| 観点           | コメント                                                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------------------------- |
| **ボリューム**    | 12 セクション / 64 レクチャー / **約 5 時間 30 分** ([udemy.com][1])                                                                  |
| **試験での出題割合** | KCNA では *Cloud-Native Architecture* ドメイン全体で 16 % しかなく、その中で Service Mesh は “Landscape を知っているか” が 1〜2 問レベル ([cncf.io][2]) |
| **深さ**       | 講座は Gateway, Canary, Fault Injection まで実装するため、**実務ハンズオン寄り**。試験が要求する「Sidecar 方式・mTLS が何か説明できる」よりははるかに踏み込んでいる             |

#### まとめ

* **試験点数の純粋な伸び幅**に対する **時間コストは割高**。

  * 全章をこなしても KCNA/KCSA のスコアに寄与するのは 2〜3 問程度。
* ただし **EKS 上で Mesh を PoC したい／将来 mTLS を本番導入したい** なら、貴重な日本語教材なので投資価値は高い。

---

## おすすめの“軽量”利用法（試験優先の場合）

| 優先度 | 章                                    | 何が拾えるか                                  | 所要     |
| --- | ------------------------------------ | --------------------------------------- | ------ |
| ★★★ | **Istio 概要 / アーキテクチャ**               | Data-plane vs Control-plane、Sidecar の役割 | 20 分   |
| ★★★ | **mTLS 全体有効化 & STRICT モード**          | Zero-Trust・暗号化通信キーワード                   | 25 分   |
| ★★☆ | **JWT 認証 / 認可**                      | KCSA「Platform Security」領域にも効く           | 20 分   |
| ★☆☆ | Fault Injection / Circuit Breaker など | SRE ネタ（可観測性への言及）                        | 試験後でも可 |

→ **合計 1 時間強で「Service Mesh 基礎＋セキュリティ要素」を押さえ、残りは試験後に回す** のが高コスパです。

---

## もし講座をスキップするなら

1. **Istio 公式 “What is Istio?” ページを日本語に機械翻訳（10 分）**
2. **Bookinfo サンプルを kind でデプロイ → `istioctl install --set profile=demo` だけ実行（20 分）**
3. **模擬試験で Service Mesh が出たら都度ノートを更新（15 分）**

これで **試験に十分な“概念＋用語”は 45 分以内** で補えます。

---

### 最終判断

* **「合格が最優先」→** 上記★印の章だけ摘み食い or 公式ドキュメントで穴埋め
* **「将来 EKS で Istio を本格運用」→** 今のうちに全章を流して PoC 手順書を残しておくと後工程が楽

ご自身のロードマップ（まず Helm→Argo CD→Operator を極める方針）に合わせて、**時間配分とリターン**を天秤にかけてみてください。

[1]: https://www.udemy.com/course/istio-service-mesh-masterclass-kubernetes-aws-eks-2020/?srsltid=AfmBOor18UDfkUrAtiNiAu5vFsdAW2jfjdG3ya2r1b7KgJ8LHjaAq0r0&utm_source=chatgpt.com "Complete Istio Service Mesh (1.8) Masterclass + AWS EKS | Udemy"
[2]: https://www.cncf.io/training/certification/kcna/ "Kubernetes and Cloud Native Associate (KCNA) | CNCF"
