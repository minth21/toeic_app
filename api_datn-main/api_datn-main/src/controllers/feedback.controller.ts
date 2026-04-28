import { Request, Response } from 'express';
import { NotificationType } from '@prisma/client';
import { prisma } from '../config/prisma';
import { NotificationService } from '../services/notification.service';
import { successResponse, errorResponse } from '../utils/response';
import { HTTP_STATUS } from '../config/constants';
import { logger } from '../utils/logger';

export class FeedbackController {
    /**
     * 1. Học viên gửi ý kiến lên Giáo viên
     * POST /api/feedbacks
     */
    static async sendFeedback(req: Request, res: Response) {
        try {
            const { classId, content, imageUrl } = req.body;
            const userId = (req as any).user.id;
            const userName = (req as any).user.name;

            if (!classId || !content) {
                return errorResponse(res, 'Vui lòng cung cấp classId và nội dung ý kiến', HTTP_STATUS.BAD_REQUEST);
            }

            // Kiểm tra lớp học và lấy TeacherId
            const targetClass = await prisma.class.findUnique({
                where: { id: classId },
                include: {
                    students: { where: { id: userId } }
                }
            });

            if (!targetClass) {
                return errorResponse(res, 'Không tìm thấy lớp học', HTTP_STATUS.NOT_FOUND);
            }

            // Kiểm tra học sinh có thuộc lớp này không (Bảo mật)
            if (targetClass.students.length === 0) {
                return errorResponse(res, 'Bạn không thuộc lớp học này để gửi ý kiến', HTTP_STATUS.FORBIDDEN);
            }

            // 1. Tạo Feedback trong DB
            const feedback = await (prisma as any).studentFeedback.create({
                data: {
                    classId,
                    userId,
                    teacherId: targetClass.teacherId,
                    content,
                    imageUrl,
                    status: 'PENDING'
                },
                include: {
                    class: { select: { className: true } }
                }
            });

            // 2. Gửi thông báo cho Giáo viên
            await NotificationService.createNotification({
                userId: targetClass.teacherId,
                title: `💬 Ý kiến mới từ học viên ${targetClass.className}`,
                content: `Học viên ${userName} gửi ý kiến: "${content.substring(0, 50)}${content.length > 50 ? '...' : ''}"`,
                type: 'STUDENT_FEEDBACK' as NotificationType,
                relatedId: feedback.id
            });

            // 3. Thông báo cho chính Học viên là đã gửi thành công
            await NotificationService.createNotification({
                userId: userId,
                title: '✅ Gửi ý kiến thành công',
                content: `Ý kiến của bạn đã được gửi tới Giáo viên phụ trách ${targetClass.className}.`,
                type: 'SYSTEM' as NotificationType,
                relatedId: feedback.id
            });

            return successResponse(res, feedback, 'Gửi ý kiến thành công');
        } catch (error) {
            logger.error('Error in sendFeedback:', error);
            return errorResponse(res, 'Lỗi khi gửi ý kiến');
        }
    }

    /**
     * 2. Lấy danh sách ý kiến (Phân quyền)
     * GET /api/feedbacks
     */
    static async getFeedbacks(req: Request, res: Response) {
        try {
            const user = (req as any).user;
            let feedbacks;

            if (user.role === 'TEACHER') {
                // Giáo viên chỉ thấy ý kiến gửi cho mình
                feedbacks = await (prisma as any).studentFeedback.findMany({
                    where: { teacherId: user.id },
                    include: {
                        user: { select: { name: true, avatarUrl: true } },
                        class: { select: { className: true, classCode: true } }
                    },
                    orderBy: { createdAt: 'desc' }
                });
            } else if (user.role === 'STUDENT') {
                // Học viên chỉ thấy ý kiến của chính mình
                feedbacks = await (prisma as any).studentFeedback.findMany({
                    where: { userId: user.id },
                    include: {
                        class: { select: { className: true } },
                        teacher: { select: { name: true } }
                    },
                    orderBy: { createdAt: 'desc' }
                });
            } else if (user.role === 'ADMIN') {
                // Admin thấy tất cả (để giám sát nếu cần)
                feedbacks = await (prisma as any).studentFeedback.findMany({
                    include: {
                        user: { select: { name: true } },
                        teacher: { select: { name: true } },
                        class: { select: { className: true } }
                    },
                    orderBy: { createdAt: 'desc' }
                });
            } else {
                return errorResponse(res, 'Bạn không có quyền truy cập', HTTP_STATUS.FORBIDDEN);
            }

            return successResponse(res, feedbacks, 'Tải danh sách ý kiến thành công');
        } catch (error) {
            logger.error('Error in getFeedbacks:', error);
            return errorResponse(res, 'Lỗi khi tải danh sách ý kiến');
        }
    }

    /**
     * 3. Giáo viên đánh dấu đã xử lý/phản hồi
     * PATCH /api/feedbacks/:id/resolve
     */
    static async resolveFeedback(req: Request, res: Response) {
        try {
            const { id } = req.params;
            const teacherId = (req as any).user.id;

            // Tìm feedback và kiểm tra quyền sở hữu
            const existingFeedback = await (prisma as any).studentFeedback.findUnique({
                where: { id }
            });

            if (!existingFeedback) {
                return errorResponse(res, 'Không tìm thấy ý kiến', HTTP_STATUS.NOT_FOUND);
            }

            if (existingFeedback.teacherId !== teacherId && (req as any).user.role !== 'ADMIN') {
                return errorResponse(res, 'Bạn không có quyền xử lý ý kiến này', HTTP_STATUS.FORBIDDEN);
            }

            const feedback = await (prisma as any).studentFeedback.update({
                where: { id },
                data: { status: 'RESOLVED' },
                include: {
                    class: { select: { className: true } }
                }
            });

            // Gửi thông báo cho Học viên
            await NotificationService.createNotification({
                userId: feedback.userId,
                title: '🎉 Ý kiến của bạn đã được Giáo viên xử lý',
                content: `Giáo viên phụ trách lớp ${feedback.class.className} đã ghi nhận và xử lý ý kiến của bạn.`,
                type: 'FEEDBACK_RESOLVED' as NotificationType,
                relatedId: feedback.id
            });

            return successResponse(res, feedback, 'Đã đánh dấu xử lý ý kiến thành công');
        } catch (error) {
            logger.error('Error in resolveFeedback:', error);
            return errorResponse(res, 'Lỗi khi xử lý ý kiến');
        }
    }

    /**
     * 4. Giáo viên phản hồi ý kiến học viên
     * PATCH /api/feedbacks/:id/reply
     */
    static async replyFeedback(req: Request, res: Response) {
        try {
            const { id } = req.params;
            const { teacherReply } = req.body;
            const teacherId = (req as any).user.id;
            const teacherName = (req as any).user.name;

            if (!teacherReply) {
                return errorResponse(res, 'Vui lòng cung cấp nội dung phản hồi', HTTP_STATUS.BAD_REQUEST);
            }

            // Tìm feedback và kiểm tra quyền sở hữu
            const existingFeedback = await (prisma as any).studentFeedback.findUnique({
                where: { id }
            });

            if (!existingFeedback) {
                return errorResponse(res, 'Không tìm thấy ý kiến', HTTP_STATUS.NOT_FOUND);
            }

            if (existingFeedback.teacherId !== teacherId && (req as any).user.role !== 'ADMIN') {
                return errorResponse(res, 'Bạn không có quyền phản hồi ý kiến này', HTTP_STATUS.FORBIDDEN);
            }

            const feedback = await (prisma as any).studentFeedback.update({
                where: { id },
                data: {
                    teacherReply,
                    repliedAt: new Date(),
                    status: 'RESOLVED'
                },
                include: {
                    class: { select: { className: true } }
                }
            });

            // Gửi thông báo cho Học viên
            await NotificationService.createNotification({
                userId: feedback.userId,
                title: `Giáo viên vừa phản hồi thắc mắc của bạn`,
                content: `Giáo viên ${teacherName} đã trả lời ý kiến của bạn trong lớp ${feedback.class.className}.`,
                type: 'FEEDBACK_RESOLVED' as NotificationType,
                relatedId: feedback.id
            });

            return successResponse(res, feedback, 'Đã gửi phản hồi thành công');
        } catch (error) {
            logger.error('Error in replyFeedback:', error);
            return errorResponse(res, 'Lỗi khi gửi phản hồi');
        }
    }

    /**
     * 5. Giáo viên chủ động gửi ý kiến cho học viên
     * POST /api/feedbacks/teacher
     */
    static async sendTeacherOpinion(req: Request, res: Response) {
        try {
            const { userId, classId, content } = req.body;
            const teacherId = (req as any).user.id;
            const teacherName = (req as any).user.name;

            if (!userId || !classId || !content) {
                return errorResponse(res, 'Vui lòng cung cấp userId, classId và nội dung', HTTP_STATUS.BAD_REQUEST);
            }

            // Kiểm tra lớp học và quyền của giáo viên
            const targetClass = await prisma.class.findFirst({
                where: {
                    id: classId,
                    teacherId: teacherId
                },
                include: {
                    students: { where: { id: userId } }
                }
            });

            if (!targetClass) {
                return errorResponse(res, 'Lớp học không tồn tại hoặc bạn không có quyền', HTTP_STATUS.FORBIDDEN);
            }

            if (targetClass.students.length === 0) {
                return errorResponse(res, 'Học viên không thuộc lớp học này', HTTP_STATUS.NOT_FOUND);
            }

            // Tạo Feedback với cờ isFromTeacher = true
            const feedback = await (prisma as any).studentFeedback.create({
                data: {
                    userId,
                    classId,
                    teacherId,
                    content,
                    isFromTeacher: true,
                    status: 'RESOLVED' // Gửi từ GV thì coi như đã xử lý
                }
            });

            // Gửi thông báo cho Học viên
            await NotificationService.createNotification({
                userId: userId,
                title: `💡 Lời khuyên mới từ giáo viên ${teacherName}`,
                content: `Giáo viên đã gửi một nhận xét mới cho bạn trong lớp ${targetClass.className}`,
                type: 'SYSTEM' as NotificationType,
                relatedId: feedback.id
            });

            return successResponse(res, feedback, 'Đã gửi ý kiến cho học viên thành công');
        } catch (error) {
            logger.error('Error in sendTeacherOpinion:', error);
            return errorResponse(res, 'Lỗi khi gửi ý kiến');
        }
    }

    /**
     * 6. Xem chi tiết một ý kiến
     * GET /api/feedbacks/:id
     */
    static async getFeedbackDetail(req: Request, res: Response) {
        try {
            const { id } = req.params;
            const user = (req as any).user;

            const feedback = await (prisma as any).studentFeedback.findUnique({
                where: { id },
                include: {
                    user: { select: { name: true, avatarUrl: true, email: true } },
                    teacher: { select: { name: true, avatarUrl: true } },
                    class: { select: { className: true, classCode: true } }
                }
            });

            if (!feedback) {
                return errorResponse(res, 'Không tìm thấy ý kiến', HTTP_STATUS.NOT_FOUND);
            }

            // Kiểm tra quyền xem chi tiết
            const isOwner = feedback.userId === user.id;
            const isTargetTeacher = feedback.teacherId === user.id;
            const isAdmin = user.role === 'ADMIN';

            if (!isOwner && !isTargetTeacher && !isAdmin) {
                return errorResponse(res, 'Bạn không có quyền xem chi tiết ý kiến này', HTTP_STATUS.FORBIDDEN);
            }

            return successResponse(res, feedback, 'Tải chi tiết ý kiến thành công');
        } catch (error) {
            logger.error('Error in getFeedbackDetail:', error);
            return errorResponse(res, 'Lỗi khi tải chi tiết ý kiến');
        }
    }
}
