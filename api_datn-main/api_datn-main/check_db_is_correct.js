
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkDatabaseStats() {
  console.log('--- ĐANG KIỂM TRA DATABASE (ROBUST VERSION) ---');
  
  try {
    // 1. Tìm các TestAttempt gần đây
    const lastAttempts = await prisma.testAttempt.findMany({
      orderBy: { createdAt: 'desc' },
      take: 5
    });

    if (lastAttempts.length === 0) {
      console.log('❌ Lỗi: Không tìm thấy lượt làm bài nào.');
      return;
    }

    console.log(`✅ Tìm thấy ${lastAttempts.length} lượt làm bài gần đây.`);

    for (const attempt of lastAttempts) {
      console.log(`\n--- Lượt làm bài ID: ${attempt.id} ---`);
      console.log(`📊 Ngày làm: ${attempt.createdAt}`);
      console.log(`🎯 Kết quả tổng: ${attempt.correctCount}/${attempt.totalQuestions}`);
      
      const details = await prisma.attemptDetail.findMany({
        where: { attemptId: attempt.id }
      });

      const correctInDetails = details.filter(d => d.isCorrect === true).length;
      const totalInDetails = details.length;

      console.log(`✅ Số câu isCorrect: true trong AttemptDetail: ${correctInDetails}/${totalInDetails}`);
      
      if (attempt.testId) {
        console.log(`📝 Loại: Làm full Test (TestID: ${attempt.testId})`);
      } else if (attempt.partId) {
        console.log(`📝 Loại: Luyện tập Part (PartID: ${attempt.partId})`);
      }
    }

  } catch (err) {
    console.error('❌ Lỗi thực thi:', err);
  } finally {
    await prisma.$disconnect();
  }
}

checkDatabaseStats();
