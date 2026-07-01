import express from 'express';
import cors from 'cors';
import 'dotenv/config';

import authRoutes from './routes/auth.routes.js';
import uploadRoutes from './routes/upload.routes.js';
import bookingRoutes from './routes/booking.routes.js';
import saleRoutes from './routes/sale.routes.js';
import reportRoutes from './routes/report.routes.js';
import dashboardRoutes from './routes/dashboard.routes.js';
import productRoutes from './routes/product.routes.js';
import customerRoutes from './routes/customer.routes.js';
import fieldRoutes from './routes/field.routes.js';
import fieldServiceRoutes from './routes/field_service.routes.js';
import employeeRoutes from './routes/employee.routes.js';
import crudRoutes from './routes/crud.routes.js';

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

app.get('/api/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api/upload', uploadRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/products', productRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/fields', fieldRoutes);
app.use('/api/field-services', fieldServiceRoutes);
app.use('/api/employees', employeeRoutes);

app.use('/api', crudRoutes);

app.use((err: any, _req: any, res: any, _next: any) => {
  console.error(err);

  res.status(500).json({
    message: 'Server error',
    detail: err.message,
  });
});

const port = Number(process.env.PORT || 4000);

app.listen(port, () => {
  console.log(`Backend running at http://localhost:${port}`);
});