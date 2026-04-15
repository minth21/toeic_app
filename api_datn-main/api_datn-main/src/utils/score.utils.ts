import { PrismaClient } from '@prisma/client';
import { getListeningScore, getReadingScore } from './score.util';

/**
 * Tính điểm TOEIC dự kiến theo logic chuẩn:
 * - Với mỗi Part (1-7), lấy bài làm GẦN NHẤT của user cho part đó → correctCount
 * - Cộng correctCount của P1+P2+P3+P4 → quy đổi Listening score (bảng chuẩn TOEIC)
 * - Cộng correctCount của P5+P6+P7 → quy đổi Reading score
 * - Tổng = Listening + Reading
 */
export async function computeLatestPartScores(userId: string, prisma: PrismaClient): Promise<{
    estimatedListening: number;
    estimatedReading: number;
    estimatedScore: number;
    listeningCorrect: number;
    readingCorrect: number;
    partBreakdown: Record<number, { correct: number; total: number; date: Date } | null>;
}> {
    // 1. Lấy bài làm GẦN NHẤT cho mỗi Part từ bảng userPartProgress (chứa cả Full Test và Part lẻ)
    const allProgress = await (prisma as any).userPartProgress.findMany({
        where: { userId },
        include: { part: { select: { partNumber: true } } },
        orderBy: [{ partId: 'asc' }, { attemptNumber: 'desc' }],
    });

    const partBreakdown: Record<number, { correct: number; total: number; date: Date } | null> = {};
    const seenParts = new Set<string>();

    for (const progress of allProgress) {
        if (!seenParts.has(progress.partId)) {
            seenParts.add(progress.partId);
            const pNum = progress.part?.partNumber;
            if (pNum && pNum >= 1 && pNum <= 7) {
                partBreakdown[pNum] = {
                    correct: progress.score || 0,
                    total: progress.totalQuestions || 0,
                    date: progress.createdAt,
                };
            }
        }
    }

    // 2. Tổng correctCount cho từng kỹ năng (Incremental - có nhiêu tính bấy nhiêu)
    let listeningCorrect = 0;
    let readingCorrect = 0;

    for (const pNum of [1, 2, 3, 4]) {
        if (partBreakdown[pNum]) {
            listeningCorrect += partBreakdown[pNum]!.correct;
        }
    }
    for (const pNum of [5, 6, 7]) {
        if (partBreakdown[pNum]) {
            readingCorrect += partBreakdown[pNum]!.correct;
        }
    }

    // Giới hạn an toàn (1 kỹ năng tối đa 100 câu)
    listeningCorrect = Math.min(100, listeningCorrect);
    readingCorrect = Math.min(100, readingCorrect);

    // 3. Quy đổi sang thang điểm TOEIC (0-495)
    const estimatedListening = getListeningScore(listeningCorrect);
    const estimatedReading = getReadingScore(readingCorrect);
    const estimatedScore = estimatedListening + estimatedReading;

    return { estimatedListening, estimatedReading, estimatedScore, listeningCorrect, readingCorrect, partBreakdown };
}
