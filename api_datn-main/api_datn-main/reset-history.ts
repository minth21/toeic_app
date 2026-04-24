import { prisma } from './src/config/prisma';

async function run() {
  try {
    await prisma.attemptDetail.deleteMany();
    await (prisma as any).aiAssessment.deleteMany();
    await prisma.testAttempt.deleteMany();
    await prisma.userPartProgress.deleteMany();
    console.log('✅ Đã xóa toàn bộ lịch sử làm bài!');
  } catch (error) {
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

run();
