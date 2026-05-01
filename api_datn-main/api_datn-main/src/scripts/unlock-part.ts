
import { prisma } from '../config/prisma';

async function unlockPart(partId: string) {
    try {
        const result = await prisma.question.updateMany({
            where: { partId: partId },
            data: { status: 'ACTIVE' }
        });
        
        await prisma.part.update({
            where: { id: partId },
            data: { status: 'ACTIVE' }
        });

        console.log(`✅ SUCCESS: Unlocked ${result.count} questions for Part ${partId}`);
    } catch (err) {
        console.error('Unlock failed:', err);
    } finally {
        await prisma.$disconnect();
    }
}

unlockPart('261486ba-e02c-4a7e-a247-d0d128140274');
