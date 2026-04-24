import { prisma } from '../../config/prisma';
import { logger } from '../../utils/logger';
import bcrypt from 'bcrypt';
import { RequestStatus } from '@prisma/client';

export class PasswordRequestService {
    /**
     * Lấy danh sách yêu cầu cấp lại mật khẩu
     */
    async getRequests(status?: string) {
        try {
            return await (prisma as any).passwordResetRequest.findMany({
                where: status ? { status: status as RequestStatus } : {},
                include: {
                    user: {
                        select: {
                            id: true,
                            name: true,
                            role: true,
                            email: true,
                            phoneNumber: true,
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
            });
        } catch (error) {
            logger.error('Error getting password reset requests:', error);
            throw error;
        }
    }

    /**
     * Thực hiện cấp mật khẩu mới cho người dùng
     */
    async fulfillRequest(requestId: string, newPassword: string, adminNote?: string) {
        try {
            // 1. Tìm yêu cầu
            const request = await (prisma as any).passwordResetRequest.findUnique({
                where: { id: requestId },
            });

            if (!request) {
                throw new Error('Yêu cầu không tồn tại');
            }

            if (request.status === 'COMPLETED') {
                throw new Error('Yêu cầu này đã được xử lý xong');
            }

            // 2. Tìm người dùng dựa trên username (hoặc userId nếu có)
            const user = await prisma.user.findUnique({
                where: { username: request.username },
            });

            if (!user) {
                throw new Error('Người dùng không tồn tại trong hệ thống');
            }

            // 3. Hash mật khẩu mới
            const hashedPassword = await bcrypt.hash(newPassword, 10);

            // 4. Cập nhật mật khẩu và đánh dấu yêu cầu đã xong (trong Transaction)
            await prisma.$transaction([
                prisma.user.update({
                    where: { id: user.id },
                    data: { 
                        password: hashedPassword,
                        isFirstLogin: true, // Bắt buộc đổi lại khi đăng nhập bằng pass admin cấp
                    },
                }),
                (prisma as any).passwordResetRequest.update({
                    where: { id: requestId },
                    data: {
                        status: 'COMPLETED',
                        adminNote: adminNote || 'Admin đã cấp mật khẩu mới.',
                    },
                }),
                prisma.notification.create({
                    data: {
                        userId: user.id,
                        title: 'Mật khẩu đã được đặt lại',
                        content: `Yêu cầu cấp lại mật khẩu của bạn đã được xử lý. Vui lòng đăng nhập bằng mật khẩu mới được cấp.`,
                        type: 'SYSTEM',
                    },
                }),
            ]);

            return { success: true, message: 'Đã cấp mật khẩu mới thành công' };
        } catch (error: any) {
            logger.error('Error fulfilling password request:', error);
            return { success: false, message: error.message };
        }
    }

    /**
     * Từ chối yêu cầu
     */
    async rejectRequest(requestId: string, adminNote: string) {
        try {
            await (prisma as any).passwordResetRequest.update({
                where: { id: requestId },
                data: {
                    status: 'REJECTED',
                    adminNote: adminNote || 'Yêu cầu bị từ chối.',
                },
            });
            return { success: true, message: 'Đã từ chối yêu cầu' };
        } catch (error: any) {
            logger.error('Error rejecting password request:', error);
            return { success: false, message: error.message };
        }
    }
}

export const passwordRequestService = new PasswordRequestService();
