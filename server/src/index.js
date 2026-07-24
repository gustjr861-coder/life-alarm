require('dotenv').config();

const express = require('express');
const cors = require('cors');
const store = require('./store');
const routes = require('./routes');
const { startScheduler, seoulParts } = require('./scheduler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '1mb' }));

store.ensureStore();

app.get('/health', (_req, res) => {
  const now = seoulParts();
  res.json({
    ok: true,
    service: 'life-alarm-telegram-server',
    timezone: 'Asia/Seoul',
    seoulNow: now,
    telegramConfigured: Boolean(process.env.TELEGRAM_BOT_TOKEN && process.env.TELEGRAM_CHAT_ID),
    scheduleCount: store.getAll().length,
  });
});

app.use(routes);

app.use((err, _req, res, _next) => {
  console.error('[server] unhandled', err);
  res.status(500).json({ error: err.message || 'Internal Server Error' });
});

app.listen(PORT, () => {
  console.log(`[server] listening on :${PORT}`);
  console.log(`[server] Asia/Seoul now:`, seoulParts());
  if (!process.env.TELEGRAM_BOT_TOKEN || !process.env.TELEGRAM_CHAT_ID) {
    console.warn('[server] WARNING: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID 미설정');
  }
  startScheduler();
});
