import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.get(
  '/',
  auth,
  asyncHandler(async (_req, res) => {
    const [[todayBookings]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM bookings
      WHERE booking_date = CURDATE()
      AND status != 'cancelled'
    `);

    const [[todayRevenue]]: any = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) total
      FROM bookings
      WHERE booking_date = CURDATE()
      AND payment_status = 'paid'
      AND status != 'cancelled'
    `);

    const [[pendingPayments]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM bookings
      WHERE payment_status = 'pending'
      AND status != 'cancelled'
    `);

    const [[checkedIn]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM bookings
      WHERE booking_date = CURDATE()
      AND status = 'checked_in'
    `);

    const [[totalCustomers]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM customers
    `);

    res.json({
      today_bookings: todayBookings.total,
      today_revenue: todayRevenue.total,
      pending_payments: pendingPayments.total,
      checked_in: checkedIn.total,
      total_customers: totalCustomers.total,
    });
  })
);

export default router;