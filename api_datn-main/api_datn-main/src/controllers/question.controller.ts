import { Request, Response, NextFunction } from 'express';
import * as path from 'path';
import * as fs from 'fs';
import { validateAndStandardizePassageData } from '../utils/passageValidator';
import { Difficulty } from '@prisma/client';
import { prisma } from '../config/prisma';

console.log('RUNTIME Difficulty Enum:', Object.values(Difficulty));

/**
 * Helper to sanitize and map Difficulty values
 */
const sanitizeDifficulty = (level: string | null | undefined): Difficulty | null => {
    if (!level) return null;
    
    const upperLevel = level.toUpperCase().trim();
    
    // Map common variants to enum values
    const mapping: Record<string, Difficulty> = {
        'A1': Difficulty.A1_A2,
        'A2': Difficulty.A1_A2,
        'A1_A2': Difficulty.A1_A2,
        'B1': Difficulty.B1_B2,
        'B2': Difficulty.B1_B2,
        'B1_B2': Difficulty.B1_B2,
        'B2_C1': Difficulty.B2_C1,
        'C1': Difficulty.C1,
        'C2': Difficulty.C2,
        'EASY': Difficulty.EASY,
        'MEDIUM': Difficulty.MEDIUM,
        'HARD': Difficulty.HARD
    };

    return mapping[upperLevel] || null;
};

/**
 * Get all questions by Part ID
 * GET /api/parts/:partId/questions
 */
export const getQuestionsByPartId = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        let { partId } = req.params;
        if (partId) partId = partId.trim().replace(/[^a-f0-9-]/gi, '');
        const { level, status } = req.query;
        const role = (req as any).user?.role;
        const isAdminOrSpecialist = role === 'ADMIN' || role === 'SPECIALIST';

        const where: any = { partId };
        
        // Filter by status (Admin/Specialist can see all, students only ACTIVE)
        if (isAdminOrSpecialist) {
            if (status && status !== 'ALL') {
                where.status = status;
            }
        } else {
            where.status = 'ACTIVE';
        }

        // Filter by level if provided
        if (level && level !== 'ALL') {
            where.level = level;
        }

        const questions = await (prisma.question as any).findMany({
            where,
            orderBy: {
                questionNumber: 'asc',
            },
        });

        res.status(200).json({
            success: true,
            questions,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Create a single question manually
 * POST /api/parts/:partId/questions
 */
export const createQuestion = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        let { partId } = req.params;
        if (partId) partId = partId.trim().replace(/[^a-f0-9-]/gi, '');
        const {
            questionNumber,
            questionText,
            optionA,
            optionB,
            optionC,
            optionD,
            correctAnswer,
            explanation,
            analysis, // ✅ New
            evidence, // ✅ New
            questionTranslation, // ✅ New
            optionTranslations, // ✅ New
            keyVocabulary, // ✅ New
            level, // ✅ New
            audioUrl,
            imageUrl, // Add imageUrl
            transcript,
            passage,
            passageImageUrl,
            questionScanUrl,
            passageTranslationData,
            topic_tag,
        } = req.body;

        // Get part info to validate question number range
        const part = await prisma.part.findUnique({
            where: { id: partId },
        });

        if (!part) {
            res.status(404).json({
                success: false,
                message: 'Part không tồn tại',
            });
            return;
        }

        // Validate question number range based on part number
        if (!questionNumber) {
            res.status(400).json({
                success: false,
                message: 'Số câu hỏi là bắt buộc',
            });
            return;
        }
        const qNum = parseInt(questionNumber);
        if (isNaN(qNum)) {
            res.status(400).json({
                success: false,
                message: 'Số câu hỏi phải là một số hợp lệ',
            });
            return;
        }
        const partRanges: Record<number, { min: number; max: number }> = {
            1: { min: 1, max: 6 },
            2: { min: 7, max: 31 },
            3: { min: 32, max: 70 },
            4: { min: 71, max: 100 },
            5: { min: 101, max: 130 },
            6: { min: 131, max: 146 },
            7: { min: 147, max: 200 },
        };

        const range = partRanges[part.partNumber];
        if (range && (qNum < range.min || qNum > range.max)) {
            console.log(`[CreateQuestion] Range Validation Failed: qNum=${qNum}, part=${part.partNumber}, expected=${range.min}-${range.max}`);
            res.status(400).json({
                success: false,
                message: `Part ${part.partNumber} chỉ chấp nhận câu hỏi từ ${range.min} đến ${range.max}`,
            });
            return;
        }

        // Check if question number already exists in the ENTIRE TEST
        // We need to find if any question in any part of this test has this number
        const existingQuestionInTest = await prisma.question.findFirst({
            where: {
                part: {
                    testId: part.testId
                },
                questionNumber: qNum
            },
            include: {
                part: true
            }
        });

        if (existingQuestionInTest) {
            console.log(`[CreateQuestion] Duplicate Check Failed: questionNumber ${questionNumber} already exists in Part ${existingQuestionInTest.part.partNumber}`);
            res.status(400).json({
                success: false,
                message: `Câu hỏi số ${questionNumber} đã tồn tại trong Part ${existingQuestionInTest.part.partNumber} của bài test này.`,
            });
            return;
        }

        const newQuestion = await (prisma.question as any).create({
            data: {
                partId,
                questionNumber: qNum,
                questionText,
                optionA,
                optionB,
                optionC,
                optionD,
                correctAnswer,
                explanation,
                analysis, // ✅ New
                evidence, // ✅ New
                questionTranslation, // ✅ New
                optionTranslations, // ✅ New
                keyVocabulary, // ✅ New
                level, // ✅ New

                audioUrl,
                imageUrl, // Add imageUrl
                transcript,
                passage,
                passageImageUrl,
                questionScanUrl,
                passageTranslationData,
                topic_tag,
                status: part.status as any // Inherit status from Part (if ACTIVE, question becomes ACTIVE)
            },
        });

        res.status(201).json({
            success: true,
            message: 'Tạo câu hỏi thành công',
            question: newQuestion,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Update a question
 * PATCH /api/questions/:id
 */
export const updateQuestion = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const {
            questionNumber,
            questionText,
            optionA,
            optionB,
            optionC,
            optionD,
            correctAnswer,
            explanation,
            analysis, // ✅ New
            evidence, // ✅ New
            questionTranslation, // ✅ New
            optionTranslations, // ✅ New
            keyVocabulary, // ✅ New
            level, // ✅ New
            passage,
            audioUrl,
            imageUrl,
            transcript,
            passageImageUrl, // ✅ New: dedicated passage image URLs
            questionScanUrl, // ✅ New: dedicated question scan URLs
            passageTranslationData,
            topic_tag,
        } = req.body;

        // --- Range Validation ---
        if (questionNumber) {
            const qNum = parseInt(questionNumber);
            const question = await prisma.question.findUnique({
                where: { id },
                include: { part: true }
            });
            
            if (question) {
                const partRanges: Record<number, { min: number; max: number }> = {
                    1: { min: 1, max: 6 },
                    2: { min: 7, max: 31 },
                    3: { min: 32, max: 70 },
                    4: { min: 71, max: 100 },
                    5: { min: 101, max: 130 },
                    6: { min: 131, max: 146 },
                    7: { min: 147, max: 200 },
                };

                const range = partRanges[question.part.partNumber];
                if (range && (qNum < range.min || qNum > range.max)) {
                    res.status(400).json({
                        success: false,
                        message: `Part ${question.part.partNumber} chỉ chấp nhận câu hỏi từ ${range.min} đến ${range.max}`,
                    });
                    return;
                }
            }
        }

        // Validate and Standardize
        let sanitizedData: string | null = null;
        if (passageTranslationData) {
            sanitizedData = validateAndStandardizePassageData(passageTranslationData);
        }

        const updatedQuestion = await (prisma.question as any).update({
            where: { id },
            data: {
                questionNumber: questionNumber ? parseInt(questionNumber) : undefined,
                questionText,
                optionA,
                optionB,
                optionC,
                optionD,
                correctAnswer,
                explanation,
                analysis, // ✅ New
                evidence, // ✅ New
                questionTranslation, // ✅ New
                optionTranslations, // ✅ New
                level: sanitizeDifficulty(level), // ✅ Sanitized
                passage,
                audioUrl,
                imageUrl,
                transcript,
                passageImageUrl,
                questionScanUrl,
                passageTranslationData: sanitizedData,
                topic_tag,
                // Safety check: Don't overwrite with empty string or empty array if provided as such
                ...(keyVocabulary !== undefined && keyVocabulary !== null && keyVocabulary !== '[]' && keyVocabulary !== '' 
                    ? { keyVocabulary } 
                    : {}),
            },
        });

        // Removed redundant updateMany sync. The frontend now handles patching all questions in a group explicitly.
        
        res.status(200).json({
            success: true,
            message: 'Cập nhật câu hỏi thành công',
            question: updatedQuestion,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete a question
 * DELETE /api/questions/:id
 */
export const deleteQuestion = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { id } = req.params;
        const user = (req as any).user;

        if (user.role !== 'ADMIN' && user.role !== 'SPECIALIST') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN hoặc Chuyên viên mới có quyền xóa câu hỏi.',
            });
            return;
        }
        // Get question to extract image/audio URLs before deleting
        const question = await prisma.question.findUnique({
            where: { id },
        });

        if (!question) {
            res.status(404).json({
                success: false,
                message: 'Câu hỏi không tồn tại',
            });
            return;
        }

        // Delete from database
        await (prisma.question as any).delete({ where: { id } });

        // Cleanup Cloudinary assets (Async)
        if (question) {
            import('../config/cloudinary.config').then(({ cleanupCloudinaryAssets }) => {
                cleanupCloudinaryAssets([
                    question.imageUrl,
                    question.audioUrl,
                    question.passageImageUrl,
                    question.questionScanUrl
                ].filter((url): url is string => !!url));
            }).catch(err => console.error('Cloudinary cleanup error:', err));
        }

        res.status(200).json({
            success: true,
            message: 'Xóa câu hỏi thành công',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete all questions in a Part
 * DELETE /api/parts/:partId/questions
 */
export const deleteAllQuestionsByPartId = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        let { partId } = req.params;
        if (partId) partId = partId.trim().replace(/[^a-f0-9-]/gi, '');
        const user = (req as any).user;

        if (user.role !== 'ADMIN' && user.role !== 'SPECIALIST') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN hoặc Chuyên viên mới có quyền xóa nội dung này.',
            });
            return;
        }

        // Get all questions first to cleanup assets
        const questions = await prisma.question.findMany({
            where: { partId },
            select: {
                imageUrl: true,
                audioUrl: true,
                passageImageUrl: true,
                questionScanUrl: true
            }
        });

        const result = await prisma.question.deleteMany({
            where: { partId },
        });

        // Cleanup Cloudinary assets (Batch)
        import('../config/cloudinary.config').then(({ cleanupCloudinaryAssets }) => {
            const allUrls: string[] = [];
            questions.forEach(q => {
                if (q.imageUrl) allUrls.push(q.imageUrl);
                if (q.audioUrl) allUrls.push(q.audioUrl);
                if (q.passageImageUrl) allUrls.push(q.passageImageUrl);
                if (q.questionScanUrl) allUrls.push(q.questionScanUrl);
            });
            if (allUrls.length > 0) cleanupCloudinaryAssets(allUrls);
        }).catch(err => console.error('Cloudinary bulk cleanup error:', err));

        res.status(200).json({
            success: true,
            message: `Đã xóa ${result.count} câu hỏi`,
            count: result.count,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Bulk delete questions by IDs
 * DELETE /api/questions/bulk
 */
export const bulkDeleteQuestions = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const user = (req as any).user;

        if (user.role !== 'ADMIN' && user.role !== 'SPECIALIST') {
            res.status(403).json({
                success: false,
                message: 'Chỉ ADMIN hoặc Chuyên viên mới có quyền xóa hàng loạt câu hỏi.',
            });
            return;
        }
        const { questionIds } = req.body;

        if (!Array.isArray(questionIds) || questionIds.length === 0) {
            res.status(400).json({
                success: false,
                message: 'Vui lòng cung cấp danh sách ID câu hỏi',
            });
            return;
        }

        // Get questions first to cleanup assets
        const questions = await prisma.question.findMany({
            where: {
                id: { in: questionIds }
            },
            select: {
                imageUrl: true,
                audioUrl: true,
                passageImageUrl: true,
                questionScanUrl: true
            }
        });

        const result = await prisma.question.deleteMany({
            where: {
                id: {
                    in: questionIds,
                },
            },
        });

        // Cleanup Cloudinary assets
        const { cleanupCloudinaryAssets } = await import('../config/cloudinary.config');
        questions.forEach(q => {
            cleanupCloudinaryAssets(q.imageUrl);
            cleanupCloudinaryAssets(q.audioUrl);
            cleanupCloudinaryAssets(q.passageImageUrl);
            cleanupCloudinaryAssets(q.questionScanUrl);
        });

        res.status(200).json({
            success: true,
            message: `Đã xóa ${result.count} câu hỏi`,
            count: result.count,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Create batch questions (Part 6)
 * POST /api/parts/:partId/questions/batch
 */
export const createBatchQuestions = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        let { partId } = req.params;
        if (partId) partId = partId.trim().replace(/[^a-f0-9-]/gi, '');
        const { passage, passageImageUrl, questionScanUrl, passageTranslationData, questions, audioUrl, transcript, mode } = req.body; // mode: 'append' | 'replace'

        // Validate and Standardize
        let sanitizedData: string | null = null;
        if (passageTranslationData) {
            sanitizedData = validateAndStandardizePassageData(passageTranslationData);
        }

        if (!Array.isArray(questions) || questions.length === 0) {
            res.status(400).json({
                success: false,
                message: 'Danh sách câu hỏi không được để trống',
            });
            return;
        }

        // Get part info for validation
        const part = await prisma.part.findUnique({
            where: { id: partId },
        });

        if (!part) {
            res.status(404).json({
                success: false,
                message: 'Part không tồn tại',
            });
            return;
        }

        // Validate passage requirement based on Part number
        // ✅ Nới lỏng kiểm tra: Chấp nhận nếu có text 'passage' HOẶC có ảnh 'passageImageUrl' (chuỗi không rỗng)
        const firstQuestionPassageImage = questions[0]?.passageImageUrl;
        const hasPassage = (passage && passage.trim().length > 0) || (firstQuestionPassageImage && firstQuestionPassageImage.trim().length > 0);
        
        console.log(`[Batch Save] Part: ${part.partNumber}, hasPassageText: ${!!passage}, hasPassageImage: ${!!firstQuestionPassageImage}`);

        if ((part.partNumber === 6 || part.partNumber === 7) && !hasPassage) {
            res.status(400).json({
                success: false,
                message: 'Đoạn văn là bắt buộc đối với Part 6 và 7 (Vui lòng nhập văn bản hoặc upload ảnh đoạn văn)',
            });
            return;
        }

        // Handle replace mode for Part 5: delete all existing questions first
        if (mode === 'replace' && part.partNumber === 5) {
            await prisma.question.deleteMany({
                where: { partId },
            });
        }

        // For append mode, check if adding would exceed limit
        if (mode === 'append' && part.partNumber === 5) {
            const existingCount = await prisma.question.count({
                where: { partId },
            });
            const totalAfterImport = existingCount + questions.length;
            if (totalAfterImport > 30) {
                res.status(400).json({
                    success: false,
                    message: `Không thể import. Tổng số câu sẽ vượt quá 30 (${existingCount} + ${questions.length} = ${totalAfterImport})`,
                });
                return;
            }
        }

        // Get last question number
        const lastQuestion = await prisma.question.findFirst({
            where: { partId },
            orderBy: { questionNumber: 'desc' },
        });

        // For Part 6/7, use standard logic. For Part 5, check start number
        let startQuestionNumber = lastQuestion ? lastQuestion.questionNumber + 1 : (part.partNumber === 6 ? 131 : part.partNumber === 5 ? 101 : 1);

        // --- Removed same-part duplicate check to allow for batch updates (Upsert will handle this) ---
        // Duplicate check across different parts of the same test is still performed below.

        // Prepare data
        const questionsToInsert = questions.map((q: any, index: number) => {
            const qNum = q.questionNumber ? q.questionNumber : (startQuestionNumber + index);

            // Basic validation
            if (!q.correctAnswer) {
                throw new Error(`Câu ${qNum} thiếu đáp án đúng.`);
            }
            if (!q.optionA || !q.optionB || !q.optionC || !q.optionD) {
                throw new Error(`Câu ${qNum} thiếu một hoặc nhiều lựa chọn (A-D).`);
            }

            // Validate question number range based on part number
            const partRanges: Record<number, { min: number; max: number }> = {
                1: { min: 1, max: 6 },
                2: { min: 7, max: 31 },
                3: { min: 32, max: 70 },
                4: { min: 71, max: 100 },
                5: { min: 101, max: 130 },
                6: { min: 131, max: 146 },
                7: { min: 147, max: 200 },
            };

            const range = partRanges[part.partNumber];
            if (range && (qNum < range.min || qNum > range.max)) {
                throw new Error(`Part ${part.partNumber} chỉ chấp nhận câu hỏi từ ${range.min}-${range.max}. Câu ${qNum} không hợp lệ.`);
            }

            return {
                partId,
                questionNumber: qNum,
                questionText: q.questionText,
                optionA: q.optionA,
                optionB: q.optionB,
                optionC: q.optionC,
                optionD: q.optionD,
                correctAnswer: q.correctAnswer,
                explanation: q.explanation,
                analysis: q.analysis || null, // ✅ New
                evidence: q.evidence || null, // ✅ New
                questionTranslation: q.questionTranslation || null, // ✅ New
                optionTranslations: q.optionTranslations || null, // ✅ New
                keyVocabulary: q.keyVocabulary || null, // ✅ New
                level: sanitizeDifficulty(q.level), // ✅ Sanitized
                audioUrl: audioUrl || q.audioUrl,
                passage: q.passage || passage, // ✅ Allow individual passages
                passageImageUrl: q.passageImageUrl || passageImageUrl || null,
                questionScanUrl: q.questionScanUrl || questionScanUrl || null,
                passageTranslationData: q.passageTranslationData || sanitizedData || null,
                topic_tag: q.topic_tag || null,
                transcript: transcript || q.transcript,
                imageUrl: q.imageUrl || null,
                status: part.status as any // Inherit status from Part
            };
        });

        // Check for duplicate question numbers in ENTIRE TEST
        const questionNumbers = questionsToInsert.map(q => q.questionNumber);

        const existingQuestionsInTest = await prisma.question.findMany({
            where: {
                part: { testId: part.testId },
                questionNumber: { in: questionNumbers }
            },
            select: {
                questionNumber: true,
                partId: true,
                part: {
                    select: { partNumber: true }
                }
            }
        });

        // 6. Check for cross-part duplicates
        const crossPartDuplicates = existingQuestionsInTest.filter(q => q.partId !== partId);
        
        if (mode !== 'replace' && crossPartDuplicates.length > 0) {
            const duplicatesInfo = crossPartDuplicates.map(q => `${q.questionNumber} (Part ${q.part.partNumber})`).join(', ');
            res.status(400).json({
                success: false,
                message: `Các câu hỏi sau đã tồn tại ở Part khác: ${duplicatesInfo}. Vui lòng kiểm tra lại số câu!`,
            });
            return;
        }

        // Deep Diagnostic
        console.log('--- DIAGNOSTIC START ---');
        console.log('Difficulty Enum Runtime:', Object.values(Difficulty));
        console.log('First Question Data:', JSON.stringify(questionsToInsert[0], null, 2));
        console.log('--- DIAGNOSTIC END ---');

        // 7. Perform Upsert (Create or Update) for each question
        const results = await prisma.$transaction(
            questionsToInsert.map((qData) => {
                const { questionNumber, ...data } = qData;
                return prisma.question.upsert({
                    where: {
                        partId_questionNumber: {
                            partId,
                            questionNumber,
                        }
                    },
                    update: data,
                    create: {
                        ...data,
                        partId,
                        questionNumber,
                    }
                });
            })
        );

        res.status(201).json({
            success: true,
            message: `Đã xử lý thành công ${results.length} câu hỏi (Tạo mới/Cập nhật).`,
            count: results.length,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Import questions from Excel (Part 5 or Part 6)
 * POST /api/parts/:partId/questions/import
 */
export const importQuestions = async (
    req: Request,
    res: Response
): Promise<void> => {
    try {
        const { partId } = req.params;
        const mode = req.body.mode || 'append'; // Default to append mode
        console.log('Start Import for Part:', partId, 'Mode:', mode);

        if (!req.file) {
            console.log('No file received');
            res.status(400).json({
                success: false,
                message: 'Vui lòng upload file Excel',
            });
            return;
        }

        console.log('File received:', req.file.originalname, req.file.size);

        // Get Part info to determine which parser to use
        const part = await prisma.part.findUnique({
            where: { id: partId },
        });

        if (!part) {
            res.status(404).json({
                success: false,
                message: 'Part không tồn tại',
            });
            return;
        }

        // Use ExcelParser to parse and validate
        const { ExcelParser } = await import('../utils/excelParser');

        // Choose parser based on Part number
        let questions: any[];
        if (part.partNumber >= 1 && part.partNumber <= 4) {
            questions = ExcelParser.parseListeningTemplate(req.file.buffer, part.partNumber);
        } else if (part.partNumber === 5) {
            questions = ExcelParser.parsePart5Template(req.file.buffer);
        } else if (part.partNumber === 6) {
            questions = ExcelParser.parsePart6Template(req.file.buffer);
        } else if (part.partNumber === 7) {
            questions = ExcelParser.parsePart7Template(req.file.buffer);
        } else {
            res.status(400).json({
                success: false,
                message: `Import chưa được hỗ trợ cho Part ${part.partNumber}`,
            });
            return;
        }

        console.log(`Parsed ${questions.length} valid questions`);

        // Handle replace mode: delete all existing questions first
        if (mode === 'replace') {
            const deletedCount = await prisma.question.deleteMany({
                where: { partId },
            });
            console.log(`Deleted ${deletedCount.count} existing questions`);
        }

        // SMART IMPORT LOGIC: Fill in only missing questions
        // 1. Get all existing question numbers for this ENTIRE TEST
        // (If replace mode, we already deleted questions in THIS part, so we get questions from OTHER parts)
        const existingQuestions = await prisma.question.findMany({
            where: {
                part: {
                    testId: part.testId
                }
            },
            select: { questionNumber: true },
        });
        const existingSet = new Set(existingQuestions.map(q => q.questionNumber));

        // 2. Check if part is already full (only for append mode)
        if (mode === 'append') {
            const maxCounts: Record<number, number> = { 1: 6, 2: 25, 3: 39, 4: 30, 5: 30, 6: 16, 7: 54 };
            const maxQuestions = maxCounts[part.partNumber];
            if (maxQuestions && existingQuestions.length >= maxQuestions) {
                res.status(400).json({
                    success: false,
                    message: `Part ${part.partNumber} đã đủ ${maxQuestions} câu hỏi. Vui lòng sử dụng chế độ "Ghi đè" hoặc xóa câu hỏi cũ trước.`,
                });
                return;
            }
        }

        // 3. Prepare data, skipping existing numbers and validating ranges
        const questionsToInsert: any[] = [];
        const invalidQuestions: number[] = [];

        questions.forEach((q) => {
            // Use questionNumber from Excel if available
            const contentNumber = (q as any).questionNumber;

            // Validate question number range based on part number
            const partRanges: Record<number, { min: number; max: number }> = {
                1: { min: 1, max: 6 },
                2: { min: 7, max: 31 },
                3: { min: 32, max: 70 },
                4: { min: 71, max: 100 },
                5: { min: 101, max: 130 },
                6: { min: 131, max: 146 },
                7: { min: 147, max: 200 },
            };

            const range = partRanges[part.partNumber];
            if (range && (contentNumber < range.min || contentNumber > range.max)) {
                invalidQuestions.push(contentNumber);
                return; // Skip this question
            }

            if (!existingSet.has(contentNumber)) {
                questionsToInsert.push({
                    partId,
                    questionNumber: contentNumber,
                    passage: (q as any).passage || null,
                    passageTitle: (q as any).passageTitle || null,
                    questionText: q.questionText,
                    optionA: q.optionA,
                    optionB: q.optionB,
                    optionC: q.optionC,
                    optionD: q.optionD || null,
                    correctAnswer: q.correctAnswer,
                    explanation: q.explanation || null,
                    transcript: (q as any).transcript || null,
                    level: (q as any).level || null,
                    status: 'PENDING' as any // Default to PENDING for imported questions
                });
            }
        });

        // Check if there are invalid question numbers
        if (invalidQuestions.length > 0) {
            const rangeMsg = part.partNumber === 5
                ? 'Part 5 chỉ chấp nhận câu hỏi từ 101-130'
                : 'Part 6 chỉ chấp nhận câu hỏi từ 131-146';
            res.status(400).json({
                success: false,
                message: `${rangeMsg}. Các câu không hợp lệ: ${invalidQuestions.join(', ')}`,
            });
            return;
        }

        console.log(`Smart Import: Found ${questionsToInsert.length} missing questions to insert.`);

        if (questionsToInsert.length > 0) {
            await prisma.question.createMany({
                data: questionsToInsert,
            });
        }

        const modeMessage = mode === 'replace'
            ? `Đã thay thế toàn bộ bằng ${questionsToInsert.length} câu hỏi mới`
            : `Đã import thành công ${questionsToInsert.length} câu hỏi`;

        res.status(201).json({
            success: true,
            message: modeMessage,
            count: questionsToInsert.length,
        });

    } catch (error: any) {
        console.error('Import error:', error);
        res.status(400).json({
            success: false,
            message: error.message || 'Lỗi khi import file Excel',
        });
    }
};

/**
 * Download Excel Template
 * GET /api/questions/template?partNumber=5 or 6
 */
export const downloadTemplate = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const partNumber = parseInt(req.query.partNumber as string) || 5; // Default to Part 5
        console.log('📥 Download template request - partNumber:', partNumber, 'query:', req.query);

        let templatePath: string;
        let fileName: string;

        if (partNumber === 5) {
            templatePath = path.join(__dirname, '..', '..', '..', 'toeic_practice_admin', 'public', 'templates', 'part5_template.xlsx');
            fileName = 'Part5_Template.xlsx';
        } else if (partNumber === 6) {
            templatePath = path.join(__dirname, '..', '..', '..', 'toeic_practice_admin', 'public', 'templates', 'part6_template.xlsx');
            fileName = 'Part6_Template.xlsx';
        } else {
            res.status(400).json({
                success: false,
                message: `Template chưa được hỗ trợ cho Part ${partNumber}`,
            });
            return;
        }

        console.log('📂 Template path:', templatePath);
        console.log('📄 File name:', fileName);

        // Check if file exists
        if (!fs.existsSync(templatePath)) {
            console.log('❌ File does not exist at path:', templatePath);
            res.status(404).json({
                success: false,
                message: 'Template file không tồn tại',
            });
            return;
        }

        // Send file
        res.download(templatePath, fileName, (err) => {
            if (err) {
                console.error('Error downloading template:', err);
                next(err);
            }
        });
    } catch (error) {
        next(error);
    }
};



/**
 * Approve a question (ADMIN only)
 * PATCH /api/questions/:id/approve
 */
export const approveQuestion = async (
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
                message: 'Chào bạn, chỉ ADMIN mới có quyền duyệt câu hỏi. Vui lòng liên hệ quản trị viên.',
            });
            return;
        }

        const updatedQuestion = await (prisma.question as any).update({
            where: { id },
            data: { status: 'ACTIVE' },
        });

        res.status(200).json({
            success: true,
            message: 'Đã duyệt câu hỏi thành công!',
            question: updatedQuestion,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Toggle lock/unlock status of a question (ADMIN only)
 * PATCH /api/questions/:id/toggle-lock
 */
export const toggleQuestionLock = async (
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
                message: 'Chào bạn, chỉ ADMIN mới có quyền khóa/khôi phục câu hỏi. Vui lòng liên hệ quản trị viên.',
            });
            return;
        }

        const question = await prisma.question.findUnique({ where: { id } });
        if (!question) {
            res.status(404).json({ success: false, message: 'Không tìm thấy câu hỏi.' });
            return;
        }

        const newStatus = (question as any).status === 'LOCKED' ? 'ACTIVE' : 'LOCKED';
        const updatedQuestion = await (prisma.question as any).update({
            where: { id },
            data: { status: newStatus },
        });

        res.status(200).json({
            success: true,
            message: newStatus === 'LOCKED' ? 'Đã khóa câu hỏi thành công!' : 'Đã khôi phục câu hỏi thành công!',
            question: updatedQuestion,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Bulk toggle status for multiple questions
 * PATCH /api/questions/bulk-status
 */
export const bulkToggleStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const { questionIds, status } = req.body;

        if (!questionIds || !Array.isArray(questionIds) || questionIds.length === 0) {
            res.status(400).json({ success: false, message: 'Danh sách câu hỏi không hợp lệ.' });
            return;
        }

        const validStatuses = ['ACTIVE', 'LOCKED', 'PENDING'];
        if (!validStatuses.includes(status)) {
            res.status(400).json({ success: false, message: `Trạng thái không hợp lệ. Chỉ chấp nhận: ${validStatuses.join(', ')}` });
            return;
        }

        const result = await (prisma.question as any).updateMany({
            where: { id: { in: questionIds } },
            data: { status },
        });

        res.status(200).json({
            success: true,
            message: `Đã cập nhật trạng thái ${result.count} câu hỏi thành ${status}`,
            count: result.count,
        });
    } catch (error) {
        next(error);
    }
};
