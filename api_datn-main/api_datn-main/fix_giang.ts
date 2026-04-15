import { PrismaClient } from '@prisma/client';
import { calculateEstimatedScore } from './src/services/user.service';

const prisma = new PrismaClient();

async function main() {
  const user = await (prisma as any).user.findFirst({ where: { name: { contains: 'Giang' } } });
  if (!user) return;

  console.log(`Updating Thi Giang (${user.id})...`);
  
  // Update target score to 350 as requested by user
  await prisma.user.update({
    where: { id: user.id },
    data: { targetScore: 350 }
  });

  // Trigger score calculation with new logic
  const results = await calculateEstimatedScore(user.id);
  console.log('Update results:', results);
}

main().catch(console.error).finally(() => prisma.$disconnect());
