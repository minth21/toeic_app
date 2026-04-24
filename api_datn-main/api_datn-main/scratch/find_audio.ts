import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const assets = await prisma.cloudinaryAsset.findMany({
    where: {
      OR: [
        { url: { contains: 'test', mode: 'insensitive' } },
        { publicId: { contains: 'test', mode: 'insensitive' } }
      ]
    },
    take: 20
  });

  console.log('--- Cloudinary Assets Found ---');
  console.log(JSON.stringify(assets, null, 2));

  const partsWithAudio = await prisma.part.findMany({
    where: {
      test: {
        title: { contains: 'Test 1', mode: 'insensitive' }
      }
    },
    select: {
      partNumber: true,
      audioUrl: true,
      test: { select: { title: true } }
    }
  });

  console.log('\n--- Parts in Test 1 with Audio ---');
  console.log(JSON.stringify(partsWithAudio, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
