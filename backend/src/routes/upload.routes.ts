import { Router } from 'express';
import multer from 'multer';

const router = Router();

router.get('/', (_req, res) => {
  res.json({ message: 'Upload API ready' });
});

const storage = multer.diskStorage({
  destination: 'uploads/slips',
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  },
});

const upload = multer({ storage });

router.post('/', upload.single('slip'), (req, res) => {
  res.json({
    filename: req.file?.filename,
    path: req.file?.path,
  });
});

export default router;