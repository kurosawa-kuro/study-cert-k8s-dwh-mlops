cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh
cd ../script
make reset-heavy


=========================================================
問題1 - etcdバックアップとリストア
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

現在稼働中のKubernetesクラスターのetcdデータベースをバックアップし、その後リストアする必要があります。以下のタスクを実行してください。

1. etcdのバックアップを/tmp/etcd-backup.dbに作成してください。
   - etcdのエンドポイント、証明書、鍵の場所を確認してください
   - ETCDCTL_API=3を使用してください

2. test-backupという名前空間を作成し、nginx:alpineイメージを使用したtest-podというPodを作成してください。

3. etcdデータベースを先ほど作成したバックアップからリストアし、test-backup名前空間が削除されていることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# etcdのエンドポイントと証明書の場所を確認
kubectl describe pod etcd-controlplane -n kube-system | grep -E "(--advertise-client-urls|--cert-file|--key-file|--trusted-ca-file)"

# etcdのバックアップを作成
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# バックアップの検証
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db

# etcdをリストア（システムによって異なる場合があります）
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-backup
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題2 - クラスターアップグレード
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

現在のKubernetesクラスターを次のマイナーバージョンにアップグレードする必要があります。以下のタスクを実行してください。

1. 現在のクラスターバージョンを確認してください。

2. controlplaneノードを次のマイナーバージョンにアップグレードしてください。
   - kubeadmを最初にアップグレード
   - アップグレード計画を確認
   - controlplaneコンポーネントをアップグレード

3. workerノードを順次アップグレードしてください。
   - ノードをdrainしてからアップグレード
   - アップグレード後、ノードをuncordonする

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 現在のバージョンを確認
kubectl get nodes
kubectl version --short

# 利用可能なバージョンを確認
apt update
apt-cache madison kubeadm

# controlplaneのアップグレード
kubectl drain controlplane --ignore-daemonsets
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.XX.X-00
apt-mark hold kubeadm
kubeadm upgrade plan
kubeadm upgrade apply v1.XX.X
kubectl uncordon controlplane

# kubeletとkubectlのアップグレード
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.XX.X-00 kubectl=1.XX.X-00
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題3 - RBACとServiceAccount
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成してください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cka-questions/main/practice-questions/3/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: development
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-app
  namespace: development
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dev-app
  template:
    metadata:
      labels:
        app: dev-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: prod-app
  template:
    metadata:
      labels:
        app: prod-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

問題

development名前空間とproduction名前空間で異なる権限を持つServiceAccountを作成する必要があります。

1. developer-saというServiceAccountをdevelopment名前空間に作成してください。

2. developer-saに対して、development名前空間内のすべてのリソースに対する読み書き権限を付与してください。

3. viewer-saというServiceAccountをdefault名前空間に作成してください。

4. viewer-saに対して、全ての名前空間のPodとDeploymentを参照（get, list, watch）できる権限を付与してください。

5. 権限が正しく設定されていることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# ServiceAccountの作成
kubectl create sa developer-sa -n development
kubectl create sa viewer-sa

# development名前空間のRoleとRoleBindingを作成
kubectl create role developer-role -n development \
  --verb="*" \
  --resource="*"

kubectl create rolebinding developer-binding -n development \
  --role=developer-role \
  --serviceaccount=development:developer-sa

# ClusterRoleとClusterRoleBindingを作成
kubectl create clusterrole viewer-role \
  --verb=get,list,watch \
  --resource=pods,deployments

kubectl create clusterrolebinding viewer-binding \
  --clusterrole=viewer-role \
  --serviceaccount=default:viewer-sa

# 権限の確認
kubectl auth can-i --list --as=system:serviceaccount:development:developer-sa -n development
kubectl auth can-i --list --as=system:serviceaccount:default:viewer-sa
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題4 - ノードのメンテナンスとPodの再配置
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースをデプロイしてください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cka-questions/main/practice-questions/4/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: critical-apps
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-deployment
  namespace: critical-apps
spec:
  replicas: 6
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - critical-app
            topologyKey: kubernetes.io/hostname
```

問題

critical-apps名前空間でcritical-deploymentが実行されています。workerノードの1つをメンテナンスする必要がありますが、アプリケーションの可用性を維持する必要があります。

1. 全てのノードとPodの配置状況を確認してください。

2. worker-1ノードをメンテナンスモードにしてください（cordon）。

3. worker-1ノード上のPodを安全に退避させてください（drain）。
   - DaemonSetは無視してください
   - 必要に応じて強制オプションを使用してください

4. critical-deploymentのPodが他のノードで正常に動作していることを確認してください。

5. メンテナンス完了後、worker-1ノードを通常状態に戻してください（uncordon）。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# ノードとPodの状態を確認
kubectl get nodes -o wide
kubectl get pods -n critical-apps -o wide

# ノードをメンテナンスモードに設定
kubectl cordon worker-1

# ノードからPodを退避
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data --force

# Podの再配置を確認
kubectl get pods -n critical-apps -o wide

# ノードを通常状態に戻す
kubectl uncordon worker-1

# 最終状態を確認
kubectl get nodes
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題5 - Static PodとDaemonSet
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

1. controlplaneノードにstatic-nginxという名前のStatic Podを作成してください。
   - nginx:alpineイメージを使用
   - Static Podの設定ファイルはkubeletが監視するディレクトリに配置

2. monitoring名前空間を作成し、node-exporterという名前のDaemonSetを作成してください。
   - busyboxイメージを使用
   - コマンド: sh -c "while true; do echo 'Node: $HOSTNAME'; sleep 30; done"
   - 全てのノードで実行されることを確認

3. controlplaneノードのみで実行されるようにDaemonSetを更新してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# kubeletの設定ファイルを確認してStatic Podのパスを特定
systemctl status kubelet
cat /var/lib/kubelet/config.yaml | grep staticPodPath

# Static Podを作成
cat <<EOF > /etc/kubernetes/manifests/static-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# DaemonSetを作成
kubectl create ns monitoring
kubectl create deployment node-exporter -n monitoring \
  --image=busybox \
  --dry-run=client -o yaml \
  -- sh -c "while true; do echo 'Node: \$HOSTNAME'; sleep 30; done" > daemonset.yaml

# DeploymentをDaemonSetに変更して適用
# kind: DaemonSet に変更し、replicas: を削除

# ノードセレクターを追加してcontrolplaneノードのみで実行
kubectl patch daemonset node-exporter -n monitoring -p '{"spec":{"template":{"spec":{"nodeSelector":{"node-role.kubernetes.io/control-plane":""}}}}}'
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題6 - NetworkPolicyとトラブルシューティング
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成してください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cka-questions/main/practice-questions/6/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: secure-app
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: secure-app
  labels:
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: secure-app
  labels:
    tier: backend
spec:
  containers:
  - name: nginx
    image: nginx:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: secure-app
  labels:
    tier: database
spec:
  containers:
  - name: nginx
    image: nginx:alpine
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: secure-app
spec:
  selector:
    tier: backend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: secure-app
spec:
  selector:
    tier: database
  ports:
  - port: 80
    targetPort: 80
```

問題

secure-app名前空間で3層アプリケーションが動作しています。セキュリティ要件に従ってNetworkPolicyを設定する必要があります。

1. secure-app名前空間のすべてのPodへのingressトラフィックをデフォルトで拒否するNetworkPolicyを作成してください。

2. 以下の通信のみを許可するNetworkPolicyを作成してください：
   - frontendからbackend-serviceへの通信（ポート80）
   - backendからdatabase-serviceへの通信（ポート80）
   - 外部からfrontendへの通信（ポート80）

3. 設定したNetworkPolicyが正しく動作することを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# デフォルト拒否ポリシーを作成
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

# frontend用のNetworkPolicyを作成
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 80
EOF

# backend用のNetworkPolicyを作成
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# database用のNetworkPolicyを作成
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 80
EOF

# 接続テスト
kubectl exec -it frontend -n secure-app -- curl -m 2 backend-service
kubectl exec -it backend -n secure-app -- curl -m 2 database-service
kubectl exec -it frontend -n secure-app -- curl -m 2 database-service  # これは失敗するはず
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題7 - トラブルシューティング：kubeletとノード
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題のあるノードをシミュレートしてください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cka-questions/main/practice-questions/7/break-node.yaml

問題

worker-2ノードがNotReady状態になっています。原因を特定し、修正してください。

1. クラスターの全ノードの状態を確認してください。

2. 問題のあるノードにSSHでログインし、kubeletの状態を確認してください。

3. kubeletのログを確認し、エラーの原因を特定してください。

4. 問題を修正し、ノードがReady状態に戻ることを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# ノードの状態を確認
kubectl get nodes
kubectl describe node worker-2

# worker-2ノードにSSH（またはdocker exec）
ssh worker-2

# kubeletの状態を確認
systemctl status kubelet
journalctl -u kubelet -f

# kubeletの設定ファイルを確認
cat /var/lib/kubelet/config.yaml
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 証明書の期限を確認
openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout | grep -A2 Validity

# kubeletを再起動
systemctl restart kubelet
systemctl enable kubelet

# ノードの状態を再確認
kubectl get nodes
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題8 - クラスターDNSトラブルシューティング
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成してください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cka-questions/main/practice-questions/8/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: dns-test
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: dns-test
spec:
  containers:
  - name: busybox
    image: busybox:1.28
    command: ['sh', '-c', 'sleep 3600']
---
apiVersion: v1
kind: Service
metadata:
  name: test-service
  namespace: dns-test
spec:
  selector:
    app: test
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: test-backend
  namespace: dns-test
  labels:
    app: test
spec:
  containers:
  - name: nginx
    image: nginx:alpine
```

問題

dns-test名前空間のtest-podからtest-serviceへの名前解決ができません。DNSの問題を特定し、修正してください。

1. test-podからtest-serviceへの名前解決をテストしてください。

2. CoreDNSのPodとServiceの状態を確認してください。

3. CoreDNSの設定を確認し、必要に応じて修正してください。

4. 名前解決が正常に動作することを確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# DNSテスト
kubectl exec -it test-pod -n dns-test -- nslookup test-service
kubectl exec -it test-pod -n dns-test -- nslookup test-service.dns-test.svc.cluster.local

# CoreDNSの状態を確認
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get svc -n kube-system kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# CoreDNSのConfigMapを確認
kubectl get configmap coredns -n kube-system -o yaml

# PodのDNS設定を確認
kubectl exec -it test-pod -n dns-test -- cat /etc/resolv.conf

# CoreDNSを再起動
kubectl rollout restart deployment coredns -n kube-system

# 再度DNSテスト
kubectl exec -it test-pod -n dns-test -- nslookup kubernetes.default
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題9 - 証明書の管理と更新
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

Kubernetesクラスターの証明書を管理する必要があります。

1. 現在のクラスター証明書の有効期限を確認してください。

2. 新しいユーザー「john」用のクライアント証明書を作成してください。
   - CNは「john」
   - Organizationは「developers」

3. johnユーザー用のkubeconfigファイルを作成してください。

4. johnユーザーがdefault名前空間のPodを参照できるように権限を設定してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 証明書の有効期限を確認
kubeadm certs check-expiration

# 秘密鍵を生成
openssl genrsa -out john.key 2048

# 証明書署名要求（CSR）を作成
openssl req -new -key john.key -out john.csr -subj "/CN=john/O=developers"

# KubernetesのCSRオブジェクトを作成
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: $(cat john.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# CSRを承認
kubectl certificate approve john

# 証明書を取得
kubectl get csr john -o jsonpath='{.status.certificate}' | base64 -d > john.crt

# kubeconfigを作成
kubectl config set-credentials john --client-certificate=john.crt --client-key=john.key
kubectl config set-context john-context --cluster=kubernetes --user=john --namespace=default
kubectl config view

# RBACを設定
kubectl create role pod-reader --verb=get,list,watch --resource=pods
kubectl create rolebinding john-pod-reader --role=pod-reader --user=john
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題10 - PersistentVolumeとStorageClass
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

1. local-storageという名前のStorageClassを作成してください。
   - provisioner: kubernetes.io/no-provisioner
   - volumeBindingMode: WaitForFirstConsumer

2. 以下の仕様でPersistentVolumeを作成してください。
   - 名前: local-pv
   - 容量: 1Gi
   - アクセスモード: ReadWriteOnce
   - storageClassName: local-storage
   - hostPath: /mnt/data

3. storage名前空間を作成し、PersistentVolumeClaimを作成してください。
   - 名前: local-pvc
   - 容量要求: 500Mi
   - storageClassName: local-storage

4. mysqlイメージを使用したStatefulSetを作成し、PVCをマウントしてください。
   - 名前: mysql-db
   - レプリカ数: 1
   - マウントパス: /var/lib/mysql
   - 環境変数: MYSQL_ROOT_PASSWORD=password123

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# StorageClassを作成
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# PersistentVolumeを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  hostPath:
    path: /mnt/data
    type: DirectoryOrCreate
EOF

# 名前空間とPVCを作成
kubectl create ns storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
  namespace: storage
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: local-storage
EOF

# StatefulSetを作成
kubectl create statefulset mysql-db -n storage \
  --image=mysql:5.7 \
  --replicas=1 \
  --dry-run=client -o yaml > mysql-statefulset.yaml

# マウントとenv設定を追加して適用
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題11 - リソース制限とResourceQuota
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

1. limited名前空間を作成し、以下のResourceQuotaを設定してください。
   - 名前: compute-quota
   - requests.cpu: 4
   - requests.memory: 8Gi
   - limits.cpu: 8
   - limits.memory: 16Gi
   - persistentvolumeclaims: 5

2. 同じ名前空間にLimitRangeを作成してください。
   - 名前: resource-limits
   - コンテナのデフォルトlimits - cpu: 500m, memory: 1Gi
   - コンテナのデフォルトrequests - cpu: 100m, memory: 256Mi
   - コンテナの最大limits - cpu: 1, memory: 2Gi

3. nginx:alpineイメージを使用したDeploymentを作成してください。
   - 名前: limited-app
   - レプリカ数: 3
   - リソース要求がResourceQuotaの範囲内であることを確認

4. ResourceQuotaの使用状況を確認してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間とResourceQuotaを作成
kubectl create ns limited
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: limited
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "5"
EOF

# LimitRangeを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: limited
spec:
  limits:
  - default:
      cpu: 500m
      memory: 1Gi
    defaultRequest:
      cpu: 100m
      memory: 256Mi
    max:
      cpu: "1"
      memory: 2Gi
    type: Container
EOF

# Deploymentを作成
kubectl create deployment limited-app -n limited --image=nginx:alpine --replicas=3

# ResourceQuotaの状況を確認
kubectl describe resourcequota compute-quota -n limited
kubectl get resourcequota -n limited
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題12 - Schedulerの設定とPod配置
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成してください。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/cka-questions/main/practice-questions/12/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: scheduling
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-scheduler-config
  namespace: kube-system
data:
  config.yaml: |
    apiVersion: kubescheduler.config.k8s.io/v1beta3
    kind: KubeSchedulerConfiguration
    profiles:
    - schedulerName: custom-scheduler
```

問題

カスタムスケジューラーを使用してPodをスケジューリングする必要があります。

1. worker-1ノードに以下のラベルを追加してください。
   - environment=production
   - disk=ssd

2. worker-2ノードに以下のラベルを追加してください。
   - environment=development
   - disk=hdd

3. scheduling名前空間に、production環境かつSSDディスクを持つノードにのみスケジュールされるPodを作成してください。
   - 名前: prod-app
   - イメージ: nginx:alpine
   - nodeSelector使用

4. Taintとtolerationを使用して、worker-1ノードに特別なワークロードのみを配置できるようにしてください。
   - Taint: special=true:NoSchedule
   - special-appというPodを作成し、このTaintをtolerateするように設定

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# ノードにラベルを追加
kubectl label node worker-1 environment=production disk=ssd
kubectl label node worker-2 environment=development disk=hdd

# ラベルを確認
kubectl get nodes --show-labels

# nodeSelectorを使用したPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: prod-app
  namespace: scheduling
spec:
  nodeSelector:
    environment: production
    disk: ssd
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# Taintを追加
kubectl taint nodes worker-1 special=true:NoSchedule

# Tolerationを持つPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: special-app
  namespace: scheduling
spec:
  tolerations:
  - key: special
    operator: Equal
    value: "true"
    effect: NoSchedule
  nodeSelector:
    environment: production
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# Pod配置を確認
kubectl get pods -n scheduling -o wide
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題13 - ログ収集とモニタリング
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

1. monitoring名前空間を作成し、ログを生成するアプリケーションをデプロイしてください。
   - Deployment名: log-generator
   - レプリカ数: 2
   - イメージ: busybox
   - コマンド: sh -c "while true; do echo '[$(date)] Application log message'; sleep 5; done"

2. サイドカーコンテナを追加して、ログをファイルに保存してください。
   - サイドカーコンテナ名: log-collector
   - 共有ボリューム: /var/log
   - メインコンテナのログを/var/log/app.logにリダイレクト

3. すべてのノードのシステムログを確認する方法を説明してください。

4. クラスター全体のイベントをフィルタリングして、Error型のイベントのみを表示してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# monitoring名前空間とDeploymentを作成
kubectl create ns monitoring
kubectl create deployment log-generator -n monitoring \
  --image=busybox \
  --replicas=2 \
  --dry-run=client -o yaml > log-generator.yaml

# サイドカーコンテナを追加（log-generator.yamlを編集）
spec:
  containers:
  - name: app
    image: busybox
    command: 
    - sh
    - -c
    - "while true; do echo '[$(date)] Application log message' >> /var/log/app.log; sleep 5; done"
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: log-collector
    image: busybox
    command:
    - sh
    - -c
    - "tail -f /var/log/app.log"
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: varlog
    emptyDir: {}

# ノードのシステムログ確認
kubectl get nodes
# 各ノードにSSHして確認
journalctl -u kubelet
journalctl -u docker

# エラーイベントをフィルタリング
kubectl get events --all-namespaces --field-selector type=Warning
kubectl get events --all-namespaces -o json | jq '.items[] | select(.type=="Warning")'
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題14 - Ingress ControllerとTLS設定
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

1. 次のコマンドを実行して、Ingress Controllerをインストールしてください。

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

問題

1. web-apps名前空間を作成し、2つのアプリケーションをデプロイしてください。
   - app1: nginx:alpineイメージ、Service名: app1-svc、ポート: 80
   - app2: httpd:alpineイメージ、Service名: app2-svc、ポート: 80

2. 自己署名証明書を作成してください。
   - CN: myapp.example.com
   - 秘密鍵: tls.key
   - 証明書: tls.crt

3. TLS Secretを作成してください。
   - 名前: myapp-tls
   - 名前空間: web-apps

4. Ingressリソースを作成してください。
   - ホスト: myapp.example.com
   - パス /app1 → app1-svc
   - パス /app2 → app2-svc
   - TLS有効化

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 名前空間とアプリケーションを作成
kubectl create ns web-apps
kubectl create deployment app1 -n web-apps --image=nginx:alpine
kubectl create deployment app2 -n web-apps --image=httpd:alpine
kubectl expose deployment app1 -n web-apps --name=app1-svc --port=80
kubectl expose deployment app2 -n web-apps --name=app2-svc --port=80

# 自己署名証明書を作成
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com/O=myapp"

# TLS Secretを作成
kubectl create secret tls myapp-tls -n web-apps \
  --key=tls.key \
  --cert=tls.crt

# Ingressを作成
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: web-apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-svc
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-svc
            port:
              number: 80
EOF

# Ingressの状態を確認
kubectl get ingress -n web-apps
kubectl describe ingress myapp-ingress -n web-apps
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題15 - クラスター監査とセキュリティ
=========================================================
環境準備
cd /home/wsl/dev/k8s-cka/wsl/test/
../script/reset-hard.sh

問題

1. security名前空間を作成し、セキュリティ設定を持つPodを作成してください。
   - Pod名: secure-pod
   - イメージ: nginx:alpine
   - 非rootユーザー（UID: 1000）で実行
   - 読み取り専用ルートファイルシステム
   - 特権昇格を無効化

2. PodSecurityPolicyの代替として、PodSecurityStandardsを使用してsecurity名前空間にセキュリティポリシーを適用してください。
   - レベル: restricted
   - enforce、audit、warnモードを設定

3. kube-apiserverの監査ログを有効化する設定を説明してください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# security名前空間を作成
kubectl create ns security

# PodSecurityStandardsを適用
kubectl label namespace security \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# セキュアなPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
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

# 監査ログ設定の例（kube-apiserver設定）
# /etc/kubernetes/audit-policy.yaml を作成
# kube-apiserverマニフェストに以下を追加：
# --audit-policy-file=/etc/kubernetes/audit-policy.yaml
# --audit-log-path=/var/log/kubernetes/audit.log
# --audit-log-maxage=30
# --audit-log-maxbackup=3
# --audit-log-maxsize=100
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・