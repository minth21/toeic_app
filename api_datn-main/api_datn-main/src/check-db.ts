import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  try {
    // Ép kiểu sang any để bỏ qua lỗi TS trong script chẩn đoán nhanh
    const roadmapCount = await (prisma.aiAssessment as any).count({
      where: {
        type: 'ROADMAP'
      }
    });

    const allCount = await (prisma.aiAssessment as any).count();

    const roadmaps = await (prisma.aiAssessment as any).findMany({
      where: {
        type: 'ROADMAP'
      },
      take: 5,
      select: {
        id: true,
        title: true,
        userId: true,
        isPublished: true,
        createdAt: true
      }
    });

    console.log('--- DATABASE CHECK: AiAssessment ---');
    console.log(`Total AiAssessments: ${allCount}`);
    console.log(`AiAssessments with type "ROADMAP": ${roadmapCount}`);
    
    if (roadmapCount > 0) {
      console.log('\nRecent Roadmaps (max 5):');
      console.table(roadmaps);
    } else {
      console.log('\nNo ROADMAP records found.');
    }

  } catch (error) {
    console.error('Error checking database:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();

