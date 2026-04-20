
import { prisma } from './src/config/prisma';

async function check() {
    const p1 = '647de6a5-c74e-4012-a94c-10ab8d897d28';
    const p2 = '261486ba-e02c-4a7e-a247-d0d128140274';

    const part1 = await prisma.part.findUnique({ where: { id: p1 }, include: { test: true } });
    const part2 = await prisma.part.findUnique({ where: { id: p2 }, include: { test: true } });

    console.log('--- Part 1 ---');
    console.log('Test Title:', part1?.test?.title);
    console.log('Part Number:', part1?.partNumber);

    console.log('--- Part 2 ---');
    console.log('Test Title:', part2?.test?.title);
    console.log('Part Number:', part2?.partNumber);

    const attempts1 = await prisma.testAttempt.findMany({ 
        where: { partId: p1 }, 
        include: { details: { take: 5 } },
        orderBy: { createdAt: 'desc' },
        take: 1
    });

    const attempts2 = await prisma.testAttempt.findMany({ 
        where: { partId: p2 }, 
        include: { details: { take: 5 } },
        orderBy: { createdAt: 'desc' },
        take: 1
    });

    console.log('--- Attempt 1 ---');
    if (attempts1.length > 0) {
        console.log('ID:', attempts1[0].id);
        console.log('Correct Count:', attempts1[0].correctCount);
        console.log('Details Sample:', attempts1[0].details.map(d => ({ qId: d.questionId, correct: d.isCorrect })));
    } else {
        console.log('No attempts found for Part 1');
    }

    console.log('--- Attempt 2 ---');
    if (attempts2.length > 0) {
        console.log('ID:', attempts2[0].id);
        console.log('Correct Count:', attempts2[0].correctCount);
        console.log('Details Sample:', attempts2[0].details.map(d => ({ qId: d.questionId, correct: d.isCorrect })));
    } else {
        console.log('No attempts found for Part 2');
    }
}

check().catch(console.error);
