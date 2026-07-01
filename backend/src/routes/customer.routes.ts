import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { signToken } from '../utils/jwt.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { auth } from '../middleware/auth.js';

const router = Router();

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { full_name, phone, email, password } = req.body;

    if (!full_name || !phone || !password) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນຊື່, ເບີໂທ ແລະ ລະຫັດຜ່ານ',
      });
    }

    const [existingRows]: any = await pool.query(
      'SELECT id FROM customers WHERE phone = ? LIMIT 1',
      [phone]
    );

    if (existingRows.length > 0) {
      return res.status(409).json({
        message: 'ເບີໂທນີ້ມີຜູ້ໃຊ້ແລ້ວ',
      });
    }

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
      [full_name, phone, email || null, password_hash]
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

    if (!phone || !password) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນເບີໂທ ແລະ password',
      });
    }

    const [rows]: any = await pool.query(
      `
      SELECT *
      FROM customers
      WHERE phone = ?
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

router.get(
  '/',
  auth,
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query(
      `
      SELECT
        id,
        full_name,
        phone,
        email,
        note,
        created_at
      FROM customers
      ORDER BY id DESC
      `
    );

    res.json(rows);
  })
);

router.post(
  '/',
  auth,
  asyncHandler(async (req, res) => {
    const { full_name, phone, email, password, note } = req.body;

    if (!full_name || !phone) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນຊື່ ແລະ ເບີໂທ',
      });
    }

    const [existingRows]: any = await pool.query(
      'SELECT id FROM customers WHERE phone = ? LIMIT 1',
      [phone]
    );

    if (existingRows.length > 0) {
      return res.status(409).json({
        message: 'ເບີໂທນີ້ມີລູກຄ້າໃຊ້ແລ້ວ',
      });
    }

    const password_hash = password
      ? await bcrypt.hash(password, 10)
      : await bcrypt.hash('123456', 10);

    const [result]: any = await pool.query(
      `
      INSERT INTO customers
      (
        full_name,
        phone,
        email,
        password_hash,
        note
      )
      VALUES (?,?,?,?,?)
      `,
      [
        full_name,
        phone,
        email || null,
        password_hash,
        note || null,
      ]
    );

    res.status(201).json({
      id: result.insertId,
      message: 'ເພີ່ມລູກຄ້າສຳເລັດ',
    });
  })
);

router.put(
  '/:id',
  auth,
  asyncHandler(async (req, res) => {
    const { full_name, phone, email, note } = req.body;

    if (!full_name || !phone) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນຊື່ ແລະ ເບີໂທ',
      });
    }

    const [existingRows]: any = await pool.query(
      'SELECT id FROM customers WHERE phone = ? AND id != ? LIMIT 1',
      [phone, req.params.id]
    );

    if (existingRows.length > 0) {
      return res.status(409).json({
        message: 'ເບີໂທນີ້ມີລູກຄ້າໃຊ້ແລ້ວ',
      });
    }

    const [result]: any = await pool.query(
      `
      UPDATE customers
      SET
        full_name = ?,
        phone = ?,
        email = ?,
        note = ?
      WHERE id = ?
      `,
      [
        full_name,
        phone,
        email || null,
        note || null,
        req.params.id,
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບລູກຄ້າ',
      });
    }

    res.json({
      message: 'ແກ້ໄຂລູກຄ້າສຳເລັດ',
    });
  })
);

router.patch(
  '/:id/password',
  auth,
  asyncHandler(async (req, res) => {
    const { password } = req.body;

    if (!password || password.toString().length < 4) {
      return res.status(400).json({
        message: 'Password ຕ້ອງມີຢ່າງໜ້ອຍ 4 ຕົວອັກສອນ',
      });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const [result]: any = await pool.query(
      `
      UPDATE customers
      SET password_hash = ?
      WHERE id = ?
      `,
      [password_hash, req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບລູກຄ້າ',
      });
    }

    res.json({
      message: 'ປ່ຽນ password ລູກຄ້າສຳເລັດ',
    });
  })
);

router.delete(
  '/:id',
  auth,
  asyncHandler(async (req, res) => {
    const [usedRows]: any = await pool.query(
      `
      SELECT id
      FROM bookings
      WHERE customer_id = ?
      LIMIT 1
      `,
      [req.params.id]
    );

    if (usedRows.length > 0) {
      return res.status(400).json({
        message: 'ລູກຄ້ານີ້ມີປະຫວັດການຈອງ ບໍ່ສາມາດລຶບໄດ້',
      });
    }

    const [result]: any = await pool.query(
      `
      DELETE FROM customers
      WHERE id = ?
      `,
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບລູກຄ້າ',
      });
    }

    res.json({
      message: 'ລຶບລູກຄ້າສຳເລັດ',
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
        full_name = ?,
        phone = ?,
        email = ?
      WHERE id = ?
      `,
      [full_name, phone, email || null, id]
    );

    const [rows]: any = await pool.query(
      `
      SELECT id, full_name, phone, email
      FROM customers
      WHERE id = ?
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
      WHERE id = ?
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
      SET password_hash = ?
      WHERE id = ?
      `,
      [password_hash, id]
    );

    res.json({
      message: 'Password changed',
    });
  })
);

export default router;