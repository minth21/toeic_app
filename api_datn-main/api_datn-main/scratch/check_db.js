const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const prisma = new PrismaClient();

async function main() {
    const questions = await prisma.question.findMany({
        where: {
            questionNumber: {
                in: [143, 144, 145, 146]
            }
        },
        orderBy: {
            questionNumber: 'asc'
        }
    });

    console.log(JSON.stringify(questions, (key, value) => {
        if (typeof value === 'string' && value.length > 200) {
            return value.substring(0, 200) + '...';
        }
        return value;
    }, 2));
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
