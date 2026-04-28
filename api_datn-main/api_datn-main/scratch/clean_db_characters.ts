import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const cleanHtml = (text: string) => {
    if (!text || typeof text !== 'string') return text;
    return text
        .replace(/&nbsp;/g, ' ')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/\s+/g, ' ')
        .trim();
};

async function main() {
    console.log('🚀 Bắt đầu dọn dẹp dữ liệu rác trong Database...');

    // Lấy toàn bộ câu hỏi có khả năng chứa dữ liệu AI (Reading Parts 5, 6, 7 và Listening)
    const questions = await prisma.question.findMany({
        select: {
            id: true,
            questionNumber: true,
            passage: true,
            questionTranslation: true,
            explanation: true,
            analysis: true,
            evidence: true,
            keyVocabulary: true,
            passageTranslationData: true,
            optionTranslations: true,
        }
    });

    console.log(`🔍 Tìm thấy ${questions.length} câu hỏi. Đang xử lý...`);

    let updateCount = 0;

    for (const q of questions) {
        let needsUpdate = false;
        const updates: any = {};

        // 1. Clean simple text fields
        const textFields: (keyof typeof q)[] = ['passage', 'questionTranslation', 'explanation', 'analysis', 'evidence'];
        for (const field of textFields) {
            const original = q[field] as string;
            if (original) {
                const cleaned = cleanHtml(original);
                if (cleaned !== original) {
                    updates[field] = cleaned;
                    needsUpdate = true;
                }
            }
        }

        // 2. Clean keyVocabulary (JSON)
        if (q.keyVocabulary) {
            try {
                const vocab = typeof q.keyVocabulary === 'string' ? JSON.parse(q.keyVocabulary) : q.keyVocabulary;
                if (Array.isArray(vocab)) {
                    let vocabChanged = false;
                    const cleanedVocab = vocab.map((v: any) => {
                        const cleanV = { ...v };
                        ['word', 'text', 'type', 'pos', 'ipa', 'pronunciation', 'meaning'].forEach(key => {
                            if (v[key]) {
                                const original = v[key];
                                const cleaned = cleanHtml(original);
                                if (cleaned !== original) {
                                    cleanV[key] = cleaned;
                                    vocabChanged = true;
                                }
                            }
                        });
                        return cleanV;
                    });

                    if (vocabChanged) {
                        updates.keyVocabulary = JSON.stringify(cleanedVocab);
                        needsUpdate = true;
                    }
                }
            } catch (e) {
                // Skip if not valid JSON
            }
        }

        // 3. Clean passageTranslationData (JSON)
        if (q.passageTranslationData) {
            try {
                const data = typeof q.passageTranslationData === 'string' ? JSON.parse(q.passageTranslationData) : q.passageTranslationData;
                let dataChanged = false;
                
                // Handle different schemas of passageTranslationData
                const passages = data.passages || data.passageTranslations || (Array.isArray(data) ? data : null);
                if (passages && Array.isArray(passages)) {
                    passages.forEach((p: any) => {
                        if (p.label) {
                            const original = p.label;
                            const cleaned = cleanHtml(original);
                            if (cleaned !== original) {
                                p.label = cleaned;
                                dataChanged = true;
                            }
                        }
                        if (p.items && Array.isArray(p.items)) {
                            p.items.forEach((item: any) => {
                                ['en', 'vi'].forEach(key => {
                                    if (item[key]) {
                                        const original = item[key];
                                        const cleaned = cleanHtml(original);
                                        if (cleaned !== original) {
                                            item[key] = cleaned;
                                            dataChanged = true;
                                        }
                                    }
                                });
                            });
                        }
                    });
                }

                if (dataChanged) {
                    updates.passageTranslationData = JSON.stringify(data);
                    needsUpdate = true;
                }
            } catch (e) {
                // Skip if not valid JSON
            }
        }

        // 4. Clean optionTranslations (JSON)
        if (q.optionTranslations) {
            try {
                const ots = typeof q.optionTranslations === 'string' ? JSON.parse(q.optionTranslations) : q.optionTranslations;
                if (ots && typeof ots === 'object') {
                    let otChanged = false;
                    Object.keys(ots).forEach(key => {
                        const original = ots[key];
                        const cleaned = cleanHtml(original);
                        if (cleaned !== original) {
                            ots[key] = cleaned;
                            otChanged = true;
                        }
                    });
                    if (otChanged) {
                        updates.optionTranslations = JSON.stringify(ots);
                        needsUpdate = true;
                    }
                }
            } catch (e) {}
        }

        if (needsUpdate) {
            await prisma.question.update({
                where: { id: q.id },
                data: updates
            });
            updateCount++;
            if (updateCount % 10 === 0) console.log(`✅ Đã dọn dẹp ${updateCount} câu hỏi...`);
        }
    }

    console.log(`\n✨ HOÀN TẤT! Đã làm sạch tổng cộng ${updateCount} câu hỏi.`);
}

main()
    .catch((e) => {
        console.error('❌ Lỗi thực thi:', e);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
