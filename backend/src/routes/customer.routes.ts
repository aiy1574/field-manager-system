import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { signToken } from '../utils/jwt.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { full_name, phone, email, password } = req.body;

    const password_hash = await bcrypt.hash(password, 10);

    const [result]: any = await pool.query(
      `
      INSERT INTO customers
      (
        full_name,
        phone,
        email,
        password_hash
      )
      VALUES (?,?,?,?)
      `,
      [full_name, phone, email, password_hash]
    );

    res.status(201).json({
      message: 'Customer register success',
      id: result.insertId,
    });
  })
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { phone, password } = req.body;

    const [rows]: any = await pool.query(
      `
      SELECT *
      FROM customers
      WHERE phone=?
      LIMIT 1
      `,
      [phone]
    );

    const customer = rows[0];

    if (!customer) {
      return res.status(401).json({
        message: 'Phone or password incorrect',
      });
    }

    const isMatch = await bcrypt.compare(password, customer.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        message: 'Phone or password incorrect',
      });
    }

    const token = signToken({
      id: customer.id,
      phone: customer.phone,
      role: 'customer',
    });

    res.json({
      token,
      customer: {
        id: customer.id,
        full_name: customer.full_name,
        phone: customer.phone,
        email: customer.email,
      },
    });
  })
);

router.put(
  '/profile',
  asyncHandler(async (req, res) => {
    const { id, full_name, phone, email } = req.body;

    if (!id || !full_name || !phone) {
      return res.status(400).json({
        message: 'Missing required fields',
      });
    }

    await pool.query(
      `
      UPDATE customers
      SET
        full_name=?,
        phone=?,
        email=?
      WHERE id=?
      `,
      [full_name, phone, email || null, id]
    );

    const [rows]: any = await pool.query(
      `
      SELECT id, full_name, phone, email
      FROM customers
      WHERE id=?
      LIMIT 1
      `,
      [id]
    );

    res.json({
      message: 'Profile updated',
      customer: rows[0],
    });
  })
);

router.patch(
  '/change-password',
  asyncHandler(async (req, res) => {
    const { id, old_password, new_password } = req.body;

    if (!id || !old_password || !new_password) {
      return res.status(400).json({
        message: 'Missing required fields',
      });
    }

    const [rows]: any = await pool.query(
      `
      SELECT *
      FROM customers
      WHERE id=?
      LIMIT 1
      `,
      [id]
    );

    const customer = rows[0];

    if (!customer) {
      return res.status(404).json({
        message: 'Customer not found',
      });
    }

    const isMatch = await bcrypt.compare(
      old_password,
      customer.password_hash
    );

    if (!isMatch) {
      return res.status(400).json({
        message: 'Old password incorrect',
      });
    }

    const password_hash = await bcrypt.hash(new_password, 10);

    await pool.query(
      `
      UPDATE customers
      SET password_hash=?
      WHERE id=?
      `,
      [password_hash, id]
    );

    res.json({
      message: 'Password changed',
    });
  })
);

export default router;