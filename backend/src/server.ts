import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import authRoutes from './routes/auth.routes.js';
import crudRoutes from './routes/crud.routes.js';
import bookingRoutes from './routes/booking.routes.js';
import saleRoutes from './routes/sale.routes.js';
import reportRoutes from './routes/report.routes.js';

const app = express();
app.use(cors());
app.use(express.json());
app.get('/api/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api', crudRoutes);
app.use((err: any, _req: any, res: any, _next: any) => {
  console.error(err);
  res.status(500).json({ message: 'Server error', detail: err.message });
});
const port = Number(process.env.PORT || 4000);
app.listen(port, () => console.log(`Backend running at http://localhost:${port}`));
