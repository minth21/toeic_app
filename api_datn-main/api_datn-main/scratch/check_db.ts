import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const questions = await prisma.question.findMany({
        where: {
            questionNumber: {
                in: [131, 132, 133, 134]
            }
        },
        select: {
            id: true,
            questionNumber: true,
            passageTranslationData: true
        }
    });

    console.log(JSON.stringify(questions, null, 2));
}

main()
    .finally(async () => {
        await prisma.$disconnect();
    });
