# api-nodejs-k8s-8000

Express.jsを使用したシンプルなAPIサーバーです。

## 機能

- ヘルスチェックエンドポイント (`/healthz`)
- レディネスチェックエンドポイント (`/readyz`)
- 設定情報エンドポイント (`/config`)
- Prometheusメトリクスエンドポイント (`/metrics`)
- 環境変数による設定

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