
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function showPart5Details() {
  console.log('--- CHI TIẾT BẢNG KẾT QUẢ PART 5 (TOEIC-TEST 1) ---');
  
  try {
    // 1. Tìm Test 1
    const tests = await prisma.test.findMany({
      where: { title: 'TOEIC-TEST 1' },
      include: {
        parts: {
          where: { partNumber: 5 },
          include: { questions: { select: { id: true, questionNumber: true, correctAnswer: true } } }
        }
      }
    });

    const allP5QuestIds = tests.flatMap(t => t.parts.flatMap(p => p.questions.map(q => q.id)));
    
    // 2. Tìm lượt làm bài gần nhất
    const lastAttempt = await prisma.testAttempt.findFirst({
      where: {
        details: { some: { questionId: { in: allP5QuestIds } } }
      },
      orderBy: { createdAt: 'desc' },
      include: {
        details: {
          where: { questionId: { in: allP5QuestIds } },
          include: { question: { select: { id: true, questionNumber: true, correctAnswer: true } } }
        }
      }
    });

    if (!lastAttempt) {
      console.log('❌ Không tìm thấy lượt làm bài nào.');
      return;
    }

    console.log(`✅ Lượt làm bài ngày: ${lastAttempt.createdAt}`);
    console.log('--------------------------------------------------------------------------------------');
    console.log('STT | Question ID (UUID)                     | User Ans | Correct Ans | Kết quả');
    console.log('--------------------------------------------------------------------------------------');

    // Sắp xếp theo số thứ tự câu hỏi
    const sortedDetails = lastAttempt.details.sort((a, b) => 
      (a.question.questionNumber || 0) - (b.question.questionNumber || 0)
    );

    sortedDetails.forEach(d => {
      const q = d.question;
      const qId = q.id;
      const qNum = q.questionNumber.toString().padEnd(3);
      const userAns = (d.userAnswer || 'EMPTY').padEnd(8);
      const corrAns = (q.correctAnswer || 'N/A').padEnd(11);
      const status = d.isCorrect ? '✅ ĐÚNG' : '❌ SAI';
      
      console.log(`${qNum} | ${qId} | ${userAns} | ${corrAns} | ${status}`);
    });
    
    const correctCount = lastAttempt.details.filter(d => d.isCorrect).length;
    console.log('--------------------------------------------------------------------------------------');
    console.log(`📊 TỔNG CỘNG: Đúng ${correctCount}/${lastAttempt.details.length} câu.`);

  } catch (err) {
    console.error('❌ Lỗi:', err);
  } finally {
    await prisma.$disconnect();
  }
}

showPart5Details();
