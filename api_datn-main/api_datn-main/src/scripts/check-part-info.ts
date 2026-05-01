
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const part = await prisma.part.findUnique({
    where: { id: 'd4baaadc-ce81-4164-81c9-c7ab79eca779' },
    select: { id: true, partNumber: true, partName: true }
  });
  console.log('PART INFO:', JSON.stringify(part, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
