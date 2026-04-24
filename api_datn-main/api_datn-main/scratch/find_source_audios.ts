import { prisma } from '../src/config/prisma';

async function findSourceFiles() {
  const files = await prisma.cloudinaryAsset.findMany({
    where: {
      OR: [
        { publicId: { contains: 'Test01_Part3_1' } },
        { publicId: { contains: 'Test01_Part3_2' } },
        { url: { contains: 'Test01_Part3_1' } },
        { url: { contains: 'Test01_Part3_2' } }
      ]
    }
  });

  console.log(`Tìm thấy ${files.length} file.`);
  files.forEach(f => {
    console.log(`- Public ID: ${f.publicId}`);
    console.log(`  URL: ${f.url}`);
  });
}

findSourceFiles().catch(console.error).finally(() => prisma.$disconnect());
