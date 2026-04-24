import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const test = await prisma.test.findFirst({
    where: { title: { contains: 'Test 1', mode: 'insensitive' } },
    include: {
      parts: {
        orderBy: { partNumber: 'asc' },
        select: { partNumber: true, audioUrl: true }
      }
    }
  });

  if (!test) {
    console.log('Không tìm thấy đề thi nào tên "Test 1"');
    return;
  }

  console.log(`--- Trạng thái Audio của đề: ${test.title} ---`);
  test.parts.forEach(p => {
    console.log(`Part ${p.partNumber}: ${p.audioUrl || 'Chưa có Audio'}`);
  });
}

main().catch(e => console.error(e)).finally(() => prisma.$disconnect());
