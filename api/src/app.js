import express from 'express';
import promBundle from 'express-prom-bundle';
import morgan from 'morgan';
import dotenv from 'dotenv';

// テスト時はdotenvを読み込まない
if (process.env.NODE_ENV !== 'test') {
  dotenv.config();
}

const app  = express();

// Prometheus metrics ( /metrics )
app.use(promBundle({ includeMethod: true, promClient: { collectDefaultMetrics: {} } }));

// Env‑based config
const APP_GREETING = process.env.APP_GREETING ?? 'Hello from Express!';
const API_KEY      = process.env.API_KEY      ?? 'not‑set';

console.log("APP_GREETING",APP_GREETING);
console.log("API_KEY", API_KEY);

// HTTP request logger middleware
app.use(morgan('combined'));

// セキュリティ: x-powered-byヘッダーを無効化
app.disable('x-powered-by');

// Routes
app.get('/',      (_req, res) => res.send(APP_GREETING));
app.get('/healthz',(_req, res) => res.json({ status: 'ok' }));
app.get('/readyz', (_req, res) => res.json({ status: 'ready' }));
app.get('/config', (_req, res) => res.json({ APP_GREETING, API_KEY }));

const port = process.env.PORT || 8000;

// Only start server if not in test environment
if (process.env.NODE_ENV !== 'test') {
  app.listen(port, () => console.log(`Listening on ${port}`));
}

// Export app for testing
export default app; 