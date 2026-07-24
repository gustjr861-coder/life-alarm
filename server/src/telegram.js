const axios = require('axios');

/**
 * Telegram Bot API sendMessage
 * https://api.telegram.org/bot<TOKEN>/sendMessage
 *
 * Token / Chat ID 는 환경변수에서만 읽는다. 하드코딩 금지.
 */
async function sendTelegramMessage(text) {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;

  if (!token || !chatId) {
    throw new Error('TELEGRAM_BOT_TOKEN 또는 TELEGRAM_CHAT_ID 환경변수가 없습니다.');
  }

  const url = `https://api.telegram.org/bot${token}/sendMessage`;
  const response = await axios.post(
    url,
    {
      chat_id: chatId,
      text,
      disable_web_page_preview: true,
    },
    { timeout: 15000 }
  );

  return response.data;
}

function formatMessage(schedule) {
  return `🔔 ${schedule.title} 알림\n${schedule.body}`;
}

module.exports = {
  sendTelegramMessage,
  formatMessage,
};
