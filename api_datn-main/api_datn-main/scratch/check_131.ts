import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const questions = await prisma.question.findMany({
    where: {
      questionNumber: {
        in: [131, 132, 133, 134, 135, 136, 137, 138]
      }
    },
    select: {
      id: true,
      questionNumber: true,
      keyVocabulary: true,
      passageTranslationData: true
    },
    orderBy: {
      questionNumber: 'asc'
    }
  });

  console.log('--- DATABASE CHECK (131-138) ---');
  questions.forEach(q => {
    console.log(`\n[Question ${q.questionNumber}]`);
    console.log('keyVocabulary:', q.keyVocabulary);
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
