import { PrismaClient } from '@prisma/client';
import * as dotenv from 'dotenv';
dotenv.config();

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

    console.log(JSON.stringify(questions, (_, value) => {
        // Truncate long fields for easier reading
        if (typeof value === 'string' && value.length > 100) {
            return value.substring(0, 100) + '...';
        }
        return value;
    }, 2));
}

main()
    .finally(async () => {
        await prisma.$disconnect();
    });
