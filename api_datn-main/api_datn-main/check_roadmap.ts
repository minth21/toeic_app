import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkRoadmap() {
    const userId = '5b909ee0-f003-4ee6-8db5-a8a3ef82b0d6';
    const assessments = await prisma.aiAssessment.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' }
    });

    console.log('--- AI ASSESSMENTS FOR STUDENT ---');
    assessments.forEach((a: any) => {
        console.log(`ID: ${a.id} | Type: ${a.type} | Title: ${a.title} | Published: ${a.isPublished} | CreatedAt: ${a.createdAt}`);
    });
}

checkRoadmap()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
