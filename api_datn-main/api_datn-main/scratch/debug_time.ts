
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function debugTime() {
  const now = new Date();
  console.log('--- SYSTEM TIME DEBUG ---');
  console.log('Server Native Time:', now.toString());
  console.log('Server ISO (UTC):', now.toISOString());
  
  // Lấy ra 1 record mới nhất để xem nó lưu giờ nào
  const latest = await prisma.testAttempt.findFirst({
    orderBy: { createdAt: 'desc' }
  });
  
  if (latest) {
    console.log('Latest Attempt createdAt (DB):', latest.createdAt.toString());
    console.log('Latest Attempt createdAt (ISO):', latest.createdAt.toISOString());
  }

  // Thử logic tính toán ngày hiện tại (Local VN là 18/04 01:00)
  // Mong đợi: Trả về được bản ghi làm lúc 17h chiều ngày 17/04 (UTC)
  const targetDate = new Date();
  // Giả sử server là UTC thì targetDate đang là 17/04 18:00
  // Nếu muốn thống kê cho ngày 18/04 VN:
  const vnOffset = 7;
  const vnTime = new Date(targetDate.getTime() + (vnOffset * 60 * 60 * 1000));
  const year = vnTime.getUTCFullYear();
  const month = vnTime.getUTCMonth();
  const day = vnTime.getUTCDate();
  
  console.log(`Calculation for VN Today (${day}/${month+1}/${year}):`);
  
  const dayStart = new Date(Date.UTC(year, month, day, 0 - vnOffset));
  const dayEnd = new Date(Date.UTC(year, month, day, 23 - vnOffset, 59, 59, 999));
  
  console.log('Query dayStart (UTC):', dayStart.toISOString());
  console.log('Query dayEnd (UTC):', dayEnd.toISOString());

  const count = await prisma.testAttempt.count({
    where: {
      createdAt: {
        gte: dayStart,
        lte: dayEnd,
      }
    }
  });
  
  console.log('Results Found for calculation:', count);
}

debugTime().catch(console.error).finally(() => prisma.$disconnect());
