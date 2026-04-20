import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const ids = ['261486ba-e02c-4a7e-a247-d0d128140274', '647de6a5-c74e-4012-a94c-10ab8d897d28'];
  const parts = await prisma.part.findMany({
    where: { id: { in: ids } },
    include: { test: true }
  });
  console.log(JSON.stringify(parts, null, 2));
}

main().finally(() => prisma.$disconnect());
