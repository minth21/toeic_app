import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function verify() {
  console.log('--- Verifying Submission Detail Fix ---');
  
  // 1. Get the latest attempt
  const latestAttempt = await prisma.testAttempt.findFirst({
    orderBy: { createdAt: 'desc' }
  });

  if (!latestAttempt) {
    console.log('No attempts found in database. Please run a practice test first.');
    return;
  }

  console.log(`Checking Attempt ID: ${latestAttempt.id}`);

  // 2. Fetch with includes (Mocking the controller logic manually since mocking Req/Res is complex)
  const attempt = await prisma.testAttempt.findUnique({
    where: { id: latestAttempt.id },
    include: {
        user: {
            select: { id: true, name: true, avatarUrl: true }
        },
        part: {
            include: {
                test: {
                    select: { id: true, title: true }
                }
            }
        }
    } as any
  });

  if (!attempt) {
    console.error('FAILED: Attempt not found with the same ID.');
    return;
  }

  console.log('RESULTS:');
  console.log(`- User Name: ${ (attempt as any).user?.name || 'MISSING' }`);
  console.log(`- Test Title: ${ (attempt as any).part?.test?.title || 'MISSING' }`);
  
  if ((attempt as any).user?.name && (attempt as any).part?.test?.title) {
    console.log('\n✅ VERIFICATION SUCCESSFUL: All required fields are present.');
  } else {
    console.log('\n❌ VERIFICATION FAILED: Some fields are still missing.');
  }
}

verify().catch(console.error).finally(() => prisma.$disconnect());
