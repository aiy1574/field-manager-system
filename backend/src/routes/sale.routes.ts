import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';
const router = Router();

router.post('/', auth, asyncHandler(async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const { items, payment_method = 'cash', customer_id = null } = req.body;
    const total = items.reduce((s: number, i: any) => s + Number(i.unit_price) * Number(i.qty), 0);
    const [saleResult]: any = await conn.query('INSERT INTO sales(total,payment_method,customer_id,sold_by) VALUES (?,?,?,?)', [total, payment_method, customer_id, req.user!.id]);
    for (const item of items) {
      await conn.query('INSERT INTO sale_items(sale_id,product_id,product_name,unit_price,qty,subtotal) VALUES (?,?,?,?,?,?)', [saleResult.insertId, item.product_id, item.product_name, item.unit_price, item.qty, item.unit_price * item.qty]);
      await conn.query('UPDATE products SET stock=stock-? WHERE id=?', [item.qty, item.product_id]);
    }
    await conn.commit();
    res.status(201).json({ id: saleResult.insertId, total });
  } catch (e) { await conn.rollback(); throw e; }
  finally { conn.release(); }
}));
router.get('/', auth, asyncHandler(async (_req, res) => {
  const [rows] = await pool.query('SELECT * FROM sales ORDER BY created_at DESC');
  res.json(rows);
}));
export default router;
