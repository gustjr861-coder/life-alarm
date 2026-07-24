const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const DATA_DIR = path.join(__dirname, '..', 'data');
const DATA_FILE = path.join(DATA_DIR, 'schedules.json');
const SENT_FILE = path.join(DATA_DIR, 'sent-log.json');

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  if (!fs.existsSync(DATA_FILE)) {
    const seed = [
      {
        id: uuidv4(),
        title: '월세',
        body: '김현석 월세 내는 날입니다.',
        repeatKind: 'monthly',
        weekdays: [],
        dayOfMonth: 7,
        monthOfYear: 1,
        dayOfYear: 1,
        hour: 8,
        minute: 0,
        isEnabled: true,
      },
    ];
    fs.writeFileSync(DATA_FILE, JSON.stringify(seed, null, 2), 'utf8');
  }
  if (!fs.existsSync(SENT_FILE)) {
    fs.writeFileSync(SENT_FILE, JSON.stringify({}, null, 2), 'utf8');
  }
}

function readSchedules() {
  ensureStore();
  const raw = fs.readFileSync(DATA_FILE, 'utf8');
  return JSON.parse(raw);
}

function writeSchedules(schedules) {
  ensureStore();
  fs.writeFileSync(DATA_FILE, JSON.stringify(schedules, null, 2), 'utf8');
}

function readSentLog() {
  ensureStore();
  const raw = fs.readFileSync(SENT_FILE, 'utf8');
  return JSON.parse(raw);
}

function writeSentLog(log) {
  ensureStore();
  fs.writeFileSync(SENT_FILE, JSON.stringify(log, null, 2), 'utf8');
}

function getAll() {
  return readSchedules();
}

function getById(id) {
  return readSchedules().find((s) => s.id === id) || null;
}

function create(schedule) {
  const schedules = readSchedules();
  const item = {
    id: schedule.id || uuidv4(),
    title: schedule.title,
    body: schedule.body,
    repeatKind: schedule.repeatKind || 'monthly',
    weekdays: Array.isArray(schedule.weekdays) ? schedule.weekdays : [],
    dayOfMonth: Number(schedule.dayOfMonth ?? 7),
    monthOfYear: Number(schedule.monthOfYear ?? 1),
    dayOfYear: Number(schedule.dayOfYear ?? 1),
    hour: Number(schedule.hour ?? 8),
    minute: Number(schedule.minute ?? 0),
    isEnabled: schedule.isEnabled !== false,
  };
  schedules.push(item);
  writeSchedules(schedules);
  return item;
}

function update(id, patch) {
  const schedules = readSchedules();
  const index = schedules.findIndex((s) => s.id === id);
  if (index < 0) return null;
  schedules[index] = {
    ...schedules[index],
    ...patch,
    id,
  };
  writeSchedules(schedules);
  return schedules[index];
}

function remove(id) {
  const schedules = readSchedules();
  const next = schedules.filter((s) => s.id !== id);
  if (next.length === schedules.length) return false;
  writeSchedules(next);
  return true;
}

function replaceAll(schedules) {
  const normalized = (schedules || []).map((schedule) => ({
    id: schedule.id || uuidv4(),
    title: schedule.title,
    body: schedule.body,
    repeatKind: schedule.repeatKind || 'monthly',
    weekdays: Array.isArray(schedule.weekdays) ? schedule.weekdays : [],
    dayOfMonth: Number(schedule.dayOfMonth ?? 7),
    monthOfYear: Number(schedule.monthOfYear ?? 1),
    dayOfYear: Number(schedule.dayOfYear ?? 1),
    hour: Number(schedule.hour ?? 8),
    minute: Number(schedule.minute ?? 0),
    isEnabled: schedule.isEnabled !== false,
  }));
  writeSchedules(normalized);
  return normalized;
}

function markSent(key) {
  const log = readSentLog();
  log[key] = new Date().toISOString();
  writeSentLog(log);
}

function wasSent(key) {
  const log = readSentLog();
  return Boolean(log[key]);
}

module.exports = {
  ensureStore,
  getAll,
  getById,
  create,
  update,
  remove,
  replaceAll,
  markSent,
  wasSent,
};
