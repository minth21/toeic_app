/**
 * Utility to validate and standardize passage translation data.
 * Ensures the data follows the structure: [{label, sentences: [{en, vi, vocab: [{text, meaning}]}]}]
 */

export interface VocabItem {
    text: string;
    meaning: string;
}

export interface SentenceItem {
    en: string;
    vi: string;
    vocab?: VocabItem[];
}

export interface PassageBlock {
    label: string;
    sentences: SentenceItem[];
}

/**
 * Validates and standardizes passage translation data.
 * @param data Stringified JSON or Object
 * @returns Standardized flat JSON string [ { type: 'passage', ... } ]
 */
export const validateAndStandardizePassageData = (data: any): string | null => {
    if (!data) return null;

    let parsed: any;
    try {
        const cleanJson = (text: string) => {
            return text.replace(/```json|```/g, '').trim();
        };
        parsed = typeof data === 'string' ? JSON.parse(cleanJson(data)) : data;
    } catch (e) {
        console.error('[PassageValidator] Parse Error:', e);
        console.error('[PassageValidator] Raw Data:', data);
        throw new Error('Định dạng JSON của bản dịch không hợp lệ.');
    }

    // --- RULE: If it's already an array, keep it; if it's an object, wrap it ---
    if (parsed && !Array.isArray(parsed)) {
        if (parsed.passages || parsed.passageTranslations) {
            parsed = parsed.passages || parsed.passageTranslations;
        } else if (parsed.en || parsed.vi || parsed.items || parsed.sentences || parsed.content) {
            parsed = [parsed];
        } else {
            // If it's some other object, try to preserve it by wrapping
            parsed = [parsed];
        }
    }

    if (!Array.isArray(parsed)) {
        return null;
    }

    // Standardization & Validation
    const standardized: any[] = parsed.map((block: any, index: number) => {
        // Case 1: Legacy format (Flat array of {en, vi})
        if (block.en || block.vi) {
            return {
                type: 'passage',
                label: String(block.label || (index === 0 ? 'Passage' : `Passage ${index + 1}`)),
                items: [{
                    en: String(block.en || '').replace(/&nbsp;/g, ' ').trim(),
                    vi: String(block.vi || '').replace(/&nbsp;/g, ' ').trim(),
                    vocab: Array.isArray(block.vocab) ? block.vocab.map((v: any) => ({
                        text: String(v.text || v.lemma || '').replace(/&nbsp;/g, ' ').trim(),
                        meaning: String(v.meaning || '').replace(/&nbsp;/g, ' ').trim(),
                        ipa: String(v.ipa || '').replace(/&nbsp;/g, ' ').trim()
                    })) : []
                }]
            };
        }

        // Case 3: General format (simple content + vocabulary)
        if (block.type === 'general' || block.content !== undefined) {
            return {
                type: 'general',
                label: String(block.label || 'Bản dịch & Từ vựng'),
                content: String(block.content || '').trim(),
                vocabulary: Array.isArray(block.vocabulary) ? block.vocabulary.map((v: any) => ({
                    text: String(v.text || '').trim(),
                    pos: String(v.pos || v.wordType || '').trim(),
                    ipa: String(v.ipa || '').trim(),
                    meaning: String(v.meaning || '').trim()
                })) : []
            };
        }

        // Case 2: Standard format (supports both 'sentences' and 'items')
        const rawItems = Array.isArray(block.items) ? block.items : (Array.isArray(block.sentences) ? block.sentences : []);
        
        const items = rawItems.map((s: any) => ({
            en: String(s.en || '').replace(/&nbsp;/g, ' ').trim(),
            vi: String(s.vi || '').replace(/&nbsp;/g, ' ').trim(),
            vocab: Array.isArray(s.vocab) ? s.vocab.map((v: any) => ({
                text: String(v.text || v.lemma || '').replace(/&nbsp;/g, ' ').trim(),
                meaning: String(v.meaning || '').replace(/&nbsp;/g, ' ').trim(),
                ipa: String(v.ipa || '').replace(/&nbsp;/g, ' ').trim()
            })) : []
        }));

        return {
            type: block.type || 'passage',
            label: String(block.label || (index === 0 ? 'Passage' : `Passage ${index + 1}`)),
            items
        };
    }).filter((block: any) => (block.items && block.items.length > 0) || (block.type === 'general' && block.content));

    if (standardized.length === 0) return null;

    // RULE 4: Always return the flat array as JSON string
    return JSON.stringify(standardized);
};
