import { prisma } from './src/config/prisma';
import 'dotenv/config';

async function main() {
  console.log('🚀 Đang bắt đầu đồng bộ trạng thái AiAssessment...');

  const result = await (prisma as any).aiAssessment.updateMany({
    where: {
      type: 'COACHING',
      status: 'DRAFT',
      isPublished: true,
    },
    data: {
      status: 'PUBLISHED',
    },
  });

  console.log(`✅ Thành công! Đã cập nhật ${result.count} bản ghi Coaching sang trạng thái PUBLISHED.`);
}

main()
  .catch((e) => {
    console.error('❌ Lỗi khi cập nhật dữ liệu:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
