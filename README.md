# 생활 알림 + Telegram Bot

iOS 로컬 알림 + **Telegram 자동 전송** + **Render.com Node.js 스케줄러**

## 왜 서버가 필요한가?

| 상황 | 동작 |
|------|------|
| 앱이 **실행 중** | iOS `TelegramForegroundScheduler`가 정각에 Telegram 전송 |
| 앱이 **종료됨** | iOS 백그라운드 제약으로 네트워크 자동 전송 불가 → **Render 서버**가 전송 |

기본 시드 일정: **매달 7일 오전 8시 (Asia/Seoul)**  
메시지:

```
🔔 월세 알림
김현석 월세 내는 날입니다.
```

---

## 프로젝트 구조

```
wolse-alarm/
├── LifeAlarm/                 # iOS 앱
│   ├── Config/
│   │   ├── AppConfig.swift    # Token/ChatID/URL 로드 (하드코딩 없음)
│   │   ├── Secrets.plist      # 실제 값 입력 (비공개)
│   │   └── Secrets.example.plist
│   ├── Managers/
│   │   ├── TelegramManager.swift
│   │   ├── TelegramForegroundScheduler.swift
│   │   └── ScheduleAPIClient.swift
│   └── ...
├── LifeAlarmWidget/
├── LifeAlarm.xcodeproj
└── server/                    # Render Node.js
    ├── package.json
    ├── render.yaml
    ├── .env.example
    └── src/
        ├── index.js
        ├── routes.js
        ├── store.js
        ├── telegram.js
        └── scheduler.js
```

---

## 1) Telegram BotFather에서 봇 생성

1. 텔레그램 앱에서 **@BotFather** 검색 → 대화 시작  
2. `/newbot` 입력  
3. 봇 이름 입력 (예: `생활알림`)  
4. username 입력 (예: `my_life_alarm_bot` — 끝은 반드시 `bot`)  
5. BotFather가 **HTTP API Token** 을 줍니다.  
   예: `7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxx`  
6. 이 값을 안전한 곳에 보관하세요. **절대 Git에 올리지 마세요.**

---

## 2) Bot Token 발급

위 1단계에서 받은 토큰이 곧 Bot Token입니다.

- iOS: `LifeAlarm/Config/Secrets.plist` → `TELEGRAM_BOT_TOKEN`
- Render: Environment → `TELEGRAM_BOT_TOKEN`
- 로컬 서버: `server/.env` → `TELEGRAM_BOT_TOKEN`

---

## 3) Chat ID 확인

본인 계정으로 봇에게 먼저 말해야 합니다.

1. 방금 만든 봇을 검색해 **Start** / 아무 메시지 전송  
2. 브라우저에서 아래 URL 접속 (TOKEN을 실제 값으로 교체):

```
https://api.telegram.org/bot<TOKEN>/getUpdates
```

3. JSON에서 `"chat":{"id": 123456789}` 형태의 숫자를 찾습니다.  
   그 숫자가 **Chat ID** 입니다.  
4. 결과가 비어 있으면 봇에게 메시지를 한 번 더 보낸 뒤 새로고침하세요.

대안: `@userinfobot` 등 Chat ID 확인 봇 사용.

---

## 4) iOS Secrets 설정

1. `LifeAlarm/Config/Secrets.example.plist` 내용을 참고  
2. `LifeAlarm/Config/Secrets.plist` 에 실제 값 입력:

```xml
<key>TELEGRAM_BOT_TOKEN</key>
<string>여기에_봇_토큰</string>
<key>TELEGRAM_CHAT_ID</key>
<string>여기에_채팅_ID</string>
<key>SERVER_BASE_URL</key>
<string>https://your-service.onrender.com</string>
```

3. Xcode에서 앱 실행  
4. **Telegram** 탭 → Chat ID / 서버 URL 저장(선택) → **Telegram 테스트 메시지 보내기**

Token은 코드에 하드코딩하지 않습니다. `AppConfig`가 plist · UserDefaults · 환경변수 순으로 읽습니다.

---

## 5) Render 환경변수 등록

1. [https://render.com](https://render.com) 가입  
2. Dashboard → **Environment** (또는 서비스 생성 후 Environment)  
3. 다음 변수 추가:

| Key | Value |
|-----|--------|
| `TELEGRAM_BOT_TOKEN` | BotFather 토큰 |
| `TELEGRAM_CHAT_ID` | 본인 Chat ID |
| `TZ` | `Asia/Seoul` |

---

## 6) Render 배포

### 방법 A — GitHub 연결 (권장)

1. 이 프로젝트를 GitHub 저장소에 push  
   (`Secrets.plist`에 실토큰을 넣었다면 **commit 하지 마세요**. 빈 값만 커밋)  
2. Render → **New → Web Service**  
3. 저장소 연결  
4. 설정:

| 항목 | 값 |
|------|-----|
| Root Directory | `server` |
| Runtime | Node |
| Build Command | `npm install` |
| Start Command | `npm start` |
| Instance | Free |

5. Environment Variables에 Token / Chat ID / `TZ=Asia/Seoul` 등록  
6. **Create Web Service** → 배포 완료 후 URL 확인  
   예: `https://life-alarm-xxxx.onrender.com`

`server/render.yaml` 이 있으면 Blueprint로도 배포 가능합니다.

### 방법 B — 로컬 테스트 후 배포

```bash
cd server
cp .env.example .env
# .env 에 TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID 입력
npm install
npm start
```

브라우저: `http://localhost:3000/health`

---

## 7) 테스트 방법

### 서버

```bash
# Health
curl https://YOUR.onrender.com/health

# Telegram 테스트
curl -X POST https://YOUR.onrender.com/telegram/test

# 일정 목록
curl https://YOUR.onrender.com/schedule

# 일정 추가
curl -X POST https://YOUR.onrender.com/schedule \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"월세\",\"body\":\"김현석 월세 내는 날입니다.\",\"repeatKind\":\"monthly\",\"dayOfMonth\":7,\"hour\":8,\"minute\":0,\"isEnabled\":true}"
```

### iOS 앱

1. Telegram 탭 → 테스트 메시지  
2. 홈 → **Telegram 테스트**  
3. Telegram 탭 → **일정을 서버에 동기화**  
4. `GET /schedule` 로 앱 일정이 서버에 있는지 확인

### 정각 전송 (앱 실행 중)

1. 테스트용으로 **매일 / 현재 시각 + 1분** 일정 추가  
2. 앱을 켠 채로 대기  
3. 해당 분에 Telegram 수신 확인

---

## 8) 실제 자동 발송 확인 방법

1. Render 로그: Dashboard → 서비스 → **Logs**  
   `[scheduler] sent: 월세 @ 8:00` 확인  
2. 매달 7일 08:00 (한국시간) 전에:
   - 서버에 월세 일정이 `isEnabled: true`, `dayOfMonth: 7`, `hour: 8` 인지 확인  
   - 앱을 꺼 두어도 서버가 보내야 정상  
3. Free 플랜은 **약 15분 idle 후 슬립**할 수 있습니다.  
   - 슬립 중이면 첫 요청이 깨웁니다.  
   - 안정성이 필요하면 Render paid 또는 cron-job.org 에서 `GET /health` 5분마다 ping  
4. 중복 방지: 같은 일정·같은 분에는 한 번만 전송 (`data/sent-log.json`)

> Render Free 디스크는 ephemeral 입니다. 재배포 시 JSON이 초기화될 수 있으니,  
> 앱에서 **동기화**를 다시 하거나 Persistent Disk를 사용하세요.

---

## REST API

| Method | Path | 설명 |
|--------|------|------|
| GET | `/health` | 상태 + 서울 시각 |
| GET | `/schedule` | 전체 일정 |
| POST | `/schedule` | 일정 추가 |
| PUT | `/schedule/:id` | 일정 수정 |
| DELETE | `/schedule/:id` | 일정 삭제 |
| POST | `/sync` | `{ "schedules": [...] }` 전체 교체 |
| POST | `/telegram/test` | 테스트 메시지 |
| POST | `/telegram/send-schedule/:id` | 특정 일정 즉시 전송 |

일정 JSON 예시:

```json
{
  "id": "uuid",
  "title": "월세",
  "body": "김현석 월세 내는 날입니다.",
  "repeatKind": "monthly",
  "weekdays": [],
  "dayOfMonth": 7,
  "monthOfYear": 1,
  "dayOfYear": 1,
  "hour": 8,
  "minute": 0,
  "isEnabled": true
}
```

`repeatKind`: `daily` | `weekly` | `monthly` | `yearly`

---

## iOS 실행 요약

1. Mac에서 `LifeAlarm.xcodeproj` 열기  
2. Signing Team 설정 + App Groups  
3. `Secrets.plist` 작성  
4. 실행 → 알림 허용  
5. Telegram 탭에서 테스트 · 서버 URL · 동기화  

상세 iOS 설치는 기존 앱 설정을 따릅니다.

---

## 보안 체크리스트

- [ ] Bot Token을 Swift 소스에 직접 쓰지 않았다  
- [ ] `Secrets.plist` / `.env` 를 public repo에 올리지 않았다  
- [ ] Render Environment Variables로만 서버 비밀값을 넣었다  
- [ ] Chat ID가 본인 계정인지 확인했다  
