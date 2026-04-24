import { Role } from '@prisma/client';
import { prisma } from '../config/prisma';
import { computeLatestPartScores } from '../utils/score.utils';

/**
 * Lấy danh sách tất cả người dùng với phân trang và tìm kiếm
 */
export const getAllUsers = async (
    page: number = 1,
    limit: number = 10,
    search?: string,
    role?: Role
) => {
    const skip = (page - 1) * limit;

    // Xây dựng điều kiện tìm kiếm
    const where: any = {};

    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { username: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
        ];
    }

    if (role) {
        where.role = role;
    }

    // Lấy tổng số users và danh sách users
    const [total, users] = await Promise.all([
        prisma.user.count({ where }),
        prisma.user.findMany({
            where,
            skip,
            take: limit,
            select: {
                id: true,
                username: true,
                name: true,
                email: true,
                phoneNumber: true,
                dateOfBirth: true,
                avatarUrl: true,
                role: true,
                progress: true,
                targetScore: true,
                estimatedScore: true,
                estimatedListening: true,
                estimatedReading: true,
                createdAt: true,
                updatedAt: true,
            } as any,
            orderBy: {
                createdAt: 'desc',
            },
        }),
    ]);

    return {
        users,
        pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        },
    };
};

/**
 * Lấy thông tin chi tiết của 1 user
 */
export const getUserById = async (id: string) => {
    const user = await prisma.user.findUnique({
        where: { id },
        select: {
            id: true,
            username: true,
            name: true,
            email: true,
            phoneNumber: true,
            avatarUrl: true,
            role: true,
            progress: true,
            targetScore: true,
            estimatedScore: true,
            estimatedListening: true,
            estimatedReading: true,
            createdAt: true,
            updatedAt: true,
        } as any,
    });

    return user;
};

/**
 * Cập nhật thông tin user
 */
export const updateUser = async (id: string, data: any) => {
    const updatedUser = await prisma.user.update({
        where: { id },
        data: {
            name: data.name,
            email: data.email,
            username: data.username,
            phoneNumber: data.phoneNumber,
            dateOfBirth: data.dateOfBirth,
            gender: data.gender,
            avatarUrl: data.avatarUrl,
            role: data.role,
            progress: data.progress,
            targetScore: data.targetScore,
        },
        select: {
            id: true,
            username: true,
            name: true,
            email: true,
            phoneNumber: true,
            dateOfBirth: true,
            gender: true,
            avatarUrl: true,
            role: true,
            progress: true,
            targetScore: true,
            estimatedScore: true,
            estimatedListening: true,
            estimatedReading: true,
            createdAt: true,
            updatedAt: true,
        } as any,
    });

    return updatedUser;
};


/**
 * Tính toán điểm TOEIC dự kiến dựa trên KỶ LỤC CÁ NHÂN (Best All-time Raw) của từng Part
 * Logic: Sum(Max_P1..P4) -> TOEIC_L | Sum(Max_P5..P7) -> TOEIC_R
 */
export const calculateEstimatedScore = async (userId: string) => {
    // Chỉ tính cho role STUDENT
    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, role: true }
    });

    if (!user || user.role !== Role.STUDENT) return null;

    // 1. Calculate scores using the new "Latest per Part" logic
    const scoreData = await computeLatestPartScores(userId, prisma);

    // 2. Fetch Overall Attempt Stats for average and count
    const attemptStats = await prisma.testAttempt.aggregate({
        where: { userId },
        _avg: { totalScore: true },
        _count: { _all: true }
    });

    const avgScore = Math.round(attemptStats._avg.totalScore || 0);
    const totalCount = attemptStats._count._all || 0;

    // 3. Cập nhật vào DB (User board)
    await prisma.user.update({
        where: { id: userId },
        data: {
            estimatedScore: scoreData.estimatedScore,
            estimatedListening: scoreData.estimatedListening,
            estimatedReading: scoreData.estimatedReading,
            highestScore: { set: Math.max(0, scoreData.estimatedScore) },
            averageScore: avgScore,
            totalAttempts: totalCount
        } as any
    });

    console.log(`[Score Logic Upgrade] User ${userId}: Summed Raw L:${scoreData.listeningCorrect} -> ${scoreData.estimatedListening}, Summed Raw R:${scoreData.readingCorrect} -> ${scoreData.estimatedReading}, Total:${scoreData.estimatedScore}`);

    return { 
        totalEstimated: scoreData.estimatedScore, 
        estimatedL: scoreData.estimatedListening, 
        estimatedR: scoreData.estimatedReading,
        partBreakdown: scoreData.partBreakdown 
    };
};
