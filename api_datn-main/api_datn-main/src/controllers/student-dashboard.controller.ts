import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { computeLatestPartScores } from '../utils/score.utils';

/**
 * Get student dashboard data
 * GET /api/dashboard/student
 */
export const getStudentDashboard = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const userId = req.user?.id;

        if (!userId) {
            res.status(401).json({
                success: false,
                message: 'Unauthorized',
            });
            return;
        }

        // Helper to format Date to YYYY-MM-DD (VN +7)
        const formatDateVN = (d: Date) => {
            const vn = new Date(d.getTime() + (7 * 60 * 60 * 1000));
            const y = vn.getUTCFullYear();
            const m = String(vn.getUTCMonth() + 1).padStart(2, '0');
            const day = String(vn.getUTCDate()).padStart(2, '0');
            return `${y}-${m}-${day}`;
        };

        // 1. Get User Data with streak fields
        const user = (await (prisma as any).user.findUnique({
            where: { id: userId },
            select: {
                name: true,
                progress: true,
                targetScore: true,
                currentStreak: true,
                lastActiveAt: true,
            } as any,
        })) as any;

        if (!user) {
            res.status(404).json({ success: false, message: 'User not found' });
            return;
        }

        // 1b. Get scores from history: latest attempt of EACH part (1-7)
        const scoreData = await computeLatestPartScores(userId, prisma);

        const estimatedListening = scoreData.estimatedListening;
        const estimatedReading = scoreData.estimatedReading;
        const estimatedTotal = scoreData.estimatedScore;

        // 1c. Get live totalAttempts count
        const totalAttempts = await prisma.testAttempt.count({ where: { userId } });

        // 2. Persistent Streak Logic (Normalized to VN Time +7)
        let updatedStreak = user.currentStreak || 0;
        
        // Helper to get VN Date (UTC+7)
        const getVNDate = (d: Date) => {
            const vnTime = new Date(d.getTime() + (7 * 60 * 60 * 1000));
            return new Date(vnTime.getUTCFullYear(), vnTime.getUTCMonth(), vnTime.getUTCDate());
        };

        const now = new Date();
        const todayVN = getVNDate(now);
        
        if (!user.lastActiveAt) {
            // First time activity
            updatedStreak = 1;
            await prisma.user.update({
                where: { id: userId },
                data: { currentStreak: 1, lastActiveAt: now } as any,
            });
        } else {
            const lastActiveVN = getVNDate(new Date(user.lastActiveAt));
            
            const diffTime = todayVN.getTime() - lastActiveVN.getTime();
            const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

            if (diffDays === 1) {
                // Practiced exactly the day after -> Increment streak
                updatedStreak += 1;
                await prisma.user.update({
                    where: { id: userId },
                    data: { currentStreak: updatedStreak, lastActiveAt: now } as any,
                });
            } else if (diffDays > 1) {
                // Broke streak -> Reset to 1
                updatedStreak = 1;
                await prisma.user.update({
                    where: { id: userId },
                    data: { currentStreak: 1, lastActiveAt: now } as any,
                });
            } else if (diffDays === 0) {
                // Already active today -> Keep current streak, just update timestamp
                await prisma.user.update({
                    where: { id: userId },
                    data: { lastActiveAt: now } as any,
                });
            }
        }

        // 3. Recent Activities (Last 3 persistence attempts from TestAttempt)
        const recentActivities = await prisma.testAttempt.findMany({
            where: { userId },
            take: 3,
            orderBy: { createdAt: 'desc' },
            include: {
                part: {
                    select: {
                        partNumber: true,
                        partName: true,
                        test: {
                            select: {
                                title: true,
                            }
                        }
                    }
                },
                test: {
                    select: {
                        title: true,
                    }
                }
            }
        });

        // 4. AI Recommendations (Refined to find real weaknesses)
        let latestWeakAttempt = await prisma.userPartProgress.findFirst({
            where: { 
                userId,
                percentage: { lt: 0.7 }
            },
            orderBy: { createdAt: 'desc' },
            include: { part: { select: { partName: true } } }
        });

        // Backup: Check recent TestAttempts (v2) if no weakness found in legacy table
        if (!latestWeakAttempt) {
            const recentAttempts = await prisma.testAttempt.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: 5,
                include: { part: { select: { partName: true } } }
            });
            
            // Find first attempt with score < 70%
            const weak = recentAttempts.find((a: any) => 
                (a.totalQuestions ?? 0) > 0 && ((a.correctCount ?? 0) / (a.totalQuestions ?? 0)) < 0.7
            );
            
            if (weak) {
                const correct = weak.correctCount ?? 0;
                const total = weak.totalQuestions ?? 0;
                latestWeakAttempt = {
                    part: { partName: weak.part?.partName || 'kỹ năng này' },
                    percentage: total > 0 ? (correct / total) : 0
                } as any;
            }
        }

        const recommendations = [];
        if (latestWeakAttempt) {
            recommendations.push({
                title: `Ôn lại ${latestWeakAttempt.part.partName}`,
                subtitle: `Bạn đạt ${Math.round(latestWeakAttempt.percentage * 100)}% ở lần làm gần nhất.`,
                type: 'REVIEW',
                icon: 'warning',
            });
        }

        if (recommendations.length < 2) {
            recommendations.push({
                title: 'Luyện tập kỹ năng yếu nhất',
                subtitle: 'Gia sư AI khuyên bạn nên tập trung vào Listening Part 1.',
                type: 'SUGGESTION',
                icon: 'psychology',
            });
        }

        // 6. Activity Stats (Heatmap - Last 90 days) - Optimized: One query instead of 90
        const DAYS_TO_SCAN = 90;
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - (DAYS_TO_SCAN - 1));
        startDate.setHours(0, 0, 0, 0);
        // Adjust for VN Time offset (00:00 VN is 17:00 UTC previous day)
        const utcStartDate = new Date(startDate.getTime() - (7 * 60 * 60 * 1000));

        const allAttempts = await prisma.testAttempt.findMany({
            where: {
                userId,
                createdAt: { gte: utcStartDate }
            },
            select: { createdAt: true }
        });

        // Group by local date string (VN Time)
        const statsMap: Record<string, number> = {};
        allAttempts.forEach((attempt: any) => {
            const d = new Date(attempt.createdAt.getTime() + (7 * 60 * 60 * 1000));
            const y = d.getUTCFullYear();
            const m = String(d.getUTCMonth() + 1).padStart(2, '0');
            const dayStr = String(d.getUTCDate()).padStart(2, '0');
            const dateStr = `${y}-${m}-${dayStr}`;
            statsMap[dateStr] = (statsMap[dateStr] || 0) + 1;
        });

        const activityStats = [];
        for (let i = DAYS_TO_SCAN - 1; i >= 0; i--) {
            const d = new Date(now.getTime() - (i * 24 * 60 * 60 * 1000));
            const dateStr = formatDateVN(d);
            
            activityStats.push({
                date: dateStr,
                count: statsMap[dateStr] || 0
            });
        }
        // DEBUG: Xem thực tế dữ liệu Heatmap có bài hay không
        console.log(`[Dashboard] User ${userId} có ${allAttempts.length} bài. Stats:`, activityStats.filter(s => s.count > 0));
        // 7. Complete Learning Timeline (Journey)
        // This returns ALL attempts for the timeline view, not just the last 3
        const learningTimeline = await prisma.testAttempt.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            include: {
                part: {
                    select: {
                        partNumber: true,
                        partName: true,
                        test: { select: { title: true } }
                    }
                },
                test: {
                    select: {
                        title: true,
                    }
                }
            }
        });

        // 8. Find Historical Milestones (Peak and Start)
        const milestones: any[] = [];

        // A. Find First Ever Practice
        const firstPractice = await prisma.testAttempt.findFirst({
            where: { userId },
            orderBy: { createdAt: 'asc' },
            select: { createdAt: true }
        });

        if (firstPractice) {
            milestones.push({
                date: formatDateVN(firstPractice.createdAt),
                label: '🌱 Ngày đầu khởi nghiệp'
            });
        }

        // B. Find All-time Peak (Simplification: take the highest count in the already scanned data)
        // For more accuracy, we could query group-by, but scanning 90 days is usually enough for the heatmap context
        let peakCount = 0;
        let peakDate = '';
        activityStats.forEach(stat => {
            if (stat.count > peakCount) {
                peakCount = stat.count;
                peakDate = stat.date;
            }
        });

        if (peakCount >= 3 && peakDate) { // Only mark as peak if at least 3 tasks to avoid marking casual 1-item days
             milestones.push({
                date: peakDate,
                label: `🏆 Kỷ lục cày cuốc: ${peakCount} bài`
            });
        }

        const responseData = {
            success: true,
            data: {
                user: {
                    id: userId,
                    name: user.name,
                    progress: user.progress || 0,
                    targetScore: user.targetScore || 0,
                    estimatedScore: estimatedTotal,
                    estimatedListening: estimatedListening,
                    estimatedReading: estimatedReading,
                    totalAttempts: totalAttempts,
                    // Mastery scores from latest attempts (updated via score.utils)
                    ...scoreData.partBreakdown ? (() => {
                        const mastery: Record<string, any> = {};
                        Object.entries(scoreData.partBreakdown).forEach(([pNum, data]) => {
                            if (data) {
                                mastery[`max_p${pNum}`] = data.correct;
                                mastery[`id_p${pNum}`] = data.id;
                            }
                        });
                        return mastery;
                    })() : {}
                },
                streak: updatedStreak,
                recentActivities: recentActivities.map((a: any) => ({
                    id: a.id,
                    partId: a.partId,
                    partNumber: a.part?.partNumber ?? 0,
                    title: a.test?.title ?? a.part?.test?.title ?? 'Luyện tập',
                    partName: a.part?.partName ?? 'Tổng hợp',
                    score: a.correctCount,
                    totalQuestions: a.totalQuestions,
                    percentage: a.totalQuestions ? Math.round((a.correctCount! / a.totalQuestions!) * 100) : 0,
                    toeicScore: a.totalScore,
                    createdAt: a.createdAt,
                })),
                learningTimeline: learningTimeline.map((a: any) => ({
                    id: a.id,
                    date: a.createdAt,
                    title: a.test?.title ?? a.part?.test?.title ?? 'Luyện tập',
                    partName: a.part?.partName ?? 'Tổng hợp',
                    partNumber: a.part?.partNumber ?? 0,
                    score: a.correctCount,
                    total: a.totalQuestions,
                    toeicScore: a.totalScore,
                })),
                activityStats,
                recommendations,
                resumeLearning: recentActivities.length > 0 ? {
                    id: recentActivities[0].id,
                    partId: recentActivities[0].partId,
                    partNumber: recentActivities[0].part?.partNumber ?? 0,
                    title: recentActivities[0].test?.title ?? recentActivities[0].part?.test?.title ?? 'Luyện tập',
                    createdAt: recentActivities[0].createdAt,
                } : null,
                milestones,
            },
        };

        // DIAGNOSTIC: Ghi lại kết quả trả về để debug
        try {
            require('fs').writeFileSync('last_dashboard_response.json', JSON.stringify(responseData, null, 2));
        } catch (e) {}

        res.status(200).json(responseData);

    } catch (error) {
        next(error);
    }
};
