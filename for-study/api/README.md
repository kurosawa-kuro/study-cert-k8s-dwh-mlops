# api-nodejs-k8s-8000

Express.jsを使用したシンプルなAPIサーバーです。Kubernetes環境でのデプロイに対応しています。

## 機能

- ヘルスチェックエンドポイント (`/healthz`)
- レディネスチェックエンドポイント (`/readyz`)
- 設定情報エンドポイント (`/config`)
- Prometheusメトリクスエンドポイント (`/metrics`)
- **Swagger API ドキュメント** (`/api-docs`)
- ユーザー管理API (`/api/users`)
- 環境変数による設定
- Kubernetes対応（マルチステージDockerビルド）
- セキュリティ強化（非rootユーザー、RBAC、NetworkPolicy）

## API ドキュメント

### Swagger UI

アプリケーション起動後、以下のURLでSwagger UIにアクセスできます：

```
http://localhost:8000/api-docs
```

### 利用可能なエンドポイント

#### 基本エンドポイント
- `GET /` - アプリケーションの挨拶メッセージ
- `GET /healthz` - ヘルスチェック
- `GET /readyz` - レディネスチェック
- `GET /config` - アプリケーション設定（APIキー認証必要）
- `GET /metrics` - Prometheusメトリクス

#### ユーザー管理API
- `GET /api/users` - ユーザー一覧取得
- `POST /api/users` - 新規ユーザー作成
- `GET /api/users/{id}` - ユーザー詳細取得
- `PUT /api/users/{id}` - ユーザー情報更新
- `DELETE /api/users/{id}` - ユーザー削除

### 認証

一部のエンドポイントでは、APIキー認証が必要です：

```bash
# APIキーをヘッダーに設定
curl -H "X-API-Key: your-api-key" http://localhost:8000/config
```

### 使用例

```bash
# ユーザー一覧を取得
curl http://localhost:8000/api/users

# 新規ユーザーを作成
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "name": "New User",
    "password": "password123",
    "role": "user"
  }'

# 特定のユーザー情報を取得
curl http://localhost:8000/api/users/user-1

# ユーザー情報を更新
curl -X PUT http://localhost:8000/api/users/user-1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated User",
    "role": "admin"
  }'

# ユーザーを削除
curl -X DELETE http://localhost:8000/api/users/user-1
```

## インストール

```bash
npm install
```

## 開発サーバーの起動

```bash
npm run dev
```

## 本番サーバーの起動

```bash
npm start
```

## Kubernetes デプロイ

### 前提条件

- Minikube
- Docker
- kubectl
- Node.js 18+

### Minikube環境でのデプロイ

#### 1. Minikubeの起動

```bash
minikube start --driver=docker
```

#### 2. 完全デプロイスクリプトの実行

```bash
./deploy-minikube-complete.sh
```

このスクリプトは以下を自動実行します：
- Minikubeの状態確認
- Docker環境の設定
- Dockerイメージのビルド（権限問題回避済み）
- Kubernetesマニフェストの適用
- デプロイ状態の確認
- ヘルスチェック

#### 3. クリーンアップ

```bash
./deploy-minikube-complete.sh --clean
```

### アプリケーションへのアクセス

#### Port-forwardを使用したアクセス

```bash
kubectl port-forward svc/express-svc 8080:80 -n express-app
```

ブラウザで `http://localhost:8080` にアクセス

#### NodePort Serviceを使用したアクセス

```bash
kubectl port-forward svc/express-svc-nodeport 8080:80 -n express-app
```

または

```bash
minikube service express-svc-nodeport -n express-app
```

### ヘルスチェック

```bash
# ヘルスチェック
curl http://localhost:8080/healthz

# レディネスチェック
curl http://localhost:8080/readyz

# メトリクス
curl http://localhost:8080/metrics

# 設定情報
curl http://localhost:8080/config
```

### デプロイ状態の確認

```bash
# Podの状態確認
kubectl get pods -n express-app

# Serviceの状態確認
kubectl get svc -n express-app

# 全体的なリソース状態
kubectl get all -n express-app

# ログ確認
kubectl logs -f deployment/express-deploy -n express-app
```

## 最近の修正内容

### ✅ 解決済みの問題

1. **Ingress対応の削除**
   - 複雑なIngress設定を削除
   - NodePort ServiceとPort-forwardによるシンプルなアクセス方法に変更

2. **Docker buildx権限問題の解決**
   - `DOCKER_BUILDKIT=0`で権限エラーを回避
   - 通常のdocker buildを使用

3. **npm依存関係の問題解決**
   - package-lock.jsonの再生成
   - `caniuse-lite`パッケージの競合を解決

4. **Minikubeネットワーク問題の解決**
   - Service IP割り当てエラーの解決
   - クラスターの再作成によるネットワーク設定のリセット

5. **マニフェストファイルの修正**
   - Ingress定義の完全削除
   - シンプルなService構成に変更

### 🔧 技術的改善

- **セキュリティ強化**: 非rootユーザー、RBAC、NetworkPolicy
- **軽量化**: Ingressコントローラーの削除
- **安定性向上**: 権限問題の回避
- **再現性向上**: 自動化されたデプロイスクリプト

## テスト

### テストの実行

```bash
# 全テストを実行
npm test

# ウォッチモードでテストを実行
npm run test:watch

# カバレッジ付きでテストを実行
npm run test:coverage
```

### テスト構成

- **Jest**: テストフレームワーク
- **Supertest**: HTTPテストライブラリ
- **テストファイル**:
  - `tests/server.test.js`: 基本的なAPIテスト
  - `tests/integration.test.js`: 統合テスト

### テスト内容

#### 基本テスト (`server.test.js`)
- 各エンドポイントの正常動作確認
- HTTPステータスコードの検証
- レスポンス形式の検証
- エラーハンドリングのテスト
- パフォーマンステスト

#### 統合テスト (`integration.test.js`)
- 完全なAPIワークフローのテスト
- 負荷テストシミュレーション
- エラー回復テスト
- セキュリティテスト
- 同時アクセステスト

### テストカバレッジ

テスト実行後、`coverage/`ディレクトリにカバレッジレポートが生成されます。

## 環境変数

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `PORT` | `8000` | サーバーのポート番号 |
| `APP_GREETING` | `'Hello from Express!'` | ルートエンドポイントのメッセージ |
| `API_KEY` | `'not‑set'` | APIキー（設定例） |
| `NODE_ENV` | - | 環境設定（`test`でテストモード） |

## API エンドポイント

### GET /
ルートエンドポイント。設定可能な挨拶メッセージを返します。

**レスポンス例:**
```
Hello from Express!
```

### GET /healthz
ヘルスチェックエンドポイント。

**レスポンス例:**
```json
{
  "status": "ok"
}
```

### GET /readyz
レディネスチェックエンドポイント。

**レスポンス例:**
```json
{
  "status": "ready"
}
```

### GET /config
現在の設定情報を返します。

**レスポンス例:**
```json
{
  "APP_GREETING": "Hello from Express!",
  "API_KEY": "not‑set"
}
```

### GET /metrics
Prometheus形式のメトリクスを返します。

**レスポンス例:**
```
# HELP http_request_duration_seconds Duration of HTTP requests in seconds
# TYPE http_request_duration_seconds histogram
...
```

## 開発ガイド

### 新しいエンドポイントの追加

1. `server.js`にルートを追加
2. 対応するテストを`tests/server.test.js`に追加
3. 必要に応じて統合テストを`tests/integration.test.js`に追加

### テストの追加

新しいテストを追加する際は、以下のパターンに従ってください：

```javascript
describe('New Feature Tests', () => {
  it('should handle new functionality', async () => {
    const response = await request(app)
      .get('/new-endpoint')
      .expect(200);

    expect(response.body).toEqual(expectedData);
  });
});
```

## トラブルシューティング

### Kubernetesデプロイの問題

#### Service IP割り当てエラー
```bash
# Minikubeを再起動
minikube stop
minikube start --driver=docker

# または完全に削除して再作成
minikube delete
minikube start --driver=docker
```

#### Docker buildx権限エラー
```bash
# スクリプト内で自動的に回避されます
export DOCKER_BUILDKIT=0
```

#### Podが起動しない場合
```bash
# Podの詳細を確認
kubectl describe pod <pod-name> -n express-app

# ログを確認
kubectl logs <pod-name> -n express-app
```

### テストが失敗する場合

1. 依存関係が正しくインストールされているか確認：
   ```bash
   npm install
   ```

2. テスト環境変数が設定されているか確認：
   ```bash
   export NODE_ENV=test
   npm test
   ```

3. Jest設定が正しいか確認：
   ```bash
   node --experimental-vm-modules node_modules/jest/bin/jest.js --showConfig
   ```

### サーバーが起動しない場合

1. ポートが使用中でないか確認
2. 環境変数が正しく設定されているか確認
3. 依存関係がインストールされているか確認

## 便利なコマンド

```bash
# 状態確認
kubectl get all -n express-app

# イベント確認
kubectl get events -n express-app --sort-by='.lastTimestamp'

# リソース使用量
kubectl top pods -n express-app

# クリーンアップ
kubectl delete namespace express-app
docker rmi api-nodejs-k8s:latest
``` 