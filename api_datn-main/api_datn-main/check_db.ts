import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    const userId = '5b909ee0-f003-4ee6-8db5-a8a3ef82b0d6';
    const assessments = await (prisma as any).aiAssessment.findMany({
        where: { userId }
    });
    
    console.log(`Found ${assessments.length} assessments for user ${userId}`);
    assessments.forEach((a: any) => {
        console.log(`- ID: ${a.id}, Type: ${a.type}, Published: ${a.isPublished}, Title: ${a.title}`);
    });
}

run().catch(console.error).finally(() => prisma.$disconnect());
