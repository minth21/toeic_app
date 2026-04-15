import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  // Find Thi Giang
  const user = await (prisma as any).user.findFirst({ where: { name: { contains: 'Giang' } } });
  if (!user) { console.log('User not found'); return; }
  console.log(`\n=== User: ${user.name} (${user.id}) ===\n`);

  // Get ALL attempts, show listening and reading scores
  const attempts = await prisma.testAttempt.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      createdAt: true,
      totalScore: true,
      listeningScore: true,
      readingScore: true,
      correctCount: true,
      totalQuestions: true,
      part: { select: { partNumber: true, partName: true } },
      test: { select: { title: true } },
    }
  });

  console.log(`Total attempts: ${attempts.length}\n`);
  console.log('DateTime (Local+7)           | Skill     | Part | L Score | R Score | Total | Correct/Total');
  console.log('------------------------------|-----------|------|---------|---------|-------|----------');
  
  for (const a of attempts) {
    const dt = new Date(a.createdAt);
    const dtStr = dt.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });
    const name = a.test?.title ?? a.part?.partName ?? 'N/A';
    const pNum = a.part?.partNumber ?? '-';
    const skill = (a.listeningScore ?? 0) > 0 ? 'LISTENING' : (a.readingScore ?? 0) > 0 ? 'READING' : 'UNKNOWN';
    console.log(`${dtStr.padEnd(29)} | ${skill.padEnd(9)} | P${String(pNum).padEnd(3)} | ${String(a.listeningScore ?? 0).padEnd(7)} | ${String(a.readingScore ?? 0).padEnd(7)} | ${String(a.totalScore ?? 0).padEnd(5)} | ${a.correctCount}/${a.totalQuestions}  [${name}]`);
  }

  // Highlight the ones that matter
  const latestL = attempts.find(a => (a.listeningScore ?? 0) > 0);
  const latestR = attempts.find(a => (a.readingScore ?? 0) > 0);

  console.log('\n=== Score used for Dashboard ===');
  if (latestL) {
    console.log(`LISTENING: ${latestL.listeningScore} pts — ${new Date(latestL.createdAt).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })} [${latestL.part?.partName ?? latestL.test?.title}]`);
  } else {
    console.log('LISTENING: 0 (no listening attempt found)');
  }
  if (latestR) {
    console.log(`READING:   ${latestR.readingScore} pts — ${new Date(latestR.createdAt).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })} [${latestR.part?.partName ?? latestR.test?.title}]`);
  } else {
    console.log('READING:   0 (no reading attempt found)');
  }
  const total = (latestL?.listeningScore ?? 0) + (latestR?.readingScore ?? 0);
  console.log(`TOTAL:     ${total} pts`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
