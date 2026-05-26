import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.get(
  '/',
  auth,
  asyncHandler(async (req, res) => {
    const [rows] = await pool.query(`
      SELECT *
      FROM products
      ORDER BY id DESC
    `);

    res.json(rows);
  })
);

router.post(
  '/',
  auth,
  asyncHandler(async (req, res) => {
    const {
      name,
      price,
      stock,
    } = req.body;

    const [result]: any = await pool.query(
      `
      INSERT INTO products
      (
        name,
        price,
        stock
      )
      VALUES (?,?,?)
      `,
      [
        name,
        price,
        stock,
      ]
    );

    res.status(201).json({
      id: result.insertId,
    });
  })
);

export default router;