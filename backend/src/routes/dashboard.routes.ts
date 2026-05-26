import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.get(
  '/',
  auth,
  asyncHandler(async (req, res) => {
    const [[todayBookings]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM bookings
      WHERE DATE(booking_date) = (
        SELECT MAX(DATE(booking_date)) FROM bookings
      )
      AND status != 'cancelled'
    `);

    const [[todayRevenue]]: any = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) total
      FROM bookings
      WHERE DATE(booking_date) = (
        SELECT MAX(DATE(booking_date)) FROM bookings
      )
      AND paid = 1
      AND status != 'cancelled'
    `);

    const [[unpaidBookings]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM bookings
      WHERE paid = 0
      AND status != 'cancelled'
    `);

    const [[checkedIn]]: any = await pool.query(`
      SELECT COUNT(*) total
      FROM bookings
      WHERE DATE(booking_date) = (
        SELECT MAX(DATE(booking_date)) FROM bookings
      )
      AND status = 'checked_in'
    `);

    res.json({
      today_bookings: todayBookings.total,
      today_revenue: todayRevenue.total,
      unpaid_bookings: unpaidBookings.total,
      checked_in: checkedIn.total,
    });
  })
);

export default router;