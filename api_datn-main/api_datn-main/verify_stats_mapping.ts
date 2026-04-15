import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function verifyStats() {
  console.log('--- Verifying Dashboard Stats Mapping ---');
  
  const recentSubmissions = await prisma.testAttempt.findMany({
    orderBy: { createdAt: 'desc' },
    take: 1,
    include: {
      user: { select: { name: true, avatarUrl: true } },
      part: { select: { partName: true, test: { select: { title: true } } } }
    }
  });

  if (recentSubmissions.length === 0) {
    console.log('No submissions found.');
    return;
  }

  const sub = recentSubmissions[0];
  const mapped = {
    ...sub,
    score: sub.correctCount,
    toeicScore: sub.totalScore
  };

  console.log('Mapped Result for Activity Card:');
  console.log(`- score (correctCount): ${mapped.score}`);
  console.log(`- totalQuestions: ${mapped.totalQuestions}`);
  console.log(`- toeicScore (totalScore): ${mapped.toeicScore}`);
  
  if (mapped.score !== undefined && mapped.totalQuestions !== undefined && mapped.toeicScore !== undefined) {
    console.log('\n✅ VERIFICATION SUCCESSFUL: Frontend keys (score, totalQuestions, toeicScore) are all present.');
  } else {
    console.log('\n❌ VERIFICATION FAILED: Field mapping missing.');
  }
}

verifyStats().catch(console.error).finally(() => prisma.$disconnect());
