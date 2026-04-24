
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    const qs = await prisma.question.findMany({
        where: { 
            OR: [
                { passageImageUrl: { not: null } },
                { imageUrl: { not: null } }
            ]
        },
        orderBy: { updatedAt: 'desc' },
        take: 5,
        select: { 
            id: true,
            questionNumber: true, 
            imageUrl: true, 
            passageImageUrl: true, 
            updatedAt: true,
            partId: true
        }
    });
    console.log('--- RECENT QUESTIONS WITH IMAGES ---');
    console.log(JSON.stringify(qs, null, 2));
}

run()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
