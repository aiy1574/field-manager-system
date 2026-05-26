# Field Manager Backend

Backend แยกสำหรับระบบจองสนาม / POS / รายงาน ใช้ Node.js + Express + TypeScript + MySQL

## วิธีติดตั้ง
1. แตก zip หรือ clone โฟลเดอร์นี้
2. เปิด Laragon แล้ว start Apache + MySQL
3. เปิด phpMyAdmin แล้ว import `database/schema.sql`
4. คัดลอก `.env.example` เป็น `.env`
5. รันคำสั่ง:

```bash
npm install
npm run dev
```

API จะรันที่ `http://localhost:4000`

## Endpoint หลัก
- POST `/api/auth/register`
- POST `/api/auth/login`
- GET/POST/PUT/DELETE `/api/customers`
- GET/POST/PUT/DELETE `/api/fields`
- GET/POST `/api/bookings`
- PATCH `/api/bookings/:id/pay`
- PATCH `/api/bookings/:id/checkin`
- GET/POST `/api/sales`
- GET `/api/reports/dashboard`
