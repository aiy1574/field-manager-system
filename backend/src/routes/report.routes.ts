import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.get(
  '/',
  auth,
  asyncHandler(async (_req, res) => {
    const [[summary]]: any = await pool.query(`
      SELECT
        COALESCE(SUM(CASE WHEN payment_status='paid' THEN total_price ELSE 0 END), 0) AS total_revenue,
        COALESCE(SUM(CASE WHEN payment_status='paid' AND booking_date = CURDATE() THEN total_price ELSE 0 END), 0) AS today_revenue,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN payment_status='paid' THEN 1 ELSE 0 END) AS paid_bookings,
        SUM(CASE WHEN payment_status='pending' THEN 1 ELSE 0 END) AS pending_payments
      FROM bookings
      WHERE status != 'cancelled'
    `);

    const [revenueList]: any = await pool.query(`
      SELECT
        b.id,
        b.booking_date,
        b.start_time,
        b.end_time,
        b.total_price,
        b.payment_status,
        b.status,
        f.name AS field_name,
        c.full_name AS customer_name
      FROM bookings b
      JOIN fields f ON f.id = b.field_id
      JOIN customers c ON c.id = b.customer_id
      WHERE b.status != 'cancelled'
      ORDER BY b.booking_date DESC, b.start_time DESC
      LIMIT 50
    `);

    res.json({
      summary,
      revenue_list: revenueList,
    });
  }),
);

export default router;