const cron = require('node-cron');
const store = require('./store');
const { sendTelegramMessage, formatMessage } = require('./telegram');

/**
 * 날짜(요일/일/월)만 맞는지 — 시각은 제외
 */
function matchesDateOnly(schedule, nowParts) {
  if (!schedule.isEnabled) return false;

  const { month, day, weekday } = nowParts;

  switch (schedule.repeatKind) {
    case 'daily':
      return true;
    case 'weekly': {
      // JS getDay: 0=일 ... 6=토  →  iOS Calendar weekday: 1=일 ... 7=토
      const iosWeekday = weekday === 0 ? 1 : weekday + 1;
      const days = Array.isArray(schedule.weekdays) ? schedule.weekdays : [];
      return days.map(Number).includes(iosWeekday);
    }
    case 'monthly':
      return Number(schedule.dayOfMonth) === day;
    case 'yearly':
      return Number(schedule.monthOfYear) === month && Number(schedule.dayOfYear) === day;
    default:
      return false;
  }
}

/**
 * Asia/Seoul 기준 — 시각까지 정확히 일치
 */
function matchesSchedule(schedule, nowParts) {
  if (!matchesDateOnly(schedule, nowParts)) return false;
  return (
    Number(schedule.hour) === nowParts.hour
    && Number(schedule.minute) === nowParts.minute
  );
}

/**
 * Render sleep 등으로 정각을 놓친 경우:
 * 같은 날짜에 예정 시각이 이미 지났고 아직 미전송이면 catch-up
 */
function shouldCatchUp(schedule, nowParts) {
  if (!matchesDateOnly(schedule, nowParts)) return false;

  const nowMinutes = nowParts.hour * 60 + nowParts.minute;
  const schedMinutes = Number(schedule.hour) * 60 + Number(schedule.minute);
  if (nowMinutes < schedMinutes) return false;

  const key = sentKey(schedule, nowParts, Number(schedule.hour), Number(schedule.minute));
  return !store.wasSent(key);
}

function sentKey(schedule, nowParts, hour, minute) {
  return `${schedule.id}_${nowParts.year}${nowParts.month}${nowParts.day}_${hour}${minute}`;
}

function seoulParts(date = new Date()) {
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    weekday: 'short',
  });

  const parts = Object.fromEntries(
    fmt.formatToParts(date)
      .filter((p) => p.type !== 'literal')
      .map((p) => [p.type, p.value])
  );

  const weekdayMap = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };

  return {
    year: Number(parts.year),
    month: Number(parts.month),
    day: Number(parts.day),
    hour: Number(parts.hour === '24' ? '0' : parts.hour),
    minute: Number(parts.minute),
    weekday: weekdayMap[parts.weekday] ?? 0,
  };
}

async function sendOne(schedule, nowParts, hour, minute) {
  const key = sentKey(schedule, nowParts, hour, minute);
  if (store.wasSent(key)) return false;

  const text = formatMessage(schedule);
  await sendTelegramMessage(text);
  store.markSent(key);
  console.log(
    `[scheduler] sent: ${schedule.title} @ ${hour}:${String(minute).padStart(2, '0')} (Seoul)`
  );
  return true;
}

/**
 * @param {{ catchUp?: boolean }} options
 */
async function tick(options = {}) {
  const { catchUp = true } = options;
  const nowParts = seoulParts();
  const schedules = store.getAll();

  for (const schedule of schedules) {
    try {
      if (matchesSchedule(schedule, nowParts)) {
        await sendOne(schedule, nowParts, nowParts.hour, nowParts.minute);
        continue;
      }

      // Free 플랜 sleep 후 깨어났을 때 놓친 슬롯 보정
      if (catchUp && shouldCatchUp(schedule, nowParts)) {
        await sendOne(
          schedule,
          nowParts,
          Number(schedule.hour),
          Number(schedule.minute)
        );
      }
    } catch (err) {
      console.error(`[scheduler] failed: ${schedule.title}`, err.message);
    }
  }
}

/** 등록된 cron 작업 목록 (health 노출용) */
const registeredJobs = [];

function startScheduler() {
  registeredJobs.length = 0;

  // 1) 매분 검사 — 여러 일정(매일/매주/매달/매년) + catch-up
  const everyMinute = cron.schedule(
    '* * * * *',
    () => {
      tick({ catchUp: true }).catch((err) => console.error('[scheduler] tick error', err));
    },
    { timezone: 'Asia/Seoul', scheduled: true }
  );
  registeredJobs.push({
    expression: '* * * * *',
    timezone: 'Asia/Seoul',
    description: '모든 일정 매분 검사 + sleep catch-up',
  });

  // 2) 명시적 월세 슬롯 — 매달 7일 오전 8시 (Asia/Seoul)
  //    cron: 분 시 일 월 요일 → 0 8 7 * *
  const monthlyRent = cron.schedule(
    '0 8 7 * *',
    () => {
      console.log('[scheduler] monthly cron fired: 0 8 7 * * (Asia/Seoul)');
      tick({ catchUp: true }).catch((err) => console.error('[scheduler] monthly tick error', err));
    },
    { timezone: 'Asia/Seoul', scheduled: true }
  );
  registeredJobs.push({
    expression: '0 8 7 * *',
    timezone: 'Asia/Seoul',
    description: '매달 7일 08:00 명시 실행',
  });

  // 시작 직: 이미 놓친 오늘 일정이 있으면 즉시 보정
  tick({ catchUp: true }).catch((err) => console.error('[scheduler] startup catch-up error', err));

  console.log('[scheduler] registered jobs:');
  for (const job of registeredJobs) {
    console.log(`  - ${job.expression} (${job.timezone}) — ${job.description}`);
  }
  console.log('[scheduler] started successfully');

  return { everyMinute, monthlyRent, jobs: registeredJobs };
}

function getSchedulerStatus() {
  return {
    started: registeredJobs.length > 0,
    timezone: 'Asia/Seoul',
    jobs: registeredJobs,
    seoulNow: seoulParts(),
  };
}

/**
 * Render Free sleep 완화용 keep-alive.
 * 프로세스가 깨어 있는 동안 RENDER_EXTERNAL_URL(또는 KEEP_ALIVE_URL)로 self-ping.
 * ※ sleep 중에는 타이머도 멈추므로, 외부 ping(cron-job.org 등)과 함께 쓰는 것이 안전합니다.
 */
function startKeepAlive() {
  const base =
    process.env.KEEP_ALIVE_URL
    || process.env.RENDER_EXTERNAL_URL
    || '';

  if (!base) {
    console.log('[keepalive] skipped (KEEP_ALIVE_URL / RENDER_EXTERNAL_URL 없음)');
    return null;
  }

  const url = `${base.replace(/\/$/, '')}/health`;
  const intervalMs = Number(process.env.KEEP_ALIVE_INTERVAL_MS || 10 * 60 * 1000);

  const ping = async () => {
    try {
      const res = await fetch(url, { method: 'GET' });
      console.log(`[keepalive] ping ${url} → ${res.status}`);
    } catch (err) {
      console.warn('[keepalive] ping failed:', err.message);
    }
  };

  // 첫 ping은 1분 후, 이후 주기적으로
  setTimeout(ping, 60 * 1000);
  const timer = setInterval(ping, intervalMs);
  console.log(`[keepalive] every ${intervalMs / 1000}s → ${url}`);
  return timer;
}

module.exports = {
  startScheduler,
  startKeepAlive,
  getSchedulerStatus,
  tick,
  seoulParts,
  matchesSchedule,
  matchesDateOnly,
  shouldCatchUp,
};
