const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkLatestAttempt() {
  try {
    // 1. Find Part 5 of all tests matching 'TOEIC-TEST 1'
    const parts = await prisma.part.findMany({
      where: {
        partNumber: 5,
        test: {
          title: { contains: 'TOEIC-TEST 1' }
        }
      },
      select: { id: true, partName: true, test: { select: { title: true, id: true } } }
    });

    if (parts.length === 0) {
      console.log('Không tìm thấy Part 5 của TOEIC-TEST 1');
      return;
    }

    console.log(`Tìm thấy ${parts.length} bản ghi Part 5 cho TOEIC-TEST 1`);

    for (const part of parts) {
      console.log(`\n--- Kiểm tra Part ID: ${part.id} (Thuộc Test ID: ${part.test.id}) ---`);

      // 2. Get latest attempts for this part
      const attempts = await prisma.testAttempt.findMany({
        where: { partId: part.id },
        orderBy: { createdAt: 'desc' },
        take: 3,
        include: {
          user: { select: { name: true } }
        }
      });

      if (attempts.length === 0) {
        console.log('Chưa có lượt làm bài nào.');
      } else {
        attempts.forEach((a, i) => {
          console.log(`${i + 1}. User: ${a.user.name} | Score: ${a.correctCount}/${a.totalQuestions} | Lúc: ${a.createdAt.toLocaleString('vi-VN')}`);
        });
      }
    }


  } catch (error) {
    console.error('Lỗi:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkLatestAttempt();
