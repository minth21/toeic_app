
import { prisma } from './src/config/prisma';

async function checkQuestions() {
    const p2 = '261486ba-e02c-4a7e-a247-d0d128140274'; // Test 2 Part 5
    const questions = await prisma.question.findMany({ 
        where: { partId: p2 },
        select: { id: true, questionNumber: true, correctAnswer: true }
    });

    const missingCorrect = questions.filter(q => !q.correctAnswer || q.correctAnswer.trim() === '');
    
    console.log('Total Questions:', questions.length);
    console.log('Questions missing correct answer:', missingCorrect.length);
    if (missingCorrect.length > 0) {
        console.log('Sample IDs:', missingCorrect.slice(0, 5).map(q => q.id));
    }
}

checkQuestions().catch(console.error);
