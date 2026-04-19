import { prisma } from '../config/prisma';

export class NotificationService {
    /**
     * Tạo thông báo mới cho một người dùng cụ thể
     */
    static async createNotification(data: {
        userId: string;
        title: string;
        content: string;
        type: any;
        relatedId?: string;
    }) {
        try {
            return await prisma.notification.create({
                data: {
                    userId: data.userId,
                    title: data.title,
                    content: data.content,
                    type: data.type,
                    relatedId: data.relatedId,
                },
            });
        } catch (error) {
            console.error('Error creating notification:', error);
            // Không throw error để tránh làm gián đoạn luồng chính (ví dụ nộp bài)
            return null;
        }
    }

    /**
     * Lấy danh sách thông báo của người dùng
     */
    static async getNotifications(userId: string, limit: number = 20) {
        return await prisma.notification.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: limit,
        });
    }

    /**
     * Đếm số thông báo chưa đọc
     */
    static async getUnreadCount(userId: string) {
        return await prisma.notification.count({
            where: { userId, isRead: false },
        });
    }

    /**
     * Đánh dấu đã đọc
     */
    static async markAsRead(notificationId: string, userId: string) {
        return await prisma.notification.updateMany({
            where: { id: notificationId, userId },
            data: { isRead: true },
        });
    }

    /**
     * Đọc tất cả
     */
    static async markAllAsRead(userId: string) {
        return await prisma.notification.updateMany({
            where: { userId, isRead: false },
            data: { isRead: true },
        });
    }

    /**
     * Gửi thông báo cho TẤT CẢ học viên trong một LỚP (Class Broadcast)
     */
    static async notifyClass(classId: string, data: {
        title: string;
        content: string;
        type: any;
        relatedId?: string;
    }) {
        try {
            // 1. Lấy danh sách ID của học viên trong lớp
            const students = await prisma.user.findMany({
                where: { studentClassId: classId, role: 'STUDENT', status: 'ACTIVE' },
                select: { id: true }
            });

            if (students.length === 0) return [];

            // 2. Tạo thông báo hàng loạt
            return await prisma.notification.createMany({
                data: students.map((s: any) => ({
                    userId: s.id,
                    title: data.title,
                    content: data.content,
                    type: data.type,
                    relatedId: data.relatedId,
                })),
            });
        } catch (error) {
            console.error('Error notifying class:', error);
            return null;
        }
    }

    /**
     * Gửi thông báo cho TẤT CẢ học viên (Full Broadcast)
     */
    static async broadcastNotification(data: {
        title: string;
        content: string;
        type: any;
        relatedId?: string;
    }) {
        try {
            // 1. Lấy danh sách ID của tất cả học viên
            const students = await prisma.user.findMany({
                where: { role: 'STUDENT', status: 'ACTIVE' },
                select: { id: true }
            });

            if (students.length === 0) return [];

            // 2. Tạo thông báo hàng loạt
            return await prisma.notification.createMany({
                data: students.map((s: any) => ({
                    userId: s.id,
                    title: data.title,
                    content: data.content,
                    type: data.type,
                    relatedId: data.relatedId,
                })),
            });
        } catch (error) {
            console.error('Error broadcasting notification:', error);
            return null;
        }
    }
}
