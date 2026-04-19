import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';
import 'dotenv/config';

/**
 * Prisma Client Singleton
 * Ensures only one instance of PrismaClient exists throughout the application
 */
class PrismaService {
    private static instance: PrismaClient;

    private constructor() {
        // Private constructor to prevent direct instantiation
    }

    public static getInstance(): PrismaClient {
        if (!PrismaService.instance) {
            const pool = new Pool({ connectionString: process.env.DATABASE_URL });
            const adapter = new PrismaPg(pool);
            
            PrismaService.instance = new PrismaClient({
                adapter,
                log: ['error', 'warn']
            });


            // Graceful shutdown
            process.on('beforeExit', async () => {
                await PrismaService.instance.$disconnect();
                logger.info('Prisma Client disconnected');
            });

            logger.info('Prisma Client initialized');
        }

        return PrismaService.instance;
    }

    public static async connect(): Promise<void> {
        try {
            await this.getInstance().$connect();
            logger.info('✅ Database connected successfully');
        } catch (error) {
            logger.error('❌ Database connection failed:', error);
            throw error;
        }
    }

    public static async disconnect(): Promise<void> {
        await this.getInstance().$disconnect();
        logger.info('Database disconnected');
    }
}

// Export singleton instance
export const prisma = PrismaService.getInstance();
export default PrismaService;
