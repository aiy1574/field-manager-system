import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { signToken } from '../utils/jwt.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.post('/register', asyncHandler(async (req, res) => {
  const { full_name, email, password, phone, position } = req.body;

  const [[countRow]]: any = await pool.query(
    'SELECT COUNT(*) count FROM users'
  );

  const role = countRow.count === 0 ? 'admin' : 'staff';

  const password_hash = await bcrypt.hash(password, 10);

  const [result]: any = await pool.query(
    'INSERT INTO users(full_name,email,password_hash,phone,position,role) VALUES (?,?,?,?,?,?)',
    [
      full_name,
      email,
      password_hash,
      phone || null,
      position || null,
      role
    ]
  );

  res.status(201).json({
    id: result.insertId,
    role
  });
}));

router.post('/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const [rows]: any = await pool.query(
    'SELECT * FROM users WHERE email=? LIMIT 1',
    [email]
  );

  const user = rows[0];

  // เทียบ password ตรง ๆ
  if (!user || password !== user.password_hash) {
    return res.status(401).json({
      message: 'Email or password incorrect'
    });
  }

  const token = signToken({
    id: user.id,
    email: user.email,
    role: user.role
  });

  res.json({
    token,
    user: {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      role: user.role
    }
  });
}));

export default router;