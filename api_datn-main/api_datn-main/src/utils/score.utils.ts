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
    partBreakdown: Record<number, { id: string; correct: number; total: number; date: Date } | null>;
}> {
    // 1. Lấy bài làm GẦN NHẤT cho mỗi Part từ bảng testAttempt (Nguồn dữ liệu chính xác nhất hiện tại)
    const allAttempts = await prisma.testAttempt.findMany({
        where: { userId },
        include: { part: { select: { partNumber: true } } },
        orderBy: [{ partId: 'asc' }, { createdAt: 'desc' }],
    });

    const partBreakdown: Record<number, { id: string; correct: number; total: number; date: Date } | null> = {};
    const seenParts = new Set<string>();

    for (const attempt of allAttempts) {
        if (attempt.partId && !seenParts.has(attempt.partId)) {
            seenParts.add(attempt.partId);
            const pNum = attempt.part?.partNumber;
            if (pNum && pNum >= 1 && pNum <= 7) {
                partBreakdown[pNum] = {
                    id: attempt.partId!,
                    correct: attempt.correctCount || 0,
                    total: attempt.totalQuestions || 0,
                    date: attempt.createdAt,
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
