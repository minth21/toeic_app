
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import 'dotenv/config';

const connectionString = process.env.DATABASE_URL || "postgresql://postgres:123456@localhost:5432/toeic_practice?schema=public";
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function check() {
  try {
    const qs = await prisma.question.findMany({
      where: { 
        partId: "58c8c7b4-08a1-4dd2-8537-6c05c67cbdb7"
      },
      select: { 
        questionNumber: true, 
        keyVocabulary: true
      },
      orderBy: { questionNumber: 'asc' }
    });

    console.log('--- ALL QUESTIONS IN PART 58c8c7b4 ---');
    qs.forEach(q => {
      const vocab = JSON.parse(q.keyVocabulary || '[]');
      console.log(`Q${q.questionNumber}: Vocab Count = ${vocab.length}`);
    });
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

check();
