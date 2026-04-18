import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('--- DIAGNOSTIC: AI ASSESSMENTS ---');
    const assessments = await (prisma as any).aiAssessment.findMany({
        orderBy: { createdAt: 'desc' },
        include: {
            user: { select: { name: true, role: true } }
        }
    });

    console.log(`Total assessments found: ${assessments.length}`);
    
    assessments.forEach((a: any, i: number) => {
        console.log(`\n[${i+1}] ID: ${a.id}`);
        console.log(`    User: ${a.user?.name} (ID: ${a.userId})`);
        console.log(`    Type: ${a.type}`);
        console.log(`    Published: ${a.isPublished}`);
        console.log(`    Created: ${a.createdAt}`);
    });
}

main().catch(console.error).finally(() => prisma.$disconnect());
