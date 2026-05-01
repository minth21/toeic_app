
import { prisma } from '../config/prisma';

async function checkPart(partId: string) {
    console.log(`Checking Part: ${partId}`);
    try {
        const part = await prisma.part.findUnique({
            where: { id: partId },
            include: {
                _count: {
                    select: { questions: true }
                },
                questions: true
            }
        });

        if (!part) {
            console.log('❌ ERROR: Part NOT FOUND in Database.');
            return;
        }

        console.log(`Part Name: ${part.partName}`);
        console.log(`Status: ${part.status}`);
        console.log(`Question Count: ${part._count.questions}`);

        if (part._count.questions === 0) {
            console.log('❌ ERROR: This part has ZERO questions. That is why the app fails to load.');
        } else {
            console.log('--- Questions Detail ---');
            part.questions.forEach(q => {
                console.log(`Q${q.questionNumber}: ID=${q.id}, Status=${q.status}`);
                if (q.passageTranslationData) {
                    try {
                        const data = q.passageTranslationData;
                        JSON.parse(typeof data === 'string' ? data : JSON.stringify(data));
                        console.log(`  - Magic Scan JSON: Valid`);
                    } catch {
                        console.log(`  - ❌ ERROR: Magic Scan JSON INVALID for Q${q.questionNumber}`);
                    }
                }
            });
        }
    } catch (err) {
        console.error('Check failed:', err);
    } finally {
        await prisma.$disconnect();
    }
}

const targetPart = process.argv[2] || '261486ba-e02c-4a7e-a247-d0d128140274';
checkPart(targetPart);
