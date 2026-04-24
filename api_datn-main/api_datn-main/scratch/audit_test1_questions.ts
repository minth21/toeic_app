import { prisma } from '../src/config/prisma';

async function auditTest1() {
  const parts = await prisma.part.findMany({
    where: { test: { title: { contains: 'Test 1', mode: 'insensitive' } } },
    include: { _count: { select: { questions: true } } },
    orderBy: { partNumber: 'asc' }
  });

  console.log('--- THỐNG KÊ CÂU HỎI TOEIC-TEST 1 ---');
  const standards: Record<number, number> = {
    1: 6, 2: 25, 3: 39, 4: 30, 5: 30, 6: 16, 7: 54
  };

  parts.forEach(p => {
    const count = p._count.questions;
    const std = standards[p.partNumber];
    const status = count === std ? '✅ CHUẨN' : (count > std ? `⚠️ DƯ (${count - std} câu)` : `❌ THIẾU (${std - count} câu)`);
    console.log(`Part ${p.partNumber}: ${count}/${std} câu - ${status}`);
  });
}

auditTest1().catch(console.error).finally(() => prisma.$disconnect());
