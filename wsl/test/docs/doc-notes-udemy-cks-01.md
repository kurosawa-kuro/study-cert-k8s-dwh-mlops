cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh
cd ../script
make reset-heavy


=========================================================
問題1 - Falcoによるランタイムセキュリティ監視
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、Falcoをインストールしてください。

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco \
  --namespace falco --create-namespace \
  --set falco.grpc.enabled=true \
  --set falco.grpcOutput.enabled=true
```

問題

runtime-security名前空間で不審な動作を行うPodが動作しています。Falcoを使用して脅威を検出し、対処してください。

1. Falcoのログを確認し、どのような不審な動作が検出されているか確認してください。

2. 以下の動作を検出するカスタムFalcoルールを作成してください：
   - /etc/passwdファイルへの読み取りアクセス
   - 特権コンテナの起動
   - コンテナ内でのshellの実行

3. suspicious-podというPodを作成し、/etc/passwdを読み取るコマンドを実行してFalcoが検出することを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Falcoのログを確認
kubectl logs -n falco -l app.kubernetes.io/name=falco -f

# カスタムルールを作成
cat <<EOF > falco-custom-rules.yaml
- rule: Read sensitive file
  desc: Detect read of sensitive files
  condition: >
    open_read and 
    container and
    fd.name in (/etc/passwd, /etc/shadow)
  output: >
    Sensitive file read (user=%user.name command=%proc.cmdline file=%fd.name container_id=%container.id)
  priority: WARNING

- rule: Privileged Container Started
  desc: Detect privileged container
  condition: >
    container_started and 
    container.privileged=true
  output: >
    Privileged container started (user=%user.name container_id=%container.id image=%container.image.repository)
  priority: WARNING

- rule: Shell in container
  desc: Shell spawned in container
  condition: >
    spawned_process and 
    container and
    proc.name in (bash, sh, zsh)
  output: >
    Shell spawned in container (user=%user.name container_id=%container.id shell=%proc.name)
  priority: NOTICE
EOF

# ConfigMapとして適用
kubectl create configmap falco-custom-rules -n falco --from-file=falco-custom-rules.yaml
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題2 - Trivyによるイメージ脆弱性スキャン
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、Trivyをインストールしてください。

```bash
# Trivy-operatorのインストール
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/trivy-operator/main/deploy/static/trivy-operator.yaml
```

問題

vulnerable-apps名前空間に脆弱性のあるコンテナイメージを使用したアプリケーションがデプロイされています。

1. 以下のイメージの脆弱性をスキャンしてください：
   - nginx:1.14  
   - wordpress:4.8-apache
   - redis:3.2

2. CRITICAL以上の脆弱性を持つイメージを特定してください。

3. ImagePolicyWebhookを設定し、HIGH以上の脆弱性を持つイメージのデプロイを防ぐポリシーを作成してください。

4. 安全なイメージ（nginx:alpine-latest）を使用してsecure-appというDeploymentを作成してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Trivyでイメージをスキャン
trivy image nginx:1.14
trivy image wordpress:4.8-apache  
trivy image redis:3.2

# VulnerabilityReportを確認
kubectl get vulnerabilityreports -A
kubectl describe vulnerabilityreport -n vulnerable-apps

# ImagePolicyWebhookの設定
cat <<EOF > image-policy-webhook.yaml
apiVersion: v1
kind: Config
clusters:
- name: image-bouncer-webhook
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://image-bouncer-webhook:1323/image_policy
contexts:
- name: image-bouncer-webhook
  context:
    cluster: image-bouncer-webhook
    user: api-server
current-context: image-bouncer-webhook
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題3 - OPA Gatekeeperによるポリシー適用
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、OPA Gatekeeperをインストールしてください。

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
```

問題

OPA Gatekeeperを使用して、以下のセキュリティポリシーを実装してください。

1. すべてのPodに以下のラベルを必須とするConstraintTemplateを作成してください：
   - app
   - version
   - environment

2. 特権コンテナの作成を禁止するポリシーを作成してください。

3. latest タグのイメージ使用を禁止するポリシーを作成してください。

4. ポリシーに違反するPodを作成し、拒否されることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 必須ラベルのConstraintTemplateを作成
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Label '%v' is required", [missing])
        }
EOF

# Constraintを作成
cat <<EOF | kubectl apply -f -
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-labels
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    labels: ["app", "version", "environment"]
EOF

# 特権コンテナ禁止のテンプレート
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8sdisallowprivileged
spec:
  crd:
    spec:
      names:
        kind: K8sDisallowPrivileged
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sdisallowprivileged
        violation[{"msg": msg}] {
          input.review.object.spec.containers[_].securityContext.privileged == true
          msg := "Privileged containers are not allowed"
        }
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題4 - AppArmorプロファイルの適用
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

AppArmorを使用してコンテナのシステムコールを制限する必要があります。

1. 以下の制限を持つAppArmorプロファイル「k8s-restricted」を作成してください：
   - /etc/へのwrite権限を拒否
   - /proc/へのread権限のみ許可
   - ネットワークのraw socketを拒否

2. apparmor-test名前空間を作成し、作成したプロファイルを使用するPodをデプロイしてください。

3. プロファイルが正しく適用されていることを確認するため、制限された操作を実行してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# AppArmorプロファイルを作成
cat <<EOF > /etc/apparmor.d/k8s-restricted
#include <tunables/global>

profile k8s-restricted flags=(attach_disconnected) {
  #include <abstractions/base>
  
  # ファイルシステムアクセス
  / r,
  /** r,
  
  # /etc/への書き込みを拒否
  deny /etc/** w,
  
  # /proc/への読み取りのみ許可
  /proc/** r,
  deny /proc/** w,
  
  # ネットワーク
  network inet stream,
  network inet dgram,
  deny network raw,
  
  # 必要な権限
  /usr/bin/** ix,
  /bin/** ix,
  /lib/** r,
}
EOF

# プロファイルをロード
apparmor_parser -r /etc/apparmor.d/k8s-restricted

# プロファイルの状態を確認
aa-status | grep k8s-restricted

# AppArmorを使用するPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: apparmor-test
---
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-pod
  namespace: apparmor-test
  annotations:
    container.apparmor.security.beta.kubernetes.io/restricted: localhost/k8s-restricted
spec:
  containers:
  - name: restricted
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
EOF

# 制限をテスト
kubectl exec -n apparmor-test apparmor-pod -- sh -c "echo test > /etc/test" # 失敗するはず
kubectl exec -n apparmor-test apparmor-pod -- sh -c "cat /proc/meminfo" # 成功するはず
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題5 - Seccompプロファイルによるシステムコール制限
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Seccompを使用してコンテナで使用可能なシステムコールを制限してください。

1. 以下のシステムコールのみを許可するカスタムSeccompプロファイルを作成してください：
   - read, write, open, close
   - exit, exit_group  
   - fstat, mmap, mprotect
   - rt_sigaction, rt_sigprocmask

2. 作成したプロファイルを使用するPodをseccomp-test名前空間にデプロイしてください。

3. 許可されていないシステムコール（例：mkdir）を実行し、ブロックされることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Seccompプロファイルを作成
mkdir -p /var/lib/kubelet/seccomp
cat <<EOF > /var/lib/kubelet/seccomp/restricted-profile.json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86"
  ],
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "close",
        "exit", "exit_group",
        "fstat", "mmap", "mprotect",
        "rt_sigaction", "rt_sigprocmask",
        "brk", "access", "nanosleep", "getpid"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
EOF

# Seccompを使用するPodを作成
kubectl create ns seccomp-test
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
  namespace: seccomp-test
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: restricted-profile.json
  containers:
  - name: test
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
EOF

# システムコールをテスト
kubectl exec -n seccomp-test seccomp-pod -- sh -c "echo 'test' > /tmp/test" # 成功
kubectl exec -n seccomp-test seccomp-pod -- sh -c "mkdir /tmp/newdir" # 失敗
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題6 - Pod Security Standards (PSS)の実装
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Pod Security Standards (PSS)を使用して、名前空間レベルでセキュリティポリシーを適用してください。

1. 以下の3つの名前空間を作成し、それぞれ異なるセキュリティレベルを設定してください：
   - privileged-ns: privilegedレベル
   - baseline-ns: baselineレベル  
   - restricted-ns: restrictedレベル

2. 各名前空間に以下のPodをデプロイし、どれが成功/失敗するか確認してください：
   - 特権コンテナ
   - hostNetworkを使用するPod
   - 非rootユーザーで実行されるPod

3. restricted-ns名前空間で動作する、完全に準拠したPodを作成してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間を作成してPSSラベルを設定
kubectl create ns privileged-ns
kubectl label ns privileged-ns \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged

kubectl create ns baseline-ns  
kubectl label ns baseline-ns \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline

kubectl create ns restricted-ns
kubectl label ns restricted-ns \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# 特権コンテナのテスト
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: privileged-ns # これは成功
spec:
  containers:
  - name: priv
    image: nginx:alpine
    securityContext:
      privileged: true
EOF

# restricted名前空間用の準拠Pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: restricted-ns
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-cache
    emptyDir: {}
  - name: var-run
    emptyDir: {}
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題7 - NetworkPolicyによるマイクロサービス間通信の保護
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成してください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cks-questions/main/practice-questions/7/resources.yaml

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: microservices
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment  
metadata:
  name: database
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "securepass"
```

問題

microservices名前空間でマイクロサービスアーキテクチャが動作しています。Zero Trust原則に従ってネットワークポリシーを実装してください。

1. デフォルトですべてのingress/egressトラフィックを拒否するNetworkPolicyを作成してください。

2. 以下の通信のみを許可してください：
   - frontend → backend-api (port 80)
   - backend-api → database (port 5432)
   - backend-api → 外部DNS (port 53, UDP/TCP)
   - すべてのPod → kube-dns

3. ポリシーが正しく機能することをテストしてください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# デフォルト拒否ポリシー
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: microservices
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# frontendのポリシー
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: microservices
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend-api
    ports:
    - protocol: TCP
      port: 80
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
EOF

# backend-apiのポリシー
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-api-policy
  namespace: microservices
spec:
  podSelector:
    matchLabels:
      app: backend-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  - ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題8 - RBACとServiceAccountの最小権限設定
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

最小権限の原則に従って、アプリケーション用のRBACを設定してください。

1. monitoring-app名前空間を作成し、以下のServiceAccountを作成してください：
   - metrics-reader: 全名前空間のPodとNodeのメトリクスを読み取り可能
   - log-collector: 特定の名前空間のPodログのみ読み取り可能

2. CI/CD用のServiceAccount「deploy-bot」を作成し、以下の権限を付与してください：
   - production名前空間でのDeploymentの作成・更新
   - ConfigMapとSecretの参照のみ（作成・更新は不可）

3. 権限が正しく設定されていることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間とServiceAccountを作成
kubectl create ns monitoring-app
kubectl create sa metrics-reader -n monitoring-app
kubectl create sa log-collector -n monitoring-app
kubectl create ns production
kubectl create sa deploy-bot -n production

# metrics-reader用のClusterRole
kubectl create clusterrole metrics-reader-role \
  --verb=get,list \
  --resource=pods,nodes,pods/status

kubectl create clusterrolebinding metrics-reader-binding \
  --clusterrole=metrics-reader-role \
  --serviceaccount=monitoring-app:metrics-reader

# log-collector用のRole
kubectl create role log-collector-role -n monitoring-app \
  --verb=get,list \
  --resource=pods,pods/log

kubectl create rolebinding log-collector-binding -n monitoring-app \
  --role=log-collector-role \
  --serviceaccount=monitoring-app:log-collector

# deploy-bot用のRole
kubectl create role deploy-bot-role -n production \
  --verb=create,update,patch,get,list \
  --resource=deployments,deployments/scale

kubectl create role deploy-bot-read-role -n production \
  --verb=get,list \
  --resource=configmaps,secrets

kubectl create rolebinding deploy-bot-binding -n production \
  --role=deploy-bot-role \
  --serviceaccount=production:deploy-bot

kubectl create rolebinding deploy-bot-read-binding -n production \
  --role=deploy-bot-read-role \
  --serviceaccount=production:deploy-bot

# 権限の確認
kubectl auth can-i --as=system:serviceaccount:monitoring-app:metrics-reader list pods --all-namespaces
kubectl auth can-i --as=system:serviceaccount:production:deploy-bot create deployments -n production
kubectl auth can-i --as=system:serviceaccount:production:deploy-bot create secrets -n production # falseになるはず
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題9 - etcdの暗号化設定
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

etcdに保存されるSecretを暗号化するように設定してください。

1. EncryptionConfigurationを作成し、AES-CBC暗号化を使用してSecretを暗号化してください。

2. kube-apiserverの設定を更新し、暗号化設定を適用してください。

3. 新しいSecretを作成し、etcdで暗号化されていることを確認してください。

4. 既存のSecretを再暗号化してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 暗号化キーを生成
head -c 32 /dev/urandom | base64

# EncryptionConfigurationを作成
cat <<EOF > /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: $(head -c 32 /dev/urandom | base64)
      - identity: {}
EOF

# kube-apiserverの設定を更新
# /etc/kubernetes/manifests/kube-apiserver.yamlを編集
# - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
# volumeMountとvolumeも追加

# apiserverの再起動を待つ
kubectl get pods -n kube-system | grep kube-apiserver

# 新しいSecretを作成
kubectl create secret generic test-secret --from-literal=key=value

# etcdで暗号化を確認
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/test-secret | hexdump -C

# 既存のSecretを再暗号化
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題10 - Admission Controllerの設定
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Admission Controllerを使用してクラスターのセキュリティを強化してください。

1. 以下のAdmission Controllerを有効化してください：
   - NodeRestriction
   - ResourceQuota
   - PodSecurityPolicy (またはPod Security)
   - EventRateLimit

2. EventRateLimitの設定ファイルを作成し、以下の制限を設定してください：
   - 名前空間ごとに1分間に100イベントまで
   - ユーザーごとに1分間に50イベントまで

3. ImagePolicyWebhookを設定し、承認されたレジストリからのイメージのみ許可してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# EventRateLimit設定を作成
cat <<EOF > /etc/kubernetes/admission/event-rate-limit-config.yaml
apiVersion: eventratelimit.admission.k8s.io/v1alpha1
kind: Configuration
limits:
- type: Namespace
  qps: 100
  burst: 200
  cacheSize: 2000
- type: User
  qps: 50
  burst: 100
EOF

# ImagePolicyWebhook設定
cat <<EOF > /etc/kubernetes/admission/admission-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/image-policy-webhook-kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
EOF

# kube-apiserverマニフェストを更新
# /etc/kubernetes/manifests/kube-apiserver.yamlに追加:
# - --enable-admission-plugins=NodeRestriction,ResourceQuota,PodSecurity,EventRateLimit,ImagePolicyWebhook
# - --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml

# 設定を確認
kubectl get pods -n kube-system | grep kube-apiserver
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題11 - コンテナランタイムサンドボックス（gVisor/Kata）
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

コンテナランタイムサンドボックスを使用して、信頼できないワークロードを隔離してください。

1. RuntimeClassを作成し、gVisorランタイム（runsc）を使用するように設定してください。

2. untrusted名前空間を作成し、gVisorランタイムを使用するPodをデプロイしてください。

3. 通常のruncランタイムとgVisorランタイムの違いを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# RuntimeClassを作成
cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF

# gVisorを使用するPodを作成
kubectl create ns untrusted
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gvisor-pod
  namespace: untrusted
spec:
  runtimeClassName: gvisor
  containers:
  - name: app
    image: nginx:alpine
    command: ["sh", "-c", "sleep 3600"]
EOF

# システムコールの違いを確認
kubectl exec -n untrusted gvisor-pod -- uname -a
kubectl exec -n untrusted gvisor-pod -- dmesg # 失敗するはず
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題12 - サプライチェーンセキュリティ：イメージ署名
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

コンテナイメージの署名と検証を実装してください。

1. Cosignを使用して、プライベートレジストリのイメージに署名してください。

2. ImagePolicyWebhookまたはOPA Gatekeeperを使用して、署名されたイメージのみをデプロイできるポリシーを作成してください。

3. 署名されていないイメージのデプロイが拒否されることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Cosignでキーペアを生成
cosign generate-key-pair

# イメージに署名
cosign sign --key cosign.key registry.example.com/myapp:v1.0

# 署名を検証
cosign verify --key cosign.pub registry.example.com/myapp:v1.0

# OPA Gatekeeperポリシーを作成
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiresignedimages
spec:
  crd:
    spec:
      names:
        kind: K8sRequireSignedImages
      validation:
        openAPIV3Schema:
          type: object
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiresignedimages
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not signed_image(container.image)
          msg := sprintf("Image %v is not signed", [container.image])
        }
        signed_image(image) {
          # 実際の実装では署名検証ロジックが必要
          endswith(image, ":signed")
        }
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題13 - Audit Loggingの設定と分析
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Kubernetesの監査ログを設定し、セキュリティイベントを分析してください。

1. 以下のイベントを記録する監査ポリシーを作成してください：
   - Secretへのすべてのアクセス（Metadata以上のレベル）
   - system:mastersグループによるすべての操作（RequestResponse レベル）
   - Podの作成・削除（Request レベル）

2. 監査ログを有効化し、/var/log/kubernetes/audit/に保存してください。

3. 監査ログから以下の情報を抽出してください：
   - 過去1時間にSecretにアクセスしたユーザー
   - 失敗した認証試行

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 監査ポリシーを作成
cat <<EOF > /etc/kubernetes/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Secretへのアクセス
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]
    
  # system:mastersグループの操作
  - level: RequestResponse
    userGroups: ["system:masters"]
    
  # Podの作成・削除
  - level: Request
    resources:
    - group: ""
      resources: ["pods"]
    verbs: ["create", "delete"]
    
  # それ以外は記録しない
  - level: None
EOF

# kube-apiserverに監査設定を追加
# /etc/kubernetes/manifests/kube-apiserver.yamlを編集
# - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
# - --audit-log-path=/var/log/kubernetes/audit/audit.log
# - --audit-log-maxage=30
# - --audit-log-maxbackup=10
# - --audit-log-maxsize=100

# 監査ログの分析
# Secretアクセスを検索
grep '"objectRef":{"resource":"secrets"' /var/log/kubernetes/audit/audit.log | \
  jq -r '.user.username' | sort | uniq

# 失敗した認証を検索
grep '"responseStatus":{"code":401' /var/log/kubernetes/audit/audit.log | \
  jq '.requestURI, .user.username, .sourceIPs[]'
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題14 - ホストのセキュリティ強化
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Kubernetesノードのホストレベルのセキュリティを強化してください。

1. すべてのワーカーノードで以下のカーネルパラメータを設定してください：
   - net.ipv4.ip_forward = 1
   - net.ipv4.conf.all.send_redirects = 0
   - kernel.panic = 10
   - kernel.panic_on_oops = 1

2. 不要なサービスを無効化してください：
   - snapd
   - iscsid

3. kubeletの設定を強化してください：
   - anonymous authを無効化
   - readOnlyPortを無効化
   - protectKernelDefaultsを有効化

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# カーネルパラメータを設定
cat <<EOF >> /etc/sysctl.d/90-kubernetes.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 0
kernel.panic = 10
kernel.panic_on_oops = 1
EOF

sysctl -p /etc/sysctl.d/90-kubernetes.conf

# 不要なサービスを無効化
systemctl disable --now snapd
systemctl disable --now iscsid

# kubelet設定を更新
# /var/lib/kubelet/config.yamlを編集
cat <<EOF >> /var/lib/kubelet/config.yaml
authentication:
  anonymous:
    enabled: false
readOnlyPort: 0
protectKernelDefaults: true
EOF

# kubeletを再起動
systemctl restart kubelet
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題15 - SELinuxの設定とトラブルシューティング
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

SELinuxを使用してコンテナのセキュリティを強化してください。

1. SELinuxをEnforcingモードに設定してください。

2. カスタムSELinuxコンテキストを持つPodを作成してください：
   - level: s0:c123,c456
   - type: container_t

3. SELinuxが原因でPodが起動しない問題をトラブルシューティングしてください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# SELinuxの状態を確認
getenforce
sestatus

# SELinuxをEnforcingに設定
setenforce 1
# 永続化
sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config

# SELinuxコンテキストを持つPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: selinux-pod
spec:
  securityContext:
    seLinuxOptions:
      level: "s0:c123,c456"
      type: "container_t"
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF

# SELinux関連のログを確認
ausearch -m AVC -ts recent
sealert -a /var/log/audit/audit.log

# トラブルシューティング
# ポリシーモジュールを作成
audit2allow -M mypolicy < /var/log/audit/audit.log
semodule -i mypolicy.pp
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題16 - kube-benchによるCISベンチマーク準拠確認
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

kube-benchを使用してクラスターのCISベンチマーク準拠を確認し、問題を修正してください。

1. kube-benchをインストールし、マスターノードとワーカーノードのチェックを実行してください。

2. 以下のFAILEDチェックを修正してください：
   - etcd data directoryの権限
   - kubelet設定ファイルの権限
   - audit log pathの設定

3. 修正後、再度kube-benchを実行し、改善を確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# kube-benchをインストール
wget https://github.com/aquasecurity/kube-bench/releases/download/v0.7.0/kube-bench_0.7.0_linux_amd64.tar.gz
tar -xvf kube-bench_0.7.0_linux_amd64.tar.gz

# マスターノードのチェック
./kube-bench run --targets=master

# ワーカーノードのチェック
./kube-bench run --targets=node

# etcd data directoryの権限を修正
chmod 700 /var/lib/etcd
chown etcd:etcd /var/lib/etcd

# kubelet設定ファイルの権限
chmod 600 /var/lib/kubelet/config.yaml
chown root:root /var/lib/kubelet/config.yaml

# 結果をJSONで出力
./kube-bench run --targets=master --json > bench-results.json

# 特定のチェックのみ実行
./kube-bench run --targets=master --check=1.2.6
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題17 - mtlsによるサービス間通信の暗号化
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

サービスメッシュを使用せずに、手動でmTLS（相互TLS認証）を実装してください。

1. secure-comm名前空間を作成し、CA証明書を生成してください。

2. client-appとserver-appの証明書を生成し、Secretとして保存してください。

3. mTLSを使用して通信するようにアプリケーションを設定してください。

4. 証明書なしでの通信が失敗することを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間を作成
kubectl create ns secure-comm

# CA証明書を生成
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 365 -key ca.key -out ca.crt \
  -subj "/C=US/ST=CA/L=SF/O=MyOrg/CN=MyCA"

# サーバー証明書を生成
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=CA/L=SF/O=MyOrg/CN=server-app.secure-comm.svc.cluster.local"
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt

# クライアント証明書を生成
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=CA/L=SF/O=MyOrg/CN=client-app"
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt

# Secretを作成
kubectl create secret generic server-certs -n secure-comm \
  --from-file=tls.crt=server.crt \
  --from-file=tls.key=server.key \
  --from-file=ca.crt=ca.crt

kubectl create secret generic client-certs -n secure-comm \
  --from-file=tls.crt=client.crt \
  --from-file=tls.key=client.key \
  --from-file=ca.crt=ca.crt

# mTLS対応のサーバーをデプロイ
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-mtls-config
  namespace: secure-comm
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 443 ssl;
        ssl_certificate /certs/tls.crt;
        ssl_certificate_key /certs/tls.key;
        ssl_client_certificate /certs/ca.crt;
        ssl_verify_client on;
        location / {
          return 200 "mTLS Success!\n";
        }
      }
    }
---
apiVersion: v1
kind: Pod
metadata:
  name: server-app
  namespace: secure-comm
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    volumeMounts:
    - name: certs
      mountPath: /certs
    - name: config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: certs
    secret:
      secretName: server-certs
  - name: config
    configMap:
      name: nginx-mtls-config
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題18 - 脆弱性のあるコンテナのトラブルシューティング
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成してください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cks-questions/main/practice-questions/18/resources.yaml

問題

vulnerable-app名前空間で動作しているアプリケーションに複数の脆弱性があります。これらを特定し、修正してください。

1. Deploymentを確認し、以下のセキュリティ問題を特定してください：
   - 特権コンテナ
   - hostNetworkの使用
   - 古い脆弱なイメージ
   - ハードコードされた認証情報

2. 各問題を修正し、セキュアな設定に更新してください。

3. 修正後のDeploymentがPod Security Standards（restricted）に準拠することを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 現在の設定を確認
kubectl get deploy -n vulnerable-app vulnerable-deployment -o yaml

# セキュリティ問題を修正
kubectl patch deployment vulnerable-deployment -n vulnerable-app --type='json' -p='[
  {"op": "remove", "path": "/spec/template/spec/hostNetwork"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "nginx:alpine-latest"},
  {"op": "remove", "path": "/spec/template/spec/containers/0/securityContext/privileged"},
  {"op": "add", "path": "/spec/template/spec/securityContext", "value": {
    "runAsNonRoot": true,
    "runAsUser": 1000,
    "fsGroup": 2000,
    "seccompProfile": {"type": "RuntimeDefault"}
  }}
]'

# 環境変数のSecretを作成
kubectl create secret generic db-creds -n vulnerable-app \
  --from-literal=username=dbuser \
  --from-literal=password=securepwd

# Secretを参照するように更新
kubectl set env deployment/vulnerable-deployment -n vulnerable-app \
  DB_USERNAME= DB_PASSWORD= \
  --from=secret/db-creds
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題19 - Supply Chain Security: SBOMの生成と分析
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

SBOM（Software Bill of Materials）を生成し、サプライチェーンの脆弱性を分析してください。

1. syftを使用して、以下のイメージのSBOMを生成してください：
   - node:14-alpine
   - python:3.8-slim

2. grypeを使用して、生成したSBOMから脆弱性を検出してください。

3. 検出された脆弱性のうち、CRITICAL以上のものをリストアップし、修正方法を提案してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# syftをインストール
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# grypeをインストール
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# SBOMを生成
syft node:14-alpine -o json > node-sbom.json
syft python:3.8-slim -o json > python-sbom.json

# 脆弱性をスキャン
grype sbom:node-sbom.json
grype sbom:python-sbom.json

# CRITICAL脆弱性のみ表示
grype sbom:node-sbom.json --severity critical

# 特定のパッケージの詳細を確認
syft node:14-alpine | grep -i openssl
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題20 - KubernetesのCVE対応
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

最近発見されたKubernetesのCVEに対応してください。

1. 現在のKubernetesバージョンを確認し、既知のCVEを調査してください。

2. CVE-2021-25735（Validating Admission Webhookのバイパス）の影響を受けているか確認してください。

3. 以下の軽減策を実装してください：
   - 影響を受けるAdmission Webhookの修正
   - 追加の検証ロジックの実装

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Kubernetesバージョンを確認
kubectl version --short

# ValidatingWebhookConfigurationを確認
kubectl get validatingwebhookconfigurations

# Webhook設定の詳細を確認
kubectl get validatingwebhookconfigurations <name> -o yaml

# CVE対策：sideEffectsを明示的に設定
kubectl patch validatingwebhookconfiguration <name> --type='json' -p='[
  {"op": "replace", "path": "/webhooks/0/sideEffects", "value": "None"}
]'

# timeoutSecondsを設定して確実性を向上
kubectl patch validatingwebhookconfiguration <name> --type='json' -p='[
  {"op": "add", "path": "/webhooks/0/timeoutSeconds", "value": 10}
]'
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題21 - Kubernetes Secretsの安全な管理
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Kubernetes Secretsをより安全に管理するための対策を実装してください。

1. secret-management名前空間を作成し、以下のSecretを作成してください：
   - database-creds: username=admin, password=secretpass
   - api-key: key=abc123xyz

2. 以下の制限を実装してください：
   - Secretへのアクセスを特定のServiceAccountのみに制限
   - Secretがコンテナの環境変数として公開されないようにする

3. Sealed Secretsを使用して、Secretをgitリポジトリに安全に保存できるようにしてください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間とSecretを作成
kubectl create ns secret-management
kubectl create secret generic database-creds -n secret-management \
  --from-literal=username=admin \
  --from-literal=password=secretpass

kubectl create secret generic api-key -n secret-management \
  --from-literal=key=abc123xyz

# ServiceAccountとRBACを設定
kubectl create sa app-sa -n secret-management

kubectl create role secret-reader -n secret-management \
  --verb=get \
  --resource=secrets \
  --resource-name=database-creds,api-key

kubectl create rolebinding app-secret-binding -n secret-management \
  --role=secret-reader \
  --serviceaccount=secret-management:app-sa

# Sealed Secretsコントローラーをインストール
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Sealed Secretを作成
echo -n mypassword | kubectl create secret generic mysecret \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml > mysealedsecret.yaml
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題22 - Container Breakoutの検出と防止
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

コンテナブレイクアウト攻撃を検出し、防止する対策を実装してください。

1. 以下の潜在的なブレイクアウトベクターをチェックしてください：
   - 特権コンテナ
   - ホストPIDネームスペースの共有
   - Dockerソケットのマウント

2. Falcoルールを作成して、以下の動作を検出してください：
   - コンテナ内からのnsenterコマンドの実行
   - /proc/sys/kernel/core_patternへの書き込み

3. PodSecurityPolicyまたはOPA Gatekeeperを使用して、危険な設定を防止してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 危険な設定を持つPodを検索
kubectl get pods -A -o json | jq '.items[] | select(
  .spec.containers[].securityContext.privileged == true or
  .spec.hostPID == true or
  (.spec.volumes[] | select(.hostPath.path == "/var/run/docker.sock"))
) | {namespace: .metadata.namespace, name: .metadata.name}'

# Falcoルールを作成
cat <<EOF > container-breakout-rules.yaml
- rule: Detect nsenter
  desc: Detect nsenter usage
  condition: >
    spawned_process and 
    container and 
    proc.name = "nsenter"
  output: >
    nsenter detected in container (user=%user.name container_id=%container.id command=%proc.cmdline)
  priority: CRITICAL

- rule: Write to core_pattern
  desc: Detect write to core_pattern
  condition: >
    open_write and 
    container and 
    fd.name = "/proc/sys/kernel/core_pattern"
  output: >
    Write to core_pattern detected (user=%user.name container_id=%container.id)
  priority: CRITICAL
EOF

# OPA Gatekeeperポリシー
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8sblockdangerous
spec:
  crd:
    spec:
      names:
        kind: K8sBlockDangerous
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sblockdangerous
        violation[{"msg": msg}] {
          input.review.object.spec.hostPID == true
          msg := "hostPID is not allowed"
        }
        violation[{"msg": msg}] {
          input.review.object.spec.volumes[_].hostPath.path == "/var/run/docker.sock"
          msg := "Mounting docker socket is not allowed"
        }
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題23 - クラスター間通信のセキュリティ
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

マルチクラスター環境でのセキュアな通信を設定してください。

1. クラスター間通信用のServiceAccountと証明書を作成してください。

2. 以下の設定を実装してください：
   - クラスター間のAPIサーバー通信にmTLSを使用
   - NetworkPolicyでクラスター間の通信を制限

3. クラスター間でSecretを安全に同期する方法を実装してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# クラスター間通信用のServiceAccountを作成
kubectl create sa cluster-sync -n kube-system

# 証明書を生成
openssl genrsa -out cluster-sync.key 2048
openssl req -new -key cluster-sync.key -out cluster-sync.csr \
  -subj "/CN=cluster-sync/O=system:masters"

# CSRをKubernetesで署名
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: cluster-sync
spec:
  request: $(cat cluster-sync.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

kubectl certificate approve cluster-sync

# ClusterRoleを作成
kubectl create clusterrole cluster-sync-role \
  --verb=get,list,watch \
  --resource=secrets,configmaps

kubectl create clusterrolebinding cluster-sync-binding \
  --clusterrole=cluster-sync-role \
  --serviceaccount=kube-system:cluster-sync
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題24 - コンプライアンス監査とレポート
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

定期的なセキュリティコンプライアンス監査を実装してください。

1. 以下の項目をチェックするスクリプトを作成してください：
   - 特権コンテナの数
   - デフォルトServiceAccountを使用しているPod
   - NetworkPolicyが設定されていない名前空間

2. 結果をPrometheusメトリクスとして公開してください。

3. 毎日実行されるCronJobを作成し、結果をSlackに通知してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# コンプライアンスチェックスクリプト
cat <<'EOF' > /tmp/compliance-check.sh
#!/bin/bash

# 特権コンテナをカウント
PRIV_COUNT=$(kubectl get pods -A -o json | \
  jq '[.items[].spec.containers[] | select(.securityContext.privileged == true)] | length')

# デフォルトSAを使用しているPod
DEFAULT_SA_COUNT=$(kubectl get pods -A -o json | \
  jq '[.items[] | select(.spec.serviceAccountName == "default" or .spec.serviceAccountName == null)] | length')

# NetworkPolicyなしの名前空間
NS_WITHOUT_NETPOL=$(kubectl get ns -o json | \
  jq -r '.items[].metadata.name' | \
  xargs -I {} bash -c 'if [ $(kubectl get networkpolicy -n {} 2>/dev/null | wc -l) -eq 0 ]; then echo {}; fi' | \
  wc -l)

# Prometheusメトリクス形式で出力
cat <<METRICS
# HELP k8s_compliance_privileged_containers Number of privileged containers
# TYPE k8s_compliance_privileged_containers gauge
k8s_compliance_privileged_containers $PRIV_COUNT

# HELP k8s_compliance_default_sa_pods Number of pods using default SA  
# TYPE k8s_compliance_default_sa_pods gauge
k8s_compliance_default_sa_pods $DEFAULT_SA_COUNT

# HELP k8s_compliance_ns_without_netpol Number of namespaces without NetworkPolicy
# TYPE k8s_compliance_ns_without_netpol gauge  
k8s_compliance_ns_without_netpol $NS_WITHOUT_NETPOL
METRICS
EOF

chmod +x /tmp/compliance-check.sh

# CronJobを作成
kubectl create configmap compliance-script --from-file=/tmp/compliance-check.sh

cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: compliance-audit
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: compliance-checker
          containers:
          - name: checker
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - /scripts/compliance-check.sh
            volumeMounts:
            - name: script
              mountPath: /scripts
          volumes:
          - name: script
            configMap:
              name: compliance-script
              defaultMode: 0755
          restartPolicy: OnFailure
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題25 - Istio Service Meshのセキュリティ設定
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

# Istioのインストール
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

問題

Istioを使用してサービスメッシュのセキュリティを強化してください。

1. bookinfo名前空間でサンプルアプリケーションをデプロイし、以下を設定してください：
   - 名前空間に自動サイドカーインジェクションを有効化
   - strict mTLSを強制

2. AuthorizationPolicyを作成して以下を実装してください：
   - productpageからreviewsへのアクセスのみ許可
   - 特定のJWTトークンを持つリクエストのみ許可

3. Istioのテレメトリから不審なトラフィックパターンを検出してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間を作成し、自動インジェクションを有効化
kubectl create ns bookinfo
kubectl label namespace bookinfo istio-injection=enabled

# サンプルアプリケーションをデプロイ
kubectl apply -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml

# strict mTLSを設定
cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: bookinfo
spec:
  mtls:
    mode: STRICT
EOF

# AuthorizationPolicyを作成
cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/bookinfo/sa/bookinfo-productpage"]
    to:
    - operation:
        methods: ["GET"]
EOF

# JWT認証を設定
cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: productpage
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.19/security/tools/jwt/samples/jwks.json"
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題26 - 高度なRBACシナリオ
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

複雑な組織構造に対応するRBACを設計してください。

1. 以下の要件を満たすRBAC構造を作成してください：
   - dev-team: dev-*名前空間でのフルアクセス
   - qa-team: すべての名前空間でread-only、qa-*名前空間でDeploymentの更新可能
   - sre-team: 全クラスターでのフルアクセス、ただしSecretの削除は不可

2. 各チーム用のkubeconfigを生成してください。

3. Break-glass（緊急時）アクセス用のプロセスを実装してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# dev-team用のRole
kubectl create clusterrole dev-team-role \
  --verb="*" \
  --resource="*"

# dev-*名前空間へのバインディング（動的に作成）
for ns in $(kubectl get ns -o name | grep "namespace/dev-" | cut -d/ -f2); do
  kubectl create rolebinding dev-team-binding-$ns \
    --clusterrole=dev-team-role \
    --group=dev-team \
    -n $ns
done

# qa-team用のClusterRole
kubectl create clusterrole qa-readonly \
  --verb=get,list,watch \
  --resource="*"

kubectl create clusterrolebinding qa-team-readonly \
  --clusterrole=qa-readonly \
  --group=qa-team

# qa-*名前空間での追加権限
kubectl create clusterrole qa-deploy-updater \
  --verb=update,patch \
  --resource=deployments

# sre-team用のClusterRole（Secret削除を除く）
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sre-team-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF

# Break-glassアクセス
# 時限的な権限昇格用のRoleBinding
cat <<EOF > break-glass-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: break-glass-admin
  annotations:
    expires: "2024-01-01T00:00:00Z"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: emergency-user
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題27 - Kubernetesクラスターのフォレンジック
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

セキュリティインシデントが発生した後のフォレンジック調査を実施してください。

1. compromised-app名前空間で不審なアクティビティの痕跡を調査してください：
   - 最近作成/変更されたリソース
   - 異常なネットワーク接続
   - 実行されたコマンドの履歴

2. 以下の証拠を収集してください：
   - Podのメモリダンプ
   - ネットワークトラフィックのキャプチャ
   - コンテナのファイルシステムのスナップショット

3. タイムラインを作成し、攻撃の経路を特定してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 最近のイベントを確認
kubectl get events -n compromised-app --sort-by='.lastTimestamp'

# 監査ログから不審なアクティビティを検索
grep compromised-app /var/log/kubernetes/audit/audit.log | \
  jq 'select(.verb == "create" or .verb == "patch")'

# 実行中のプロセスを確認
kubectl exec -n compromised-app <pod-name> -- ps auxf

# ネットワーク接続を確認
kubectl exec -n compromised-app <pod-name> -- netstat -anp

# tcpdumpでトラフィックをキャプチャ
kubectl exec -n compromised-app <pod-name> -- tcpdump -i any -w /tmp/capture.pcap

# メモリダンプを取得（要crictl）
crictl ps | grep <container-id>
crictl exec <container-id> -- gcore -o /tmp/memdump <pid>

# ファイルシステムの変更を確認
kubectl exec -n compromised-app <pod-name> -- find / -mtime -1 -type f

# コンテナイメージの履歴を確認
kubectl describe pod -n compromised-app <pod-name> | grep -A5 "Container ID"
docker history <image-id>
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題28 - Zero Trust Networkingの実装
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

Zero Trustネットワーキングモデルを完全に実装してください。

1. zero-trust名前空間を作成し、以下を設定してください：
   - すべてのPod間通信をデフォルトで拒否
   - 各サービスに専用のServiceAccountを作成
   - NetworkPolicyで明示的に必要な通信のみ許可

2. Calicoを使用してGlobalNetworkPolicyを作成してください：
   - 特定のラベルを持つPodのみインターネットアクセス許可
   - ログ記録を有効化

3. eBPFを使用してネットワークレベルの可視性を実装してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Calicoのインストール（まだの場合）
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml

# Zero Trust名前空間の設定
kubectl create ns zero-trust

# デフォルト拒否ポリシー
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: zero-trust
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# サービスごとのServiceAccount
for service in frontend backend database; do
  kubectl create sa $service-sa -n zero-trust
done

# 明示的な通信許可
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: zero-trust
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - namespaceSelector:
        matchLabels:
          name: zero-trust
    ports:
    - protocol: TCP
      port: 8080
EOF

# CalicoのGlobalNetworkPolicy
cat <<EOF | kubectl apply -f -
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: internet-access
spec:
  selector: has(internet-access)
  types:
  - Egress
  egress:
  - action: Log
  - action: Allow
    destination:
      notNets:
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題29 - 機密データの検出と保護
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

クラスター内の機密データを検出し、保護する仕組みを実装してください。

1. 以下のパターンを検出するスキャナーを作成してください：
   - ハードコードされたパスワード
   - APIキー
   - 秘密鍵

2. ConfigMapやSecretに保存される前にデータを検証するAdmission Webhookを作成してください。

3. 検出された機密データを自動的にHashiCorp Vaultに移行するプロセスを実装してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 機密データ検出スクリプト
cat <<'EOF' > /tmp/secret-scanner.sh
#!/bin/bash

# パターン定義
PATTERNS=(
  'password\s*=\s*["\'][^"\']+["\']'
  'api[_-]?key\s*=\s*["\'][^"\']+["\']'
  'BEGIN RSA PRIVATE KEY'
  'BEGIN PRIVATE KEY'
  'aws_access_key_id'
)

# ConfigMapとSecretをスキャン
for resource in configmap secret; do
  kubectl get $resource -A -o json | jq -r '.items[] | 
    "\(.metadata.namespace)/\(.metadata.name):\n\(.data | to_entries[] | .value)"' | \
    while IFS= read -r line; do
      for pattern in "${PATTERNS[@]}"; do
        if echo "$line" | base64 -d 2>/dev/null | grep -iE "$pattern"; then
          echo "FOUND: $pattern in $line"
        fi
      done
    done
done
EOF

# Admission Webhook用の検証ロジック
cat <<EOF > validate-secrets.py
import base64
import re
import json
from flask import Flask, request, jsonify

app = Flask(__name__)

FORBIDDEN_PATTERNS = [
    r'password\s*=\s*["\'][^"\']+["\']',
    r'api[_-]?key\s*=\s*["\'][^"\']+["\']',
    r'BEGIN RSA PRIVATE KEY',
]

@app.route('/validate', methods=['POST'])
def validate():
    admission_review = request.get_json()
    obj = admission_review['request']['object']
    
    if 'data' in obj:
        for key, value in obj['data'].items():
            try:
                decoded = base64.b64decode(value).decode('utf-8')
                for pattern in FORBIDDEN_PATTERNS:
                    if re.search(pattern, decoded, re.IGNORECASE):
                        return jsonify({
                            'apiVersion': 'admission.k8s.io/v1',
                            'kind': 'AdmissionReview',
                            'response': {
                                'uid': admission_review['request']['uid'],
                                'allowed': False,
                                'status': {'message': f'Forbidden pattern detected: {pattern}'}
                            }
                        })
            except:
                pass
    
    return jsonify({
        'apiVersion': 'admission.k8s.io/v1',
        'kind': 'AdmissionReview',
        'response': {
            'uid': admission_review['request']['uid'],
            'allowed': True
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=443, ssl_context='adhoc')
EOF
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題30 - 完全なセキュリティ評価とレポート作成
=========================================================
環境準備
cd /home/wsl/dev/k8s-cks/wsl/test/
../script/reset-hard.sh

問題

クラスター全体の包括的なセキュリティ評価を実施し、レポートを作成してください。

1. 以下のツールを使用してセキュリティスキャンを実行してください：
   - kube-bench（CISベンチマーク）
   - kube-hunter（脆弱性スキャン）
   - Polaris（ベストプラクティス）
   - Trivy（イメージ脆弱性）

2. 発見された問題を以下のカテゴリーに分類してください：
   - Critical: 即座の対応が必要
   - High: 24時間以内に対応
   - Medium: 1週間以内に対応
   - Low: 次回メンテナンス時に対応

3. 修正計画とタイムラインを含む総合レポートを作成してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 統合セキュリティ評価スクリプト
cat <<'EOF' > security-assessment.sh
#!/bin/bash

REPORT_DIR="/tmp/security-report-$(date +%Y%m%d)"
mkdir -p $REPORT_DIR

echo "=== Kubernetes Security Assessment Report ===" > $REPORT_DIR/summary.md
echo "Date: $(date)" >> $REPORT_DIR/summary.md
echo "" >> $REPORT_DIR/summary.md

# kube-bench
echo "Running kube-bench..." 
kube-bench run --json > $REPORT_DIR/kube-bench.json
echo "## CIS Benchmark Results" >> $REPORT_DIR/summary.md
jq '.totals' $REPORT_DIR/kube-bench.json >> $REPORT_DIR/summary.md

# kube-hunter
echo "Running kube-hunter..."
kube-hunter --remote $(kubectl cluster-info | grep master | awk '{print $NF}') \
  --report json > $REPORT_DIR/kube-hunter.json

# Polaris
echo "Running Polaris..."
kubectl apply -f https://github.com/FairwindsOps/polaris/releases/latest/download/dashboard.yaml
sleep 30
kubectl port-forward -n polaris svc/polaris-dashboard 8080:80 &
curl -s http://localhost:8080/api/reports > $REPORT_DIR/polaris.json

# Trivy scan all images
echo "Scanning all container images..."
kubectl get pods -A -o json | \
  jq -r '.items[].spec.containers[].image' | \
  sort -u | \
  while read image; do
    echo "Scanning $image"
    trivy image --severity CRITICAL,HIGH --format json $image >> $REPORT_DIR/trivy-images.json
  done

# Generate priority matrix
cat <<MATRIX >> $REPORT_DIR/priority-matrix.md
## Priority Matrix

### Critical (Immediate Action Required)
$(jq -r '.[] | select(.severity == "CRITICAL")' $REPORT_DIR/*.json | wc -l) issues found

### High (24 hours)
$(jq -r '.[] | select(.severity == "HIGH")' $REPORT_DIR/*.json | wc -l) issues found

### Medium (1 week)
$(jq -r '.[] | select(.severity == "MEDIUM")' $REPORT_DIR/*.json | wc -l) issues found

### Low (Next maintenance)
$(jq -r '.[] | select(.severity == "LOW")' $REPORT_DIR/*.json | wc -l) issues found
MATRIX

echo "Security assessment complete. Report saved to $REPORT_DIR"
EOF

chmod +x security-assessment.sh
./security-assessment.sh
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・