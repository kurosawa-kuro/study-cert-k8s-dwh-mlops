### `gitops-cicd-basics.md` — GitOps & CI/CD Deep-Dive

*CKAD 合格レベルの YAML/`kubectl` スキルを前提に、
KCNA・KCSA・CKS で求められる **“Git 主導デプロイ文化”** を体系的に押さえるガイド。*

---

## 1. WHY — そもそも GitOps を採用する理由

| 従来 (ClickOps / 手動 kubectl)      | **GitOps**                              |
| ------------------------------- | --------------------------------------- |
| 人手更新 → Drift → 再現困難             | **単一信頼源 (Git)** に宣言的マニフェストを保存           |
| いつ誰が変更したか不明                     | Git Commit & PR で **監査証跡**              |
| マルチ環境 (dev/test/prod) の差分管理が手作業 | **ブランチ or Kustomize/Helm** で環境パッチ管理     |
| 手動 Rollback                     | Git Revert → **即 Rollback** (Reconcile) |

---

## 2. WHAT — 用語＆コンポーネント対比

| レイヤ    | CI (Build/Test)                            | CD (GitOps Sync)                        |
| ------ | ------------------------------------------ | --------------------------------------- |
| 主要 OSS | GitHub Actions, Jenkins, Tekton, GitLab CI | **Argo CD, Flux**                       |
| トリガ    | Push / PR / Tag                            | Git チェックサム差分 or `ImageUpdateAutomation` |
| 産物     | コンテナイメージ, Helm Chart                       | 実クラスタの **Desired State = Git**          |
| アクション  | Lint, UnitTest, `docker build/push`        | Reconcile, Health Check, Auto-Rollback  |

> **覚え方**:
> **CI → “モノを作るまで”** **CD → “作ったモノを届けるまで”**

---

## 3. GitOps ツール 2 強イメージ

|                 | **Argo CD**                   | **Flux (v2)**                        |
| --------------- | ----------------------------- | ------------------------------------ |
| デプロイ方式          | Pull (Reconciler Pod)         | Pull (Controller + Source/Sync CRD)  |
| UI              | あり (React ダッシュボード)            | GitOps Toolkit CLI + Grafana ダッシュボード |
| マルチクラスター        | ApplicationSet (Generator)    | Fleet Pattern (multi-tenant)         |
| 自動 Image Update | Argo Rollouts / Image updater | `ImageUpdateAutomation` CRD          |
| 用途イメージ          | UI で状態を可視化したいチーム              | 完全宣言的・CLI 派の SRE                     |

---

## 4. HOW — 最小パイプライン作ってみる

### 4-1. レポジトリ構成例

```
gitops-demo/
 ├─ kustomization.yaml
 ├─ base/
 │   └─ deployment.yaml   # image: demo:v1
 └─ overlays/prod/
     └─ kustomization.yaml (replicas=3)
```

### 4-2. CI (GitHub Actions)

```yaml
# .github/workflows/build.yml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & Push
        run: |
          docker build -t ghcr.io/org/demo:${{ github.sha }} .
          docker push ghcr.io/org/demo:${{ github.sha }}
      - name: Patch kustomize
        run: |
          yq -i '.images[0].newTag = "${{ github.sha }}"' base/kustomization.yaml
      - name: Commit back
        run: |
          git config user.name bot && git config user.email bot@gh
          git commit -am "image bump ${{ github.sha }}" && git push
```

### 4-3. CD (Argo CD)

```bash
# ❶ Install (kind cluster)
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ❷ Register repo
argocd repo add https://github.com/you/gitops-demo.git

# ❸ Create Application
argocd app create demo \
  --repo https://github.com/you/gitops-demo.git \
  --path overlays/prod \
  --dest-namespace prod --dest-server https://kubernetes.default.svc

# ❹ 自動同期
argocd app set demo --sync-policy automated
```

`git push` → GitHub Actions で新イメージ Tag → kustomize patch → commit
→ Argo CD が差分検知 → **Pod 自動 RollingUpdate** が流れる。

---

## 5. セキュリティ“3 つの鉄則”

1. **最小 RBAC**   Argo CD/Flux の ServiceAccount は `apps/*`, `patch` のみに絞る
2. **署名イメージだけ許可**   cosign + Kyverno/OPA Gatekeeper
3. **PR / MR レビュー必須**   GitHub CODEOWNERS で Ops チーム承認を強制

---

## 6. KCNA / KCSA / CKS 試験チート

| 試験       | 出やすいワード                    | ワンフレーズ回答例                                                          |
| -------- | -------------------------- | ------------------------------------------------------------------ |
| **KCNA** | *“GitOps 原則”*              | Single Source of Truth, Automated Sync, Continuous Drift Detection |
| **KCSA** | *“supply-chain hardening”* | Image signature + Admission controller in GitOps pipeline          |
| **CKS**  | *“Progressive Delivery”*   | Argo Rollouts Canary / Blue-Green with automated metrics analysis  |

---

## 7. 20 分セルフチェッククイズ

1. GitOps 3 原則を順番に挙げる
2. “Push-based CD” と “Pull-based GitOps” の違いは？
3. Argo CD で **自動 Rollback** が起こる条件は？
4. Flux で **イメージ自動更新** を有効化する CRD 名は？

<details><summary>回答例</summary>

1. Declarative – SSoT, Automated Change, Continuous Reconciliation
2. Push: CI から `kubectl apply`; Pull: クラスタが Git を Watch
3. Health=Degraded で前コミットとの差分が自動復元設定あり
4. `ImageUpdateAutomation`

</details>

---

## 8. まとめ & 次の一歩

* GitOps = **Git を Kubernetes Desired State の唯一ソース**にする運用文化
* CI と CD を物理的・責務的に **分離** → セキュリティとスケール両立
* **Argo CD or Flux** を 1 つ PoC し、

  * `git revert` → 自動 Rollback
  * イメージ Tag Push → 自動 Update
    を体験するのが最短学習コース。

> 高度なトピック（Progressive Delivery, Multi-Cluster, Secret Encryption）も必要なら順次ガイドを追加します。お気軽に！
