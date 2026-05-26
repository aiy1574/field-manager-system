import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth, allowRoles } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';
const router = Router();
const tables = new Set(['customers','fields','pricing_rules','products','expenses','notifications']);

router.get('/:table', auth, asyncHandler(async (req, res) => {
  const table = req.params.table;
  if (!tables.has(table)) return res.status(404).json({ message: 'Table not allowed' });
  const [rows] = await pool.query(`SELECT * FROM ${table} ORDER BY id DESC`);
  res.json(rows);
}));
router.post('/:table', auth, asyncHandler(async (req, res) => {
  const table = req.params.table;
  if (!tables.has(table)) return res.status(404).json({ message: 'Table not allowed' });
  const [result]: any = await pool.query(`INSERT INTO ${table} SET ?`, [req.body]);
  res.status(201).json({ id: result.insertId, ...req.body });
}));
router.put('/:table/:id', auth, asyncHandler(async (req, res) => {
  const table = req.params.table;
  if (!tables.has(table)) return res.status(404).json({ message: 'Table not allowed' });
  await pool.query(`UPDATE ${table} SET ? WHERE id=?`, [req.body, req.params.id]);
  res.json({ id: req.params.id, ...req.body });
}));
router.delete('/:table/:id', auth, allowRoles('admin'), asyncHandler(async (req, res) => {
  const table = req.params.table;
  if (!tables.has(table)) return res.status(404).json({ message: 'Table not allowed' });
  await pool.query(`DELETE FROM ${table} WHERE id=?`, [req.params.id]);
  res.json({ message: 'deleted' });
}));
export default router;
