# life-alarm-telegram-server

Render.com 용 Node.js + Express + node-cron + Axios 스케줄러.

## 로컬 실행

```bash
cp .env.example .env
# TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID 입력
npm install
npm start
```

- Health: http://localhost:3000/health  
- Timezone: `Asia/Seoul`  
- 매분 cron 검사 후 일치 일정 Telegram 전송  

## 기본 시드

서버 최초 기동 시 `data/schedules.json` 이 없으면:

- 제목: 월세  
- 내용: 김현석 월세 내는 날입니다.  
- 매달 7일 08:00  

## API

문서 루트 `README.md` 참고.
