import express from 'express';
import { adminController } from '../controllers/admin.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { roleMiddleware } from '../middlewares/role.middleware';
import { Role } from '@prisma/client';

import { passwordRequestController } from '../controllers/admin/password-request.controller';

const router = express.Router();

/**
 * Quản lý yêu cầu cấp lại mật khẩu
 */
router.get(
    '/password-requests',
    authMiddleware,
    roleMiddleware([Role.ADMIN]),
    passwordRequestController.getRequests
);

router.post(
    '/password-requests/:id/fulfill',
    authMiddleware,
    roleMiddleware([Role.ADMIN]),
    passwordRequestController.fulfillRequest
);

router.post(
    '/password-requests/:id/reject',
    authMiddleware,
    roleMiddleware([Role.ADMIN]),
    passwordRequestController.rejectRequest
);

/**
 * POST /api/admin/users/auto
 * Chỉ ADMIN và SPECIALIST mới có quyền tạo tài khoản tự động (Sinh mã & Password mặc định) cho GV, CV, HV
 */
router.post(
    '/users/auto',
    authMiddleware,
    roleMiddleware([Role.ADMIN, Role.SPECIALIST]),
    adminController.createUserAuto
);

export default router;
