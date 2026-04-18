
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, name: true, email: true, currentStreak: true, lastActiveAt: true }
    });
    console.log('--- DANH SÁCH NGƯỜI DÙNG VÀ HIỆN TRẠNG STREAK ---');
    users.forEach(u => {
      console.log(`ID: ${u.id} | Tên: ${u.name} | Streak: ${u.currentStreak} | Hoạt động cuối: ${u.lastActiveAt}`);
    });

    const totalAttempts = await prisma.testAttempt.count();
    console.log(`\nTổng số bài làm trong toàn bộ hệ thống: ${totalAttempts}`);

    if (totalAttempts > 0) {
      const sample = await prisma.testAttempt.findFirst({ select: { userId: true, createdAt: true } });
      console.log(`Mẫu bài làm ngẫu nhiên thuộc về User ID: ${sample.userId} lúc ${sample.createdAt}`);
    }

  } catch (error) {
    console.error('Lỗi debug:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
