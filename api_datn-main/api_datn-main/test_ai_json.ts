import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    console.log('--- TESTING API RESPONSE LOGIC ---');
    const userId = '5b909ee0-f003-4ee6-8db5-a8a3ef82b0d6';
    
    // Exact logic from getAiTimeline (reverted)
    const assessments = await (prisma as any).aiAssessment.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
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

    console.log(`Results COUNT: ${assessments.length}`);
    if (assessments.length > 0) {
        console.log('FIRST ITEM JSON:', JSON.stringify(assessments[0], null, 2));
    }
}

run().catch(console.error).finally(() => prisma.$disconnect());
