const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function compareTables() {
  try {
    const userId = await prisma.user.findFirst({
        where: { name: 'Thi Giang' },
        select: { id: true }
    }).then(u => u?.id);

    if (!userId) {
        console.log('Không tìm thấy user Thi Giang');
        return;
    }

    const [oldRecords, newRecords] = await Promise.all([
        prisma.userPartProgress.count({ where: { userId } }),
        prisma.testAttempt.count({ where: { userId } })
    ]);

    console.log(`--- PHÂN TÍCH DỮ LIỆU USER ${userId} ---`);
    console.log(`- Bảng cũ (UserPartProgress): ${oldRecords} bản ghi`);
    console.log(`- Bảng mới (TestAttempt): ${newRecords} bản ghi`);

    if (oldRecords > 0) {
        const sampleOld = await prisma.userPartProgress.findFirst({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            select: { createdAt: true, score: true, partId: true }
        });
        console.log(`- Bản ghi cũ nhất/mới nhất trong UserPartProgress: ${sampleOld.score} điểm, lúc ${sampleOld.createdAt}`);
    }

  } catch (error) {
    console.error('Lỗi:', error);
  } finally {
    await prisma.$disconnect();
  }
}

compareTables();
