
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- THỐNG KÊ LỊCH SỬ LÀM BÀI ---');
  
  const attempts = await prisma.testAttempt.findMany({
    orderBy: { createdAt: 'desc' },
    include: {
      user: { select: { name: true, username: true } },
      part: { select: { partNumber: true, partName: true } },
      test: { select: { title: true } }
    }
  });

  if (attempts.length === 0) {
    console.log('Chưa có lịch sử làm bài nào trong hệ thống.');
    return;
  }

  const stats = attempts.map(a => ({
    user: a.user.name,
    date: a.createdAt.toISOString().split('T')[0],
    content: a.part ? `Part ${a.part.partNumber}` : (a.test?.title || 'Full Test'),
    score: `${a.correctCount}/${a.totalQuestions}`
  }));

  console.table(stats);

  console.log('\n--- CHI TIẾT SỐ LẦN LÀM LẠI (UserPartProgress) ---');
  const progress = await prisma.userPartProgress.findMany({
    include: {
      user: { select: { name: true } },
      part: { select: { partNumber: true } }
    },
    orderBy: [
      { userId: 'asc' },
      { partId: 'asc' },
      { attemptNumber: 'desc' }
    ]
  });

  const progressStats = progress.map(p => ({
    'Học viên': p.user.name,
    'Part': `Part ${p.part.partNumber}`,
    'Lần làm thứ': p.attemptNumber,
    'Kết quả': `${p.score}/${p.totalQuestions}`,
    'Ngày': p.createdAt.toISOString().split('T')[0]
  }));

  console.table(progressStats);
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
