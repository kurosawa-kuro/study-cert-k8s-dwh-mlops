# Cluster Hardening 基礎 — ウェブエンジニア向け実践ガイド

> **対象:** ウェブエンジニア（SQLインジェクション等の基礎セキュリティ知識あり）が KCSA 試験対策として押さえる **Cluster Hardening** のエッセンシャル。
> **範囲:** RBAC, Pod Security Standards (PSS), Admission Controller (OPA Gatekeeper / Kyverno)
> **目標:** 最小権限 & ポリシー駆動のクラスタを素早く構築し、`kubectl run` で Privileged Pod が拒否されることを実演・理解する。

---

## 1. A4 図解：Security フロー全体像（攻撃者視点）

```
┌────────┐   ServiceAccount   ┌──────────────┐   Pod  ┌──────────────┐
│  User  │───(kubectl)───▶───│   RBAC Auth   │───▶───▶│  PSA / PSS   │──▶ …
└────────┘    can‑i?          └──────────────┘  allow/deny  └──────────────┘
                                        │                │
                                        ▼                ▼
                             ┌───────────────────┐  ┌───────────────────┐
                             │  OPA Gatekeeper   │  │     Kyverno       │
                             │(Validating/Mutate)│  │(Validate/Mutate) │
                             └───────────────────┘  └───────────────────┘
```

**攻撃ベクトル:**
- **RBAC**: 権限昇格・サービスアカウント悪用・過剰権限
- **PSS**: 特権コンテナ・ホストマウント・リソース枯渇
- **Admission**: ポリシー回避・不正なリソース作成・セキュリティ設定無視

---

## 2. ウェブエンジニア向けベストプラクティス

| カテゴリ          | ベストプラクティス                                                        | ウェブアプリとの関連性                                    |
| ------------- | ---------------------------------------------------------------- | ----------------------------------------------- |
| **RBAC**      | *Role/ClusterRole を職務単位で細分化し、`kubectl auth can-i --as` で定期検証*    | Webアプリのユーザー権限管理・セッション管理に類似              |
| **PSS**       | *Namespace に `baseline` → `restricted` へ段階的に Enforcement を引き上げる* | Webアプリの入力検証・出力エスケープ・実行権限制限に類似          |
| **Admission** | *OPA Gatekeeper / Kyverno で組織ポリシーをコード化 (GitOps) ＋ CI でテスト*       | Webアプリのバリデーション・サニタイゼーション・セキュリティヘッダーに類似 |

---

## 3. Hands‑on ラボ（20 分）

### 3.1 Pod Security Standards — Privileged Pod 拒否を確認

```bash
# 1) 制限付き Namespace 作成
kubectl create ns secure
kubectl label ns secure pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=latest

# 2) Privileged Pod を試行（失敗するはず）
kubectl run priv-nginx --image=nginx --privileged --restart=Never -n secure
# => Error: pods "priv-nginx" is forbidden: violates PodSecurity "baseline:privileged"
```

> **Tweak:** `enforce=restricted` に変更すると特権コンテナだけでなく `hostNetwork`, `hostPID` なども拒否される。

### 3.2 Kyverno で Privileged 禁止をポリシー化

```bash
# 1) インストール (kind 環境例)
kubectl create -f https://raw.githubusercontent.com/kyverno/kyverno/release/v1.12/config/release/install.yaml

# 2) ポリシー (validate‑privileged.yaml)
cat <<'EOF' | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-privileged
    match:
      resources:
        kinds: [ Pod ]
    validate:
      message: "Privileged containers are not allowed"
      pattern:
        spec:
          =(securityContext):
            =(privileged): "false"
EOF

# 3) 再チャレンジ
kubectl run priv2 --image=nginx --privileged --restart=Never -n default
# => Error from server: admission webhook "validate.kyverno.svc" denied the request
```

### 3.3 Gatekeeper で same policy (オプション)

```bash
# Quick install
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.x/deploy/gatekeeper.yaml

# ConstraintTemplate + Constraint 例は公式サンプルを参照
```

---

## 4. チェックリスト ✅ / ❌

* [ ] `kubectl auth can-i --list` の出力を読解できる
* [ ] baseline と restricted の主な差分を 3 つ列挙できる
* [ ] Kyverno / Gatekeeper どちらでも Privileged 拒否が機能する
* [ ] Admission エラーを `kubectl describe pod` で追跡できる
* [ ] ウェブアプリケーションの **セキュリティ制御** との関連性を理解している

---

## 5. 推奨リソース

* Kubernetes 公式 Docs — **Pod Security Standards**
* Kyverno Policy Samples — Disallow Privileged
* OPA Gatekeeper Library — `k8spspprivileged` ConstraintTemplate
* Blog: "From PodSecurityPolicy to PSS + Kyverno" (CNCF)
* OWASP Kubernetes Security Cheat Sheet

---

### エンドノート

このガイドは「**PSS → Admission Controller → RBAC**」の 3 段レイヤで守りを固めるための最短ルートです。まずは Privileged Pod を Block できる状態まで進め、次に `hostNetwork` 禁止やイメージ署名検証など他ポリシーへ拡張してみてください。ウェブエンジニアの既存セキュリティ知識を活かし、k8s 固有のセキュリティ制御を理解してください。
