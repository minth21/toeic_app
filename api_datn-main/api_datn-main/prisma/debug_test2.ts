import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- DB INTEGRITY AUDIT: TARGET READING TEST (9632) ---');
  
  const targetTestId = '96321b17-a3d4-45ae-bf63-fda0a4a15113';
  const targetPartId = '261486ba-e02c-4a7e-a247-d0d128140274';

  // 1. Audit THE Test
  const test = await prisma.test.findUnique({
    where: { id: targetTestId },
    include: {
      parts: {
        orderBy: { partNumber: 'asc' },
        include: {
          _count: { select: { questions: true } }
        }
      }
    }
  });

  if (!test) {
    console.log(`❌ Test ID ${targetTestId} NOT FOUND in DB.`);
  } else {
    console.log(`✅ Found Test: ${test.title} (${test.testType})`);
    console.log(`   Status: ${test.status}`);
    console.log('--- Parts Structure ---');
    for (const p of test.parts) {
      const isTarget = p.id === targetPartId;
      console.log(`${isTarget ? '🎯' : '  '} Part ${p.partNumber}: ${p.partName}`);
      console.log(`     ID: ${p.id}`);
      console.log(`     Questions in Part table count: ${p.totalQuestions}`);
      console.log(`     Questions linked in 'questions' table: ${p._count.questions}`);
      
      if (isTarget) {
        // Deep dive into questions of this part
        const questions = await prisma.question.findMany({
          where: { partId: p.id },
          select: { id: true, questionNumber: true, status: true }
        });
        if (questions.length > 0) {
          console.log(`     Questions List: ${JSON.stringify(questions)}`);
        } else {
          console.log(`     ⚠️ WARNING: ZERO questions found in 'questions' table for this Part ID.`);
        }
      }
    }
  }

  // 2. Extra orphan check
  console.log('\n--- Orphan Question Check ---');
  const orphanCount = await prisma.question.count({
    where: { partId: { notIn: test?.parts.map(p => p.id) ?? [] } }
  });
  console.log(`   Total orphan questions in DB: ${orphanCount}`);
}

main()
  .catch((e) => console.error(e))
  .finally(() => prisma.$disconnect());
