import { Router } from 'express';
import { pool } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.get(
  '/',
  asyncHandler(async (req, res) => {
    const [rows]: any = await pool.query(
      `
      SELECT *
      FROM fields
      ORDER BY id DESC
      `
    );

    res.json(rows);
  })
);

export default router;