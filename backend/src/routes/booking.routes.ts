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
      sql += " AND b.booking_date=?";
      params.push(date);
    }

    if (field_id) {
      sql += " AND b.field_id=?";
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

    const [overlap]: any = await pool.query(
      `
      SELECT id
      FROM bookings
      WHERE field_id=?
      AND booking_date=?
      AND status!='cancelled'
      AND start_time < ?
      AND end_time > ?
      `,
      [field_id, booking_date, end_time, start_time]
    );

    if (overlap.length) {
      return res.status(409).json({
        message: "This time is already booked",
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
        created_by
      )
      VALUES (?,?,?,?,?,?,?,?,?,?)
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
        null,
      ]
    );

    res.status(201).json({
      id: result.insertId,
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
        paid=1,
        paid_at=NOW(),
        payment_status='paid'
      WHERE id=?
      `,
      [req.params.id]
    );

    res.json({
      message: "paid",
    });
  })
);

router.patch(
  "/:id/checkin",
  auth,
  asyncHandler(async (req, res) => {
    await pool.query(
      `
      UPDATE bookings
      SET
        status='checked_in',
        checked_in_at=NOW()
      WHERE id=?
      `,
      [req.params.id]
    );

    res.json({
      message: "checked in",
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
      SET status='cancel_requested'
      WHERE id=?
      AND status!='cancelled'
      AND status!='checked_in'
      `,
      [req.params.id]
    );

    res.json({
      message: "cancel requested",
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
      SET status='cancelled'
      WHERE id=?
      `,
      [req.params.id]
    );

    res.json({
      message: "cancelled",
    });
  })
);

router.patch(
  "/:id/slip",
  auth,
  asyncHandler(async (req, res) => {
    const { slip_image } = req.body;

    await pool.query(
      `
      UPDATE bookings
      SET
        slip_image=?,
        payment_status='pending'
      WHERE id=?
      `,
      [slip_image, req.params.id]
    );

    res.json({
      message: "slip uploaded",
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
        paid=1,
        paid_at=NOW(),
        payment_status='paid'
      WHERE id=?
      `,
      [req.params.id]
    );

    res.json({
      message: "payment approved",
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
        paid=0,
        paid_at=NULL,
        payment_status='rejected'
      WHERE id=?
      `,
      [req.params.id]
    );

    res.json({
      message: "payment rejected",
    });
  })
);

export default router;