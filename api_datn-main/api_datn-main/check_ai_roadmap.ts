import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    where: { role: 'STUDENT' },
    select: { id: true, name: true }
  });

  console.log(`\n=== KIỂM TRA LỘ TRÌNH AI COACH ===\n`);

  for (const user of users) {
    const assessments = await (prisma as any).aiAssessment.findMany({
      where: { 
        userId: user.id,
        type: 'COACHING',
        title: 'Lộ trình phát triển năng lực cá nhân'
      },
      orderBy: { createdAt: 'desc' }
    });

    if (assessments.length > 0) {
      console.log(`Học viên: ${user.name} (${user.id})`);
      console.log(`Số lần phân tích lộ trình: ${assessments.length}`);
      console.log(`Lần cuối: ${assessments[0].createdAt.toLocaleString('vi-VN')}`);
      console.log('-----------------------------------');
    }
  }

  const total = await (prisma as any).aiAssessment.count({
    where: { 
      type: 'COACHING',
      title: 'Lộ trình phát triển năng lực cá nhân'
    }
  });
  console.log(`\nTỔNG CỘNG TOÀN HỆ THỐNG: ${total} lần phân tích lộ trình.`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
