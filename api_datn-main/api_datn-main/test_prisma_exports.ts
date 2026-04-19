import { PrismaClient, Role } from '@prisma/client';

console.log('PrismaClient:', typeof PrismaClient);
console.log('Role enum:', Role);

const prisma = new PrismaClient();
console.log('Instance created successfully');
