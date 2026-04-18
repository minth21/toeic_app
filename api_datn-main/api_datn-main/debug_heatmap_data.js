
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const userId = '5b909ee0-f003-4ee6-8db5-a8a3ef82b0d6'; // ID của Thi Giang
    console.log(`--- KIỂM TRA DỮ LIỆU HEATMAP CHO USER: Thi Giang ---`);

    const now = new Date();
    // Logic tối ưu mới (1 query)
    const DAYS_TO_SCAN = 90;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - (DAYS_TO_SCAN - 1));
    startDate.setHours(0, 0, 0, 0);
    const utcStartDate = new Date(startDate.getTime() - (7 * 60 * 60 * 1000));

    const allAttempts = await prisma.testAttempt.findMany({
        where: {
            userId,
            createdAt: { gte: utcStartDate }
        },
        select: { createdAt: true }
    });

    console.log(`Tìm thấy ${allAttempts.length} bài làm trong 90 ngày.`);

    const statsMap = {};
    allAttempts.forEach(attempt => {
        const localDate = new Date(attempt.createdAt.getTime() + (7 * 60 * 60 * 1000));
        const dateStr = localDate.toISOString().split('T')[0];
        statsMap[dateStr] = (statsMap[dateStr] || 0) + 1;
    });

    // In ra các ngày có dữ liệu
    console.log('Các ngày có màu (Vàng/Cam) sẽ là:');
    Object.entries(statsMap).sort().forEach(([date, count]) => {
      console.log(` -> ${date}: ${count} phần`);
    });

  } catch (error) {
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
