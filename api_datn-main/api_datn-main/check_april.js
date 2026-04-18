
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const start = new Date('2026-04-01T00:00:00Z');
    const end = new Date('2026-05-01T00:00:00Z');

    const attempts = await prisma.testAttempt.findMany({
      where: {
        createdAt: {
          gte: start,
          lt: end,
        },
      },
      select: {
        createdAt: true,
      },
    });

    const stats = {};
    attempts.forEach((a) => {
      const d = new Date(a.createdAt);
      // Giả lập múi giờ Việt Nam (UTC+7)
      d.setHours(d.getHours() + 7);
      const dateStr = d.toISOString().split('T')[0];
      stats[dateStr] = (stats[dateStr] || 0) + 1;
    });

    console.log('--- THỐNG KÊ CHI TIẾT THÁNG 4/2026 ---');
    const dates = Object.keys(stats).sort();
    if (dates.length === 0) {
      console.log('Không tìm thấy dữ liệu luyện tập nào trong tháng 4.');
    } else {
      dates.forEach((date) => {
        console.log('Ngày ' + date + ': ' + stats[date] + ' phần (lượt luyện tập)');
      });
    }
  } catch (error) {
    console.error('Lỗi khi truy vấn:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
