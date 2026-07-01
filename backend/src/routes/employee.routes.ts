import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

const allowRoles = ['owner', 'admin', 'staff', 'sales', 'checkin'];

function getCurrentUser(req: any) {
  return req.user || req.auth || {};
}

function isOwnerOrAdmin(req: any) {
  const user = getCurrentUser(req);
  const role = user.role?.toString().toLowerCase();

  return role === 'owner' || role === 'admin';
}

function requireOwnerOrAdmin(req: any, res: any) {
  if (!isOwnerOrAdmin(req)) {
    res.status(403).json({
      message: 'ບໍ່ມີສິດຈັດການພະນັກງານ',
    });
    return false;
  }

  return true;
}

router.get(
  '/',
  auth,
  asyncHandler(async (req: any, res) => {
    if (!requireOwnerOrAdmin(req, res)) return;

    const [rows] = await pool.query(
      `
      SELECT
        id,
        full_name,
        email,
        phone,
        position,
        role,
        is_active,
        created_at
      FROM users
      ORDER BY id DESC
      `,
    );

    res.json(rows);
  }),
);

router.post(
  '/',
  auth,
  asyncHandler(async (req: any, res) => {
    if (!requireOwnerOrAdmin(req, res)) return;

    const {
      full_name,
      email,
      password,
      phone,
      position,
      role,
      is_active,
    } = req.body;

    if (!full_name || !email || !password) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນຊື່, ອີເມວ ແລະ ລະຫັດຜ່ານ',
      });
    }

    const userRole = role || 'staff';

    if (!allowRoles.includes(userRole)) {
      return res.status(400).json({
        message: 'Role ບໍ່ຖືກຕ້ອງ',
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

    const password_hash = await bcrypt.hash(password, 10);

    const [result]: any = await pool.query(
      `
      INSERT INTO users (
        full_name,
        email,
        password_hash,
        phone,
        position,
        role,
        is_active
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [
        full_name,
        email,
        password_hash,
        phone || null,
        position || null,
        userRole,
        is_active === 0 ? 0 : 1,
      ],
    );

    res.status(201).json({
      id: result.insertId,
      message: 'ເພີ່ມພະນັກງານສຳເລັດ',
    });
  }),
);

router.put(
  '/:id',
  auth,
  asyncHandler(async (req: any, res) => {
    if (!requireOwnerOrAdmin(req, res)) return;

    const {
      full_name,
      email,
      phone,
      position,
      role,
      is_active,
    } = req.body;

    if (!full_name || !email) {
      return res.status(400).json({
        message: 'ກະລຸນາປ້ອນຊື່ ແລະ ອີເມວ',
      });
    }

    const userRole = role || 'staff';

    if (!allowRoles.includes(userRole)) {
      return res.status(400).json({
        message: 'Role ບໍ່ຖືກຕ້ອງ',
      });
    }

    const [existingRows]: any = await pool.query(
      'SELECT id FROM users WHERE email = ? AND id != ? LIMIT 1',
      [email, req.params.id],
    );

    if (existingRows.length > 0) {
      return res.status(409).json({
        message: 'ອີເມວນີ້ມີຜູ້ໃຊ້ແລ້ວ',
      });
    }

    const [result]: any = await pool.query(
      `
      UPDATE users
      SET
        full_name = ?,
        email = ?,
        phone = ?,
        position = ?,
        role = ?,
        is_active = ?
      WHERE id = ?
      `,
      [
        full_name,
        email,
        phone || null,
        position || null,
        userRole,
        is_active === 0 ? 0 : 1,
        req.params.id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບພະນັກງານ',
      });
    }

    res.json({
      message: 'ແກ້ໄຂພະນັກງານສຳເລັດ',
    });
  }),
);

router.patch(
  '/:id/password',
  auth,
  asyncHandler(async (req: any, res) => {
    if (!requireOwnerOrAdmin(req, res)) return;

    const { password } = req.body;

    if (!password || password.toString().length < 4) {
      return res.status(400).json({
        message: 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 4 ຕົວອັກສອນ',
      });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const [result]: any = await pool.query(
      `
      UPDATE users
      SET password_hash = ?
      WHERE id = ?
      `,
      [password_hash, req.params.id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບພະນັກງານ',
      });
    }

    res.json({
      message: 'ປ່ຽນລະຫັດຜ່ານສຳເລັດ',
    });
  }),
);

router.delete(
  '/:id',
  auth,
  asyncHandler(async (req: any, res) => {
    if (!requireOwnerOrAdmin(req, res)) return;

    const currentUser = getCurrentUser(req);
    const currentUserId = Number(currentUser.id);
    const targetId = Number(req.params.id);

    if (currentUserId === targetId) {
      return res.status(400).json({
        message: 'ບໍ່ສາມາດປິດບັນຊີຂອງຕົນເອງໄດ້',
      });
    }

    const [result]: any = await pool.query(
      `
      UPDATE users
      SET is_active = 0
      WHERE id = ?
      `,
      [req.params.id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບພະນັກງານ',
      });
    }

    res.json({
      message: 'ປິດການໃຊ້ງານພະນັກງານສຳເລັດ',
    });
  }),
);

export default router;