import { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const p = prisma as any;

/**
 * Get dashboard statistics
 * GET /api/dashboard/stats
 */
export const getDashboardStats = async (
    _req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const [userCount, testCount, classCount, questionCount, averageScoreResult, totalSubmissions, topStudents, recentSubmissions] = await Promise.all([
            // Chỉ đếm người dùng có role là STUDENT - loại trừ ban quản trị
            p.user.count({ where: { role: 'STUDENT' } }),
            p.test.count(),
            p.class.count(),
            p.question.count(),
            // Điểm trung bình của sinh viên (chỉ tính những người đã có điểm > 0)
            p.user.aggregate({
                _avg: { estimatedScore: true },
                where: { role: 'STUDENT', estimatedScore: { gt: 0 } }
            }),
            // Tổng số lượt làm bài
            p.testAttempt.count(),
            // Top 5 học viên có điểm cao nhất
            p.user.findMany({
                where: { role: 'STUDENT' },
                orderBy: { estimatedScore: 'desc' },
                take: 5,
                select: {
                    id: true,
                    name: true,
                    username: true,
                    avatarUrl: true,
                    estimatedScore: true,
                    estimatedListening: true,
                    estimatedReading: true,
                }
            }),
            // 10 lượt làm bài gần nhất của hệ thống (Dùng TestAttempt để hỗ trợ detail modal)
            p.testAttempt.findMany({
                orderBy: { createdAt: 'desc' },
                take: 10,
                include: {
                    user: {
                        select: { name: true, avatarUrl: true }
                    },
                    part: {
                        select: { partName: true, test: { select: { title: true } } }
                    }
                }
            })
        ]);

        res.status(200).json({
            success: true,
            data: {
                users: userCount || 0,
                tests: testCount || 0,
                classes: classCount || 0,
                questions: questionCount || 0,
                averageScore: Math.round(averageScoreResult?._avg?.estimatedScore || 0),
                totalSubmissions: totalSubmissions || 0,
                topStudents: topStudents || [],
                // Duy trì tính tương thích với Frontend (map correctCount -> score, totalScore -> toeicScore)
                recentSubmissions: (recentSubmissions || []).map((sub: any) => ({
                    ...sub,
                    score: sub.correctCount,
                    toeicScore: sub.totalScore
                })),
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get stats comparing class performances
 * GET /api/dashboard/class-comparison
 */
export const getClassComparisonStats = async (
    _req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        // Lấy tất cả các lớp kèm theo học viên của họ
        const classes = await p.class.findMany({
            include: {
                students: {
                    select: { 
                        role: true,
                        estimatedScore: true 
                    }
                }
            }
        });

        // Tính toán điểm trung bình và sĩ số cho mỗi lớp
        const comparisonData = classes.map((c: any) => {
            // Sĩ số thực tế (chỉ tính người dùng có role STUDENT)
            const allStudents = (c.students || []).filter((s: any) => s.role === 'STUDENT');
            const studentCount = allStudents.length;

            // Chỉ tính trung bình cho những học viên đã làm bài và có điểm để không làm nhiễu dữ liệu
            const studentsWithScores = allStudents.filter((s: any) => (s.estimatedScore || 0) > 0);
            const studentScores = studentsWithScores.map((s: any) => s.estimatedScore);
            
            const avgScore = studentScores.length > 0 
                ? Math.round(studentScores.reduce((a: number, b: number) => a + b, 0) / studentScores.length)
                : 0;
            
            return {
                id: c.id,
                className: c.className,
                classCode: c.classCode,
                averageScore: avgScore,
                studentCount: studentCount
            };
        });

        // Sắp xếp theo điểm trung bình giảm dần
        comparisonData.sort((a: any, b: any) => b.averageScore - a.averageScore);

        res.status(200).json({
            success: true,
            data: comparisonData
        });
    } catch (error) {
        next(error);
    }
};
