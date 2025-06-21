### `observability-three-pillars.md` — Metrics / Logs / Traces 詳細ガイド

*CKAD を終えたエンジニアが KCNA・KCSA・CKS で要求される “可観測性の全体像” を 1 ファイルで把握できるように構成しています。*

---

## 0. TL;DR

| Pillar      | 代表 OSS                                   | 主要フォーマット                | 主な問いに答える                             |
| ----------- | ---------------------------------------- | ----------------------- | ------------------------------------ |
| **Metrics** | Prometheus / Thanos / Grafana            | PromQL, OpenMetrics     | いま **数値がどう推移**しているか？ (CPU, QPS, SLA) |
| **Logs**    | Fluent Bit / Loki / Elastic Stack        | JSON / Logfmt / Syslog  | 何が **いつ・どこで**起きたか？ (ERROR, WARN)     |
| **Traces**  | OpenTelemetry Collector / Jaeger / Tempo | OTLP, W3C Trace Context | 1 リクエストが **どのサービスを何 ms** で通ったか？      |

---

## 1. Why — 可観測性が「三本柱」な理由

1. **Metrics** … SLA を保つための **早期傾向検知**
2. **Logs** … インシデント原因を **深掘り**
3. **Traces** … 分散アプリで **遅延ボトルネックを特定**

三つを合わせて “MELT” (Metrics-Events-Logs-Traces) スタックとも呼ぶ。
Prometheus だけでは「遅い原因が何か」は突き止めにくく、トレースが最後の 1 ピースになる。

---

## 2. Metrics — 時系列データ

### 2-1. 基礎用語

* **Sample** = `value + timestamp`
* **Time Series** = `{name, label_set} → [sample…]`
* **Scrape** = Exporter → Prometheus pull

### 2-2. PromQL ３式だけ覚える

```promql
rate(http_requests_total[5m])         # RPS
histogram_quantile(0.99, rate(latency_bucket[5m])) # 99p latency
sum by(pod) (container_memory_working_set_bytes)   # Mem per Pod
```

### 2-3. Hands-on

```bash
# デフォルトターゲット確認
kubectl -n monitoring port-forward svc/prometheus-k8s 9090:9090 &
curl -s localhost:9090/api/v1/targets | jq .data.activeTargets[].labels.job | head
```

---

## 3. Logs — イベント履歴

### 3-1. Fluent Bit → Loki 流れ

```
Pod (stdout) ─► containerd ─► journald
             └► Fluent Bit ─► Loki ─► Grafana Explore
```

### 3-2. 検索クエリ（LogQL v2）

```logql
{app="nginx", level="error"} |= "timeout"
```

### 3-3. Hands-on

```bash
kubectl logs deploy/nginx --tail 20
kubectl exec -it deploy/fluent-bit -- tail /var/log/containers/*.log | head
```

---

## 4. Traces — 分散トランザクション

### 4-1. OpenTelemetry パイプライン

```
OTel SDK (auto-instrument) 
   └─> OTLP gRPC 
        └─> OTel Collector 
              ├─> Jaeger (storage) 
              └─> Tempo
```

### 4-2. Jaeger UI で見るポイント

* **TraceID** 同一か
* **Span waterfall** で赤帯(エラー) or 青帯(遅延)
* **Critical path** 合計 > 95 % は問題域

### 4-3. Hands-on

```bash
kubectl -n tracing port-forward svc/jaeger-query 16686:16686 &
open http://localhost:16686
```

---

## 5. End-to-End 可観測性パイプライン (例: EKS)

```
Node Exporter ──┐
cAdvisor ───────┤   [Metrics] ─► Prometheus ─► Thanos ─► Grafana Dashboards
App stdout ───┐ │
Fluent Bit ─┐ │ │   [Logs] ─► Loki ─► Grafana Explore
            │ │ │
OTel SDK ─┐ │ │ │   [Traces] ─► OTel Collector ─► Tempo / Jaeger
          ▼ ▼ ▼ ▼
          Kubernetes Labels (namespace/pod/container) を共通 key に
```

---

## 6. 15 分セルフラボ

1. **メトリクス追加**

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install kube-prom prometheus-community/kube-prometheus-stack
   ```
2. **Loki＋Promtail セット追加** (Grafana Agent でも可)
3. **OTel Sidecar** を sample Python app に auto-instrument
4. **Grafana Dashboard** を 1 枚だけ作成 → Metric / Log / Trace を Drill-Down

---

## 7. 試験チート

| 試験       | よく出るキーワード                                     | 最低覚えること                            |
| -------- | --------------------------------------------- | ---------------------------------- |
| **KCNA** | *“Prometheus は Observability の何？”*            | 三本柱の分類＋代表 OSS 名                    |
| **KCSA** | `audit_log`, `metric_exporter`, `traceparent` | ログ改ざん検知、メトリクスで DoS 検知、Trace Header |
| **CKS**  | `Falco → Prometheus Alert → Slack`            | 連携パイプラインで攻撃通知                      |

---

### 8. まとめ

* **Metrics = 遠くを見る望遠鏡**、**Logs = 拡大鏡**、**Traces = 地図と時計**
* まず **Prom + Loki + OTel Collector** の “P-L-T” を PoC し、
  ボトルネックが出たら **Thanos (long-term) / Tempo (scalable trace)** を追加。

> さらに SQL-based observability (Grafana Faro, ClickHouse) や eBPF トレースを深掘りしたい場合は気軽にリクエストしてください！
