import { prisma } from '../src/config/prisma';

async function main() {
  const assessment = await prisma.aiAssessment.findFirst({
    where: { 
      userId: '5b909ee0-f003-4ee6-8db5-a8a3ef82b0d6',
      type: 'ROADMAP'
    },
    orderBy: { createdAt: 'desc' }
  });

  console.log("Assessment:", JSON.stringify(assessment, null, 2));
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
