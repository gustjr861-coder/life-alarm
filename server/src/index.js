require('dotenv').config();

// Render / 로컬 모두 서울 시간대 기본값
process.env.TZ = process.env.TZ || 'Asia/Seoul';

const express = require('express');
const cors = require('cors');
const axios = require('axios');
const store = require('./store');
const routes = require('./routes');
const {
  startScheduler,
  startKeepAlive,
  getSchedulerStatus,
  seoulParts,
  tick,
} = require('./scheduler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '1mb' }));

store.ensureStore();

app.get('/health', async (_req, res) => {
  // 외부 keep-alive / 수동 접속 시에도 놓친 일정 catch-up
  try {
    await tick({ catchUp: true });
  } catch (err) {
    console.error('[health] catch-up error', err.message);
  }

  const now = seoulParts();
  const scheduler = getSchedulerStatus();
  res.json({
    ok: true,
    service: 'life-alarm-telegram-server',
    timezone: 'Asia/Seoul',
    tzEnv: process.env.TZ || null,
    seoulNow: now,
    telegramConfigured: Boolean(process.env.TELEGRAM_BOT_TOKEN && process.env.TELEGRAM_CHAT_ID),
    scheduleCount: store.getAll().length,
    scheduler,
  });
});

/**
 * GET /telegram/test
 * 브라우저 접속용 — TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID 로 sendMessage 호출
 */
app.get('/telegram/test', async (_req, res) => {
  try {
    const token = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;

    if (!token || !chatId) {
      return res.status(500).json({
        success: false,
        error: 'TELEGRAM_BOT_TOKEN 또는 TELEGRAM_CHAT_ID 환경변수가 없습니다.',
      });
    }

    await axios.post(
      `https://api.telegram.org/bot${token}/sendMessage`,
      {
        chat_id: chatId,
        text: '✅ Render 테스트 성공',
        disable_web_page_preview: true,
      },
      { timeout: 15000 }
    );

    return res.json({ success: true });
  } catch (err) {
    const detail = err.response?.data || err.message;
    console.error('[telegram/test] failed:', detail);
    return res.status(500).json({
      success: false,
      error: typeof detail === 'string' ? detail : JSON.stringify(detail),
    });
  }
});

/** 스케줄러 상태만 확인 */
app.get('/scheduler/status', (_req, res) => {
  res.json(getSchedulerStatus());
});

app.use(routes);

app.use((err, _req, res, _next) => {
  console.error('[server] unhandled', err);
  res.status(500).json({ error: err.message || 'Internal Server Error' });
});

app.listen(PORT, () => {
  console.log(`[server] listening on :${PORT}`);
  console.log(`[server] Asia/Seoul now:`, seoulParts());
  console.log('[server] GET /telegram/test registered');
  if (!process.env.TELEGRAM_BOT_TOKEN || !process.env.TELEGRAM_CHAT_ID) {
    console.warn('[server] WARNING: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID 미설정');
  }

  const { jobs } = startScheduler();
  console.log(`[server] scheduler jobs count: ${jobs.length}`);
  startKeepAlive();
});
