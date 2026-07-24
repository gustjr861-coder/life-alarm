const cron = require('node-cron');
const store = require('./store');
const { sendTelegramMessage, formatMessage } = require('./telegram');

/**
 * Asia/Seoul 기준으로 매분 검사.
 * 해당 분의 일정과 일치하면 Telegram 전송 (중복 방지 로그 사용).
 */
function matchesSchedule(schedule, nowParts) {
  if (!schedule.isEnabled) return false;

  const { year, month, day, hour, minute, weekday } = nowParts;
  if (Number(schedule.hour) !== hour || Number(schedule.minute) !== minute) {
    return false;
  }

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

function seoulParts(date = new Date()) {
  // Asia/Seoul 벽시계 값 추출
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

async function tick() {
  const nowParts = seoulParts();
  const schedules = store.getAll();

  for (const schedule of schedules) {
    if (!matchesSchedule(schedule, nowParts)) continue;

    const key = `${schedule.id}_${nowParts.year}${nowParts.month}${nowParts.day}_${nowParts.hour}${nowParts.minute}`;
    if (store.wasSent(key)) continue;

    try {
      const text = formatMessage(schedule);
      await sendTelegramMessage(text);
      store.markSent(key);
      console.log(`[scheduler] sent: ${schedule.title} @ ${nowParts.hour}:${String(nowParts.minute).padStart(2, '0')}`);
    } catch (err) {
      console.error(`[scheduler] failed: ${schedule.title}`, err.message);
    }
  }
}

function startScheduler() {
  // 매분 0초 (Asia/Seoul)
  cron.schedule('* * * * *', () => {
    tick().catch((err) => console.error('[scheduler] tick error', err));
  }, {
    timezone: 'Asia/Seoul',
  });

  console.log('[scheduler] started (timezone=Asia/Seoul, every minute)');
}

module.exports = {
  startScheduler,
  tick,
  seoulParts,
  matchesSchedule,
};
