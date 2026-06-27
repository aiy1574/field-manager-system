import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { signToken } from '../utils/jwt.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

function isBcryptHash(value: string) {
  return (
    value.startsWith('$2a$') ||
    value.startsWith('$2b$') ||
    value.startsWith('$2y$')
  );
}

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { full_name, email, password, phone, position, role } = req.body;

    if (!full_name || !email || !password) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນຊື່, ອີເມວ ແລະ ລະຫັດຜ່ານ',
      });
    }

    const [existingRows]: any = await pool.query(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email],
    );

    if (existingRows.length > 0) {
      return res.status(409).json({
        message: 'ອີເມວນີ້ມີຜູ້ໃຊ້ແລ້ວ',
      });
    }

    const [[countRow]]: any = await pool.query(
      'SELECT COUNT(*) AS count FROM users',
    );

    const userRole =
      countRow.count === 0
        ? 'owner'
        : role || 'staff';

    const allowRoles = ['owner', 'admin', 'staff', 'sales', 'checkin'];

    if (!allowRoles.includes(userRole)) {
      return res.status(400).json({
        message: 'Role ບໍ່ຖືກຕ້ອງ',
      });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const [result]: any = await pool.query(
      `
      INSERT INTO users (
        full_name,
        email,
        password_hash,
        phone,
        position,
        role
      )
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        full_name,
        email,
        password_hash,
        phone || null,
        position || null,
        userRole,
      ],
    );

    res.status(201).json({
      id: result.insertId,
      role: userRole,
      message: 'ສ້າງຜູ້ໃຊ້ສຳເລັດ',
    });
  }),
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນອີເມວ ແລະ ລະຫັດຜ່ານ',
      });
    }

    const [rows]: any = await pool.query(
      `
      SELECT
        id,
        full_name,
        email,
        password_hash,
        phone,
        position,
        role,
        is_active
      FROM users
      WHERE email = ?
      LIMIT 1
      `,
      [email],
    );

    const user = rows[0];

    if (!user) {
      return res.status(401).json({
        message: 'Email or password incorrect',
      });
    }

    if (user.is_active !== undefined && Number(user.is_active) === 0) {
      return res.status(403).json({
        message: 'ບັນຊີນີ້ຖືກປິດການໃຊ້ງານ',
      });
    }

    const storedPassword = user.password_hash?.toString() || '';

    let passwordOk = false;

    if (isBcryptHash(storedPassword)) {
      passwordOk = await bcrypt.compare(password, storedPassword);
    } else {
      passwordOk = password === storedPassword;
    }

    if (!passwordOk) {
      return res.status(401).json({
        message: 'Email or password incorrect',
      });
    }

    const token = signToken({
      id: user.id,
      email: user.email,
      role: user.role,
    });

    res.json({
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        phone: user.phone,
        position: user.position,
        role: user.role,
      },
    });
  }),
);

export default router;