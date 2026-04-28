import { Router } from 'express';
import { FeedbackController } from '../controllers/feedback.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { roleMiddleware } from '../middlewares/role.middleware';

const router = Router();

// Tất cả các route đều yêu cầu đăng nhập
router.use(authMiddleware);

// 1. Học viên gửi ý kiến (Chỉ STUDENT)
router.post('/', roleMiddleware(['STUDENT'] as any[]), FeedbackController.sendFeedback);

// 2. Lấy danh sách ý kiến (GV xem của lớp, HV xem của mình, Admin xem hết)
router.get('/', roleMiddleware(['ADMIN', 'TEACHER', 'STUDENT'] as any[]), FeedbackController.getFeedbacks);

// 6. Xem chi tiết một ý kiến
router.get('/:id', roleMiddleware(['ADMIN', 'TEACHER', 'STUDENT'] as any[]), FeedbackController.getFeedbackDetail);

// 3. GV xử lý xong ý kiến (Chỉ TEACHER hoặc ADMIN)
router.patch('/:id/resolve', roleMiddleware(['ADMIN', 'TEACHER'] as any[]), FeedbackController.resolveFeedback);

// 4. GV phản hồi ý kiến (Chỉ TEACHER hoặc ADMIN)
router.patch('/:id/reply', roleMiddleware(['ADMIN', 'TEACHER'] as any[]), FeedbackController.replyFeedback);

// 5. GV chủ động gửi nhận xét (Chỉ TEACHER hoặc ADMIN)
router.post('/teacher', roleMiddleware(['ADMIN', 'TEACHER'] as any[]), FeedbackController.sendTeacherOpinion);

export default router;
