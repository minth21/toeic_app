import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    console.log('--- AUDITING AI ASSESSMENTS ---');
    const assessments = await (prisma as any).aiAssessment.findMany({
        orderBy: { createdAt: 'desc' },
        take: 10
    });

    if (assessments.length === 0) {
        console.log('No assessments found in DB.');
    } else {
        assessments.forEach((a: any, i: number) => {
            console.log(`[${i}] ID: ${a.id}`);
            console.log(`    Title: "${a.title}"`);
            console.log(`    Type: ${a.type}`);
            console.log(`    User: ${a.userId}`);
            console.log('---------------------------');
        });
    }
}

run().catch(console.error).finally(() => prisma.$disconnect());
