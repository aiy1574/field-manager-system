import type { Request, Response, NextFunction } from 'express';
import { verifyToken, type JwtUser } from '../utils/jwt.js';

declare global { namespace Express { interface Request { user?: JwtUser } } }

export function auth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return res.status(401).json({ message: 'Unauthorized' });
  try { req.user = verifyToken(header.slice(7)); next(); }
  catch { return res.status(401).json({ message: 'Invalid token' }); }
}
export function allowRoles(...roles: JwtUser['role'][]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) return res.status(403).json({ message: 'Forbidden' });
    next();
  };
}
