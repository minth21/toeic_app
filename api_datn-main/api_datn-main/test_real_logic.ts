import { PrismaClient } from '@prisma/client';
import { computeLatestPartScores } from './src/utils/score.utils';

const prisma = new PrismaClient();

async function main() {
  const userId = '5b909ee0-f003-4ee6-8db5-a8a3ef82b0d6'; // Thi Giang
  const results = await computeLatestPartScores(userId, prisma);
  console.log('\n=== REAL LOGIC RESULTS ===');
  console.log('Listening Correct Sum:', results.listeningCorrect);
  console.log('Listening Score:', results.estimatedListening);
  console.log('Reading Correct Sum:', results.readingCorrect);
  console.log('Reading Score:', results.estimatedReading);
  console.log('Total Score:', results.estimatedScore);
  console.log('\nBreakdown:');
  for (const [part, data] of Object.entries(results.partBreakdown)) {
    if (data) {
        console.log(`Part ${part}: ${data.correct}/${data.total} (${data.date})`);
    } else {
        console.log(`Part ${part}: No attempt`);
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
