import { useState, useEffect } from 'react';
import { Modal, Form, Input, Select, message, Card, Upload, Button, Row, Col, Space, Radio, InputNumber, Empty, Progress, Image, Tag, Typography, Layout, Tabs, Divider, Alert } from 'antd';
import { 
    DeleteOutlined, 
    PlusOutlined, 
    RobotOutlined, 
    ExperimentOutlined, 
    CameraOutlined, 
    BookOutlined, 
    CheckCircleOutlined,
    InfoCircleOutlined
} from '@ant-design/icons';
import ReactQuill from 'react-quill-new';
import 'quill/dist/quill.snow.css';
import api from '../services/api';
import { QUILL_MODULES, QUILL_FORMATS } from '../utils/editorUtils';

const { Dragger } = Upload;
const { Text } = Typography;
const { Sider, Content } = Layout;

interface CreatePart6ModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    mode?: 'add' | 'edit';
    initialData?: any;
    partName?: string;
    partNumber?: number;
}

export default function CreatePart6Modal({ open, onCancel, onSuccess, partId, mode = 'add', initialData, partName, partNumber }: CreatePart6ModalProps) {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [aiDoneIndexes, setAiDoneIndexes] = useState<number[]>([]);
    const [passageFileLists, setPassageFileLists] = useState<Record<number, any[]>>({});
    const [questionFileLists, setQuestionFileLists] = useState<Record<number, any[]>>({});
    const [isAiProcessing, setIsAiProcessing] = useState(false);
    const [aiProgress, setAiProgress] = useState(0);
    const [currentInsightIndex, setCurrentInsightIndex] = useState<number>(0);

    useEffect(() => {
        if (open) {
            if (mode === 'edit' && initialData) {
                const passage = initialData;
                const questions = (passage.questions || []).sort((a: any, b: any) => a.questionNumber - b.questionNumber);
                const firstQ = questions[0] || {};
                const lastQ = questions[questions.length - 1] || {};

                const pUrls = firstQ.passageImageUrl ? firstQ.passageImageUrl.split(',').filter(Boolean) : [];
                const sUrls = firstQ.questionScanUrl ? firstQ.questionScanUrl.split(',').filter(Boolean) : [];

                const isImagePassage = pUrls.length > 0 || (passage.passage || '').includes('<img');

                form.setFieldsValue({
                    passages: [{
                        passageTitle: (passage.passage?.match(/<p[^>]*>\s*<b>\s*(.*?)\s*<\/b>\s*<\/p>/)?.[1] || '').trim(),
                        passage: (passage.passage || '').replace(/<p[^>]*>\s*<b>\s*.*?\s*<\/b>\s*<\/p>/, '').trim(),
                        passageType: isImagePassage ? 'image' : 'text',
                        passageTranslationData: firstQ.passageTranslationData,
                        passageImageUrl: firstQ.passageImageUrl,
                        questionScanUrl: firstQ.questionScanUrl,
                        audioUrl: firstQ.audioUrl,
                        startQuestion: firstQ.questionNumber,
                        endQuestion: lastQ.questionNumber,
                        questions: questions.map((q: any) => ({
                            id: q.id,
                            questionNumber: q.questionNumber,
                            questionText: (q.questionText || '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim(),
                            optionA: (q.optionA || '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim(),
                            optionB: (q.optionB || '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim(),
                            optionC: (q.optionC || '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim(),
                            optionD: (q.optionD || '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim(),
                            optionTranslations: typeof q.optionTranslations === 'string' ? JSON.parse(q.optionTranslations) : (q.optionTranslations || {}),
                            questionTranslation: q.questionTranslation || '',
                            correctAnswer: q.correctAnswer,
                            explanation: q.explanation,
                            analysis: q.analysis || '',
                            evidence: q.evidence || '',
                            keyVocabulary: typeof q.keyVocabulary === 'string' ? JSON.parse(q.keyVocabulary) : (q.keyVocabulary || [])
                        }))
                    }]
                });

                setPassageFileLists({
                    0: pUrls.map((url: string, i: number) => ({
                        uid: `-p-${i}`, name: `Passage ${i + 1}`, status: 'done', url, thumbUrl: url, response: { data: { url } }
                    }))
                });

                setQuestionFileLists({
                    0: sUrls.map((url: string, i: number) => ({
                        uid: `-s-${i}`, name: `Scan ${i + 1}`, status: 'done', url, thumbUrl: url, response: { data: { url } }
                    }))
                });

                setAiDoneIndexes([0]);
                setCurrentInsightIndex(0);
            } else {
                form.resetFields();
                setAiDoneIndexes([]);
                setPassageFileLists({});
                setQuestionFileLists({});
                setCurrentInsightIndex(0);
            }
        }
    }, [open, mode, initialData, form]);

    const handleAnalyzeAll = async () => {
        const passages = form.getFieldValue('passages') || [];
        if (passages.length === 0) return message.warning('Chưa có nhóm nội dung nào!');
        setIsAiProcessing(true);
        let successCount = 0;
        for (let i = 0; i < passages.length; i++) {
            setAiProgress(Math.floor((i / passages.length) * 100));
            setCurrentInsightIndex(i);
            const type = passages[i].passageType;
            try {
                if (type === 'image') await handleMagicScan(i, true);
                else await handleGenerateAI(i, true);
                successCount++;
            } catch (e) { console.error('Error in batch analysis', i, e); }
        }
        setIsAiProcessing(false);
        setAiProgress(100);
        if (successCount === passages.length) message.success('Đã phân tích 100% tất cả các nhóm!');
    };

    const handleGenerateAI = async (index: number, isBatch = false) => {
        const passages = form.getFieldValue('passages') || [];
        const passageItem = passages[index];
        const questions = passageItem?.questions;
        if (!passageItem?.passage || !questions || questions.length === 0) {
            if (!isBatch) message.warning('Vui lòng nhập nội dung đoạn văn và câu hỏi!');
            return;
        }
        if (!isBatch) { setIsAiProcessing(true); setAiProgress(30); setCurrentInsightIndex(index); }
        try {
            const cleanPassage = (passageItem.passageTitle ? `${passageItem.passageTitle}\n${passageItem.passage}` : passageItem.passage).replace(/<[^>]*>?/gm, ' ');
            const response = await api.post('/ai/generate-part6', {
                passage: cleanPassage,
                questions: questions.map((q: any) => ({
                    questionNumber: q.questionNumber,
                    optionA: q.optionA, optionB: q.optionB,
                    optionC: q.optionC, optionD: q.optionD,
                    correctAnswer: q.correctAnswer,
                }))
            }, { timeout: 120000 });

            if (response.data.success) {
                const aiData = response.data.data;
                const updatedPassages = [...form.getFieldValue('passages')];
                const item = updatedPassages[index];
                item.passageTranslationData = aiData.passageTranslations ? JSON.stringify(aiData.passageTranslations) : undefined;
                if (aiData.questions && Array.isArray(item.questions)) {
                    item.questions = item.questions.map((q: any) => {
                        const aiQ = aiData.questions.find((aq: any) => Number(aq.questionNumber) === Number(q.questionNumber));
                        if (aiQ) return {
                            ...q,
                            questionTranslation: aiQ.questionTranslation || '',
                            optionTranslations: aiQ.optionTranslations || {},
                            analysis: aiQ.analysis || '',
                            evidence: aiQ.evidence || '',
                            explanation: aiQ.explanation || '',
                            keyVocabulary: aiData.vocabulary || []
                        };
                        return q;
                    });
                }
                form.setFieldValue('passages', updatedPassages);
                setAiDoneIndexes(prev => [...new Set([...prev, index])]);
                if (!isBatch) message.success('Đã tạo AI Insights!');
            }
        } catch (err: any) { message.error('Lỗi tạo AI'); }
        finally { if (!isBatch) { setIsAiProcessing(false); setAiProgress(0); } }
    };

    const handleMagicScan = async (index: number, isBatch = false) => {
        if (!isBatch) { setIsAiProcessing(true); setAiProgress(30); setCurrentInsightIndex(index); }
        try {
            const formData = new FormData();
            const passageFiles = (passageFileLists[index] || []).map(f => f.originFileObj).filter(Boolean);
            const questionFiles = (questionFileLists[index] || []).map(f => f.originFileObj).filter(Boolean);
            const existingUrls = [
                ...(passageFileLists[index] || []).map(f => f.url || f.response?.data?.url || f.response?.url),
                ...(questionFileLists[index] || []).map(f => f.url || f.response?.data?.url || f.response?.url)
            ].filter(url => url && typeof url === 'string' && url.startsWith('http'));

            if (passageFiles.length === 0 && questionFiles.length === 0 && existingUrls.length === 0) {
                if (!isBatch) message.warning('Vui lòng upload ảnh!');
                if (!isBatch) setIsAiProcessing(false);
                return;
            }
            passageFiles.forEach(file => formData.append('passageImages', file as any));
            questionFiles.forEach(file => formData.append('questionImages', file as any));
            if (existingUrls.length > 0) formData.append('imageUrls', JSON.stringify(existingUrls));

            const response = await api.post('/ai/magic-scan-part6', formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
                timeout: 150000
            });

            if (response.data.success) {
                const aiData = response.data.data;
                const updatedPassages = [...form.getFieldValue('passages')];
                const userStartNum = updatedPassages[index].startQuestion;
                updatedPassages[index] = {
                    ...updatedPassages[index],
                    passage: (aiData.passageHtml || updatedPassages[index].passage || '').replace(/<img[^>]*>/g, ''),
                    passageTranslationData: JSON.stringify(aiData.passageTranslations || []),
                    passageData: JSON.stringify(aiData.passageData || aiData.passageTranslations || []),
                    questions: aiData.questions.map((q: any, idx: number) => ({
                        ...q,
                        questionNumber: userStartNum ? (userStartNum + idx) : q.questionNumber,
                        optionTranslations: q.optionTranslations || {},
                        keyVocabulary: aiData.vocabulary || []
                    })),
                    startQuestion: userStartNum || aiData.questions[0]?.questionNumber,
                    endQuestion: (userStartNum || aiData.questions[0]?.questionNumber) + aiData.questions.length - 1
                };
                form.setFieldValue('passages', updatedPassages);
                setAiDoneIndexes(prev => [...new Set([...prev, index])]);
                if (!isBatch) message.success('Quét Magic Scan thành công!');
            }
        } catch (e: any) { message.error('Lỗi Magic Scan'); }
        finally { if (!isBatch) { setIsAiProcessing(false); setAiProgress(0); } }
    };

    const handleFinish = async (values: any) => {
        if (!partId) return;

        for (const passage of values.passages) {
            const outOfRange = (passage.questions || []).filter((q: any) => q.questionNumber < 131 || q.questionNumber > 146);
            if (outOfRange.length > 0) {
                message.error('Câu hỏi Part 6 phải nằm trong khoảng từ 131 đến 146');
                return;
            }
        }

        setLoading(true);
        try {
            for (let i = 0; i < values.passages.length; i++) {
                const item = values.passages[i];
                let passageHtml = item.passageTitle ? `<p><b>${item.passageTitle}</b></p>` : '';
                passageHtml += (item.passage || '').replace(/<img[^>]*>/g, '');
                
                const finalPassageImageUrl = (passageFileLists[i] || []).map(f => f.url || f.response?.data?.url).filter(Boolean).join(',');
                const finalQuestionScanUrl = (questionFileLists[i] || []).map(f => f.url || f.response?.data?.url).filter(Boolean).join(',');

                const payload = {
                    passage: passageHtml,
                    passageImageUrl: finalPassageImageUrl || null,
                    passageTranslationData: item.passageTranslationData,
                    questions: (item.questions || []).map((q: any) => ({
                        ...q,
                        passage: passageHtml,
                        passageImageUrl: finalPassageImageUrl || null,
                        questionScanUrl: finalQuestionScanUrl || null,
                        optionTranslations: typeof q.optionTranslations === 'string' ? q.optionTranslations : JSON.stringify(q.optionTranslations || {}),
                        keyVocabulary: typeof q.keyVocabulary === 'string' ? q.keyVocabulary : JSON.stringify(q.keyVocabulary || []),
                    }))
                };

                if (mode === 'edit') {
                    for (const q of payload.questions) {
                        if (q.id) await api.patch(`/questions/${q.id}`, q);
                        else await api.post(`/parts/${partId}/questions`, q);
                    }
                } else {
                    await api.post(`/parts/${partId}/questions/batch`, payload);
                }
            }
            message.success('Lưu thành công!');
            onSuccess(); onCancel();
        } catch (e: any) { message.error('Lỗi lưu'); }
        finally { setLoading(false); }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{
                        width: 42, height: 42, borderRadius: 12, 
                        background: 'linear-gradient(135deg, #1E293B 0%, #334155 100%)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center', 
                        color: '#fff', fontSize: 24, boxShadow: '0 8px 16px rgba(30, 41, 59, 0.2)'
                    }}>
                        <ExperimentOutlined />
                    </div>
                    <div>
                        <span style={{ 
                            fontWeight: 850, fontSize: 19, 
                            background: 'linear-gradient(to right, #1E293B, #475569)',
                            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
                            textTransform: 'uppercase', letterSpacing: '0.5px' 
                        }}>
                            {partName || `PART ${partNumber}: TEXT COMPLETION`}
                        </span>
                        <Text type="secondary" style={{ display: 'block', fontSize: 11, fontWeight: 500, marginTop: -4 }}>
                            Hệ thống quản trị Reading Part 6 Premium
                        </Text>
                    </div>
                </div>
            }
            open={open} onCancel={onCancel} width={1500} centered style={{ top: 20 }} maskClosable={false}
            styles={{ body: { padding: '24px 32px' } }}
            footer={[
                <Button key="cancel" size="large" onClick={onCancel} style={{ borderRadius: 10, fontWeight: 600 }}>Hủy bỏ</Button>,
                <Button 
                    key="submit" size="large" type="primary" 
                    onClick={() => form.submit()} loading={loading} 
                    icon={<CheckCircleOutlined />}
                    style={{ 
                        borderRadius: 10, fontWeight: 700, 
                        background: 'linear-gradient(135deg, #1E293B 0%, #334155 100%)', 
                        border: 'none', boxShadow: '0 4px 14px rgba(30, 41, 59, 0.3)', padding: '0 32px' 
                    }}
                >
                    {mode === 'edit' ? 'CẬP NHẬT' : 'HOÀN TẤT'}
                </Button>
            ]}
        >
            <Form form={form} layout="vertical" onFinish={handleFinish} initialValues={{ passages: [{ questions: [{}, {}, {}, {}] }] }}>
                {isAiProcessing && (
                    <div style={{ marginBottom: 24, padding: 20, background: '#F0F9FF', borderRadius: 16, border: '1px solid #BAE6FD' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                            <Text strong style={{ color: '#0369A1' }}><RobotOutlined spin /> Đang phân tích AI...</Text>
                            <Text strong>{aiProgress}%</Text>
                        </div>
                        <Progress percent={aiProgress} status="active" strokeColor="#0EA5E9" />
                    </div>
                )}

                <Layout style={{ background: 'transparent', gap: 24 }}>
                    <Sider width={260} style={{ background: '#F8FAFC', borderRadius: 20, border: '1px solid #E2E8F0', padding: 16, height: '75vh', overflowY: 'auto' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                            <Text strong style={{ color: '#64748B', fontSize: 12, textTransform: 'uppercase' }}>Danh sách nhóm</Text>
                            <Button type="primary" size="small" icon={<PlusOutlined />} onClick={() => {
                                const current = form.getFieldValue('passages') || [];
                                form.setFieldValue('passages', [...current, { questions: [{}, {}, {}, {}] }]);
                            }} style={{ borderRadius: 6, fontSize: 11 }} />
                        </div>
                        <Form.List name="passages">
                            {(fields) => (
                                <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                                    {fields.map((field, index) => (
                                        <div key={field.key} onClick={() => setCurrentInsightIndex(index)}
                                            style={{ 
                                                display: 'flex', alignItems: 'center', gap: 10, padding: '12px 16px', 
                                                background: currentInsightIndex === index ? '#1E293B' : 'transparent', 
                                                color: currentInsightIndex === index ? '#fff' : '#475569', 
                                                borderRadius: 12, cursor: 'pointer', 
                                                border: currentInsightIndex === index ? 'none' : '1px solid transparent',
                                                transition: 'all 0.2s'
                                            }}>
                                            <div style={{ 
                                                width: 24, height: 24, borderRadius: 6, 
                                                background: currentInsightIndex === index ? 'rgba(255,255,255,0.2)' : '#E2E8F0', 
                                                color: currentInsightIndex === index ? '#fff' : '#64748B', 
                                                display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: 11 
                                            }}>{index + 1}</div>
                                            <div style={{ flex: 1 }}>
                                                <div style={{ fontWeight: 700, fontSize: 13 }}>Nhóm {index + 1}</div>
                                                <div style={{ fontSize: 10, opacity: 0.7 }}>
                                                    {form.getFieldValue(['passages', index, 'startQuestion']) || '?'}-{form.getFieldValue(['passages', index, 'endQuestion']) || '?'}
                                                </div>
                                            </div>
                                            {aiDoneIndexes.includes(index) && <CheckCircleOutlined style={{ color: '#10B981', fontSize: 14 }} />}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </Form.List>
                        
                        <Divider />
                        <Space direction="vertical" style={{ width: '100%' }}>
                            <Button block icon={<RobotOutlined />} onClick={handleAnalyzeAll} loading={isAiProcessing} style={{ borderRadius: 10, height: 40, fontWeight: 700 }}>Phân tích Tất cả</Button>
                            <Button block danger icon={<DeleteOutlined />} onClick={() => {
                                const current = form.getFieldValue('passages');
                                if (current.length > 1) {
                                    const next = current.filter((_: any, i: number) => i !== currentInsightIndex);
                                    form.setFieldValue('passages', next);
                                    setCurrentInsightIndex(Math.max(0, currentInsightIndex - 1));
                                } else message.warning('Phải có ít nhất 1 nhóm!');
                            }} style={{ borderRadius: 10 }}>Xóa Nhóm Hiện Tại</Button>
                        </Space>
                    </Sider>

                    <Content style={{ background: '#fff', borderRadius: 24, border: '1px solid #E2E8F0', padding: 32, height: '75vh', overflowY: 'auto' }} className="custom-scrollbar">
                        <Form.List name="passages">
                            {(fields) => {
                                const field = fields[currentInsightIndex];
                                if (!field) return <Empty description="Chọn hoặc thêm nhóm mới" />;
                                return (
                                    <div key={field.key}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                                            <Space size="middle">
                                                <Tag color="slate" style={{ background: '#1E293B', color: '#fff', padding: '4px 12px', borderRadius: 6, fontSize: 14, fontWeight: 800 }}>NHÓM {currentInsightIndex + 1}</Tag>
                                                <Button size="small" type="primary" icon={<ExperimentOutlined />} onClick={() => handleGenerateAI(currentInsightIndex)} loading={isAiProcessing}>AI Magic Nhóm này</Button>
                                            </Space>
                                            <Space>
                                                <Form.Item label="Câu bắt đầu" name={[field.name, 'startQuestion']} style={{ margin: 0 }}><InputNumber style={{ width: 70, borderRadius: 8 }} /></Form.Item>
                                                <Form.Item label="Câu kết thúc" name={[field.name, 'endQuestion']} style={{ margin: 0 }}><InputNumber style={{ width: 70, borderRadius: 8 }} /></Form.Item>
                                            </Space>
                                        </div>

                                        <Form.Item label={<span style={{ fontWeight: 700, color: '#1E293B' }}>Tiêu đề đoạn văn (Optional)</span>} name={[field.name, 'passageTitle']}>
                                            <Input placeholder="Ví dụ: Questions 131-134 refer to the following advertisement." style={{ borderRadius: 10 }} />
                                        </Form.Item>

                                        <div style={{ marginBottom: 24 }}>
                                            <Form.Item name={[field.name, 'passageType']} initialValue="text">
                                                <Radio.Group buttonStyle="solid">
                                                    <Radio.Button value="text">Văn bản (Quill)</Radio.Button>
                                                    <Radio.Button value="image">Hình ảnh (Magic Scan)</Radio.Button>
                                                </Radio.Group>
                                            </Form.Item>

                                            <Form.Item noStyle shouldUpdate>{() => {
                                                const type = form.getFieldValue(['passages', currentInsightIndex, 'passageType']);
                                                if (type === 'image') return (
                                                    <div style={{ background: '#F8FAFC', padding: 20, borderRadius: 16, border: '1px dashed #BFDBFE' }}>
                                                        <Dragger multiple showUploadList={false} action={`${api.defaults.baseURL}/upload/image`} name="image" headers={{ Authorization: `Bearer ${localStorage.getItem('admin_token')}` }} onChange={({ fileList }) => setPassageFileLists(prev => ({ ...prev, [currentInsightIndex]: fileList }))}>
                                                            <p className="ant-upload-drag-icon"><CameraOutlined style={{ color: '#3B82F6', fontSize: 32 }} /></p>
                                                            <Text strong>Thả ảnh đoạn văn tại đây</Text>
                                                        </Dragger>
                                                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, marginTop: 12 }}>
                                                            {(passageFileLists[currentInsightIndex] || []).map((file, i) => <Image key={i} src={file.url || file.response?.data?.url} width={80} style={{ borderRadius: 8 }} />)}
                                                        </div>
                                                        <Button block icon={<ExperimentOutlined />} onClick={() => handleMagicScan(currentInsightIndex)} style={{ marginTop: 16, background: '#1E293B', color: '#fff', border: 'none', borderRadius: 8 }}>QUÉT MAGIC SCAN</Button>
                                                    </div>
                                                );
                                                return <Form.Item name={[field.name, 'passage']} rules={[{ required: true }]}><ReactQuill style={{ height: 250, marginBottom: 50, background: '#fff' }} modules={QUILL_MODULES} formats={QUILL_FORMATS} /></Form.Item>;
                                            }}</Form.Item>
                                        </div>

                                        <Divider orientation={"left" as any} orientationMargin={0}><span style={{ fontWeight: 800, color: '#64748B' }}>CÂU HỎI CHI TIẾT</span></Divider>

                                        <Form.List name={[field.name, 'questions']}>
                                            {(qFields) => (
                                                <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                                                    {qFields.map((qf, qi) => (
                                                        <Card key={qf.key} size="small" style={{ borderRadius: 16, border: '1px solid #E2E8F0', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }} 
                                                            title={<div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                                                <Tag color="blue" style={{ borderRadius: 6, fontWeight: 800 }}>CÂU {form.getFieldValue(['passages', currentInsightIndex, 'startQuestion']) + qi || '?'}</Tag>
                                                                <Form.Item name={[qf.name, 'correctAnswer']} label="Đáp án" style={{ margin: 0 }}><Select options={[{ value: 'A' }, { value: 'B' }, { value: 'C' }, { value: 'D' }]} style={{ width: 80 }} /></Form.Item>
                                                            </div>}>
                                                            <Row gutter={16}>
                                                                <Col span={12}><Form.Item name={[qf.name, 'questionText']} label="Đề bài (Optional)"><Input style={{ borderRadius: 8 }} /></Form.Item></Col>
                                                                <Col span={12}><Form.Item name={[qf.name, 'questionTranslation']} label="Dịch đề bài"><Input style={{ borderRadius: 8, border: '1px solid #BAE6FD' }} /></Form.Item></Col>
                                                            </Row>
                                                            <Row gutter={[12, 12]} style={{ marginBottom: 16 }}>
                                                                {['A', 'B', 'C', 'D'].map(opt => (
                                                                    <Col span={6} key={opt}><Form.Item name={[qf.name, `option${opt}`]} label={opt} style={{ margin: 0 }}><Input style={{ borderRadius: 6 }} /></Form.Item></Col>
                                                                ))}
                                                            </Row>
                                                            <Tabs size="small" type="line">
                                                                <Tabs.TabPane tab={<span><InfoCircleOutlined /> Lời giải</span>} key="exp">
                                                                    <Form.Item name={[qf.name, 'explanation']} noStyle><ReactQuill theme="snow" style={{ height: 150, marginBottom: 40 }} /></Form.Item>
                                                                </Tabs.TabPane>
                                                                <Tabs.TabPane tab={<span><BookOutlined /> Từ vựng</span>} key="vocab">
                                                                    <div style={{ background: '#F8FAFC', padding: 12, borderRadius: 8 }}>
                                                                        <Alert message="Từ vựng sẽ được tự động trích xuất từ nội dung AI Insights để phục vụ tính năng dịch thông minh." type="info" showIcon style={{ fontSize: 12 }} />
                                                                    </div>
                                                                </Tabs.TabPane>
                                                            </Tabs>
                                                        </Card>
                                                    ))}
                                                </div>
                                            )}
                                        </Form.List>
                                    </div>
                                );
                            }}
                        </Form.List>
                    </Content>
                </Layout>
            </Form>
        </Modal>
    );
}