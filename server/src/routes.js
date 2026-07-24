const express = require('express');
const store = require('./store');
const { sendTelegramMessage, formatMessage } = require('./telegram');

const router = express.Router();

function validateScheduleBody(body, { partial = false } = {}) {
  if (!partial) {
    if (!body || !body.title || !body.body) {
      return 'title, body 는 필수입니다.';
    }
  }
  if (body.repeatKind && !['daily', 'weekly', 'monthly', 'yearly'].includes(body.repeatKind)) {
    return 'repeatKind 는 daily|weekly|monthly|yearly 여야 합니다.';
  }
  return null;
}

/** GET /schedule — 전체 일정 */
router.get('/schedule', (_req, res) => {
  res.json(store.getAll());
});

/** POST /schedule — 일정 추가 */
router.post('/schedule', (req, res) => {
  const error = validateScheduleBody(req.body);
  if (error) return res.status(400).json({ error });

  const created = store.create(req.body);
  res.status(201).json(created);
});

/** PUT /schedule/:id — 일정 수정 */
router.put('/schedule/:id', (req, res) => {
  const error = validateScheduleBody(req.body, { partial: true });
  if (error) return res.status(400).json({ error });

  const updated = store.update(req.params.id, req.body);
  if (!updated) return res.status(404).json({ error: '일정을 찾을 수 없습니다.' });
  res.json(updated);
});

/** DELETE /schedule/:id — 일정 삭제 */
router.delete('/schedule/:id', (req, res) => {
  const ok = store.remove(req.params.id);
  if (!ok) return res.status(404).json({ error: '일정을 찾을 수 없습니다.' });
  res.json({ ok: true });
});

/** POST /sync — 앱에서 전체 일정 교체 동기화 */
router.post('/sync', (req, res) => {
  const schedules = req.body?.schedules;
  if (!Array.isArray(schedules)) {
    return res.status(400).json({ error: 'schedules 배열이 필요합니다.' });
  }
  const saved = store.replaceAll(schedules);
  res.json({ ok: true, count: saved.length, schedules: saved });
});

/** GET /telegram/test — 브라우저에서 바로 확인용 */
router.get('/telegram/test', async (_req, res) => {
  try {
    await sendTelegramMessage('✅ Render 테스트 성공');
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/** POST /telegram/test — 즉시 테스트 전송 (앱/curl용) */
router.post('/telegram/test', async (req, res) => {
  try {
    const text =
      req.body?.text ||
      '✅ Render 테스트 성공';
    await sendTelegramMessage(text);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/** POST /telegram/send-schedule/:id — 특정 일정 즉시 전송 */
router.post('/telegram/send-schedule/:id', async (req, res) => {
  try {
    const schedule = store.getById(req.params.id);
    if (!schedule) return res.status(404).json({ error: '일정을 찾을 수 없습니다.' });
    const result = await sendTelegramMessage(formatMessage(schedule));
    res.json({ ok: true, result });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
