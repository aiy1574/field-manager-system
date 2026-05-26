import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';
const router = Router();
router.get('/dashboard', auth, asyncHandler(async (_req, res) => {
  const [[booking]]: any = await pool.query('SELECT COUNT(*) bookings_today, COALESCE(SUM(total_price),0) booking_income FROM bookings WHERE booking_date=CURDATE() AND paid=1');
  const [[sale]]: any = await pool.query('SELECT COALESCE(SUM(total),0) sale_income FROM sales WHERE DATE(created_at)=CURDATE()');
  const [[customer]]: any = await pool.query('SELECT COUNT(*) total_customers FROM customers');
  const [lowStock]: any = await pool.query('SELECT * FROM products WHERE stock <= 10 ORDER BY stock ASC');
  res.json({ ...booking, ...sale, ...customer, low_stock: lowStock });
}));
export default router;
