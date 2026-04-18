
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    // 1. Tìm User có bài làm gần nhất
    const latestAttempt = await prisma.testAttempt.findFirst({
      orderBy: { createdAt: 'desc' },
      select: { userId: true, createdAt: true }
    });

    if (!latestAttempt) {
      console.log('Không tìm thấy bất kỳ bài làm nào trong DB.');
      return;
    }

    const userId = latestAttempt.userId;
    const user = await prisma.user.findUnique({ where: { id: userId }, select: { name: true } });
    console.log(`Kiểm tra cho User: ${user.name} (${userId})`);
    console.log(`Bài làm gần nhất lúc: ${latestAttempt.createdAt}`);

    // 2. Chạy thử logic đếm của Controller cho 30 ngày qua
    const activityStats = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const year = d.getFullYear();
      const month = d.getMonth();
      const day = d.getDate();

      // Logic cũ: 00:00 VN là 17:00 UTC ngày hôm trước
      const dayStart = new Date(Date.UTC(year, month, day, 17 - 24));
      const dayEnd = new Date(Date.UTC(year, month, day, 16, 59, 59, 999));

      const count = await prisma.testAttempt.count({
        where: {
          userId,
          createdAt: { gte: dayStart, lte: dayEnd }
        }
      });

      if (count > 0) {
        activityStats.push({ 
          date: `${year}-${month + 1}-${day}`, 
          count,
          start: dayStart.toISOString(),
          end: dayEnd.toISOString()
        });
      }
    }

    console.log('--- KẾT QUẢ MÔ PHỎNG CONTROLLER ---');
    console.log(JSON.stringify(activityStats, null, 2));

  } catch (error) {
    console.error('Lỗi debug:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
