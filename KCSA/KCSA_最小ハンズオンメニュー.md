### KCSA 用（合計 6〜8 時間）

|ラボ|目安|触っておく CLI / ツール|
|---|---|---|
|**1. RBAC & ServiceAccount**|1 h|`kubectl auth can-i` / RoleBinding|
|**2. PodSecurity-level 実験**|1 h|非特権→特権付き Pod を試し、Admission でブロック確認|
|**3. NetworkPolicy 基礎**|1 h|`kubectl exec` で pod 間通信テスト|
|**4. イメージスキャン**|30 min|`trivy image nginx:alpine`|
|**5. CIS ベンチ**|30 min|`kube-bench node` でレポートを眺める|
|**6. Audit Log & Secrets**|1 h|`--audit-policy-file` で簡易ログ、Secret Base64 デコード確認|
|**7. 簡易脅威シナリオ**|1 h|hostPath マウント → コンテナからホスト書き換えが拒否される例を作る|

> **“危ない設定を再現→ガードレールで防ぐ”** 流れを体験すると択一でもイメージが湧きやすい。