cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh
cd ../script
make reset-heavy


=========================================================
問題1
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/1/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: filter
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-1
  name: pod-1
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-1
    command: ["sh", "-c", "echo 'Hello from pod-1'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-2
  name: pod-2
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-2
    command: ["sh", "-c", "echo 'Hello from pod-2'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-3
  name: pod-3
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-3
    command: ["sh", "-c", "echo 'Hello from pod-3'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-4
  name: pod-4
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-4
    command: ["sh", "-c", "echo 'Hello from pod-4'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-5
  name: pod-5
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-5
    command: ["sh", "-c", "echo 'Hello from pod-5'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-6
  name: pod-6
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-6
    command: ["sh", "-c", "echo 'Hello from pod-6'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-7
  name: pod-7
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-7
    command: ["sh", "-c", "echo 'Hello from pod-7'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-8
  name: pod-8
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-8
    command: ["sh", "-c", "echo 'Hello from pod-8'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-9
  name: pod-9
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-9
    command: ["sh", "-c", "echo 'Hello from pod-9'; sleep 3600"]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: pod-10
  name: pod-10
  namespace: filter
spec:
  containers:
  - image: busybox
    name: pod-10
    command: ["sh", "-c", "echo 'Hello from pod-10'; sleep 3600"]
  restartPolicy: Always
---
```

問題
filter名前空間では、pod-1からpod-10までの10個のPodが実行されています。それぞれのPodには、app: "Pod名"のラベルが付与されています。以下のラベルを持つPodのログを、pods.logに出力して下さい。

app: pod-3
app: pod-7
app: pod-8

---------------------------------------------------------
---------------------------------------------------------

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題2
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースをデプロイして下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/2/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: credential
---
apiVersion: v1
data:
  PASSWORD: bXktY3VycmVudC1wYXNzd29yZAo=
  USERNAME: bXktdXNlcgo=
kind: Secret
metadata:
  name: creds
  namespace: credential
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: login
  name: login
  namespace: credential
spec:
  replicas: 2
  selector:
    matchLabels:
      app: login
  template:
    metadata:
      labels:
        app: login
    spec:
      containers:
      - image: nginx:alpine
        name: login
        envFrom:
        - secretRef:
            name: creds
```


問題

credential名前空間で、login Deploymentが実行するコンテナは環境変数USERNAMEとPASSWORDをcreds Secretから参照しています。credsが保持しているPASSWORDの値をmy-new-passwordに変更して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 全リソース一覧を確認（Pod, Service, Deploymentなどすべて）
kubectl get all  #  deployment.apps/loginを取得


# Podに入って環境変数を確認（Deployment経由ではなくPod名で）
kubectl exec -it deployment.apps/login -- /bin/sh
env

# Secretの内容（base64エンコード状態）を確認
kubectl get secret creds -o yaml  # Secret 'creds' の値をYAML形式で表示

# Secret/ConfigMap変更を反映するためにDeploymentを再起動
kubectl rollout restart deployment.apps/login # Deployment 'login' をローリング再起動
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

=========================================================
問題3
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh
minikube delete
minikube start --ports=32100:32100

1. wgetコマンドを使用して、以下のURLからファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/3/updated_index.html

```
new
```


2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/3/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: web
---
apiVersion: v1
data:
  index.html: |
    old
kind: ConfigMap
metadata:
  name: old-index-cm
  namespace: web
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-web
  name: my-web
  namespace: web
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-web
  template:
    metadata:
      labels:
        app: my-web
    spec:
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: index
          mountPath: /usr/share/nginx/html
      volumes:
      - name: index
        configMap:
          name: old-index-cm
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-web
  name: my-svc
  namespace: web
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 32100
  selector:
    app: my-web
  type: NodePort
```

問題

web名前空間で実行されているmy-web Deploymentは、nginxイメージコンテナを実行するPodを管理しています。DeploymentはNodePortタイプのサービスで公開されており、curl controlplane:32100を実行してコンテナに接続できます。
コンテナが表示するindex.htmlファイルを、updated_index.htmlに変更する必要があります。

index.htmlをキー、updated_index.htmlファイルをバリューとして保持するConfigMapを作成し、/usr/share/nginx/htmlディレクトリにマウントされているConfigMapを更新して下さい。ConfigMapの名前はnew-index-cmとします

---------------------------------------------------------


---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# Serviceの種類（NodePortか）、ポート番号、selectorを確認
kubectl get svc -o wide  

# DeploymentのConfigMapマウント先やvolume定義を確認
kubectl get deploy my-web -o yaml  

# 対象Podのステータス・IP・ノード配置・ラベルを確認
kubectl get po -l app=my-web -o wide  

# ノードのIPアドレスを取得（controlplaneが使えない場合に備えて）
kubectl get nodes -o wide  

# NodePort経由でアクセスし、表示されるindex.htmlを確認
curl http://controlplane:32100  

# 名前解決できない場合に直接NodeIPでcurl確認
curl http://192.168.58.2:32100  
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

=========================================================
問題4
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

1. wgetコマンドを実行して、次のURLからfrontend.yamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/frontend.yaml


```
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: ambassador
spec:
  containers:
  - image: nginx:alpine
    name: frontend
    command: ["sh", "-c", "while true; do sleep 5; date && curl $SERVICE_NAME:8080 -m 2; done"]
    env:
    - name: SERVICE_NAME
      value: "api-service"
```

2. wgetコマンドを実行して、次のURLからhaproxy.cfgファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/haproxy.cfg

```
frontend api_client
  bind *:8080
  default_backend api_backend
backend api_backend
  server s1 api-service:9090
```

3. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: ambassador
spec: {}
---
apiVersion: v1
data:
  default.conf.template: |
    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
            try_files $uri /api/index.html;
        }
    }
kind: ConfigMap
metadata:
  name: api-config
  namespace: ambassador
---
apiVersion: v1
kind: Pod
metadata:
  name: api
  namespace: ambassador
  labels:
    run: api
spec:
  initContainers:
  - name: init-con
    image: busybox
    command: ['sh', '-c', 'echo "Hello from API!" > /tmp/content/index.html']
    volumeMounts:
    - name: content
      mountPath: /tmp/content
  containers:
  - image: nginx:alpine
    name: api
    volumeMounts:
    - name: content
      mountPath: /usr/share/nginx/html/api
    - name: conf
      mountPath: /etc/nginx/templates
  volumes:
  - name: content
    emptyDir: {}
  - name: conf
    configMap:
      name: api-config
---
apiVersion: v1
kind: Service
metadata:
  labels:
    run: api
  name: api-service
  namespace: ambassador
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 80
  selector:
    run: api
  type: ClusterIP
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: ambassador
spec:
  containers:
  - image: nginx:alpine
    name: frontend
    command: ["sh", "-c", "while true; do sleep 5; date && curl $SERVICE_NAME:8080 -m 2; done"]
    env:
    - name: SERVICE_NAME
      value: "api-service"
```

問題

ambassador名前空間で稼働しているfrontend Podは、ポート番号8080を使用して、５秒毎にapi-serviceに接続します。api-serviceのポート番号は、9090に変更する必要があります。以下のタスクを実行し、frontend Podが引き続きapi-serviceに接続できる様に、新しいコンテナを追加して下さい。



1. api-serviceの公開するポート番号を、9090番に変更して下さい



2. haproxy.cfgファイルを使用して、haproxy-cfgというConfigMapを作成して下さい。



3. frontend Podに、haproxy:alpineイメージを使用したコンテナを追加して下さい。コンテナ名はhaproxyとし、/usr/local/etc/haproxyディレクトリにhaproxy-cfg ConfigMapをマウントして下さい。なお、変更にはfrontend Podのマニフェストファイルであるfrontend.yamlを使用して下さい。



4. frontendコンテナからServiceへの接続が、新しいエンドポイントに正しくプロキシされる様に、接続先をapi-serviceからlocalhostに変更して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
k logs frontend --since=15s
k create cm haproxy-cfg --from-file=haproxy.cfg





・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・



=========================================================
問題5
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースをデプロイして下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/5/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: service
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader-sa
  namespace: service
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: service
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: service
  name: pod-reader-binding
  namespace: service
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: pod-reader-sa
  namespace: service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: pod-reader
  name: pod-reader
  namespace: service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pod-reader
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: pod-reader
    spec:
      serviceAccount: default
      containers:
      - image: bitnami/kubectl
        name: kubectl
        command: ["sh", "-c", "while true; do kubectl get pods; sleep 5; done"]
```

問題

service名前空間で実行されるpod-reader Deploymentは、5秒ごとに"kubectl get pods"コマンドを実行します。

現在、Deploymentのログにはエラーメッセージが出力されています。以下のタスクを実行し、エラーを修正して下さい。なお、解答に必要なリソースは全て作成されており、新しいリソースを作成する必要はありません。



1. pod-reader Deploymentのログを確認し、エラーメッセージを調査して下さい。


2. pod-reader Deploymentを修正し、エラーの原因となっている問題を解決して下さい。


---------------------------------------------------------


---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
# 直近15秒のログを確認してエラー内容を特定
k logs deployment/pod-reader --since=15s  

# default ServiceAccount でPod一覧が取得できるか検証
k auth can-i list pods --as=system:serviceaccount:service:default

# 現在Namespace内に存在するServiceAccountを確認（候補を探す）
k get sa

# pod-reader-saがPod一覧取得できるか検証（正解候補）
k auth can-i list pods --as=system:serviceaccount:service:pod-reader-sa

# Deployment 'pod-reader' に正しいServiceAccountを割り当てる
k set sa deploy pod-reader pod-reader-sa

# 修正を反映するためDeploymentをローリング再起動
k rollout restart deploy pod-reader

# 再起動後のログを確認し、エラー解消を確認
k logs deployment/pod-reader --since=15s
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・




=========================================================
問題6
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/6/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: network
---
apiVersion: v1
kind: Pod
metadata:
  namespace: network
  name: web
  labels:
    app: web
spec:
  containers:
  - image: nginx:alpine
    name: web
---
apiVersion: v1
kind: Pod
metadata:
  namespace: network
  name: api
  labels:
    role: api
spec:
  initContainers:
  - name: init-con
    image: busybox
    command: ['sh', '-c', 'echo "Welcome to api!" > /tmp/content/index.html']
    volumeMounts:
    - name: content
      mountPath: /tmp/content
  volumes:
  - name: content
  containers:
  - image: nginx:alpine
    name: api
    volumeMounts:
    - name: content
      mountPath: /usr/share/nginx/html
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  namespace: network
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  namespace: network
  name: api-netpol
spec:
  podSelector:
    matchLabels:
      role: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 80
---
```


問題

network名前空間では、デフォルトでは全てのPodの内向き（ingress）トラフィックが無効化されています。web Podからapi Podへの内向きのトラフィックを許可するため、api-netpolというNetworkPolicyが作成されましたが、エラーが発生しています。web Podに必要な設定を追加し、api Podへの接続を有効化して下さい。

なお、解答に必要なKubernetesリソースは全て作成されており、新しく作成する必要はありません。また、既存のNetworkPolicyは変更または削除しないでください。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
k get pods -o wide     # 全てのPodをノードやIPなど詳細情報付きで一覧表示
k exec web -- sh -c "curl -m 2 aaa.aaa.a.a"   # web Pod内で指定IPへ2秒タイムアウト付きでHTTPリクエストを実行
k get netpol apinet -o yaml  # apinetというNetworkPolicyの設定内容をYAML形式で取得
k label pods web role=backend  # web Podに role=backend ラベルを付与してNetworkPolicyのセレクター条件を満たす
k exec web -- sh -c "curl -m 2 aaa.aaa.a.a"   # ラベル付与後、再度web PodからAPI Podへの接続を確認



・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題7
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/7/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: resource-management
---
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-resource-constraint
  namespace: resource-management
spec:
  limits:
  - max:
      cpu: 900m
    type: Container
---
```

問題

resource-management名前空間では、cpu-resource-constraintというLimitRangeによって、CPUリソース使用量の最大値が定義されています。

nginxイメージを使用してmanagedというPodを作成して下さい。なお、Podには以下の条件を満たすリソース管理を設定して下さい。



コンテナのCPUリソース要求として、200mを設定して下さい。

resource-management名前空間に設定された最大cpu制約の半分を、コンテナのリソース制限として設定して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
k describe limitranges -n resource-management cpu-resource-constraint

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題8
=========================================================
問題

1. cronという名前空間を作成し、以下の条件を満たすCronJobを作成して下さい。

コンテナイメージはalpineを使用し、CronJobの名前はps-cronとします。ps-cronは"ps aux"コマンドを1分毎に実行し、成功したJobを5、失敗したJobを3まで保存します。また、Jobは開始から6秒経過したPodを終了させます。



2. CronJobからJobを作成して下さい。Job名はps-jobとします。

---------------------------------------------------------


---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectl create cronjob ps-cron -n cron \
  --image=alpine \
  --schedule="*/1 * * * *" \
  --dry-run=client -o yaml \
  -- sh -c "ps aux" > ps-cron.yaml
# ps-cron という名前の CronJob マニフェストを cron 名前空間向けに生成（1分毎実行、alpine で ps aux、適用はせず YAML 出力）

kubectl explain cj --recursive | grep success
# CronJob（cj）リソース定義全体を再帰的に表示し、’success’ に関係するフィールドを抽出

kubectl explain cj.spec | grep success
# CronJob.spec のドキュメントを表示し、’success’ に関する説明行を検索

kubectl explain cj.spec
# CronJob.spec フィールドの詳細な説明を表示

kubectl explain cj.spec.successfulJobsHistoryLimit
# CronJob.spec.successfulJobsHistoryLimit の意味と制限値設定方法を表示

kubectl explain cj --recursive | grep active
# CronJob リソース定義全体から ’active’ に関するフィールドを抽出

kubectl explain cj.spec.jobTemplate.spec --recursive | grep active
# CronJob.jobTemplate.spec 内で ’active’ に関わるフィールドを再帰的に検索

kubectl explain cj.spec.jobTemplate.spec
# CronJob.spec.jobTemplate.spec フィールドのドキュメントを表示

kubectl explain cj.spec.activeDeadlineSeconds
# CronJob.spec.activeDeadlineSeconds の説明を表示（Job を強制終了する秒数制限）


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題9
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/9/logger.yaml


```
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: adapter
spec:
  volumes:
  - name: tmplog
    emptyDir: {}
  containers:
  - name: logger
    image: busybox
    volumeMounts:
    - name: tmplog
      mountPath: /tmp/log
    args:
    - /bin/sh
    - -c
    - >
      while true;
      do
        echo {\"dt\": \"$(date -u)\"} >> /tmp/log/input.log;
        sleep 10;
      done
```


2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/9/resources.yaml


```
---
apiVersion: v1
kind: Namespace
metadata:
  name: adapter
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: adapter
data:
  fluent.conf: |
    <source>
      @type tail
      path /tmp/log/input.log
      <parse>
        @type json
      </parse>
      tag logger.format1
    </source>
    <match logger.format1>
      @type file
      path /tmp/log/output
    </match>
---
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: adapter
spec:
  containers:
  - name: logger
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      while true;
      do
        echo {\"dt\": \"$(date -u)\"} >> /tmp/log/input.log;
        sleep 10;
      done
    volumeMounts:
    - name: tmplog
      mountPath: /tmp/log
  volumes:
  - name: tmplog
    emptyDir: {}
```


問題

adapter名前空間において、loggerという名前のPodがbusyboxイメージを使用してコンテナを実行しています。このコンテナは、10秒ごとにdateコマンドの結果をJSON形式でinput.logファイルに記録します。PodはemptyDirボリュームを/tmp/logディレクトリにマウントし、input.logファイルをそこに保存します。

Podにfluent/fluentd:edgeイメージを使用したコンテナを追加し、/tmp/log/input.logの内容を/tmp/log/output/ディレクトリ内のbufferファイルに出力します。次の手順を実行して下さい。

コンテナ名をfluentdに設定して下さい

loggerコンテナと共有するボリュームを/tmp/logディレクトリにマウントして下さい。

/fluentd/etcディレクトリにfluentd-configmapをマウントして下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
k exec -it -n adapter logger -c logger --sh


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題10
=========================================================
問題

contextという名前空間を作成し、そこにsecure-redisというPodを作成して下さい。コンテナイメージには、redis:alpineを使用し、コンテナのSecurityContextには以下の項目を設定して下さい。



ユーザーID: 2000で実行する。

Privilege escalationをtrueとする。

NET_ADMIN capabilityを付与する。

---------------------------------------------------------
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectl explain pod --recursive | grep SecurityContext  
# Pod リソース定義全体を再帰的に表示し、SecurityContext に関するフィールドを抽出  

kubectl explain pod --recursive | grep Privilege  
# Pod 定義内から Privilege に関連するフィールドを検索  

kubectl explain pod.spec.containers.securityContext --recursive | grep Privilege  
# コンテナの securityContext 下で Privilege 関連フィールドを再帰的に抽出  

kubectl explain pod.spec.containers.securityContext.allowPrivilegeEscalation  
# allowPrivilegeEscalation フラグの意味と設定方法を表示  

kubectl get pod -n context secure-redis -o jsonpath="{.spec.containers[0].securityContext}"  
# context 名前空間の secure-redis Pod からコンテナの securityContext 設定を JSON パスで取得  

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題11
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

1. 次のコマンドを実行して、Ingress Controllerをインストールして下さい。

curl -s https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/11/init-ingress.sh | sh

```
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace

NODE_IP=$(kubectl get nodes controlplane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
echo $NODE_IP path-ingress.info >> /etc/hosts
```

2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/11/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: path-ingress
---
apiVersion: v1
data:
  default.conf.template: |
    server {
        listen       80;
        server_name  localhost;

        location /menu {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
            try_files $uri /menu/index.html;
        }
    }
kind: ConfigMap
metadata:
  name: menu-config
  namespace: path-ingress
---
apiVersion: v1
kind: Pod
metadata:
  name: menu-app
  namespace: path-ingress
  labels:
    run: menu-app
spec:
  initContainers:
  - name: init-con
    image: busybox
    command: ['sh', '-c', 'echo "Menu" > /tmp/content/index.html']
    volumeMounts:
    - name: content
      mountPath: /tmp/content
  containers:
  - image: nginx:alpine
    name: menu-app
    volumeMounts:
    - name: content
      mountPath: /usr/share/nginx/html/menu
    - name: conf
      mountPath: /etc/nginx/templates
  volumes:
  - name: content
    emptyDir: {}
  - name: conf
    configMap:
      name: menu-config
---
apiVersion: v1
kind: Service
metadata:
  labels:
    run: menu-app
  name: menu-svc
  namespace: path-ingress
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: menu-app
  type: ClusterIP
---
apiVersion: v1
data:
  default.conf.template: |
    server {
        listen       80;
        server_name  localhost;

        location /contact {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
            try_files $uri /contact/index.html;
        }
    }
kind: ConfigMap
metadata:
  name: contact-config
  namespace: path-ingress
---
apiVersion: v1
kind: Pod
metadata:
  name: contact-app
  namespace: path-ingress
  labels:
    run: contact-app
spec:
  initContainers:
  - name: init-con
    image: busybox
    command: ['sh', '-c', 'echo "Contact" > /tmp/content/index.html']
    volumeMounts:
    - name: content
      mountPath: /tmp/content
  containers:
  - image: nginx:alpine
    name: contact-app
    volumeMounts:
    - name: content
      mountPath: /usr/share/nginx/html/contact
    - name: conf
      mountPath: /etc/nginx/templates
  volumes:
  - name: content
    emptyDir: {}
  - name: conf
    configMap:
      name: contact-config
---
apiVersion: v1
kind: Service
metadata:
  labels:
    run: contact-app
  name: contact-svc
  namespace: path-ingress
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: contact-app
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    helm.sh/chart: ingress-nginx-4.0.15
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
  name: ingress-nginx-controller-service
  namespace: ingress-nginx
spec:
  type: NodePort
  ipFamilyPolicy: SingleStack
  ipFamilies:
    - IPv4
  ports:
    - name: http
      port: 80
      nodePort: 31100
      protocol: TCP
      targetPort: http
      appProtocol: http
    - name: https
      port: 443
      nodePort: 30443
      protocol: TCP
      targetPort: https
      appProtocol: https
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: info-ingress
  namespace: path-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: path-ingress.info
    http:
      paths:
        - path: /contact
          pathType: Prefix
          backend:
            service:
              name: contact-svc
              port:
                number: 80
```

問題

path-ingress名前空間では、menu-svcとcontact-svcというClusterIPタイプのServiceが、それぞれmenu-appとcontact-appというPodを公開しています。どちらのServiceも、ポート番号は80番を使用します。

contact-svcはinfo-ingressというIngressによってルーティングされ、http://path-ingress.info:31100/contactを使用してcontact-appにアクセスすることが出来ます。



info-ingressを変更し、http://path-ingress.info:31100/menuを使用してmenu-appにアクセスできる設定を追加して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
curl http://path-ingress.info:31100/contact    # info-ingress 経由で contact-app にリクエストし疎通確認
curl http://path-ingress.info:31100/menu       # menu-app 用のパス設定後に動作を検証するためのリクエスト

kubectl explain ingress.spec --recursive | grep service    
# Ingress.spec 以下の service フィールド定義を再帰的に検索して表示

kubectl explain ingress.spec.rules.http.paths.backend   
# Ingress の HTTP ルールで backend ブロック（Service 名／ポート指定）の詳細を表示


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題12
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/12/payment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app-version: stable
    app: payment
  name: payment
  namespace: pay
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment
      app-version: stable
  template:
    metadata:
      labels:
        app: payment
        app-version: stable
    spec:
      containers:
      - image: nginx:alpine
        name: nginx
        volumeMounts:
        - name: labels
          mountPath: /usr/share/nginx/html
      volumes:
      - name: labels
        downwardAPI:
          items:
            - path: "index.html"
              fieldRef:
                fieldPath: metadata.labels
```

2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/12/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: pay
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app-version: stable
    app: payment
  name: payment
  namespace: pay
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment
      app-version: stable
  template:
    metadata:
      labels:
        app: payment
        app-version: stable
    spec:
      containers:
      - image: nginx:alpine
        name: nginx
        volumeMounts:
        - name: labels
          mountPath: /usr/share/nginx/html
      volumes:
      - name: labels
        downwardAPI:
          items:
            - path: "index.html"
              fieldRef:
                fieldPath: metadata.labels
---
apiVersion: v1
kind: Service
metadata:
  name: payment-svc
  namespace: pay
spec:
  selector:
    app: payment
    app-version: stable
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 31120
  type: NodePort
```

問題

pay名前空間では、payment  Deploymentがpayment-svcというServiceにより、NodePort番号31120を使用して外部のネットワークに公開されています。

カナリアデプロイメント戦略を利用し、アプリケーションの新しいバージョンをリリースする必要があります。以下のタスクを実行し、新しいバージョンをDeploymentで作成されるレプリカの20％に展開して下さい。また、アプリケーションを実行するレプリカ数の合計は5に設定して下さい。



1. paymentと同じPodの構成で、payment-canary というDeploymentを作成して下さい。app-versionラベルの値には、canaryを設定して下さい。レプリカ数には、アプリケーションを実行する合計の20％を設定して下さい。

（payment.yamlは、payment Deploymentのマニフェストです。ファイルをコピーしてpayment-canary Deploymentの作成に使用して下さい。）



2. payment-svcを更新し、トラフィックの20％をpayment-canaryに送信して下さい。



なお、curl controlplane:31120を実行することでpayment-svcへの接続をテストする事が出来ます。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
k scale deploy -n pay payment --replicas=4


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

k scale deployment payment -n pay --replicas=4      # payment Deployment を4レプリカにスケールし、合計レプリカ数を5に調整
k get deployment payment -n pay -o yaml > payment-canary.yaml   # 既存 payment Deployment のマニフェストをファイルに出力
# --- payment-canary.yaml を以下のように編集 ---
#   metadata.name: payment-canary         ← Deployment 名を変更
#   metadata.labels:
#     app: payment                       ← 元の app ラベルをそのまま維持
#     app-version: canary                ← canary 用バージョンラベルを追加
#   spec.replicas: 1                     ← レプリカ数を全体の20％(5中1)に設定
#   spec.template.metadata.labels:       ← Pod テンプレートにも同じラベルを追加
#     app: payment
#     app-version: canary
k apply -f payment-canary.yaml    # payment-canary Deployment を作成し、canary Pod を1台起動
k patch svc payment-svc -n pay -p '{"spec":{"selector":{"app":"payment"}}}'  # payment-svc の selector を app=payment のみに設定し、canary Pod を含める
k get endpoints payment-svc -n pay   # payment-svc に登録された Pod 数が5（4 stable + 1 canary）であることを確認
k exec -n pay deploy/payment -- sh -c "curl -m 2 http://payment-svc:80"   # payment-svc 経由でアプリにリクエストし、正常応答を検証



=========================================================
問題13
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

以下のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/13/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: server
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: webapp
  name: webapp
  namespace: server
spec:
  containers:
  - image: bitnami/express
    env:
      - name: PORT
        value: "3030"
    name: webapp
    resources: {}
    command: ["sh", "-c", "express app && cd app; npm i && npm start"]
    ports:
    - containerPort: 3030
---
apiVersion: v1
kind: Service
metadata:
  labels:
    run: webapp
  name: websvc
  namespace: server
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 3000
    nodePort: 30500
  selector:
    run: webapp
  type: NodePort
---
```

問題

server名前空間で作成されているwebapp Podは、bitnami/expressイメージを使用するコンテナを実行しています。Podは同じ名前空間に作成されているwebsvc Serviceによって公開される必要があります。

現在、websvc Serviceを通じてwebapp Podに接続することができません。websvc Serviceの構成を確認し、問題の原因を修正してください。なお、変更はwebsvcにのみ適用し、webapp Podは変更しないで下さい。

---------------------------------------------------------



---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectl get svc                                      # server名前空間の全Serviceを一覧表示し、websvcのタイプやポート設定を確認  
kubectl describe pod webapp -n server                 # webapp Podのラベルやステータス、ポートを詳細表示  
kubectl describe svc websvc -n server                  # websvc Serviceのセレクターやポート設定、エンドポイント情報を確認  
kubectl get endpoints websvc -n server                 # websvc Serviceに紐づくPodのIPリストを表示し、未登録かどうかを確認  
kubectl get nodes -o wide                              # 各ノードのアドレスや条件を確認し、外部IPが必要かどうかを判断  
kubectl edit svc websvc -n server                      # websvc Serviceのマニフェストを編集し、セレクターやポート設定を修正  

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題14
=========================================================
問題

1. rolling-updateという名前空間を作成し、rollingという名前のDeploymentを作成して下さい。イメージはredis:6.2-alpineを使用し、レプリカ数は5とします。strategyのtypeにはRollingUpdateを指定し、maxSurgeを20%、maxUnavailableを2に設定して下さい。



2. kubectl setコマンドを実行し、rollingDeploymentが実行するコンテナのイメージをredis:7.2-alpineに更新して下さい。



3. rollingDeploymentを一つ前のリビジョンにロールバックして下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectl explain deploy --recursive | grep RollingUpdate  
# Deployment リソース定義全体を再帰的に表示し、RollingUpdate に関するフィールドを抽出して確認

kubectl explain deploy.spec.strategy --recursive | grep RollingUpdate  
# Deployment.spec.strategy 以下を再帰的に表示し、RollingUpdate タイプの設定箇所を検索

kubectl explain deploy.spec.strategy.rollingUpdate  
# strategy.rollingUpdate フィールド（maxSurge、maxUnavailable 等）の詳細情報を表示

k get deploy -n rolling-update -o wide  
# rolling-update 名前空間の全 Deployment を詳細情報付きで一覧表示（レプリカ数や戦略タイプ確認用）

k set image deploy rolling -n rolling-update redis=redis:7.2-alpine  
# rolling Deployment のコンテナイメージを redis:7.2-alpine にアップデートしてローリングアップデートを開始

k get deploy -n rolling-update -o wide  
# イメージ更新後、Deployment の現在のリビジョンやレプリカ状態を再度確認

k rollout undo deploy rolling -n rolling-update  
# rolling Deployment を一つ前のリビジョンにロールバックして、元の redis:6.2-alpine イメージに戻す


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
 問題15
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/15/web.yaml

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: web
  name: web
  namespace: probes
spec:
  restartPolicy: Never
  containers:
  - image: nginx:alpine
    name: web
    volumeMounts:
      - name: conf
        mountPath: /etc/nginx/templates
  volumes:
    - name: conf
      configMap:
        name: ng-cm
```

2. 以下のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/15/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: probes
---
apiVersion: v1
data:
  default.conf.template: |
    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        location /live {
            return 200;
        }

        location /ready {
            return 200;
        }
    }
kind: ConfigMap
metadata:
  name: ng-cm
  namespace: probes
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: web
  name: web
  namespace: probes
spec:
  restartPolicy: Never
  containers:
  - image: nginx:alpine
    name: web
    volumeMounts:
      - name: conf
        mountPath: /etc/nginx/templates
  volumes:
    - name: conf
      configMap:
        name: ng-cm
```

問題

probes名前空間では、webという名前のPodが作成されています。web PodにHTTPリクエストによるLiveness ProbeとReadiness Probeを追加して下さい。詳細は以下のとおりです。



Liveness Probeでは、80番ポートを使用して/liveエンドポイントが正常なステータスコードを返すかどうかを認識します。最初のProbeを実行する前に5秒間待機し、その後、10秒おきに実行されます。

Readiness Probeでは、80番ポートを使用して/readyエンドポイントが正常なステータスコードを返すかどうかを認識します。最初のProbeを実行する前に15秒間待機し、その後、10秒おきに実行されます。



ダウンロードしたweb.yamlは、web Podのマニフェストファイルです。上記のLiveness ProbeとReadiness Probeをweb.yamlに追加し、実行中のPodに変更を適用して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectl explain pod. --recursive | grep Probe  
# Podリソース定義を再帰的に表示し、Probeに関連するすべてのフィールドを抽出

kubectl explain pod. --recursive | grep livenessProbe  
# Podリソース定義から livenessProbe フィールドの説明行を検索

kubectl explain pod.spec.containers --recursive | grep livenessProb  
# Pod.spec.containers 以下の定義を再帰的に調べ、livenessProb* にマッチする項目を抽出

kubectl explain pod.spec.containers.livenessProbe  
# コンテナの livenessProbe 設定（HTTP GET パラメータやタイミング）の詳細ドキュメントを表示


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題16
=========================================================
問題

1. helmにbitnamiという名前のリポジトリを追加して下さい。リポジトリのURLはhttps://charts.bitnami.com/bitnamiを使用して下さい。



2. helm search repoコマンドを使用してbitnami/nginxチャートが存在することを確認して下さい。



3. helmを使用してckad-helm名前空間にbitnami/nginxチャートをインストールして下さい。リリース名はmy-nginxとします。



4. helm listコマンドを実行して、my-nginxがデプロイされていることを確認後、kubectl get deploy コマンドを実行して、レプリカの数を確認して下さい。



5. helm upgradeコマンドを実行して、my-nginxのレプリカ数を2に更新して下さい。

---------------------------------------------------------
helmはＣＫＡＤ対象外なので、スキップ
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題17
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

1. wgetコマンドを実行し、次のURLから問題に必要なyamlファイルをダウンロードして下さい。

wget https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/17/ckad-pv-claim.yaml

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: persistent
  name: ckad-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: special
```

2. 以下のコマンドを実行し、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/17/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: persistent
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ckad-pv
  namespace: persistent
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  hostPath:
    path: /tmp/ckad
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: persistent
  name: ckad-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: special
```

問題

persistent名前空間では、ckad-pv Persistent Volumeとckad-pv-claim Persistent Volume Claimが作成されています。ckad-pv は、ckad-pv-claim をバインドする必要があります。

ckad-pv-claimのSTATUSがPendingになっている原因を特定し、Boundになる様に修正して下さい。



なお、修正にはダウンロードしたckad-pv-claim.yamlファイルを使用し、ckad-pv は変更しないで下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
k get pv,pvc -n persistent

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題18
=========================================================
環境準備
cd /home/wsl/dev/k8s-ckad/wsl/test/
../script/reset-hard.sh

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/18/resources.yaml

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: session
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis-deploy
  name: redis-deploy
  namespace: session
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-deploy
  template:
    metadata:
      labels:
        app: redis-deploy
    spec:
      containers:
      - image: redis:alpinee
        name: redis
```

問題

session名前空間では、redis-deployという名前のDeploymentが作成されています。このDeploymentは、redis:alpineイメージを使用したコンテナをレプリカ数1で実行することを目的としていますが、現在エラーが発生しており、Podの起動に失敗しています。エラーの原因を特定し、問題を解決して下さい。

---------------------------------------------------------

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectl get pods -n session
# イメージ名誤りで Pod が Pending または ImagePullBackOff になっていることを確認

kubectl describe pod -n session $(kubectl get pod -n session -o name)
# Events 欄に ErrImagePull や ImagePullBackOff, “not found” のエラーが出ているはず

kubectl set image deployment/redis-deploy \
  -n session \
  redis=redis:alpine

# 新しい Pod が起動して Ready になることを確認
kubectl rollout status deployment/redis-deploy -n session

# Pod が正常に動作しているか
kubectl get pods -n session


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

