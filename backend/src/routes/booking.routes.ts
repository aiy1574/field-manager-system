import { Router } from "express";
import { pool } from "../config/db.js";
import { auth } from "../middleware/auth.js";
import { asyncHandler } from "../utils/asyncHandler.js";

const router = Router();

router.get(
  "/",
  auth,
  asyncHandler(async (req, res) => {
    const { date, field_id } = req.query;

    let sql = `
      SELECT
        b.*,
        f.name AS field_name,
        c.full_name AS customer_name,
        c.phone AS customer_phone
      FROM bookings b
      JOIN fields f ON f.id = b.field_id
      JOIN customers c ON c.id = b.customer_id
      WHERE 1=1
    `;

    const params: any[] = [];

    if (date) {
      sql += " AND b.booking_date = ?";
      params.push(date);
    }

    if (field_id) {
      sql += " AND b.field_id = ?";
      params.push(field_id);
    }

    sql += " ORDER BY b.booking_date DESC, b.start_time ASC";

    const [rows] = await pool.query(sql, params);
    res.json(rows);
  })
);

router.post(
  "/",
  auth,
  asyncHandler(async (req, res) => {
    const {
      field_id,
      customer_id,
      booking_date,
      start_time,
      end_time,
      total_price,
      note,
      slip_image,
    } = req.body;

    if (!field_id || !customer_id || !booking_date || !start_time || !end_time) {
      return res.status(400).json({
        message: "ກະລຸນາປ້ອນຂໍ້ມູນການຈອງໃຫ້ຄົບ",
      });
    }

    const [overlap]: any = await pool.query(
      `
      SELECT id
      FROM bookings
      WHERE field_id = ?
      AND booking_date = ?
      AND status != 'cancelled'
      AND start_time < ?
      AND end_time > ?
      `,
      [field_id, booking_date, end_time, start_time]
    );

    if (overlap.length) {
      return res.status(409).json({
        message: "ເວລານີ້ຖືກຈອງແລ້ວ",
      });
    }

    const [result]: any = await pool.query(
      `
      INSERT INTO bookings
      (
        field_id,
        customer_id,
        booking_date,
        start_time,
        end_time,
        total_price,
        note,
        slip_image,
        payment_status,
        status,
        paid,
        created_by
      )
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
      `,
      [
        field_id,
        customer_id,
        booking_date,
        start_time,
        end_time,
        total_price || 0,
        note || null,
        slip_image || null,
        "pending",
        "booked",
        0,
        null,
      ]
    );

    res.status(201).json({
      id: result.insertId,
      message: "ສ້າງການຈອງສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/pay",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET
        paid = 1,
        paid_at = NOW(),
        payment_status = 'paid'
      WHERE id = ?
      `,
      [req.params.id]
    );

    res.json({
      message: "ຊຳລະແລ້ວ",
    });
  })
);

router.patch(
  "/:id/approve-payment",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET
        paid = 1,
        paid_at = NOW(),
        payment_status = 'paid'
      WHERE id = ?
      `,
      [req.params.id]
    );

    res.json({
      message: "ອະນຸມັດການຊຳລະສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/reject-payment",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET
        paid = 0,
        paid_at = NULL,
        payment_status = 'rejected'
      WHERE id = ?
      `,
      [req.params.id]
    );

    res.json({
      message: "ປະຕິເສດການຊຳລະສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/partial-payment",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET
        paid = 0,
        paid_at = NULL,
        payment_status = 'partial'
      WHERE id = ?
      `,
      [req.params.id]
    );

    res.json({
      message: "ບັນທຶກສະຖານະຈ່າຍບໍ່ຄົບສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/checkin",
  auth,
  asyncHandler(async (req, res) => {
    const [rows]: any = await pool.query(
      `
      SELECT id, payment_status, status
      FROM bookings
      WHERE id = ?
      `,
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: "ບໍ່ພົບການຈອງ",
      });
    }

    const booking = rows[0];

    if (booking.status === "cancelled") {
      return res.status(400).json({
        message: "ການຈອງນີ້ຖືກຍົກເລີກແລ້ວ",
      });
    }

    if (booking.payment_status !== "paid") {
      return res.status(400).json({
        message: "ຕ້ອງຊຳລະເງິນກ່ອນຈຶ່ງ Check-in ໄດ້",
      });
    }

    await pool.query(
      `
      UPDATE bookings
      SET
        status = 'checked_in',
        checked_in_at = NOW()
      WHERE id = ?
      `,
      [req.params.id]
    );

    res.json({
      message: "Check-in ສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/cancel-request",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET status = 'cancel_requested'
      WHERE id = ?
      AND status != 'cancelled'
      AND status != 'checked_in'
      `,
      [req.params.id]
    );

    res.json({
      message: "ສົ່ງຄຳຂໍຍົກເລີກສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/approve-cancel",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET status = 'cancelled'
      WHERE id = ?
      AND status = 'cancel_requested'
      `,
      [req.params.id]
    );

    res.json({
      message: "ອະນຸມັດການຍົກເລີກສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/reject-cancel",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET status = 'booked'
      WHERE id = ?
      AND status = 'cancel_requested'
      `,
      [req.params.id]
    );

    res.json({
      message: "ປະຕິເສດຄຳຂໍຍົກເລີກສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/cancel",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET status = 'cancelled'
      WHERE id = ?
      `,
      [req.params.id]
    );

    res.json({
      message: "ຍົກເລີກສຳເລັດ",
    });
  })
);

router.patch(
  "/:id/slip",
  auth,
  asyncHandler(async (req, res) => {
    const { slip_image } = req.body;

    if (!slip_image) {
      return res.status(400).json({
        message: "ບໍ່ພົບຮູບສະລິບ",
      });
    }

    await pool.query(
      `
      UPDATE bookings
      SET
        slip_image = ?,
        payment_status = 'pending',
        paid = 0,
        paid_at = NULL
      WHERE id = ?
      `,
      [slip_image, req.params.id]
    );

    res.json({
      message: "ອັບໂຫຼດສະລິບສຳເລັດ",
    });
  })
);

export default router;