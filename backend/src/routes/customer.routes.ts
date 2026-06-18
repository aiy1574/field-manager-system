import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { signToken } from '../utils/jwt.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const {
      full_name,
      phone,
      email,
      password,
    } = req.body;

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
      [
        full_name,
        phone,
        email,
        password_hash,
      ]
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
    const {
      phone,
      password,
    } = req.body;

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

    const isMatch = await bcrypt.compare(
      password,
      customer.password_hash
    );

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

export default router;