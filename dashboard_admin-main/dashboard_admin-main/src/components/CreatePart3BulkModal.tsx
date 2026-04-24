import { useState, useEffect } from 'react';
import * as XLSX from 'xlsx';
import { Modal, Button, Row, Col, Input, Typography, Divider, Upload, Image, message, Select, Tag, Space, Card, Tabs } from 'antd';
import {
    PlusOutlined,
    DeleteOutlined,
    CheckCircleOutlined,
    GlobalOutlined,
    BookOutlined,
    FileExcelOutlined,
    FileTextOutlined,
    PictureOutlined
} from '@ant-design/icons';
import ReactQuill from 'react-quill-new';
import 'quill/dist/quill.snow.css';
import { uploadApi, questionApi, partApi } from '../services/api';
import AudioBanner from './AudioBanner';

const { Text, Title } = Typography;
const { Option } = Select;

interface QuestionData {
    id?: string;
    questionNumber: number;
    questionText: string;
    optionA: string;
    optionB: string;
    optionC: string;
    optionD: string;
    correctAnswer: string;
    explanation?: string;
}

interface GroupData {
    transcript: string;
    graphicPreview: string | null;
    graphicFile: File | null;
    questions: QuestionData[];
    translationSentences: { en: string; vi: string }[];
    keyVocabulary: { word: string; type: string; ipa: string; meaning: string }[];
}

interface CreatePart3BulkModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    currentAudioUrl?: string;
    partNumber: number;
    partName?: string;
    initialData?: any[];
}

export default function CreatePart3BulkModal({ open, onCancel, onSuccess, partId, currentAudioUrl, partNumber, initialData }: CreatePart3BulkModalProps) {
    const [loading, setLoading] = useState(false);
    const [groups, setGroups] = useState<GroupData[]>([]);
    const [audioFile, setAudioFile] = useState<File | null>(null);

    useEffect(() => {
        if (open) {
            const groupCount = partNumber === 3 ? 13 : 10;
            const startQ = partNumber === 3 ? 32 : 71;

            const initialGroups: GroupData[] = Array.from({ length: groupCount }, (_, gIdx) => ({
                transcript: '',
                graphicPreview: null,
                graphicFile: null,
                translationSentences: [],
                keyVocabulary: [],
                questions: Array.from({ length: 3 }, (_, qIdx) => ({
                    questionNumber: startQ + (gIdx * 3) + qIdx,
                    questionText: '',
                    optionA: '',
                    optionB: '',
                    optionC: '',
                    optionD: '',
                    correctAnswer: 'A'
                }))
            }));

            if (initialData && initialData.length > 0) {
                initialData.forEach((row: any) => {
                    const qNum = Number(row['Số câu'] || row['questionNumber'] || 0);
                    if (qNum >= startQ && qNum < startQ + (groupCount * 3)) {
                        const relativeIdx = qNum - startQ;
                        const gIdx = Math.floor(relativeIdx / 3);
                        const qIdx = relativeIdx % 3;
                        const targetQuestion = initialGroups[gIdx].questions[qIdx];
                        targetQuestion.id = row.id; // ✅ Quan trọng để Update
                        targetQuestion.questionText = String(row['Nội dung câu hỏi'] || row['questionText'] || '');
                        targetQuestion.optionA = String(row['A'] || row['optionA'] || '');
                        targetQuestion.optionB = String(row['B'] || row['optionB'] || '');
                        targetQuestion.optionC = String(row['C'] || row['optionC'] || '');
                        targetQuestion.optionD = String(row['D'] || row['optionD'] || '');
                        targetQuestion.correctAnswer = (String(row['Đáp án đúng'] || row['correctAnswer'] || 'A').toUpperCase() as any);
                        targetQuestion.explanation = String(row['Giải thích'] || row['explanation'] || '');

                        // Load Transcript/Passage/Vocab/Translation từ câu hỏi đầu tiên của nhóm
                        if (row.transcript && !initialGroups[gIdx].transcript) initialGroups[gIdx].transcript = row.transcript;
                        if (row.passageImageUrl && !initialGroups[gIdx].graphicPreview) initialGroups[gIdx].graphicPreview = row.passageImageUrl;
                        
                        if (row.passageTranslationData && initialGroups[gIdx].translationSentences.length === 0) {
                            try {
                                const transData = typeof row.passageTranslationData === 'string' ? JSON.parse(row.passageTranslationData) : row.passageTranslationData;
                                const sentences = Array.isArray(transData) ? transData[0]?.items : transData.passages?.[0]?.items;
                                if (sentences) initialGroups[gIdx].translationSentences = sentences;
                            } catch (e) { console.error('Parse translation error', e); }
                        }

                        if (row.keyVocabulary && initialGroups[gIdx].keyVocabulary.length === 0) {
                            try {
                                const vocab = typeof row.keyVocabulary === 'string' ? JSON.parse(row.keyVocabulary) : row.keyVocabulary;
                                if (Array.isArray(vocab)) {
                                    initialGroups[gIdx].keyVocabulary = vocab.map((v: any) => ({
                                        word: v.word || v.text || '',
                                        type: v.type || v.lemma || '',
                                        ipa: v.ipa || '',
                                        meaning: v.meaning || ''
                                    }));
                                }
                            } catch (e) { console.error('Parse vocab error', e); }
                        }

                        const transcriptKey = Object.keys(row).find(k => {
                            const lowK = k.toLowerCase().trim();
                            return lowK.includes('transcript') || lowK.includes('hội thoại') || lowK.includes('lời thoại') || lowK.includes('nội dung') || lowK.includes('bài nói') || lowK.includes('đoạn văn');
                        });
                        const transcriptVal = transcriptKey ? row[transcriptKey] : null;
                        if (transcriptVal && !initialGroups[gIdx].transcript) initialGroups[gIdx].transcript = String(transcriptVal);
                    }
                });
            }
            // Nếu là chế độ "Sửa nhóm" (initialData có chứa câu hỏi có ID), 
            // ta chỉ hiển thị các nhóm thực sự có dữ liệu
            if (initialData && initialData.length > 0 && initialData.some(row => row.id)) {
                const activeGroups = initialGroups.filter(g => 
                    g.transcript.trim() !== '' || 
                    g.questions.some(q => q.id || q.questionText.trim() !== '')
                );
                setGroups(activeGroups);
            } else {
                setGroups(initialGroups);
            }
        }
    }, [open, partNumber, initialData]);

    const handleTranscriptChange = (gIdx: number, val: string) => {
        const newGroups = [...groups];
        newGroups[gIdx].transcript = val;
        setGroups(newGroups);
    };

    const handleGraphicChange = (gIdx: number, file: File) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            const newGroups = [...groups];
            newGroups[gIdx].graphicFile = file;
            newGroups[gIdx].graphicPreview = e.target?.result as string;
            setGroups(newGroups);
        };
        reader.readAsDataURL(file);
    };

    const handleQuestionChange = (gIdx: number, qIdx: number, field: keyof QuestionData, val: any) => {
        const newGroups = [...groups];
        (newGroups[gIdx].questions[qIdx] as any)[field] = val;
        setGroups(newGroups);
    };

    const handleAddTranslation = (gIdx: number) => {
        const newGroups = [...groups];
        newGroups[gIdx].translationSentences.push({ en: '', vi: '' });
        setGroups(newGroups);
    };

    const handleTranslationChange = (gIdx: number, tIdx: number, field: 'en' | 'vi', val: string) => {
        const newGroups = [...groups];
        newGroups[gIdx].translationSentences[tIdx][field] = val;
        setGroups(newGroups);
    };

    const handleRemoveTranslation = (gIdx: number, tIdx: number) => {
        const newGroups = [...groups];
        newGroups[gIdx].translationSentences.splice(tIdx, 1);
        setGroups(newGroups);
    };

    const handleAddVocab = (gIdx: number) => {
        const newGroups = [...groups];
        newGroups[gIdx].keyVocabulary.push({ word: '', type: '', ipa: '', meaning: '' });
        setGroups(newGroups);
    };

    const handleVocabChange = (gIdx: number, vIdx: number, field: keyof GroupData['keyVocabulary'][0], val: string) => {
        const newGroups = [...groups];
        (newGroups[gIdx].keyVocabulary[vIdx] as any)[field] = val;
        setGroups(newGroups);
    };

    const handleRemoveVocab = (gIdx: number, vIdx: number) => {
        const newGroups = [...groups];
        newGroups[gIdx].keyVocabulary.splice(vIdx, 1);
        setGroups(newGroups);
    };

    const handleRemoveQuestion = (gIdx: number, qIdx: number) => {
        const newGroups = [...groups];
        // Thay vì xóa khỏi array (làm xô lệch thứ tự 3 câu), ta sẽ clear nội dung
        // Hệ thống đã có logic filter câu hỏi trống khi lưu nên sẽ tự động bỏ qua câu này
        newGroups[gIdx].questions[qIdx] = {
            ...newGroups[gIdx].questions[qIdx],
            questionText: '',
            optionA: '',
            optionB: '',
            optionC: '',
            optionD: '',
            correctAnswer: 'A'
        };
        setGroups(newGroups);
        message.info(`Đã xóa nội dung câu ${newGroups[gIdx].questions[qIdx].questionNumber}`);
    };

    const handleAddGroup = () => {
        const lastGroup = groups[groups.length - 1];
        const nextStartQ = lastGroup ? lastGroup.questions[2].questionNumber + 1 : (partNumber === 3 ? 32 : 71);
        const newGroup: GroupData = {
            transcript: '',
            graphicPreview: null,
            graphicFile: null,
            translationSentences: [],
            keyVocabulary: [],
            questions: Array.from({ length: 3 }, (_, qIdx) => ({
                questionNumber: nextStartQ + qIdx,
                questionText: '',
                optionA: '',
                optionB: '',
                optionC: '',
                optionD: '',
                correctAnswer: 'A'
            }))
        };
        setGroups([...groups, newGroup]);
        message.success('Đã thêm 1 nhóm mới (3 câu hỏi)');
    };

    const handleExcelImport = (file: File) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const data = new Uint8Array(e.target?.result as ArrayBuffer);
                const workbook = XLSX.read(data, { type: 'array' });
                const sheet = workbook.Sheets[workbook.SheetNames[0]];
                const rows: any[] = XLSX.utils.sheet_to_json(sheet);
                if (rows.length === 0) { message.error('File Excel trống'); return; }

                const groupCount = partNumber === 3 ? 13 : 10;
                const startQ = partNumber === 3 ? 32 : 71;
                const finalGroups: GroupData[] = Array.from({ length: groupCount }, (_, gIdx) => ({
                    transcript: '', graphicPreview: null, graphicFile: null, translationSentences: [], keyVocabulary: [],
                    questions: Array.from({ length: 3 }, (_, qIdx) => ({
                        questionNumber: startQ + (gIdx * 3) + qIdx, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A'
                    }))
                }));

                rows.forEach((row: any) => {
                    const qNum = Number(row['Số câu'] || row['questionNumber'] || 0);
                    if (qNum >= startQ && qNum < startQ + (groupCount * 3)) {
                        const relativeIdx = qNum - startQ;
                        const gIdx = Math.floor(relativeIdx / 3);
                        const qIdx = relativeIdx % 3;
                        const targetQuestion = finalGroups[gIdx].questions[qIdx];
                        targetQuestion.questionText = String(row['Nội dung câu hỏi'] || row['questionText'] || '');
                        targetQuestion.optionA = String(row['A'] || row['optionA'] || '');
                        targetQuestion.optionB = String(row['B'] || row['optionB'] || '');
                        targetQuestion.optionC = String(row['C'] || row['optionC'] || '');
                        targetQuestion.optionD = String(row['D'] || row['optionD'] || '');
                        targetQuestion.correctAnswer = (String(row['Đáp án đúng'] || row['correctAnswer'] || 'A').toUpperCase() as any);
                        targetQuestion.explanation = String(row['Giải thích'] || row['explanation'] || '');

                        const transcriptKey = Object.keys(row).find(k => {
                            const lowK = k.toLowerCase().trim();
                            return lowK.includes('transcript') || lowK.includes('hội thoại') || lowK.includes('lời thoại') || lowK.includes('nội dung') || lowK.includes('bài nói') || lowK.includes('đoạn văn');
                        });
                        const transcriptVal = transcriptKey ? row[transcriptKey] : null;
                        if (transcriptVal && !finalGroups[gIdx].transcript) finalGroups[gIdx].transcript = String(transcriptVal);
                    }
                });

                Modal.confirm({
                    title: 'Xác nhận nạp dữ liệu',
                    content: 'Hệ thống sẽ nạp dữ liệu từ file vào đúng các vị trí câu hỏi tương ứng. Tiếp tục?',
                    onOk: () => { setGroups(finalGroups); message.success('Nạp dữ liệu thành công'); }
                });
            } catch (err: any) { message.error('Lỗi file Excel: ' + err.message); }
        };
        reader.readAsArrayBuffer(file);
        return false;
    };

    const handleDownloadTemplate = () => {
        const groupCount = partNumber === 3 ? 13 : 10;
        const startQ = partNumber === 3 ? 32 : 71;
        const rows: any[] = [];
        for (let i = 0; i < groupCount; i++) {
            for (let j = 0; j < 3; j++) {
                rows.push({
                    'Số câu': startQ + (i * 3) + j,
                    'Transcript (Hội thoại)': j === 0 ? 'Nội dung bài nói...' : '',
                    'Nội dung câu hỏi': '', 'A': '', 'B': '', 'C': '', 'D': '', 'Đáp án đúng': '', 'Giải thích': ''
                });
            }
        }
        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, `Part${partNumber}`);
        XLSX.writeFile(wb, `Part${partNumber}_Bulk_Template.xlsx`);
    };

    const handleSubmit = async () => {
        if (!partId) return;
        setLoading(true);
        try {
            let partAudioUrl = currentAudioUrl || '';

            // 1. Chỉ upload và cập nhật audio PART một lần duy nhất nếu có file mới
            if (audioFile) {
                const audioRes = await uploadApi.audio(audioFile);
                if (audioRes.success) {
                    partAudioUrl = audioRes.url;
                    await partApi.update(partId, { audioUrl: partAudioUrl });
                } else throw new Error('Upload Audio thất bại');
            }

            // 2. Lọc các nhóm có nội dung thực sự
            const validGroups = groups.filter(g =>
                g.transcript.trim() !== '' ||
                g.questions.some(q => q.questionText.trim() !== '')
            );

            if (validGroups.length === 0) {
                message.warning('Không có dữ liệu hợp lệ để lưu');
                setLoading(false);
                return;
            }

            // 3. Xử lý từng nhóm
            for (const group of validGroups) {
                const validQuestions = group.questions.filter(q => q.questionText.trim() !== '');

                // QUAN TRỌNG: Backend bắt buộc danh sách câu hỏi không được rỗng
                // Nên nếu nhóm không có câu hỏi nào, ta bỏ qua nhóm này
                if (validQuestions.length === 0) continue;

                let graphicUrl = group.graphicPreview?.startsWith('http') ? group.graphicPreview : null;
                if (group.graphicFile) {
                    const res = await uploadApi.image(group.graphicFile);
                    if (res.success) graphicUrl = res.url;
                }

                const keyVocabularyJson = JSON.stringify(group.keyVocabulary || []);
                const passageTranslationDataJson = JSON.stringify([
                    { type: 'passage', label: 'Transcript', items: group.translationSentences || [] }
                ]);

                let passageHtml = `<audio src="${partAudioUrl}"></audio>`;
                if (graphicUrl) {
                    passageHtml += `<p><img src="${graphicUrl}" style="max-width: 100%; display: block; margin: 10px auto;" /></p>`;
                }

                const payload = {
                    transcript: group.transcript,
                    passage: passageHtml,
                    passageImageUrl: graphicUrl,
                    passageTranslationData: passageTranslationDataJson,
                    keyVocabulary: keyVocabularyJson,
                    audioUrl: partAudioUrl,
                    questions: validQuestions.map(q => ({
                        id: q.id, // ✅ Gửi ID để Backend thực hiện Update
                        questionNumber: q.questionNumber,
                        questionText: q.questionText,
                        optionA: q.optionA,
                        optionB: q.optionB,
                        optionC: q.optionC,
                        optionD: q.optionD,
                        correctAnswer: q.correctAnswer,
                        audioUrl: partAudioUrl,
                        transcript: group.transcript,
                        passage: passageHtml,
                        passageImageUrl: graphicUrl,
                        passageTranslationData: passageTranslationDataJson,
                        keyVocabulary: keyVocabularyJson,
                        explanation: q.explanation || group.transcript || '',
                        analysis: q.explanation || group.transcript || '',
                        evidence: group.transcript || '',
                        status: 'ACTIVE'
                    })),
                    mode: 'append'
                };

                // Gửi từng nhóm một để tránh Payload Too Large và dễ track lỗi
                await (questionApi as any).createBatch(partId, payload);
            }

            message.success('Import dữ liệu hàng loạt thành công!');
            onSuccess();
            onCancel();
        } catch (error: any) {
            console.error('Bulk save error:', error);
            message.error('Lỗi khi lưu dữ liệu: ' + (error.response?.data?.message || error.message));
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: 'linear-gradient(135deg, #1E293B 0%, #334155 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <FileExcelOutlined style={{ color: '#fff', fontSize: 18 }} />
                    </div>
                    <Title level={4} style={{ margin: 0 }}>
                        {initialData && initialData.some((r: any) => r.id) ? `CHỈNH SỬA NHÓM CÂU HỎI PART ${partNumber}` : 'NHẬP CÂU HỎI HÀNG LOẠT'}
                    </Title>
                </div>
            }
            open={open} onCancel={onCancel} footer={null} width={1400} centered maskClosable={false} styles={{ body: { padding: '24px', background: '#F4F7FE' } }}
        >
            <div style={{ maxHeight: '85vh', overflowY: 'auto', paddingRight: 8 }}>
                <AudioBanner currentAudioUrl={currentAudioUrl} newAudioFile={audioFile} onAudioFileChange={setAudioFile} />

                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 20 }}>
                    <Space>
                        <Button icon={<PlusOutlined />} onClick={handleAddGroup} type="dashed" style={{ borderRadius: 8, fontWeight: 600 }}>Thêm nhóm mới</Button>
                        <Button icon={<DeleteOutlined />} onClick={() => setGroups([])} danger type="text" style={{ borderRadius: 8 }}>Xóa tất cả</Button>
                    </Space>
                    <Space>
                        <Upload beforeUpload={handleExcelImport} showUploadList={false}><Button icon={<FileExcelOutlined />} type="primary" style={{ borderRadius: 8 }}>Nhập Excel</Button></Upload>
                        <Button icon={<FileExcelOutlined />} onClick={handleDownloadTemplate} style={{ borderRadius: 8 }}>Mẫu Excel</Button>
                    </Space>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                    {groups.map((group, gIdx) => (
                        <Card
                            key={gIdx}
                            className="group-card"
                            title={
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <Space>
                                        <Tag color="blue" style={{ borderRadius: 6, fontWeight: 800, padding: '2px 10px' }}>NHÓM {gIdx + 1}</Tag>
                                        <Text strong style={{ color: '#64748B' }}>CÂU {group.questions[0].questionNumber} - {group.questions[2]?.questionNumber}</Text>
                                    </Space>
                                    <Button type="text" danger icon={<DeleteOutlined />} onClick={() => {
                                        const newGroups = [...groups];
                                        newGroups.splice(gIdx, 1);
                                        setGroups(newGroups);
                                    }} />
                                </div>
                            }
                            style={{ borderRadius: 16, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.03)' }}
                        >
                            <Row gutter={24}>
                                {/* Left Side: Content */}
                                <Col span={10}>
                                    <div style={{ background: '#F8FAFC', padding: 16, borderRadius: 12, border: '1px solid #E2E8F0', height: '100%' }}>
                                        <div style={{ marginBottom: 16 }}>
                                            <div style={{ fontWeight: 800, fontSize: 12, color: '#475569', marginBottom: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
                                                <FileTextOutlined /> TRANSCRIPT (LỜI THOẠI)
                                            </div>
                                            <ReactQuill
                                                theme="snow"
                                                value={group.transcript}
                                                onChange={(val) => handleTranscriptChange(gIdx, val)}
                                                modules={{ toolbar: [['bold', 'italic', 'underline']] }}
                                                style={{ background: '#fff', borderRadius: 8 }}
                                            />
                                        </div>

                                        <div style={{ marginBottom: 16 }}>
                                            <div style={{ fontWeight: 800, fontSize: 12, color: '#475569', marginBottom: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
                                                <PictureOutlined /> ĐỒ HỌA (GRAPHIC)
                                            </div>
                                            <Upload beforeUpload={(f) => { handleGraphicChange(gIdx, f); return false; }} showUploadList={false}>
                                                <div style={{ width: '100%', height: 100, border: '1.5px dashed #CBD5E1', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', background: '#fff', overflow: 'hidden' }}>
                                                    {group.graphicPreview && group.graphicPreview.trim() !== '' ? (
                                                        <Image src={group.graphicPreview} preview={true} height={80} style={{ objectFit: 'contain' }} />
                                                    ) : (
                                                        <div style={{ textAlign: 'center' }}>
                                                            <PictureOutlined style={{ fontSize: 20, color: '#94A3B8' }} />
                                                            <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 4 }}>Bấm để tải ảnh</div>
                                                        </div>
                                                    )}
                                                </div>
                                            </Upload>
                                        </div>

                                        <Divider style={{ margin: '16px 0' }} />

                                        <Tabs size="small" items={[
                                            {
                                                key: 'trans',
                                                label: <Space><GlobalOutlined /> Bản dịch</Space>,
                                                children: (
                                                    <div>
                                                        {group.translationSentences.map((s, tIdx) => (
                                                            <div key={tIdx} style={{ marginBottom: 8, position: 'relative' }}>
                                                                <Input size="small" placeholder="EN" value={s.en} onChange={(e) => handleTranslationChange(gIdx, tIdx, 'en', e.target.value)} style={{ marginBottom: 4 }} />
                                                                <Input size="small" placeholder="VI" value={s.vi} onChange={(e) => handleTranslationChange(gIdx, tIdx, 'vi', e.target.value)} />
                                                                <Button size="small" type="text" danger icon={<DeleteOutlined />} onClick={() => handleRemoveTranslation(gIdx, tIdx)} style={{ position: 'absolute', right: -25, top: 10 }} />
                                                            </div>
                                                        ))}
                                                        <Button size="small" block type="dashed" icon={<PlusOutlined />} onClick={() => handleAddTranslation(gIdx)}>Thêm câu dịch</Button>
                                                    </div>
                                                )
                                            },
                                            {
                                                key: 'vocab',
                                                label: <Space><BookOutlined /> Từ vựng Flashcards</Space>,
                                                children: (
                                                    <div>
                                                        {group.keyVocabulary.map((v, vIdx) => (
                                                            <div key={vIdx} style={{ display: 'flex', gap: 4, marginBottom: 6, alignItems: 'center' }}>
                                                                <Input size="small" placeholder="Từ" value={v.word} onChange={(e) => handleVocabChange(gIdx, vIdx, 'word', e.target.value)} style={{ flex: 1.5 }} title="Từ vựng" />
                                                                <Input size="small" placeholder="Loại" value={v.type} onChange={(e) => handleVocabChange(gIdx, vIdx, 'type', e.target.value)} style={{ flex: 0.8 }} title="Loại từ" />
                                                                <Input size="small" placeholder="IPA" value={v.ipa} onChange={(e) => handleVocabChange(gIdx, vIdx, 'ipa', e.target.value)} style={{ flex: 1 }} title="Phiên âm" />
                                                                <Input size="small" placeholder="Nghĩa" value={v.meaning} onChange={(e) => handleVocabChange(gIdx, vIdx, 'meaning', e.target.value)} style={{ flex: 2 }} title="Nghĩa" />
                                                                <Button size="small" type="text" danger icon={<DeleteOutlined />} onClick={() => handleRemoveVocab(gIdx, vIdx)} />
                                                            </div>
                                                        ))}
                                                        <Button size="small" block type="dashed" icon={<PlusOutlined />} onClick={() => handleAddVocab(gIdx)}>Thêm từ vựng</Button>
                                                    </div>
                                                )
                                            }
                                        ]} />
                                    </div>
                                </Col>

                                {/* Right Side: 3 Questions */}
                                <Col span={14}>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                                        {group.questions.map((q, qIdx) => (
                                            <div key={qIdx} style={{ background: '#fff', padding: '12px 16px', borderRadius: 12, border: '1px solid #F1F5F9', position: 'relative' }}>
                                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                                                    <Space>
                                                        <span style={{ fontWeight: 800, color: '#1E293B' }}>{q.questionNumber}.</span>
                                                        <Input
                                                            variant="borderless"
                                                            placeholder="Nhập nội dung câu hỏi..."
                                                            value={q.questionText}
                                                            onChange={(e) => handleQuestionChange(gIdx, qIdx, 'questionText', e.target.value)}
                                                            style={{ fontWeight: 600, width: 420 }}
                                                        />
                                                    </Space>
                                                    <Space>
                                                        <Select
                                                            size="small"
                                                            value={q.correctAnswer}
                                                            onChange={(val) => handleQuestionChange(gIdx, qIdx, 'correctAnswer', val)}
                                                            style={{ width: 60 }}
                                                            dropdownStyle={{ minWidth: 60 }}
                                                        >
                                                            {['A', 'B', 'C', 'D'].map(o => <Option key={o} value={o}>{o}</Option>)}
                                                        </Select>
                                                        <Button size="small" type="text" danger icon={<DeleteOutlined />} onClick={() => handleRemoveQuestion(gIdx, qIdx)} />
                                                    </Space>
                                                </div>
                                                <Row gutter={[12, 8]}>
                                                    {['A', 'B', 'C', 'D'].map(opt => (
                                                        <Col span={12} key={opt}>
                                                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                                                <div style={{
                                                                    width: 24, height: 24, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                                    fontSize: 10, fontWeight: 900,
                                                                    background: q.correctAnswer === opt ? '#22C55E' : '#F1F5F9',
                                                                    color: q.correctAnswer === opt ? '#fff' : '#64748B',
                                                                    border: q.correctAnswer === opt ? 'none' : '1px solid #E2E8F0'
                                                                }}>{opt}</div>
                                                                <Input
                                                                    size="small"
                                                                    variant="borderless"
                                                                    value={(q as any)[`option${opt}`]}
                                                                    onChange={(e) => handleQuestionChange(gIdx, qIdx, `option${opt}` as any, e.target.value)}
                                                                    placeholder={`Đáp án ${opt}...`}
                                                                    style={{ fontSize: 13 }}
                                                                />
                                                            </div>
                                                        </Col>
                                                    ))}
                                                </Row>
                                            </div>
                                        ))}
                                    </div>
                                </Col>
                            </Row>
                        </Card>
                    ))}
                </div>

                <div style={{ marginTop: 40, padding: '24px 0', borderTop: '1px solid #E2E8F0', display: 'flex', justifyContent: 'flex-end', gap: 16 }}>
                    <Button onClick={onCancel} size="large" style={{ borderRadius: 12, width: 120 }}>Hủy bỏ</Button>
                    <Button
                        type="primary" onClick={handleSubmit} loading={loading} size="large" icon={<CheckCircleOutlined />}
                        style={{ background: 'linear-gradient(135deg, #1E293B 0%, #334155 100%)', border: 'none', width: 300, fontWeight: 700, borderRadius: 12, height: 50 }}
                    >
                        {initialData && initialData.some(r => r.id) ? 'CẬP NHẬT NHÓM' : 'LƯU TẤT CẢ CÁC NHÓM'}
                    </Button>
                </div>
            </div>
            <style>{`
                .group-card .ant-card-head { background: #F8FAFC; border-bottom: 1px solid #E2E8F0; border-radius: 16px 16px 0 0; min-height: 48px; padding: 0 20px; }
                .group-card .ant-card-body { padding: 20px; }
                .ant-tabs-nav::before { border-bottom: none !important; }
                .ql-container { height: 120px !important; border-bottom-left-radius: 8px; border-bottom-right-radius: 8px; overflow-y: auto; }
                .ql-toolbar { border-top-left-radius: 8px; border-top-right-radius: 8px; }
            `}</style>
        </Modal>
    );
}
