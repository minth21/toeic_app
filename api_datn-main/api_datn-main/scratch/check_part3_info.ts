import { prisma } from '../src/config/prisma';

async function getPartInfo() {
  const partId = '7e02336e-fb84-4da0-9862-bd63d8c28094';
  const part = await prisma.part.findUnique({
    where: { id: partId },
    select: {
      id: true,
      audioUrl: true,
      partNumber: true,
      test: { select: { title: true } }
    }
  });

  if (part) {
    console.log('--- THÔNG TIN PART 3 ---');
    console.log(`ID: ${part.id}`);
    console.log(`Part Number: ${part.partNumber}`);
    console.log(`Đề: ${part.test.title}`);
    console.log(`Audio URL hiện tại: ${part.audioUrl}`);
  } else {
    console.log('Không tìm thấy Part với ID này.');
  }
}

getPartInfo().catch(console.error).finally(() => prisma.$disconnect());
