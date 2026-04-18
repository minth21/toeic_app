import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function run() {
    const teacher = await prisma.user.findFirst({ where: { username: 'GV001' } });
    if (!teacher) {
        console.log('Teacher GV001 not found');
    } else {
        console.log(`Teacher GV001: id=${teacher.id}, username=${teacher.username}, role=${teacher.role}`);
        
        // Check classes managed by this teacher
        const classes = await prisma.class.findMany({ where: { teacherId: teacher.id } });
        console.log(`Classes managed by this teacher id (${teacher.id}): ${classes.length}`);
        classes.forEach(c => console.log(`- Class: ${c.className} (${c.id})`));

        // Check classes managed by teacher.username just in case
        const classesByUsername = await prisma.class.findMany({ where: { teacherId: teacher.username } });
        console.log(`Classes managed by this teacher username (${teacher.username}): ${classesByUsername.length}`);
    }

    const student = await prisma.user.findFirst({ where: { name: { contains: 'Giang' } } });
    if (student) {
        console.log(`Student Thi Giang: id=${student.id}, studentClassId=${student.studentClassId}`);
        
        if (teacher && student.studentClassId) {
             const check = await prisma.class.findFirst({
                 where: { id: student.studentClassId, teacherId: teacher.id }
             });
             console.log(`Permission Check (TeacherID: ${teacher.id}): ${!!check}`);
             
             const checkByUsername = await prisma.class.findFirst({
                 where: { id: student.studentClassId, teacherId: teacher.username }
             });
             console.log(`Permission Check (TeacherID: ${teacher.username}): ${!!checkByUsername}`);
        }
    }
}

run().catch(console.error).finally(() => prisma.$disconnect());
