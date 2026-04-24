import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { NotificationService } from '../services/notification.service';

/**
 * Get all tests
 * GET /api/tests
 */
export const getTests = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 10;
        const difficulty = req.query.difficulty as string;
        const status = req.query.status as string;
        const search = req.query.search as string;

        const skip = (page - 1) * limit;

        // Build filtering criteria for the list
        const where: any = {};

        if (difficulty && difficulty !== 'ALL') {
            where.difficulty = difficulty;
        }

        const role = (req as any).user?.role;
        const isAdminOrSpecialist = role === 'ADMIN' || role === 'SPECIALIST';

        if (isAdminOrSpecialist) {
            if (status && status !== 'ALL') {
                where.status = status as any;
            }
            // If no status or status === 'ALL', no filter (show all)
        } else {
            // Students see ACTIVE and PENDING (to show Coming Soon label)
            where.status = { in: ['ACTIVE', 'PENDING'] };
        }

        if (search) {
            where.OR = [
                { title: { contains: search, mode: 'insensitive' } },
            ];
        }

        // Parallel execution for list and global stats
        const [filteredTotal, stats, tests] = await Promise.all([
            // 1. Total count for CURRENT filter (pagination)
            prisma.test.count({ where }),

            // 2. Accurate Global Stats (Total, Pending, Active, Locked)
            prisma.test.groupBy({
                by: ['status'],
                _count: {
                    _all: true
                }
            }),

            // 3. Paginated list
            prisma.test.findMany({
                where,
                include: {
                    parts: {
                        // Only show active parts for students
                        where: !isAdminOrSpecialist ? { status: 'ACTIVE' } : undefined,
                        select: {
                            id: true,
                            partNumber: true,
                            partName: true,
                            totalQuestions: true,
                            timeLimit: true,
                            instructions: true,
                            instructionImgUrl: true,
                            audioUrl: true,
                            _count: {
                                select: {
                                    questions: true,
                                },
                            },
                        },
                    },
                },
                orderBy: {
                    createdAt: 'desc',
                },
                skip,
                take: limit,
            })
        ]);

        // Transform groupBy result into a friendly object
        const systemStats = {
            total: 0,
            pending: 0,
            active: 0,
            locked: 0
        };

        stats.forEach(item => {
            const count = item._count._all;
            systemStats.total += count;
            if (item.status === 'PENDING') systemStats.pending = count;
            else if (item.status === 'ACTIVE') systemStats.active = count;
            else if (item.status === 'LOCKED') systemStats.locked = count;
        });

        // Calculate progression for each test based on current user's progress
        const userId = (req as any).user?.id;
        let userProgressMap: Record<string, string[]> = {}; // testId -> completedPartIds

        if (userId) {
            const completedEntries = await prisma.testAttempt.findMany({
                where: { userId },
                select: { partId: true, part: { select: { testId: true } } }
            });


            completedEntries.forEach(entry => {
                const tId = entry.part?.testId;
                const pId = entry.partId;
                if (tId && pId) {
                    if (!userProgressMap[tId]) userProgressMap[tId] = [];
                    if (!userProgressMap[tId].includes(pId)) {
                        userProgressMap[tId].push(pId);
                    }
                }
            });
        }

        const testsWithProgress = tests.map(test => {
            const totalPartsCount = test.parts.length || 7;
            const completedPartsCount = userProgressMap[test.id]?.length || 0;

            // Calculate listeningQuestions and readingQuestions from testType
            const listeningQuestions = (test as any).testType === 'LISTENING' ? (test as any).totalQuestions : 0;
            const readingQuestions = (test as any).testType === 'READING' ? (test as any).totalQuestions : 0;

            return {
                ...test,
                totalParts: totalPartsCount,
                completedParts: completedPartsCount,
                progress: Math.min(100, Math.round((completedPartsCount / totalPartsCount) * 100)),
                listeningQuestions,
                readingQuestions,
            };
        });


        res.status(200).json({
            success: true,
            data: testsWithProgress || [], // For Web Admin Compatibility
            tests: testsWithProgress || [], // For Flutter App Compatibility
            meta: {
                pagination: {
                    total: filteredTotal || 0,
                    page,
                    limit,
                    totalPages: Math.ceil((filteredTotal || 0) / limit),
                },
                stats: systemStats
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get test by ID
 * GET /api/tests/:id
 */
export const getTestById = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const userId = (req as any).user?.id; // Get authenticated user ID

        const role = (req as any).user?.role;
        const isAdminOrSpecialist = role === 'ADMIN' || role === 'SPECIALIST';

        const test = await prisma.test.findUnique({
            where: { id },
            include: {
                parts: {
                    where: !isAdminOrSpecialist ? { status: 'ACTIVE' } : undefined,
                    include: {
                        _count: {
                            select: {
                                questions: true,
                            },
                        },
                    },
                    orderBy: {
                        partNumber: 'asc',
                    },
                },
            },
        });

        if (!test) {
            res.status(404).json({
                success: false,
                message: 'Test not found',
            });
            return;
        }

        // Fetch User Progress if user is logged in
        let partsWithProgress = test.parts.map(part => ({
            ...part,
            userProgress: 0 // Default 0
        }));

        if (userId) {
            const partIds = test.parts.map(p => p.id);
            const progresses = await prisma.testAttempt.findMany({
                where: {
                    userId,
                    partId: { in: partIds }
                },
                orderBy: {
                    createdAt: 'desc' // Latest first
                }
            });

            // Map progress to parts
            partsWithProgress = test.parts.map(part => {
                // Find latest attempt for this part (first one in list)
                const latestAttempt = progresses.find(p => p.partId === part.id);

                let currentProgress = 0;

                if (latestAttempt) {
                    // Use correct percentage if available
                    const total = latestAttempt.totalQuestions || 0;
                    const correct = latestAttempt.correctCount || 0;
                    currentProgress = total > 0 ? (correct / total) * 100 : 0;
                }


                return {
                    ...part,
                    // Use latest progress
                    userProgress: Math.round(currentProgress)
                };
            });
        }

        res.status(200).json({
            success: true,
            test: {
                ...test,
                parts: partsWithProgress
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Create new test
 * POST /api/tests
 */
export const createTest = async (
    req: Request,
    res: Response
): Promise<void> => {
    try {
        console.log('--- Create Test Request ---');
        console.log('Body:', req.body);
        const { title, testType, difficulty, duration, totalQuestions } = req.body;
        const user = (req as any).user;
        const authorId = user?.id;
        const isAdmin = user?.role === 'ADMIN';

        // Validation
        if (!title || !testType || !difficulty) {
            res.status(400).json({
                success: false,
                message: 'Thiếu thông tin bắt buộc: title, testType, hoặc difficulty'
            });
            return;
        }

        const parsedDuration = parseInt(duration);
        const parsedTotalQuestions = parseInt(totalQuestions);

        if (isNaN(parsedDuration) || isNaN(parsedTotalQuestions)) {
            res.status(400).json({
                success: false,
                message: 'Duration và TotalQuestions phải là số hợp lệ'
            });
            return;
        }

        const newTest = await prisma.test.create({
            data: {
                title,
                testType,
                difficulty,
                status: isAdmin ? 'ACTIVE' : 'PENDING' as any,
                duration: parsedDuration,
                totalQuestions: parsedTotalQuestions,
                authorId,
            } as any,
        });

        console.log('Created Test Successfully:', newTest.id);

        res.status(201).json({
            success: true,
            message: 'Tạo đề thi thành công',
            test: newTest
        });

        // Notify admins about new pending test if created by non-admin
        if (!isAdmin) {
            (async () => {
                try {
                    const admins = await prisma.user.findMany({
                        where: { role: 'ADMIN' },
                        select: { id: true }
                    });

                    for (const admin of admins) {
                        await NotificationService.createNotification({
                            userId: admin.id,
                            title: 'Đề thi mới chờ duyệt',
                            content: `Một thành viên vừa tạo đề "${title}". Vui lòng kiểm tra và phê duyệt.`,
                            type: 'TEST_PENDING' as any,
                            relatedId: newTest.id
                        });
                    }
                } catch (err) {
                    console.error('Failed to send admin notification:', err);
                }
            })();
        }
    } catch (error: any) {
        console.error('CRITICAL ERROR in createTest:', error);
        res.status(500).json({
            success: false,
            message: 'Không thể tạo đề thi: ' + (error.message || 'Lỗi hệ thống'),
            error: error
        });
    }
};

/**
 * Update test
 * PATCH /api/tests/:id
 */
export const updateTest = async (
    req: Request,
    res: Response
): Promise<void> => {
    try {
        const { id } = req.params;
        console.log('Update Test Request - ID:', id);
        console.log('Update Test Request - Body:', req.body);

        const user = (req as any).user;
        const isAdmin = user.role === 'ADMIN';
        const { title, testType, difficulty, status, duration, totalQuestions } = req.body;

        const updateData: any = {};
        if (title !== undefined) updateData.title = title;
        if (testType !== undefined) updateData.testType = testType;
        if (difficulty !== undefined) updateData.difficulty = difficulty;
        
        // Only ADMIN can change status
        if (status !== undefined && isAdmin) {
            updateData.status = status;
            if (status === 'ACTIVE') {
                updateData.rejectReason = null;
            }
        } else if (status !== undefined && !isAdmin) {
            console.warn(`User ${user.id} tried to update status to ${status} without ADMIN role.`);
            // Silent refusal of status update for non-admins
        }
        
        if (duration !== undefined) {
            const parsed = parseInt(duration);
            if (!isNaN(parsed)) updateData.duration = parsed;
        }
        
        if (totalQuestions !== undefined) {
            const parsed = parseInt(totalQuestions);
            if (!isNaN(parsed)) updateData.totalQuestions = parsed;
        }

        console.log('Final Update Data for Prisma:', updateData);

        const updatedTest = await prisma.test.update({
            where: { id },
            data: updateData,
        });

        console.log('Prisma Update Result:', updatedTest);

        // Calculate listening/reading for response
        const listeningQuestions = (updatedTest as any).testType === 'LISTENING' ? (updatedTest as any).totalQuestions : 0;
        const readingQuestions = (updatedTest as any).testType === 'READING' ? (updatedTest as any).totalQuestions : 0;

        // Gửi thông báo toàn hệ thống nếu đề thi chuyển sang ACTIVE
        if (isAdmin && status === 'ACTIVE') {
            (async () => {
                try {
                    await NotificationService.broadcastNotification({
                        title: '🚀 Đề thi mới cực hot!',
                        content: `Hệ thống vừa cập nhật đề thi "${updatedTest.title}". Hãy vào luyện tập ngay để bứt phá điểm số nhé!`,
                        type: 'NEW_TEST_OPENED' as any,
                        relatedId: updatedTest.id
                    });
                } catch (err) {
                    console.error('Failed to broadcast notification on update:', err);
                }
            })();
        }

        res.status(200).json({
            success: true,
            message: 'Test updated successfully',
            test: {
                ...updatedTest,
                listeningQuestions,
                readingQuestions,
            },
        });
    } catch (error: any) {
        console.error('Update Test Error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Error updating test',
            error: error
        });
    }
};

/**
 * Delete test
 * DELETE /api/tests/:id
 */
export const deleteTest = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const user = (req as any).user;

        if (user.role !== 'ADMIN') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN mới có quyền xóa vĩnh viễn đề thi.',
            });
            return;
        }

        // 1. Check if test exists
        const test = await prisma.test.findUnique({
            where: { id },
            include: { parts: { select: { id: true } } }
        });

        if (!test) {
            res.status(404).json({
                success: false,
                message: 'Không tìm thấy đề thi để xóa.',
            });
            return;
        }

        const partIds = test.parts.map(p => p.id);

        // 2. Execute cascading delete in a transaction
        await prisma.$transaction([
            // Delete all questions belonging to parts of this test
            ...(partIds.length > 0 ? [
                (prisma.question as any).deleteMany({
                    where: { partId: { in: partIds } }
                })
            ] : []),
            // Delete all parts of this test
            prisma.part.deleteMany({
                where: { testId: id }
            }),
            // Delete the test itself
            prisma.test.delete({
                where: { id }
            })
        ]);

        res.status(200).json({
            success: true,
            message: `Đã xóa vĩnh viễn đề thi "${test.title}" cùng toàn bộ dữ liệu liên quan thành công.`,
        });
    } catch (error) {
        console.error('Error deleting test:', error);
        next(error);
    }
};

/**
 * Approve a test (ADMIN only)
 * PATCH /api/tests/:id/approve
 */
export const approveTest = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const user = (req as any).user;

        if (user.role !== 'ADMIN') {
            res.status(403).json({
                success: false,
                message: 'Chào bạn, chỉ ADMIN mới có quyền duyệt bài. Vui lòng liên hệ quản trị viên.',
            });
            return;
        }

        const updatedTest = await prisma.test.update({
            where: { id },
            data: { 
                status: 'ACTIVE' as any,
                rejectReason: null 
            }
        } as any);

        res.status(200).json({
            success: true,
            message: 'Đã duyệt bài thành công! Bài thi đã được xuất bản lên App.',
            test: updatedTest,
        });

        // NOTIFY AUTHOR (Async)
        (async () => {
            try {
                if (updatedTest.authorId) {
                    await NotificationService.createNotification({
                        userId: updatedTest.authorId,
                        title: 'Đề thi đã được duyệt',
                        content: `Chúc mừng! Đề thi "${updatedTest.title}" của bạn đã được phê duyệt và xuất bản.`,
                        type: 'TEST_APPROVED' as any,
                        relatedId: updatedTest.id
                    });
                }
            } catch (err) {
                console.error('Failed to notify author:', err);
            }
        })();

        // BROADCAST TO ALL STUDENTS
        (async () => {
            try {
                await NotificationService.broadcastNotification({
                    title: '🚀 Đề thi mới đã sẵn sàng!',
                    content: `Đề thi "${updatedTest.title}" vừa được xuất bản. Hãy vào thử sức ngay nào!`,
                    type: 'NEW_TEST_OPENED' as any,
                    relatedId: updatedTest.id
                });
            } catch (err) {
                console.error('Failed to broadcast notification on approve:', err);
            }
        })();
    } catch (error) {
        next(error);
    }
};

/**
 * Approve a test AND all its Parts and Questions in a single Transaction (ADMIN only)
 * PATCH /api/tests/:id/approve-full
 */
export const approveTestFull = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const user = (req as any).user;

        // Double-check role (also enforced by route middleware)
        if (user.role !== 'ADMIN') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN mới có quyền duyệt toàn bộ đề thi.',
            });
            return;
        }

        // Verify test exists
        const test = await prisma.test.findUnique({ where: { id } });
        if (!test) {
            res.status(404).json({ success: false, message: 'Không tìm thấy đề thi.' });
            return;
        }

        // Pre-fetch part IDs so we can use them inside the transaction
        const parts = await prisma.part.findMany({
            where: { testId: id },
            select: { id: true },
        });
        const partIds = parts.map(p => p.id);

        // Execute as a single atomic transaction
        await prisma.$transaction([
            // 1. Approve the Test
            prisma.test.update({
                where: { id },
                data: { 
                    status: 'ACTIVE' as any,
                    rejectReason: null
                },
            } as any),
            // 2. Approve all Parts of this Test
            prisma.part.updateMany({
                where: { testId: id },
                data: { 
                    status: 'ACTIVE' as any,
                    rejectReason: null 
                } as any,
            }),
            // 3. Approve all Questions inside those Parts
            ...(partIds.length > 0
                ? [(prisma.question as any).updateMany({
                    where: { partId: { in: partIds } },
                    data: { status: 'ACTIVE' as any },
                })]
                : []),
        ]);

        res.status(200).json({
            success: true,
            message: `Đã duyệt và xuất bản toàn bộ đề thi "${test.title}" thành công! Học viên có thể làm bài ngay bây giờ.`,
        });

        // NOTIFY AUTHOR (Async)
        (async () => {
            try {
                if (test.authorId) {
                    await NotificationService.createNotification({
                        userId: test.authorId,
                        title: 'Đề thi đã được duyệt (Full)',
                        content: `Đề thi "${test.title}" và toàn bộ các phần đã được Admin duyệt thành công.`,
                        type: 'TEST_APPROVED' as any,
                        relatedId: test.id
                    });
                }
            } catch (err) {
                console.error('Failed to notify author:', err);
            }
        })();

        // BROADCAST TO ALL STUDENTS
        (async () => {
            try {
                await NotificationService.broadcastNotification({
                    title: '🚀 Siêu phẩm đề thi mới!',
                    content: `Toàn bộ đề thi "${test.title}" đã được công khai. Cơ hội vàng để ôn luyện TOEIC đây rồi!`,
                    type: 'NEW_TEST_OPENED' as any,
                    relatedId: test.id
                });
            } catch (err) {
                console.error('Failed to broadcast notification on full approve:', err);
            }
        })();
    } catch (error) {
        next(error);
    }
};

/**
 * Toggle test status (ACTIVE <-> LOCKED)
 * PATCH /api/tests/:id/toggle-lock
 */
export const toggleTestLock = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const user = (req as any).user;

        if (user.role !== 'ADMIN') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN mới có quyền thực hiện thao tác Khóa/Mở khóa bài thi.',
            });
            return;
        }

        const test = await prisma.test.findUnique({
            where: { id },
        });

        if (!test) {
            res.status(404).json({ success: false, message: 'Test không tồn tại' });
            return;
        }

        if ((test.status as any) === 'PENDING') {
            res.status(400).json({ 
                success: false, 
                message: 'Bài thi đang chờ duyệt, vui lòng duyệt trước khi thay đổi trạng thái khóa.' 
            });
            return;
        }

        const newStatus = test.status === 'LOCKED' ? 'ACTIVE' : 'LOCKED';

        // Pre-fetch part IDs so we can cascade the status update to questions
        const parts = await prisma.part.findMany({
            where: { testId: id },
            select: { id: true },
        });
        const partIds = parts.map(p => p.id);

        // Execute as a single atomic transaction
        const [updatedTest] = await prisma.$transaction([
            // 1. Update the Test status
            prisma.test.update({
                where: { id },
                data: { status: newStatus as any },
            }),
            // 2. Cascade status to all Parts of this Test
            prisma.part.updateMany({
                where: { testId: id },
                data: { status: newStatus as any } as any,
            }),
            // 3. Cascade status to all Questions inside those Parts
            ...(partIds.length > 0
                ? [(prisma.question as any).updateMany({
                    where: { partId: { in: partIds } },
                    data: { status: newStatus as any } as any,
                })]
                : []),
        ]);

        res.status(200).json({
            success: true,
            message: `Đã ${newStatus === 'ACTIVE' ? 'mở khóa' : 'khóa'} bài thi thành công`,
            test: updatedTest,
        });

        // Gửi thông báo nếu MỞ KHÓA (chuyển sang ACTIVE)
        if (newStatus === 'ACTIVE') {
            (async () => {
                try {
                    await NotificationService.broadcastNotification({
                        title: '🔔 Đề thi đã mở lại!',
                        content: `Đề thi "${updatedTest.title}" đã có thể truy cập trở lại. Đừng bỏ lỡ cơ hội luyện tập nhé!`,
                        type: 'NEW_TEST_OPENED' as any,
                        relatedId: updatedTest.id
                    });
                } catch (err) {
                    console.error('Failed to broadcast notification on toggle lock:', err);
                }
            })();
        }
    } catch (error) {
        next(error);
    }
};

/**
 * Reject a test (ADMIN only)
 * PATCH /api/tests/:id/reject
 */
export const rejectTest = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const { rejectReason } = req.body;
        const user = (req as any).user;

        if (user.role !== 'ADMIN') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN mới có quyền từ chối bài thi.',
            });
            return;
        }

        if (!rejectReason) {
            res.status(400).json({
                success: false,
                message: 'Vui lòng cung cấp lý do từ chối.',
            });
            return;
        }

        const updatedTest = await prisma.test.update({
            where: { id },
            data: {
                status: 'REJECTED' as any,
                rejectReason,
            }
        } as any);

        res.status(200).json({
            success: true,
            message: 'Đã từ chối bài thi thành công. Thông báo đã được gửi đến chuyên viên.',
            test: updatedTest,
        });

        // NOTIFY AUTHOR (Async)
        (async () => {
            try {
                if (updatedTest.authorId) {
                    await NotificationService.createNotification({
                        userId: updatedTest.authorId,
                        title: 'Đề thi bị từ chối',
                        content: `Đề thi "${updatedTest.title}" cần được chỉnh sửa. Lý do: ${rejectReason}`,
                        type: 'TEST_REJECTED' as any,
                        relatedId: updatedTest.id
                    });
                }
            } catch (err) {
                console.error('Failed to notify author:', err);
            }
        })();
    } catch (error) {
        next(error);
    }
};
