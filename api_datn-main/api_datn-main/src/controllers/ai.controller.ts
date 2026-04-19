import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import sharp from 'sharp'; // Image optimization
import {
    generatePart6ExplanationService,
    generateExplanationService,
    generatePart7ExplanationService,
    scanPart7FromImageService,
    scanPart6FromImageService,
    magicScanPart7FromImagesService,
    magicScanPart6FromImagesService,
    translateWordService,
    enrichPart5QuestionService,
    enrichPart5BatchService,
    generateBatchExplanationsService,
    generatePersonalizedRoadmapService
} from '../services/ai.service';
import { calculateEstimatedScore } from '../services/user.service';
import axios from 'axios';

// Helper: Resize & nén ảnh trước khi gửi Gemini (giảm 80% dung lượng, tăng tốc 2-3x)
const optimizeImage = async (buffer: Buffer): Promise<Buffer> => {
    try {
        return await sharp(buffer)
            .resize({ width: 1024, withoutEnlargement: true })
            .jpeg({ quality: 80 })
            .toBuffer();
    } catch (error) {
        console.warn('[AI] Image optimization failed, using original:', error);
        return buffer; // Fallback: dùng buffer gốc nếu sharp lỗi
    }
};

export const generatePart6Explanations = async (req: Request, res: Response) => {
    try {
        let { passage, questions }: { passage: string; questions: any } = req.body;

        if (typeof questions === 'string') questions = JSON.parse(questions);
        if (!passage && req.body.passageText) passage = req.body.passageText;

        if (!passage || !questions || questions.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Passage and questions are required'
            });
        }

        const aiResponse = await generatePart6ExplanationService(passage, questions);
        console.log(`[INFO] AI Part 6 generated successfully for ${questions.length} questions`);

        return res.json({
            success: true,
            data: aiResponse
        });

    } catch (error: any) {
        console.error('AI Part 6 Error:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to generate explanations'
        });
    }
};

export const generateExplanation = async (req: Request, res: Response) => {
    try {
        const { questionText, options, correctAnswer } = req.body;

        if (!questionText || !options || !correctAnswer) {
            return res.status(400).json({
                success: false,
                message: 'Thiếu thông tin câu hỏi'
            });
        }

        const aiResponse = await generateExplanationService(questionText, options, correctAnswer);

        let fullExplanation = '';
        if (correctAnswer) {
            fullExplanation += `<b>Đáp án đúng: ${correctAnswer}</b><br/><br/>`;
        }
        if (aiResponse.translation) {
            fullExplanation += `📍 <b>Tạm dịch:</b><br/>${aiResponse.translation.replace(/\n/g, '<br/>')}<br/><br/>`;
        }
        if (aiResponse.explanation) {
            fullExplanation += `💡 <b>Giải thích:</b><br/>${aiResponse.explanation.replace(/\n/g, '<br/>')}<br/><br/>`;
        }
        if (aiResponse.tip) {
            fullExplanation += `💎 <b>Mẹo nhỏ:</b><br/>${aiResponse.tip.replace(/\n/g, '<br/>')}`;
        }

        return res.json({
            success: true,
            explanation: fullExplanation.trim() || aiResponse.explanation,
            translation: aiResponse.translation
        });

    } catch (error: any) {
        console.error('AI Explanation Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const generateBatchExplanations = async (req: Request, res: Response) => {
    try {
        const { questions } = req.body;

        if (!questions || !Array.isArray(questions) || questions.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Questions array is required'
            });
        }

        const aiResponses = await generateBatchExplanationsService(questions);

        const formattedExplanations = aiResponses.map((resp: any) => {
            let fullExplanation = '';
            if (resp.translation) {
                fullExplanation += `📍 <b>Tạm dịch:</b><br/>${resp.translation.replace(/\n/g, '<br/>')}<br/><br/>`;
            }
            if (resp.explanation) {
                fullExplanation += `💡 <b>Giải thích:</b><br/>${resp.explanation.replace(/\n/g, '<br/>')}<br/><br/>`;
            }
            if (resp.tip) {
                fullExplanation += `💎 <b>Mẹo nhỏ:</b><br/>${resp.tip.replace(/\n/g, '<br/>')}`;
            }

            return {
                questionNumber: resp.questionNumber,
                explanation: fullExplanation.trim() || resp.explanation || 'Không có lời giải'
            };
        });

        return res.json({
            success: true,
            explanations: formattedExplanations
        });

    } catch (error: any) {
        console.error('Batch AI Error:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to generate batch explanations'
        });
    }
};

export const scanPart7 = async (req: Request, res: Response) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Vui lòng upload ảnh' });
        const data = await scanPart7FromImageService(req.file.buffer, req.file.mimetype);
        return res.json({ success: true, data });
    } catch (error: any) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const enrichPart5Question = async (req: Request, res: Response) => {
    try {
        const { questionText, optionA, optionB, optionC, optionD, correctAnswer } = req.body;
        
        if (!questionText || !optionA || !optionB || !optionC || !optionD || !correctAnswer) {
            return res.status(400).json({ success: false, message: 'Thiếu dữ liệu câu hỏi hoặc đáp án' });
        }

        const data = await enrichPart5QuestionService(questionText, { A: optionA, B: optionB, C: optionC, D: optionD }, correctAnswer);
        return res.json({ success: true, data });
    } catch (error: any) {
        console.error('AI Part 5 Enrich Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const enrichPart5Batch = async (req: Request, res: Response) => {
    try {
        const { questions } = req.body;

        if (!questions || !Array.isArray(questions) || questions.length === 0) {
            return res.status(400).json({ success: false, message: 'Danh sách câu hỏi không hợp lệ' });
        }

        const data = await enrichPart5BatchService(questions);
        return res.json({ success: true, data });
    } catch (error: any) {
        console.error('AI Part 5 Batch Enrich Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const scanPart6 = async (req: Request, res: Response) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Vui lòng upload ảnh' });
        const data = await scanPart6FromImageService(req.file.buffer, req.file.mimetype);
        return res.json({ success: true, data });
    } catch (error: any) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const generatePart7Explanations = async (req: Request, res: Response) => {
    try {
        let { passageType, passageContent, questions } = req.body;

        if (typeof questions === 'string') questions = JSON.parse(questions);
        if (!passageContent && req.body.passageText) passageContent = req.body.passageText;

        const files = req.files as Express.Multer.File[];
        if (files && files.length > 0) {
            passageType = 'image';
            passageContent = files.map(f => ({
                buffer: f.buffer,
                mimeType: f.mimetype
            }));
        }

        if (!questions || !passageContent) return res.status(400).json({ success: false, message: 'Thiếu dữ liệu' });

        const data = await generatePart7ExplanationService(passageType || 'text', passageContent);
        console.log(`[INFO] AI Part 7 generated successfully for ${questions.length} questions`);
        return res.json({ success: true, data });
    } catch (error: any) {
        console.error('AI Part 7 Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const magicScanPart7 = async (req: Request, res: Response) => {
    try {
        const filesFields = req.files as { [fieldname: string]: Express.Multer.File[] };
        const passageFiles = filesFields['passageImages'] || [];
        const questionFiles = filesFields['questionImages'] || [];
        const allFiles = [...passageFiles, ...questionFiles];

        let { imageUrls } = req.body;
        if (typeof imageUrls === 'string') imageUrls = JSON.parse(imageUrls);
        
        const urlImages = [];
        if (imageUrls && Array.isArray(imageUrls)) {
            console.log(`[AI] Downloading ${imageUrls.length} image URLs for Part 7 Magic Scan...`);
            for (const url of imageUrls) {
                try {
                    const response = await axios.get(url, { responseType: 'arraybuffer' });
                    urlImages.push({
                        buffer: await optimizeImage(Buffer.from(response.data)),
                        mimeType: 'image/jpeg'
                    });
                } catch (e) {
                    console.error(`[AI] Failed to download image from ${url}:`, e);
                }
            }
        }

        const uploadedImages = await Promise.all(allFiles.map(async file => ({
            buffer: await optimizeImage(file.buffer),
            mimeType: 'image/jpeg'
        })));

        // --- CLOUDINARY UPLOAD: Upload only passage images to get permanent URLs ---
        const { uploadExamImageToCloudinary, saveAssetToDb } = await import('../config/cloudinary.config');
        const passageCloudinaryUrls: string[] = [];
        
        console.log(`[AI] Uploading ${passageFiles.length} passage images to Cloudinary...`);
        for (const file of passageFiles) {
            try {
                const uploadRes = await uploadExamImageToCloudinary(file.buffer);
                if (uploadRes && uploadRes.secure_url) {
                    // Log to DB (Antigravity Audit Log)
                    await saveAssetToDb(uploadRes, (req as any).user?.id);
                    passageCloudinaryUrls.push(uploadRes.secure_url);
                }
            } catch (err) {
                console.error('[AI] Cloudinary upload failed for a passage image:', err);
                passageCloudinaryUrls.push(''); // Placeholder for failure
            }
        }

        const allImages = [...urlImages, ...uploadedImages];
        if (allImages.length === 0) {
            return res.status(400).json({ success: false, message: 'Vui lòng upload ít nhất một ảnh hoặc cung cấp URL ảnh' });
        }

        console.log(`[AI] Starting Magic Scan Part 7 with ${allImages.length} images...`);

        let data: any;
        try {
            // Pass the Cloudinary URLs as the second argument
            data = await magicScanPart7FromImagesService(allImages, passageCloudinaryUrls);
        } catch (firstErr: any) {
            console.warn(`[AI] Attempt 1 failed: ${firstErr.message}. Retrying once...`);
            data = await magicScanPart7FromImagesService(allImages, passageCloudinaryUrls);
        }

        const passageRegions: any[] = Array.isArray(data.passageRegions) ? data.passageRegions : [];
        if (passageRegions.length > 0) {
            const Jimp: any = (await import('jimp')).Jimp;
            const { uploadExamImageToCloudinary, saveAssetToDb: saveAssetToDbCrop } = await import('../config/cloudinary.config');
            const croppedUrls: string[] = [];

            for (const region of passageRegions) {
                try {
                    const imgIndex = region.pageIndex;
                    if (imgIndex !== undefined && allFiles[imgIndex]) {
                        const image = await Jimp.read(allFiles[imgIndex].buffer);
                        const width = image.bitmap.width;
                        const height = image.bitmap.height;
                        const [ymin, xmin, ymax, xmax] = region.box_2d;
                        const left = Math.floor((xmin / 1000) * width);
                        const top = Math.floor((ymin / 1000) * height);
                        const cropWidth = Math.floor(((xmax - xmin) / 1000) * width);
                        const cropHeight = Math.floor(((ymax - ymin) / 1000) * height);

                        if (cropWidth > 0 && cropHeight > 0 && left >= 0 && top >= 0) {
                            image.crop({ x: left, y: top, w: cropWidth, h: cropHeight });
                            const croppedBuffer = await image.getBuffer('image/jpeg');
                            const uploadRes = await uploadExamImageToCloudinary(croppedBuffer);
                            if (uploadRes && uploadRes.secure_url) {
                                // Log to DB (Antigravity Audit Log)
                                await saveAssetToDbCrop(uploadRes, (req as any).user?.id);
                                croppedUrls.push(uploadRes.secure_url);
                            }
                        }
                    }
                } catch (cropErr) {
                    console.error('Error cropping image region:', cropErr);
                }
            }

            if (croppedUrls.length > 0) {
                (data as any).croppedPassageUrls = croppedUrls;
            }
        }

        return res.json({ success: true, data });
    } catch (error: any) {
        console.error('Magic Scan Part 7 Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const magicScanPart6 = async (req: Request, res: Response) => {
    try {
        const filesFields = req.files as { [fieldname: string]: Express.Multer.File[] };
        const passageFiles = filesFields['passageImages'] || [];
        const questionFiles = filesFields['questionImages'] || [];
        const allFiles = [...passageFiles, ...questionFiles];

        let { imageUrls } = req.body;
        if (typeof imageUrls === 'string') imageUrls = JSON.parse(imageUrls);

        const urlImages = [];
        if (imageUrls && Array.isArray(imageUrls)) {
            console.log(`[AI] Downloading ${imageUrls.length} image URLs for Part 6 Magic Scan...`);
            for (const url of imageUrls) {
                try {
                    const response = await axios.get(url, { responseType: 'arraybuffer' });
                    urlImages.push({
                        buffer: await optimizeImage(Buffer.from(response.data)),
                        mimeType: 'image/jpeg'
                    });
                } catch (e) {
                    console.error(`[AI] Failed to download image from ${url}:`, e);
                }
            }
        }

        const uploadedImages = await Promise.all(allFiles.map(async file => ({
            buffer: await optimizeImage(file.buffer),
            mimeType: file.mimetype
        })));

        const allImages = [...urlImages, ...uploadedImages];

        if (allImages.length === 0) {
            return res.status(400).json({ success: false, message: 'Vui lòng upload ít nhất một ảnh hoặc cung cấp URL ảnh' });
        }

        const data = await magicScanPart6FromImagesService(allImages);
        console.log(`[INFO] Magic Scan Part 6 completed for ${data.questions?.length || 0} questions across ${allImages.length} images`);

        return res.json({ success: true, data });
    } catch (error: any) {
        console.error('Magic Scan Part 6 Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const translateWord = async (req: Request, res: Response) => {
    try {
        const { word, sentence } = req.body;
        if (!word || !sentence) {
            return res.status(400).json({ success: false, message: 'Thiếu từ hoặc câu ngữ cảnh' });
        }

        const data = await translateWordService(word, sentence);
        return res.json({ success: true, data });
    } catch (error: any) {
        console.error('AI Translate Word Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};



export const getAiTimeline = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId } = req.params;
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const skip = (page - 1) * limit;

        const user = (req as any).user;
        const userRole = user?.role?.toUpperCase();
        const isTeacher = userRole === 'TEACHER';
        
        console.log('=== DEBUG AI TIMELINE ---');
        console.log(`Requester ID: ${user?.id}`);
        console.log(`Requester Role: ${user?.role}`);
        console.log(`Target Student ID: ${userId}`);
        console.log(`isTeacher detected: ${isTeacher}`);
        console.log('--------------------------');

        const where: any = { userId };
        if (userRole === 'STUDENT') {
            // Học viên chỉ thấy những bài đã được Admin duyệt và phát hành
            where.status = 'PUBLISHED';
        } else if (isTeacher) {
            // Giáo viên có thể thấy tất cả (Nháp, Đang chờ duyệt, Đã duyệt, Bị từ chối) của riêng học viên đó
            // Hoặc có thể lọc thêm && teacherId = user.id nếu muốn chặt chẽ hơn
        }

        const assessments = await (prisma as any).aiAssessment.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            skip,
            take: limit,
            include: {
                testAttempt: {
                    select: {
                        id: true,
                        totalScore: true,
                        correctCount: true,
                        totalQuestions: true,
                        test: { select: { title: true } },
                        part: { select: { partName: true, partNumber: true } }
                    }
                }
            }
        });

        const total = await (prisma as any).aiAssessment.count({ where });
        
        console.log(`[DEBUG] Found ${assessments.length} assessments for user ${userId}`);
        console.log(`[DEBUG] Where clause: ${JSON.stringify(where)}`);

        return res.status(200).json({
            success: true,
            data: assessments,
            meta: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        return next(error);
    }
};

/**
 * 🚀 AI ASSESSMENT: GEN ROADMAP FOR STUDENT
 * Dành cho Admin/Giáo viên để phân tích lộ trình học tập.
 */
export const assessStudentRoadmap = async (req: Request, res: Response) => {
    try {
        const { userId } = req.params;

        // 0. Làm mới điểm số dự kiến (Real-time sync)
        await calculateEstimatedScore(userId);

        // 1. Lấy thông tin học viên & mục tiêu
        const student = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                name: true,
                targetScore: true,
                estimatedScore: true,
                estimatedListening: true,
                estimatedReading: true,
                testAttempts: {
                    take: 50,
                    orderBy: { createdAt: 'desc' },
                    select: {
                        totalScore: true,
                        correctCount: true,
                        totalQuestions: true,
                        createdAt: true,
                        test: { select: { title: true } },
                        part: { select: { partNumber: true } }
                    }
                }
            }
        });

        if (!student) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy học viên' });
        }

        // 2. Lọc ra danh sách: Duy nhất 1 bài mới nhất cho mỗi Part (từ 1 đến 7)
        const latestPartAttempts: any[] = [];
        const seenParts = new Set<number>();

        for (const attempt of student.testAttempts) {
            const partNum = attempt.part?.partNumber;
            // Nếu là bài làm theo Part và chưa lấy Part này
            if (partNum && !seenParts.has(partNum)) {
                latestPartAttempts.push(attempt);
                seenParts.add(partNum);
            }
            // Nếu đã đủ 7 Part thì dừng
            if (seenParts.size === 7) break;
        }

        // Nếu học viên làm Full Test, nó sẽ không có partNumber ở root 
        // (Tùy cấu trúc DB, ở đây ta ưu tiên lấy các bài luyện theo Part để có dữ liệu sâu)

        const roadmap = await generatePersonalizedRoadmapService(
            student.name,
            student.targetScore || 500,
            student.estimatedScore || 0,
            latestPartAttempts // Gửi danh sách 7 Part tinh hoa
        );

        // 3. Lưu vào bảng AiAssessment để lưu trữ lịch sử
        const assessment = await (prisma as any).aiAssessment.create({
            data: {
                userId,
                type: 'ROADMAP',
                title: 'Lộ trình phát triển năng lực cá nhân',
                summary: roadmap.summary || 'Phân tích lộ trình học tập dựa trên kết quả luyện tập.',
                content: {
                    ...roadmap,
                    scoreDetails: {
                        targetScore: student.targetScore || 500,
                        estimatedListening: student.estimatedListening || 0,
                        estimatedReading: student.estimatedReading || 0,
                        estimatedScore: student.estimatedScore || 0
                    }
                },
                score: student.estimatedScore || 0,
                isPublished: false // GV cần duyệt trước khi gửi cho HV
            }
        });

        return res.json({
            success: true,
            data: assessment
        });

    } catch (error: any) {
        console.error('Assess Student Roadmap Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

/**
 * 📢 PUBLISH ROADMAP
 * GV phê duyệt lộ trình, thêm ghi chú HTML và gửi thông báo cho HV.
 */
// 📢 1. SUBMIT ROADMAP (GV gửi cho Admin duyệt)
export const submitForApproval = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { teacherNote, summary, content } = req.body;
        const teacherId = (req as any).user.id;

        const assessment = await (prisma as any).aiAssessment.findUnique({
            where: { id }
        });

        if (!assessment) return res.status(404).json({ success: false, message: 'Lộ trình không tồn tại' });

        const updated = await (prisma as any).aiAssessment.update({
            where: { id },
            data: {
                summary: summary || assessment.summary,
                content: content || assessment.content,
                teacherNote: teacherNote || assessment.teacherNote,
                status: 'PENDING',
                teacherId: teacherId
            }
        });

        // Gửi thông báo cho Admin (BroadCast cho TẤT CẢ Admin)
        const { NotificationService } = await import('../services/notification.service');
        const admins = await prisma.user.findMany({ where: { role: 'ADMIN' }, select: { id: true } });
        
        for (const admin of admins) {
            await NotificationService.createNotification({
                userId: admin.id,
                title: '🛡️ Yêu cầu duyệt lộ trình mới',
                content: `Giáo viên ${(req as any).user.name} vừa gửi yêu cầu duyệt lộ trình cho học viên.`,
                type: 'ROADMAP_SUBMITTED' as any,
                relatedId: updated.id
            });
        }

        return res.json({ success: true, message: 'Đã gửi yêu cầu duyệt cho Admin', data: updated });
    } catch (error: any) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 📢 2. APPROVE ROADMAP (Admin phê duyệt phát hành cho HV)
export const approveRoadmap = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { auditNote } = req.body;

        const assessment = await (prisma as any).aiAssessment.findUnique({
            where: { id }
        });

        if (!assessment) return res.status(404).json({ success: false, message: 'Lộ trình không tồn tại' });

        const updated = await (prisma as any).aiAssessment.update({
            where: { id },
            data: {
                status: 'PUBLISHED',
                isPublished: true,
                auditNote: auditNote || ''
            }
        });

        // Gửi thông báo cho Giáo viên (người gửi duyệt)
        if (assessment.teacherId) {
            const { NotificationService } = await import('../services/notification.service');
            await NotificationService.createNotification({
                userId: assessment.teacherId,
                title: '✅ Lộ trình đã được phê duyệt',
                content: `Lộ trình bạn gửi cho học viên ${updated.userId} đã được Admin phê duyệt và phát hành.`,
                type: 'ROADMAP_APPROVED' as any,
                relatedId: assessment.id
            });
        }

        return res.json({ success: true, message: 'Đã phê duyệt và phát hành lộ trình', data: updated });
    } catch (error: any) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 📢 3. REJECT ROADMAP (Admin từ chối lộ trình)
export const rejectRoadmap = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { auditNote } = req.body;

        const assessment = await (prisma as any).aiAssessment.findUnique({
            where: { id }
        });

        if (!assessment) return res.status(404).json({ success: false, message: 'Lộ trình không tồn tại' });

        const updated = await (prisma as any).aiAssessment.update({
            where: { id },
            data: {
                status: 'REJECTED',
                auditNote: auditNote || 'Cần chỉnh sửa thêm nội dung.'
            }
        });

        // Gửi thông báo cho Giáo viên (người tạo bài)
        if (assessment.teacherId) {
            const { NotificationService } = await import('../services/notification.service');
            await NotificationService.createNotification({
                userId: assessment.teacherId,
                title: '❌ Lộ trình bị từ chối',
                content: `Lộ trình bạn gửi cho học viên đã bị Admin từ chối. Lý do: ${auditNote}`,
                type: 'ROADMAP_REJECTED' as any,
                relatedId: assessment.id
            });
        }

        return res.json({ success: true, message: 'Đã từ chối lộ trình', data: updated });
    } catch (error: any) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

/**
 * 💾 UPDATE ROADMAP DRAFT
 * GV lưu lại các chỉnh sửa nhưng chưa gửi cho học viên.
 */
export const updateRoadmap = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { summary, content, teacherNote } = req.body;

        const assessment = await (prisma as any).aiAssessment.findUnique({
            where: { id }
        });

        if (!assessment) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy lộ trình' });
        }

        const updated = await (prisma as any).aiAssessment.update({
            where: { id },
            data: {
                summary: summary || assessment.summary,
                content: content || assessment.content,
                teacherNote: teacherNote || assessment.teacherNote
            }
        });

        return res.json({
            success: true,
            message: 'Đã lưu bản nháp thành công',
            data: updated
        });
    } catch (error: any) {
        console.error('Update Roadmap Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

/**
 * 📄 EXPORT PDF ROADMAP
 */
export const exportRoadmapPdf = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        // Logic gọi export service ở đây (giả định dùng exportService có sẵn)
        const pdfBuffer = await require('../services/export.service').exportRoadmapToPdf(id);
        
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=roadmap-${id}.pdf`);
        return res.send(pdfBuffer);
    } catch (error: any) {
        console.error('Export PDF Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

/**
 * 🕵️ ADMIN ROADMAP AUDIT
 * Lấy toàn bộ lộ trình trong hệ thống (kèm thông tin Học viên)
 */
export const getAllRoadmaps = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const skip = (page - 1) * limit;

        const assessments = await (prisma as any).aiAssessment.findMany({
            where: { type: 'ROADMAP' },
            orderBy: { createdAt: 'desc' },
            skip,
            take: limit,
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        username: true,
                        avatarUrl: true,
                        studentClass: { select: { className: true } }
                    }
                }
            }
        });

        const total = await (prisma as any).aiAssessment.count({ 
            where: { type: 'ROADMAP' } 
        });

        return res.json({
            success: true,
            data: assessments,
            meta: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        return next(error);
    }
};

export const getAiAssessmentById = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const assessment = await (prisma as any).aiAssessment.findUnique({
            where: { id },
            include: {
                testAttempt: {
                    select: {
                        id: true,
                        totalScore: true,
                        test: { select: { title: true } }
                    }
                }
            }
        });

        if (!assessment) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy thông tin đánh giá' });
        }

        return res.json({
            success: true,
            data: assessment
        });
    } catch (error) {
        return next(error);
    }
};
