import { Router } from 'express';
import { pool } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.get(
  '/',
  asyncHandler(async (req, res) => {
    const { field_id } = req.query;

    let sql = `
      SELECT *
      FROM field_services
      WHERE 1=1
    `;

    const params: any[] = [];

    if (field_id) {
      sql += ' AND field_id=?';
      params.push(field_id);
    }

    sql += ' ORDER BY hour_start ASC';

    const [rows]: any = await pool.query(sql, params);

    res.json(rows);
  }),
);

export default router;