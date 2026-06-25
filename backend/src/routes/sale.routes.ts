import { Router } from 'express';
import { pool } from '../config/db.js';
import { auth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

router.post(
  '/',
  auth,
  asyncHandler(async (req, res) => {
    const {
      items,
      payment_method = 'cash',
      customer_id = null,
    } = req.body;

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        message: 'ບໍ່ມີລາຍການສິນຄ້າ',
      });
    }

    const conn = await pool.getConnection();

    try {
      await conn.beginTransaction();

      let total = 0;

      const saleItems: any[] = [];

      for (const item of items) {
        const productId = Number(item.product_id);
        const qty = Number(item.qty ?? item.quantity);

        if (!productId || !Number.isFinite(productId)) {
          await conn.rollback();
          return res.status(400).json({
            message: 'ບໍ່ພົບລະຫັດສິນຄ້າ',
          });
        }

        if (!qty || !Number.isFinite(qty) || qty <= 0) {
          await conn.rollback();
          return res.status(400).json({
            message: 'ຈຳນວນສິນຄ້າບໍ່ຖືກຕ້ອງ',
          });
        }

        const [productRows]: any = await conn.query(
          'SELECT id, name, price, stock FROM products WHERE id = ? FOR UPDATE',
          [productId],
        );

        if (productRows.length === 0) {
          await conn.rollback();
          return res.status(404).json({
            message: `ບໍ່ພົບສິນຄ້າ ID ${productId}`,
          });
        }

        const product = productRows[0];

        const stock = Number(product.stock);
        const unitPrice = Number(product.price);
        const productName = product.name;

        if (!Number.isFinite(unitPrice)) {
          await conn.rollback();
          return res.status(400).json({
            message: `ລາຄາສິນຄ້າ ${productName} ບໍ່ຖືກຕ້ອງ`,
          });
        }

        if (stock < qty) {
          await conn.rollback();
          return res.status(400).json({
            message: `ສິນຄ້າ ${productName} ບໍ່ພຽງພໍ`,
          });
        }

        const subtotal = unitPrice * qty;
        total += subtotal;

        saleItems.push({
          product_id: productId,
          product_name: productName,
          unit_price: unitPrice,
          qty,
          subtotal,
        });
      }

      const [saleResult]: any = await conn.query(
        `
        INSERT INTO sales (
          total,
          payment_method,
          customer_id,
          sold_by
        )
        VALUES (?, ?, ?, ?)
        `,
        [
          total,
          payment_method,
          customer_id,
          req.user!.id,
        ],
      );

      const saleId = saleResult.insertId;

      for (const item of saleItems) {
        await conn.query(
          `
          INSERT INTO sale_items (
            sale_id,
            product_id,
            product_name,
            unit_price,
            qty,
            subtotal
          )
          VALUES (?, ?, ?, ?, ?, ?)
          `,
          [
            saleId,
            item.product_id,
            item.product_name,
            item.unit_price,
            item.qty,
            item.subtotal,
          ],
        );

        await conn.query(
          `
          UPDATE products
          SET stock = stock - ?
          WHERE id = ?
          `,
          [
            item.qty,
            item.product_id,
          ],
        );
      }

      await conn.commit();

      return res.status(201).json({
        message: 'ຂາຍສິນຄ້າສຳເລັດ',
        id: saleId,
        sale_id: saleId,
        total,
        items: saleItems,
      });
    } catch (e) {
      await conn.rollback();
      throw e;
    } finally {
      conn.release();
    }
  }),
);

router.get(
  '/',
  auth,
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query(
      `
      SELECT 
        s.id,
        s.total,
        s.payment_method,
        s.customer_id,
        s.sold_by,
        s.created_at
      FROM sales s
      ORDER BY s.created_at DESC
      `,
    );

    res.json(rows);
  }),
);

router.get(
  '/:id',
  auth,
  asyncHandler(async (req, res) => {
    const saleId = Number(req.params.id);

    if (!saleId || !Number.isFinite(saleId)) {
      return res.status(400).json({
        message: 'ລະຫັດການຂາຍບໍ່ຖືກຕ້ອງ',
      });
    }

    const [saleRows]: any = await pool.query(
      `
      SELECT 
        id,
        total,
        payment_method,
        customer_id,
        sold_by,
        created_at
      FROM sales
      WHERE id = ?
      `,
      [saleId],
    );

    if (saleRows.length === 0) {
      return res.status(404).json({
        message: 'ບໍ່ພົບການຂາຍ',
      });
    }

    const [itemRows]: any = await pool.query(
      `
      SELECT
        id,
        sale_id,
        product_id,
        product_name,
        unit_price,
        qty,
        subtotal
      FROM sale_items
      WHERE sale_id = ?
      `,
      [saleId],
    );

    res.json({
      sale: saleRows[0],
      items: itemRows,
    });
  }),
);

export default router;