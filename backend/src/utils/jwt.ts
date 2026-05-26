import jwt from 'jsonwebtoken';
export type JwtUser = { id: number; email: string; role: 'admin'|'staff'|'sales'|'checkin' };
export function signToken(user: JwtUser) {
  return jwt.sign(user, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '7d' });
}
export function verifyToken(token: string) {
  return jwt.verify(token, process.env.JWT_SECRET || 'dev_secret') as JwtUser;
}
