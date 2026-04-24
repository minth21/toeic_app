import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkQuestions() {
  const questions = await prisma.question.findMany({
    where: {
      partId: '7e02336e-fb84-4da0-9862-bd63d8c28094',
      questionNumber: {
        in: [62, 63, 64]
      }
    },
    select: {
      questionNumber: true,
      imageUrl: true,
      passage: true
    }
  });

  console.log(JSON.stringify(questions, null, 2));
  await prisma.$disconnect();
}

checkQuestions();
