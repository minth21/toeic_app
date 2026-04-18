import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    const result = await (prisma as any).aiAssessment.updateMany({
        where: { 
            type: { in: ['COACHING', 'PERFORMANCE'] } 
        },
        data: { isPublished: true }
    });
    console.log(`Successfully updated ${result.count} records to IS_PUBLISHED: TRUE`);
}

run().catch(console.error).finally(() => prisma.$disconnect());
