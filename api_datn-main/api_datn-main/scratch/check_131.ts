import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Querying database: toeic_practice...');
  const question = await prisma.question.findFirst({
    where: { questionNumber: 131 },
  });
  if (!question) {
    console.log('NOT FOUND question 131');
    return;
  }
  console.log('--- DATA QUESTION 131 ---');
  console.log(JSON.stringify(question, null, 2));
}

main()
  .catch((e) => console.error(e))
  .finally(async () => await prisma.$disconnect());
