import { useState } from 'react';
import { message } from 'antd';
import { aiApi } from '../services/api';

/**
 * Custom hook to handle AI Magic generation across different TOEIC Parts
 */
export const useAIImport = (groups: any[], setGroups: (val: any[] | ((prev: any[]) => any[])) => void, partNumber: number) => {
    const [loading, setLoading] = useState(false);
    const [isAiProcessing, setIsAiProcessing] = useState(false);
    const [aiProgress, setAiProgress] = useState(0);
    const [batchLabel, setBatchLabel] = useState<string>('');

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

    /**
     * Handles AI generation for a specific group (Used in Parts 1-4, 6-7)
     */
    const handleAIGenerate = async (gIdx: number) => {
        const group = groups[gIdx];
        const content = group.transcript || group.passage;

        if (!content) {
            message.warning(`Vui lòng nhập ${group.transcript ? 'transcript' : 'nội dung đoạn văn'} trước khi sử dụng AI Magic`);
            return;
        }

        setLoading(true);
        try {
            let res;
            if (partNumber <= 4) {
                // Listening Parts 1-4
                res = await aiApi.generateListeningExplanation({
                    transcript: group.transcript,
                    questions: group.questions
                });
            } else {
                // Reading Parts 6-7
                res = await aiApi.generateReadingExplanation({
                    passageText: group.passage,
                    questions: group.questions
                }, partNumber);
            }

            if (res.success && res.data) {
                const newGroups = [...groups];
                const aiData = res.data;

                // 1. Handle Passage Translation Data (Touch-to-Translate)
                if (aiData.passageTranslations) {
                    const cleanedTranslations = aiData.passageTranslations.map((pt: any) => ({
                        ...pt,
                        label: cleanHtml(pt.label),
                        items: (pt.items || []).map((item: any) => {
                            const en = cleanHtml(item.en);
                            const vi = cleanHtml(item.vi);
                            
                            // Tự động đục lỗ nếu phát hiện số câu hỏi trong câu EN
                            const qMatch = en.match(/\((\d{3})\)|\[(\d{3})\]/);
                            if (qMatch) {
                                const qNum = qMatch[1] || qMatch[2];
                                
                                // Đục lỗ EN: 
                                // Nếu câu chỉ chứa dấu gạch hoặc là một câu ngắn chứa số, đục lỗ toàn bộ phần trước số
                                // Nếu là câu dài, chỉ đục lỗ từ đứng ngay trước số
                                let maskedEn = en;
                                if (en.length < 50 || en.includes('___')) {
                                    maskedEn = en.replace(/^.*(\(\d{3}\)|\[\d{3}\])/g, `____ [${qNum}]`);
                                } else {
                                    maskedEn = en.replace(/(\S+)\s*(\(\d{3}\)|\[\d{3}\])/g, `____ [${qNum}]`);
                                }
                                
                                // Đục lỗ VI: Luôn đồng nhất là gạch trống
                                const maskedVi = `_______ [${qNum}]`;
                                
                                return { ...item, en: maskedEn, vi: maskedVi };
                            }
                            
                            return { ...item, en, vi };
                        })
                    }));
                    
                    newGroups[gIdx].passageTranslationData = cleanedTranslations;
                    // Flatten to simple translation string for backward compatibility/UI
                    const allVi = cleanedTranslations.flatMap((pt: any) => pt.items || []).map((i: any) => i.vi).join(' ');
                    newGroups[gIdx].translation = allVi;
                }

                // 2. Handle Vocabulary
                if (aiData.vocabulary && aiData.vocabulary.length > 0) {
                    newGroups[gIdx].vocabulary = aiData.vocabulary.map((v: any) => ({
                        text: cleanHtml(v.word || v.text),
                        pos: cleanHtml(v.type || v.pos),
                        ipa: cleanHtml(v.ipa || v.pronunciation || ''),
                        meaning: cleanHtml(v.meaning)
                    }));
                }

                // 3. Handle Question Explanations/Analysis
                if (aiData.questions) {
                    aiData.questions.forEach((aiQ: any) => {
                        const qIdx = newGroups[gIdx].questions.findIndex((q: any) => q.questionNumber === aiQ.questionNumber);
                        if (qIdx !== -1) {
                            const analysis = cleanHtml(aiQ.analysis || '');
                            const rawEvidence = cleanHtml(aiQ.evidence || '');
                            const evidence = rawEvidence ? `<br/><br/><b>Dẫn chứng:</b> ${rawEvidence}` : '';
                            
                            // Compatibility: Part 6 uses .explanation, others might use .explanation field inside question
                            if (partNumber === 6) {
                                newGroups[gIdx].questions[qIdx].explanation = analysis + evidence;
                            } else {
                                // For Part 3, 4, 7
                                (newGroups[gIdx].questions[qIdx] as any).explanation = analysis + evidence;
                            }
                        }
                    });
                }

                setGroups(newGroups);
                message.success(`AI Magic đã xử lý xong nhóm ${gIdx + 1}!`);
            }
        } catch (error) {
            console.error('AI Magic error:', error);
            message.error('Lỗi khi gọi AI Magic. Vui lòng thử lại.');
        } finally {
            setLoading(false);
        }
    };

    /**
     * Handles batch AI enrichment for all questions (Specifically for Part 5)
     */
    const handleEnrichPart5All = async () => {
        if (partNumber !== 5) return;

        const totalQuestions = groups.length;
        const BATCH_SIZE = 3;
        const totalBatches = Math.ceil(totalQuestions / BATCH_SIZE);
        
        setIsAiProcessing(true);
        setAiProgress(0);
        setBatchLabel('Đang khởi động AI...');

        for (let batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
            const batchStart = batchIndex * BATCH_SIZE;
            const batchEnd = Math.min(batchStart + BATCH_SIZE, totalQuestions);

            // Kiểm tra xem batch này có câu nào trống không. 
            // Nếu phát hiện câu đầu tiên của batch bị trống nội dung, dừng toàn bộ quá trình.
            const batchQuestions = groups.slice(batchStart, batchEnd);
            const emptyQuestionIndex = batchQuestions.findIndex(q => !q.questionText || q.questionText.trim() === '');
            
            if (emptyQuestionIndex !== -1) {
                // Nếu câu đầu tiên của batch đã trống, dừng hẳn
                if (emptyQuestionIndex === 0) break;
                // Nếu không phải câu đầu, chỉ lấy những câu có nội dung trước đó rồi dừng
                const validQuestionsInBatch = batchQuestions.slice(0, emptyQuestionIndex);
                if (validQuestionsInBatch.length === 0) break;
            }

            setBatchLabel(`Đang phân tích AI (${batchStart + 1}–${batchEnd} / ${totalQuestions})...`);

            const currentSnapshot = groups.slice(batchStart, batchEnd);
            // AI sẽ xử lý nếu giải thích, bản dịch hoặc từ vựng đang bị trống VÀ nội dung câu hỏi KHÔNG trống
            const questionsToProcess = currentSnapshot.filter(q => {
                const hasText = q.questionText && q.questionText.trim() !== '';
                if (!hasText) return false;

                const hasExplanation = q.explanation?.trim();
                const hasTranslation = q.questionTranslation?.trim();
                const hasVocab = q.keyVocabulary && (typeof q.keyVocabulary === 'string' ? q.keyVocabulary !== '[]' : q.keyVocabulary.length > 0);
                return !hasExplanation || !hasTranslation || !hasVocab;
            });

            if (questionsToProcess.length > 0) {
                try {
                    const response = await aiApi.enrichPart5Batch({
                        questions: questionsToProcess.map(q => ({
                            questionNumber: q.questionNumber,
                            questionText: q.questionText,
                            options: { A: q.optionA, B: q.optionB, C: q.optionC, D: q.optionD },
                            correctAnswer: q.correctAnswer,
                        })),
                    });

                    if (response.success && Array.isArray(response.data)) {
                        const aiMap = new Map<number, any>(
                            response.data.map((item: any) => [Number(item.questionNumber), item])
                        );

                        setGroups((prev: any[]) => prev.map(q => {
                            const aiItem = aiMap.get(Number(q.questionNumber));
                            if (!aiItem) return q; 
                            
                            // Chỉ giữ lại dữ liệu cũ nếu nó thực sự có nội dung (dài hơn 10 ký tự)
                            const useOldExplanation = q.explanation?.trim() && q.explanation.length > 50;
                            const useOldTranslation = q.questionTranslation?.trim() && q.questionTranslation.length > 5;
                            const useOldVocab = q.keyVocabulary && (typeof q.keyVocabulary === 'string' ? q.keyVocabulary.length > 10 : q.keyVocabulary.length > 0);

                            // Clean option translations if they exist
                            let cleanedOptionTranslations = q.optionTranslations;
                            if (aiItem.optionTranslations) {
                                const rawOT = aiItem.optionTranslations;
                                const cleanOT: any = {};
                                Object.keys(rawOT).forEach(key => {
                                    cleanOT[key] = cleanHtml(rawOT[key]);
                                });
                                cleanedOptionTranslations = JSON.stringify(cleanOT);
                            }

                            // Clean vocabulary if it exists
                            let cleanedVocab = q.keyVocabulary;
                            if (aiItem.keyVocabulary && Array.isArray(aiItem.keyVocabulary)) {
                                const cleanV = aiItem.keyVocabulary.map((v: any) => ({
                                    word: cleanHtml(v.word || v.text),
                                    type: cleanHtml(v.type || v.pos),
                                    ipa: cleanHtml(v.ipa || v.pronunciation || ''),
                                    meaning: cleanHtml(v.meaning)
                                }));
                                cleanedVocab = JSON.stringify(cleanV);
                            }

                            return {
                                ...q,
                                correctAnswer: (!q.correctAnswer || q.correctAnswer === '')
                                    ? (String(aiItem.calculatedAnswer || q.correctAnswer).toUpperCase())
                                    : q.correctAnswer,
                                explanation: useOldExplanation ? q.explanation : cleanHtml(aiItem.explanation ?? q.explanation),
                                questionTranslation: useOldTranslation ? q.questionTranslation : cleanHtml(aiItem.questionTranslation ?? q.questionTranslation),
                                optionTranslations: cleanedOptionTranslations,
                                keyVocabulary: useOldVocab ? q.keyVocabulary : cleanedVocab,
                                level: aiItem.level ?? q.level,
                            };
                        }));
                    }
                } catch (batchError: any) {
                    console.error(`[AI Batch ${batchIndex + 1}] Error:`, batchError?.message || batchError);
                }
            }

            setAiProgress(Math.round((batchEnd / totalQuestions) * 100));

            // Nếu trong batch này có câu trống, nghĩa là đã hết câu hỏi thực tế, dừng loop sau batch này
            if (emptyQuestionIndex !== -1) break;

            // Wait to avoid rate limits
            if (batchEnd < totalQuestions) {
                await new Promise(resolve => setTimeout(resolve, 8000));
            }
        }

        setIsAiProcessing(false);
        setBatchLabel('');
        setAiProgress(100);
        message.success('AI Magic đã hoàn thành xử lý toàn bộ Part 5!');
    };

    return {
        loading,
        isAiProcessing,
        aiProgress,
        batchLabel,
        handleAIGenerate,
        handleEnrichPart5All
    };
};
