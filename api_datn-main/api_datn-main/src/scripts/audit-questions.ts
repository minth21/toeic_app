import { prisma } from '../config/prisma';

const partRanges: Record<number, { min: number; max: number }> = {
    1: { min: 1, max: 6 },
    2: { min: 7, max: 31 },
    3: { min: 32, max: 70 },
    4: { min: 71, max: 100 },
    5: { min: 101, max: 130 },
    6: { min: 131, max: 146 },
    7: { min: 147, max: 200 },
};

async function auditQuestions() {
    console.log('--- Starting TOEIC Question Numbering Audit ---');
    
    try {
        const questions = await prisma.question.findMany({
            include: {
                part: true,
            },
        });

        const invalidQuestions = [];

        for (const q of questions) {
            const range = partRanges[q.part.partNumber];
            if (range) {
                if (q.questionNumber < range.min || q.questionNumber > range.max) {
                    invalidQuestions.push({
                        id: q.id,
                        part: q.part.partNumber,
                        testId: q.part.testId,
                        questionNumber: q.questionNumber,
                        expectedRange: `${range.min}-${range.max}`,
                    });
                }
            }
        }

        if (invalidQuestions.length === 0) {
            console.log('✅ All questions comply with the standardized numbering schema.');
        } else {
            console.log(`❌ Found ${invalidQuestions.length} non-compliant questions:`);
            console.table(invalidQuestions);
            console.log('\nRecommendation: Re-index these questions or check if they belong to the correct Part.');
        }

    } catch (error) {
        console.error('Audit failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

auditQuestions();
