import express from 'express';
import {
    uploadUserAvatar,
    getUsers,
    getUserById,
    updateUserById,
    createUser,
    updateProfile,
    getProfile,
    toggleUserStatus,
    getLeaderboard,
} from '../controllers/user.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { adminMiddleware } from '../middlewares/admin.middleware';
import { uploadAvatar } from '../config/upload.config';

const router = express.Router();

/**
 * POST /api/users/avatar - Upload user avatar
 * Protected route - requires authentication
 */
router.post('/avatar', authMiddleware, uploadAvatar.single('image'), uploadUserAvatar);

/**
 * PATCH /api/users/me - Update current user profile
 * Protected route - requires authentication (Any Role)
 */
router.patch('/me', authMiddleware, updateProfile);

/**
 * GET /api/users/me - Get current user profile
 * Protected route - requires authentication (Any Role)
 */
router.get('/me', authMiddleware, getProfile);

/**
 * POST /api/users - Create new user (Admin only)
 * Admin only
 */
router.post('/', authMiddleware, adminMiddleware, createUser);

/**
 * GET /api/users - Lấy danh sách tất cả users
 * Admin only
 */
router.get('/', authMiddleware, adminMiddleware, getUsers);



/**
 * GET /api/users/:id - Lấy thông tin chi tiết 1 user
 * Admin or Teacher only
 */
router.get('/:id', authMiddleware, (req, res, next) => {
    const role = (req as any).user?.role?.toUpperCase();
    if (role === 'ADMIN' || role === 'TEACHER') {
        next();
    } else {
        res.status(403).json({ success: false, message: 'Forbidden: Requires Admin or Teacher role' });
    }
}, getUserById);

/**
 * PATCH /api/users/:id - Cập nhật thông tin user
 * Admin only
 */
router.patch('/:id', authMiddleware, adminMiddleware, updateUserById);

/**
 * GET /api/users/leaderboard - Lấy bảng xếp hạng học viên
 * Public for all students/teachers
 */
router.get('/leaderboard', authMiddleware, getLeaderboard);

/**
 * PATCH /api/users/:id/status - Khóa/Mở khóa tài khoản
 * Admin only
 */
router.patch('/:id/status', authMiddleware, adminMiddleware, toggleUserStatus);



export default router;


