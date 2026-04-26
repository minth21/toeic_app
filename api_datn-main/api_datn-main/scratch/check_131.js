const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const question = await prisma.question.findFirst({
      where: { questionNumber: 131 },
    });
    if (!question) {
      console.log('NOT FOUND question 131');
    } else {
      console.log('--- DATA QUESTION 131 ---');
      console.log(JSON.stringify(question, null, 2));
    }
  } catch (error) {
    console.error('ERROR:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
