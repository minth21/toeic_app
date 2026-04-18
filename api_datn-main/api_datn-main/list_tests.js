
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function listTests() {
  try {
    const tests = await prisma.test.findMany({
      select: { id: true, title: true }
    });
    console.log('--- DANH SÁCH BÀI TEST TRONG DB ---');
    tests.forEach(t => console.log(`- ID: ${t.id} | Title: ${t.title}`));
  } catch (err) {
    console.error(err);
  } finally {
    await prisma.$disconnect();
  }
}

listTests();
