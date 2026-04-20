import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const attempts = await prisma.testAttempt.findMany({
    where: { 
      part: { 
        partNumber: 5 
      } 
    },
    take: 5,
    orderBy: { createdAt: 'desc' },
    include: { 
      details: { 
        include: { 
          question: true 
        } 
      },
      part: true
    }
  });

  console.log(JSON.stringify(attempts, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
