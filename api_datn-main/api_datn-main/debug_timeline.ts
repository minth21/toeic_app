import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    const user = await (prisma as any).user.findFirst({ where: { name: { contains: 'Giang' } } });
    if (!user) { console.log('User Thi Giang not found'); return; }

    console.log(`User: ${user.name} (${user.id}), ClassId: ${user.studentClassId}, Role: ${user.role}`);

    const allAssessments = await (prisma as any).aiAssessment.findMany({
        where: { userId: user.id }
    });

    console.log(`Total assessments found in DB: ${allAssessments.length}`);
    allAssessments.forEach((a: any) => {
        console.log(`- ID: ${a.id}, Type: ${a.type}, Title: ${a.title}`);
    });

    // Test the logic
    const studentQuery = {
        userId: user.id,
        OR: [
            { type: { not: 'COACHING' } },
            { 
                type: 'COACHING', 
                title: { not: 'Lộ trình phát triển năng lực cá nhân' } 
            }
        ]
    };

    const studentResults = await (prisma as any).aiAssessment.findMany({ where: studentQuery });
    console.log(`Student View Results: ${studentResults.length}`);

    const teacherQuery = { userId: user.id };
    const teacherResults = await (prisma as any).aiAssessment.findMany({ where: teacherQuery });
    console.log(`Teacher View Results: ${teacherResults.length}`);
}

run().catch(console.error).finally(() => prisma.$disconnect());
