### `networking-cni-overview.md` — Kubernetes Networking & CNI Quick Guide

*CKAD 経験者が KCNA／KCSA／CKS に備えて「Pod 間通信の舞台裏」と
主要 CNI プラグインの違いを 1 ファイルでつかめるよう構成。*

---

## 0. Bird-Eye View — “IP-per-Pod” がすべての起点

```
┌────────────────────────────┐
│  Service (ClusterIP)       │  Virtual IP (kube-proxy / eBPF)  
└┬─────────────┬─────────────┘
 ├─ Pod A (10.244.0.5)  ─────┐
 │    eth0 → veth0 ↔ veth1   │  CNI creates veth‐pair, assigns IP  
 │                           │
 ├─ Pod B (10.244.0.7)  ─────┘   same Node → linux bridge  
 │
 └─  cni0 (10.244.0.1/24)  — overlay / routed → another Node
```

> **覚え方**: 「Pod＝1st-class IP、Service＝Virtual IP、CNI＝その交通整理係」。

---

## 1. WHY — ネットワークを理解するメリット

| 観点               | 実務 / 試験で効く場面                                        |
| ---------------- | --------------------------------------------------- |
| **Troubleshoot** | Pod から他 Pod へ ping 不可 → CNI or NetworkPolicy を即切り分け |
| **Security**     | CKS で “NetworkPolicy 制御不能 = 失点” を防ぐ                 |
| **Performance**  | eBPF datapath (Cilium) で p99 レイテンシ削減を議論できる          |

---

## 2. WHAT — 3 レイヤで整理 (K8s, CNI, Datapath)

| レイヤ                                     | 説明                                    | 主要コンポーネント                                  |
| --------------------------------------- | ------------------------------------- | ------------------------------------------ |
| **Kubernetes Abstract**                 | Service, EndpointSlice, NetworkPolicy | kube-proxy, kube-controller-manager        |
| **CNI Spec (Container Runtime ↔ Host)** | `ADD`, `DEL`, `CHECK` で veth & Route  | Calico / Cilium / Flannel / Weave / Multus |
| **Datapath**                            | iptables / ipvs / eBPF / Wireguard    | Cilium eBPF, Calico VPP, Flannel VXLAN     |

---

## 3. CNI プラグイン対比表

| 特性            | **Flannel**      | **Calico**                    | **Cilium**                              | **Multus**        |
| ------------- | ---------------- | ----------------------------- | --------------------------------------- | ----------------- |
| デフォルト採用       | k3s / MicroK8s   | GKE (Dataplane V2)、EKS Add-on | EKS-Anywhere、AKS Cilium                 | ― (追加接続用)         |
| モード           | VXLAN / host-gw  | BGP route / VXLAN             | **eBPF native**                         | n/c (delegates)   |
| NetworkPolicy | ❌ (kube-proxy依存) | ✅ (iptables)                  | ✅ (eBPF)                                | ―                 |
| 特殊機能          | シンプル & 軽量        | WireGuard, VPP                | Hubble observability, Service mesh lite | SR-IOV, DualStack |

> **試験覚え方**:
> *“Flannel＝シンプル、Calico＝BGP & NP、Cilium＝eBPF & 観測、Multus＝マルチ NIC”*

---

## 4. HOW — ハンズオン 30 分

### 4-1. Pod → Pod (同ノード)

```bash
kubectl run a --image=busybox -it --restart=Never -- sh
# 新ターミナル
kubectl run b --image=busybox -it --restart=Never -- sh
# Node & IP 確認
kubectl get pod -o wide
# ping
kubectl exec a -- ping -c 3 <Pod-B-IP>
```

* **ポイント**: veth-pair & linux bridge (cni0) → `ip link | grep veth`.

### 4-2. kube-proxy ルール確認

```bash
iptables-save | grep KUBE-SVC | head
# IPVS モードなら
ipvsadm -ln | head
```

### 4-3. NetworkPolicy で通信遮断 (Calico/Cilium)

```bash
kubectl apply -f deny.yaml   # kind: NetworkPolicy (deny all)
kubectl exec a -- ping -c 3 <Pod-B-IP>   # should fail
```

---

## 5. Exam Cheat Sheet

| 試験       | 出やすいキーワード            | 即答フレーズ                                        |
| -------- | -------------------- | --------------------------------------------- |
| **KCNA** | “CNI 目的”             | Container ↔ Host veth & IPAM                  |
| **CKAD** | “Service vs Ingress” | *Service = L4 VIP, Ingress = L7 HTTP routing* |
| **KCSA** | “4 C’s どの層？”         | NetworkPolicy → **Cluster** layer             |
| **CKS**  | “Cilium Hubble 何?”   | eBPF ベースの flow observability                  |

---

## 6. Self-Quiz (○×)

1. Calico は VXLAN をサポートするがデフォルトは BGP ルーティングである。
2. kube-proxy の iptables モードでは **Node ごとに** Service VIP が DNAT される。
3. NetworkPolicy は Service ではなく Pod‐Selector がマッチ対象である。

<details><summary>Answer</summary>1:○ 2:○ 3:○</details>

---

## 7. まとめ／Next Step

* **ネットワーク理解 = Pod-IP と Service-VIP がどう転送されるか**を追い切ること。
* 実務では **Calico↔Cilium** の乗せ換え PoC で “eBPF vs iptables” を体感すると理解が一段深くなる。
* さらなる深掘り（BGP / eBPF マップ、Service Mesh 連携、Dual-Stack IPv6）を希望の場合はお知らせください！
