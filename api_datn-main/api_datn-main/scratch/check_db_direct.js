const { Client } = require('pg');
require('dotenv').config();

const client = new Client({
    connectionString: process.env.DATABASE_URL
});

async function main() {
    await client.connect();
    const start = process.argv[2] || 131;
    const end = process.argv[3] || 134;
    const res = await client.query('SELECT "questionNumber", "passageTranslationData", "analysis", "evidence", "keyVocabulary", "optionTranslations" FROM questions WHERE "questionNumber" BETWEEN $1 AND $2 ORDER BY "questionNumber" ASC', [start, end]);
    
    console.log(JSON.stringify(res.rows, (key, value) => {
        if (typeof value === 'string' && value.length > 100) {
            return value.substring(0, 100) + '...';
        }
        return value;
    }, 2));
    
    await client.end();
}

main().catch(console.error);
