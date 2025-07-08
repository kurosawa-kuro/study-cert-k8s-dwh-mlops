
# Next.js 15 (SSR) × Express API × Aurora PostgreSQL × EKS — CKAD 実践 設計

---

## 0. ゴール

|項目|内容|
|---|---|
|**CKAD**|Probes / PDB / HPA / RBAC / NP / Jobs … **100 % カバー**|
|**フロント**|**Next.js 15 (App Router)／SSR デフォルト**|
|**バックエンド**|Express (TypeScript) + swagger-jsdoc|
|**DB**|Amazon Aurora PostgreSQL (Serverless v2)|
|**IaC / GitOps**|Terraform + Helm + Argo CD|
|**ローカル**|kind + Tilt（ホットリロード）|

---

## 1. リポジトリレイアウト

```
repo/
├─ .github/workflows/            # CI/CD
├─ docs/                         # ← ★このドキュメント
├─ front/                        # Next.js 15
│   ├─ app/
│   ├─ public/
│   └─ Dockerfile
├─ api/                          # Express (TS)
│   ├─ src/
│   ├─ test/
│   └─ Dockerfile
├─ infra/
│   ├─ helm/
│   │   ├─ front/                # Helm Charts
│   │   └─ api/
│   ├─ kustomize/                # overlays/dev,prod
│   └─ terraform/                # vpc, eks, karpenter, rds, irsa
└─ tools/
    └─ tilt/Tiltfile
```

---

## 2. Kubernetes リソース設計（front / api / shared）

|コンポーネント|Manifest|主な CKAD 要素|
|---|---|---|
|**front** (SSR)|Deployment / Service / Ingress / PDB / HPA|Probes・resources|
|**api**|Deployment / Service / HPA / Secret / ConfigMap / RBAC|DB Secret・RBAC|
|**shared**|Namespace / NetworkPolicy|default-deny + allow|

---

### 2.1 front — Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "front.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}          # 既定 2
  selector:
    matchLabels: {{- include "front.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels: {{- include "front.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: front-sa
      containers:
        - name: nextjs
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 3000
          env:
            - name: NEXT_PUBLIC_API_BASE_URL
              value: "http://api-svc.app.svc.cluster.local"
          readinessProbe:
            httpGet: { path: /healthz, port: 3000 }
            initialDelaySeconds: 5
          livenessProbe:
            httpGet: { path: /healthz, port: 3000 }
            initialDelaySeconds: 30
          resources:
            requests: { cpu: "200m", memory: "256Mi" }
            limits:   { cpu: "600m", memory: "768Mi" }
```

### 2.2 front — Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: front-svc
spec:
  selector:
    app.kubernetes.io/name: front
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
```

### 2.3 front — Ingress (ALB)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /api(/|$)(.*)
            pathType: Prefix
            backend:
              service: { name: api-svc, port: { number: 80 } }
          - path: /(.*)
            pathType: Prefix
            backend:
              service: { name: front-svc, port: { number: 80 } }
```

### 2.4 front — PDB

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: front-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: front
```

### 2.5 front — HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: front-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: front
  minReplicas: 2
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

---

### 2.6 api — Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "api.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}          # 既定 2
  selector:
    matchLabels: {{- include "api.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels: {{- include "api.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: api-sa                # ← RBAC 参照
      containers:
        - name: express
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 3000
          envFrom:
            - secretRef: { name: rds-credentials }
            - configMapRef: { name: api-config }
          readinessProbe:
            httpGet: { path: /healthz, port: 3000 }
            initialDelaySeconds: 5
          livenessProbe:
            httpGet: { path: /healthz, port: 3000 }
            initialDelaySeconds: 30
          resources:
            requests: { cpu: "250m", memory: "256Mi" }
            limits:   { cpu: "750m", memory: "768Mi" }
```

### 2.7 api — Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-svc
spec:
  selector:
    app.kubernetes.io/name: api
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
```

### 2.8 api — HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 8
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65
```

### 2.9 api — Secret（RDS）

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rds-credentials
type: Opaque
stringData:
  DB_HOST: "aurora.cluster-xyz.ap-northeast-1.rds.amazonaws.com"
  DB_PORT: "5432"
  DB_NAME: "app"
  DB_USER: "appuser"
  DB_PASSWORD: "CHANGEME"
```

### 2.A api — ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  APP_PORT: "3000"
  LOG_LEVEL: "info"
```

### 2.B api — RBAC

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: read-config
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: api-read-config
subjects:
  - kind: ServiceAccount
    name: api-sa
roleRef:
  kind: Role
  name: read-config
  apiGroup: rbac.authorization.k8s.io
```

---

## 3. Dockerfile（front, api）

### 3.1 front (SSR)

```dockerfile
FROM node:20-bookworm AS builder
WORKDIR /app
COPY package*.json pnpm-lock.yaml ./
RUN corepack enable && pnpm i --frozen-lockfile
COPY . .
RUN pnpm build                  # next build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["pnpm", "start"]           # next start
```

### 3.2 api

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json pnpm-lock.yaml ./
RUN corepack enable && pnpm i --prod --frozen-lockfile
COPY . .
EXPOSE 3000
CMD ["pnpm","start"]            # nest start or ts-node
```

---

## 4. CI/CD ワークフロー（抜粋）

- front-build.yml → Docker build/push → Helm upgrade
    
- api-build.yml → Lint/Test → Docker build/push → Helm upgrade
    
- deploy.yml → merge to `main` → Argo CD Sync (front → api)
    

---

## 5. Terraform モジュール (抜粋)

|モジュール|内容|
|---|---|
|`network`|VPC / Subnet / IGW / NATGW|
|`eks`|Cluster / NodeGroup (OD+Spot)|
|`karpenter`|Provisioner / NodeClass|
|`rds`|Aurora Serverless v2|
|`irsa`|`api-sa` → Secrets Manager / SSM|

---

## 6. CKAD 対応マッピング

|トピック|実装箇所|
|---|---|
|Probes / QoS|`infra/helm/*/deployment.yaml`|
|Secret / Config|`infra/helm/api/secret.yaml`, `config.yaml`|
|Observability|`infra/kustomize/base/monitoring/`|
|Job / CronJob|`api-migrate` Job|
|RBAC / Security|`infra/helm/api/rbac.yaml`|
|NetworkPolicy|`infra/kustomize/base/networkpolicy.yaml`|

---

## 7. ローカル開発フロー

```bash
kind create cluster
tilt up               # front & api live-reload
docker-compose up postgres
kubectl port-forward svc/front-svc 3000:3000
```

---

## 8. QA / Self-review チェックリスト

- Helm lint / chart-test ✅
    
- `kubectl auth can-i` negative cases ⛔
    
- `k6 run smoke.js` error ≤ 1 %
    
- Argo CD SyncStatus = Healthy
    
- Cost Explorer: `deployment=front` 把握
    

---

## 9. 拡張バックログ

1. Argo Rollouts + canary
    
2. KEDA (SQS event-driven autoscale)
    
3. gRPC + Envoy gateway
    
4. SOPS + KMS で Secrets 暗号化
    

---

### END

不足・追加があれば教えてください。

### 結論 – **WSL 2＋kind** でもそのまま動かせます

ただし **クラウド向け（ALB／Karpenter）とローカル向け（ingress-nginx／NodePort）をオーバーレイで切り替える**――という小さな追加が必要です。以下に “最短で稼働させるチェックリスト” と差分ポイントをまとめました。

---

## 1. WSL 2／kind 環境での最短手順

|手順|コマンド／設定|補足|
|---|---|---|
|① Docker Desktop を WSL 2 backend で起動|Windows 側で “Use the WSL 2 based engine” をオン|WSL 内では `docker ps` が通れば OK|
|② kind をインストール|`curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 && chmod +x kind && sudo mv kind /usr/local/bin/`||
|③ kind クラスタを作成|`kind create cluster --config kind-wsl.yaml`（下記参照）|80/443 を Windows ホストにバインド|
|④ ingress-nginx を導入|`helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx``helm install ingress ingress-nginx/ingress-nginx`|LoadBalancer が使えないため必須|
|⑤ `infra/kustomize/dev` を apply|`kubectl apply -k infra/kustomize/dev`|overlay で IngressClass=`nginx` に切替|
|⑥ フロント確認|ブラウザで `http://localhost/`|API は `http://localhost/api/*`|

### kind-wsl.yaml 例

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80   # ingress-nginx
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
```

---

## 2. ドキュメントとの差分ポイント

|項目|クラウド (EKS)|WSL 2＋kind (dev overlay)|
|---|---|---|
|IngressClass|`alb`|`nginx`|
|Service type|ClusterIP (→ALB)|ClusterIP + NodePort (ingress-nginxが内部で使用)|
|LoadBalancer|AWS ALB|なし（不要）|
|Karpenter / Spot|あり|なし|
|Aurora|本番接続|ローカルは `docker-compose postgres` で代替|

**実装方法**

- `infra/kustomize/overlays/dev/patch-ingress-class.yaml` で Ingress の `ingressClassName: nginx` をパッチ。
    
- `kind-wsl.yaml` をリポジトリに追加し、README に “WSL 開発手順” セクションを追記。
    

---

## 3. よくある WSL 2／kind のハマりどころ

|症状|原因 / 解決策|
|---|---|
|**Ingress にアクセス出来ない**|extraPortMappings を忘れている／ingress-nginx が Pending。`kubectl get svc -A` で `ingress-nginx-controller` の EXTERNAL-IP が `localhost` になっていれば OK|
|**ファイル変更が激遅**|WSL ↔ Windows のパス境界で Volume を共有すると遅くなる。`/mnt/wsl` 直下にリポジトリを clone すると改善|
|**Docker build が ARM/AMD 不一致**|Windows on ARM マシンの場合、Multi-arch イメージ (`--platform=linux/amd64`) を明示|
|**Tilt の Hot-reload が走らない**|`tilt doctor` で `docker_host` が `npipe` になっていないか確認。`export DOCKER_HOST=unix:///var/run/docker.sock`|

---

## 4. まとめ

- **オーバーレイで IngressClass と ServiceType を切り替える**だけで、WSL 2＋kind でもドキュメント通りに動く。
    
- 本番との差分を `kustomize overlays/dev` に閉じ込めれば、CI も Argo CD も変更不要。
    
- これにより **「ローカル（WSL）→kind→EKS」** の一貫したフローが完成し、CKAD 演習もそのまま再現できます。
    

追記用の `kind-wsl.yaml` と `patch-ingress-class.yaml` のサンプルを提供できますので、必要なら声をかけてください。