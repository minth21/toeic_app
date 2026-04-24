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
                    newGroups[gIdx].passageTranslationData = aiData.passageTranslations;
                    // Flatten to simple translation string for backward compatibility/UI
                    const allVi = aiData.passageTranslations.flatMap((pt: any) => pt.items || []).map((i: any) => i.vi).join(' ');
                    newGroups[gIdx].translation = allVi;
                }

                // 2. Handle Vocabulary
                if (aiData.vocabulary && aiData.vocabulary.length > 0) {
                    newGroups[gIdx].vocabulary = aiData.vocabulary.map((v: any) => ({
                        text: v.word || v.text,
                        pos: v.type || v.pos,
                        ipa: v.ipa || '',
                        meaning: v.meaning
                    }));
                }

                // 3. Handle Question Explanations/Analysis
                if (aiData.questions) {
                    aiData.questions.forEach((aiQ: any) => {
                        const qIdx = newGroups[gIdx].questions.findIndex((q: any) => q.questionNumber === aiQ.questionNumber);
                        if (qIdx !== -1) {
                            const analysis = aiQ.analysis || '';
                            const evidence = aiQ.evidence ? `<br/><br/><b>Dẫn chứng:</b> ${aiQ.evidence}` : '';
                            
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

            setBatchLabel(`Đang phân tích AI (${batchStart + 1}–${batchEnd} / ${totalQuestions})...`);

            const currentSnapshot = groups.slice(batchStart, batchEnd);
            // AI sẽ xử lý nếu giải thích, bản dịch hoặc từ vựng đang bị trống
            const questionsToProcess = currentSnapshot.filter(q => {
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

                            return {
                                ...q,
                                correctAnswer: (!q.correctAnswer || q.correctAnswer === '')
                                    ? (String(aiItem.calculatedAnswer || q.correctAnswer).toUpperCase())
                                    : q.correctAnswer,
                                explanation: useOldExplanation ? q.explanation : (aiItem.explanation ?? q.explanation),
                                questionTranslation: useOldTranslation ? q.questionTranslation : (aiItem.questionTranslation ?? q.questionTranslation),
                                optionTranslations: aiItem.optionTranslations
                                    ? JSON.stringify(aiItem.optionTranslations)
                                    : q.optionTranslations,
                                keyVocabulary: useOldVocab ? q.keyVocabulary : (aiItem.keyVocabulary
                                    ? JSON.stringify(aiItem.keyVocabulary)
                                    : q.keyVocabulary),
                                level: aiItem.level ?? q.level,
                            };
                        }));
                    }
                } catch (batchError: any) {
                    console.error(`[AI Batch ${batchIndex + 1}] Error:`, batchError?.message || batchError);
                }
            }

            setAiProgress(Math.round((batchEnd / totalQuestions) * 100));

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
