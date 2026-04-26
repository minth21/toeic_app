import { useState, useEffect } from 'react';
import { Modal, Form, Input, Select, message, Card, Upload, Button, Row, Col, Space, Radio, InputNumber, Empty, Image, Tag, Typography, Layout, Tabs, Divider } from 'antd';
import { 
    DeleteOutlined, 
    PlusOutlined, 
    ExperimentOutlined, 
    CameraOutlined, 
    BookOutlined, 
    CheckCircleOutlined,
    GlobalOutlined,
    ThunderboltOutlined,
    EditOutlined,
    InfoCircleOutlined,
    FileSearchOutlined
} from '@ant-design/icons';
import ReactQuill from 'react-quill-new';
import 'quill/dist/quill.snow.css';
import api from '../services/api';
import { QUILL_MODULES, QUILL_FORMATS } from '../utils/editorUtils';

const { Dragger } = Upload;
const { Text } = Typography;
const { Sider, Content } = Layout;

// Helper to clean HTML and junk characters
const cleanContent = (text: string) => {
    if (!text) return '';
    return text.replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
};

// Helper to parse JSON safely and ensure it's an array
const safeParseArray = (str: any) => {
    if (!str) return [];
    if (Array.isArray(str)) return str;
    try {
        let cleaned = typeof str === 'string' ? str.replace(/```json|```/g, '').trim() : str;
        let parsed = typeof cleaned === 'string' ? JSON.parse(cleaned) : cleaned;
        if (typeof parsed === 'string') parsed = JSON.parse(parsed);
        return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
        console.error('JSON Parse Error:', e);
        return [];
    }
};

const safeParseObj = (str: any) => {
    if (!str) return {};
    if (typeof str === 'object' && !Array.isArray(str)) return str;
    try {
        const cleaned = typeof str === 'string' ? str.replace(/```json|```/g, '').trim() : str;
        const parsed = typeof cleaned === 'string' ? JSON.parse(cleaned) : cleaned;
        return (typeof parsed === 'object' && parsed !== null) ? parsed : {};
    } catch (e) {
        return {};
    }
};

interface CreatePart7ModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    mode?: 'add' | 'edit';
    initialData?: any;
    partName?: string;
    partNumber?: number;
}

export default function CreatePart7Modal({ open, onCancel, onSuccess, partId, mode = 'add', initialData, partName, partNumber }: CreatePart7ModalProps) {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [aiDoneIndexes, setAiDoneIndexes] = useState<number[]>([]);
    const [passageFileLists, setPassageFileLists] = useState<Record<number, any[]>>({});
    const [questionFileLists, setQuestionFileLists] = useState<Record<number, any[]>>({});
    const [isAiProcessing, setIsAiProcessing] = useState(false);
    const [currentInsightIndex, setCurrentInsightIndex] = useState<number>(0);

    const passagesWatch = Form.useWatch('passages', form);
    const currentPassageType = passagesWatch?.[currentInsightIndex]?.passageType || 'text';

    const getPreviewUrls = (fileList: any[]) => {
        return (fileList || []).map(file => {
            if (file.url) return file.url;
            if (file.originFileObj) return URL.createObjectURL(file.originFileObj);
            if (file.response?.data?.url) return file.response.data.url;
            return null;
        }).filter(Boolean);
    };

    useEffect(() => {
        if (open) {
            if (mode === 'edit' && initialData) {
                const passage = initialData;
                const questions = (passage.questions || []).sort((a: any, b: any) => a.questionNumber - b.questionNumber);
                const firstQ = questions[0] || {};
                const lastQ = questions[questions.length - 1] || {};
                const pUrls = firstQ.passageImageUrl ? firstQ.passageImageUrl.split(',').filter(Boolean) : [];
                const sUrls = firstQ.questionScanUrl ? firstQ.questionScanUrl.split(',').filter(Boolean) : [];

                // Handle nested items structure from DB [ { items: [...] } ] or flat [ { en, vi }, ... ]
                const rawTransData = safeParseArray(firstQ.passageTranslationData);
                let translationItems = [];
                if (rawTransData.length > 0) {
                    if (rawTransData[0].items) translationItems = rawTransData[0].items;
                    else translationItems = rawTransData;
                }

                form.setFieldsValue({
                    passages: [{
                        passageTitle: cleanContent(passage.passage?.match(/<p[^>]*>\s*<b>\s*(.*?)\s*<\/b>\s*<\/p>/)?.[1] || ''),
                        passage: (passage.passage || '').replace(/<p[^>]*>\s*<b>\s*.*?\s*<\/b>\s*<\/p>/, '').trim(),
                        passageType: pUrls.length > 0 ? 'image' : 'text',
                        passageTranslationData: translationItems,
                        keyVocabulary: safeParseArray(firstQ.keyVocabulary),
                        startQuestion: firstQ.questionNumber,
                        endQuestion: lastQ.questionNumber,
                        questions: questions.map((q: any) => ({
                            id: q.id,
                            questionNumber: q.questionNumber,
                            questionText: cleanContent(q.questionText || ''),
                            optionA: cleanContent(q.optionA || ''),
                            optionB: cleanContent(q.optionB || ''),
                            optionC: cleanContent(q.optionC || ''),
                            optionD: cleanContent(q.optionD || ''),
                            optionTranslations: safeParseObj(q.optionTranslations),
                            questionTranslation: cleanContent(q.questionTranslation || ''),
                            correctAnswer: q.correctAnswer,
                            analysis: q.analysis,
                            evidence: q.evidence
                        }))
                    }]
                });

                setPassageFileLists({ 0: pUrls.map((url: string, i: number) => ({ uid: `-p-${i}`, status: 'done', url })) });
                setQuestionFileLists({ 0: sUrls.map((url: string, i: number) => ({ uid: `-s-${i}`, status: 'done', url })) });
                setAiDoneIndexes([0]);
            } else {
                form.resetFields();
                setAiDoneIndexes([]); setPassageFileLists({}); setQuestionFileLists({});
            }
        }
    }, [open, mode, initialData, form]);

    const handleMagicScan = async (index: number, isBatch = false) => {
        if (!isBatch) { setIsAiProcessing(true); setCurrentInsightIndex(index); }
        try {
            const formData = new FormData();
            const passageFiles = (passageFileLists[index] || []).map(f => f.originFileObj).filter(Boolean);
            const questionFiles = (questionFileLists[index] || []).map(f => f.originFileObj).filter(Boolean);
            
            if (passageFiles.length === 0 && questionFiles.length === 0) {
                if (!isBatch) message.warning('Vui lòng upload ảnh!');
                return;
            }

            passageFiles.forEach(file => formData.append('passageImages', file as any));
            questionFiles.forEach(file => formData.append('questionImages', file as any));

            const response = await api.post('/ai/magic-scan-part7', formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
                timeout: 150000
            });

            if (response.data.success) {
                const aiData = response.data.data;
                const updatedPassages = [...form.getFieldValue('passages')];
                const existingQuestions = updatedPassages[index].questions || [];
                const startNum = updatedPassages[index].startQuestion || aiData.questions[0]?.questionNumber;

                updatedPassages[index] = {
                    ...updatedPassages[index],
                    passage: (aiData.passageHtml || '').replace(/<img[^>]*>/g, ''),
                    passageTranslationData: (() => {
                        const raw = aiData.passageTranslationData || aiData.passageTranslations || [];
                        if (raw.length > 0 && raw[0].items) return raw[0].items;
                        return raw;
                    })(),
                    keyVocabulary: aiData.vocabulary || [],
                    questions: aiData.questions.map((q: any, idx: number) => ({
                        ...q,
                        id: existingQuestions[idx]?.id, // Keep the existing ID if it exists
                        questionNumber: startNum + idx,
                        questionText: cleanContent(q.questionText || ''),
                        optionA: cleanContent(q.optionA || ''),
                        optionB: cleanContent(q.optionB || ''),
                        optionC: cleanContent(q.optionC || ''),
                        optionD: cleanContent(q.optionD || '')
                    })),
                    startQuestion: startNum,
                    endQuestion: startNum + aiData.questions.length - 1
                };
                form.setFieldValue('passages', updatedPassages);
                setAiDoneIndexes(prev => [...new Set([...prev, index])]);
                if (!isBatch) message.success('Magic Scan thành công!');
            }
        } catch (e) { message.error('Lỗi Scan'); }
        finally { if (!isBatch) { setIsAiProcessing(false); } }
    };

    const handleFinish = async (values: any) => {
        if (!partId) return;
        setLoading(true);
        try {
            for (let i = 0; i < values.passages.length; i++) {
                const item = values.passages[i];
                const titleText = (item.passageTitle || '').replace(/<p[^>]*>/g, '').replace(/<\/p>/g, '').trim();
                let passageHtml = titleText ? `<p><b>${titleText}</b></p>` : '';
                passageHtml += (item.passage || '').replace(/<img[^>]*>/g, '');
                
                const pUrls = (passageFileLists[i] || []).map(f => f.url || f.response?.url).filter(Boolean).join(',');
                const sUrls = (questionFileLists[i] || []).map(f => f.url || f.response?.url).filter(Boolean).join(',');

                // Wrap translation items in the required structure
                const transPayload = [{
                    type: "passage",
                    label: "ĐOẠN VĂN",
                    items: item.passageTranslationData || []
                }];

                const payload = {
                    passage: passageHtml,
                    passageImageUrl: pUrls || null,
                    passageTranslationData: JSON.stringify(transPayload),
                    questions: (item.questions || []).map((q: any) => ({
                        ...q, 
                        passage: passageHtml, 
                        passageImageUrl: pUrls || null, 
                        questionScanUrl: sUrls || null,
                        passageTranslationData: JSON.stringify(transPayload),
                        optionTranslations: JSON.stringify(q.optionTranslations || {}),
                        keyVocabulary: JSON.stringify(item.keyVocabulary || [])
                    }))
                };

                if (mode === 'edit') {
                    for (const q of payload.questions) {
                        // Fail-safe: If q.id is missing, try to find it from initialData by matching questionNumber
                        let targetId = q.id;
                        if (!targetId && initialData?.questions) {
                            const match = initialData.questions.find((oldQ: any) => oldQ.questionNumber === q.questionNumber);
                            if (match) targetId = match.id;
                        }

                        if (targetId) await api.patch(`/questions/${targetId}`, q);
                        else await api.post(`/parts/${partId}/questions`, q);
                    }
                } else {
                    await api.post(`/parts/${partId}/questions/batch`, payload);
                }
            }
            message.success('Lưu thành công!');
            onSuccess(); onCancel();
        } catch (e) { message.error('Lỗi lưu'); }
        finally { setLoading(false); }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <div style={{
                        width: 42, height: 42, borderRadius: 12, 
                        background: '#2563EB',
                        display: 'flex', alignItems: 'center', justifyContent: 'center', 
                        color: '#fff', fontSize: 20
                    }}>
                        <ExperimentOutlined />
                    </div>
                    <div>
                        <span style={{ fontWeight: 800, fontSize: 18, color: '#1E293B', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                            {partName || `PART ${partNumber}: READING COMPREHENSION`}
                        </span>
                        <div style={{ fontSize: 12, color: '#64748B', fontWeight: 500 }}>Hệ thống quản lý Reading Part 7 Premium</div>
                    </div>
                </div>
            }
            open={open} onCancel={onCancel} width={1350} centered style={{ top: 20 }} maskClosable={false}
            styles={{ body: { padding: '24px', background: '#F8FAFC' } }}
            destroyOnHidden
            footer={[
                <Button key="cancel" size="large" onClick={onCancel} style={{ borderRadius: 10, fontWeight: 600, height: 44, padding: '0 32px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>Hủy bỏ</Button>,
                <Button 
                    key="submit" size="large" type="primary" 
                    onClick={() => form.submit()} loading={loading} 
                    icon={<CheckCircleOutlined />}
                    style={{ 
                        borderRadius: 10, fontWeight: 800, height: 44,
                        background: '#2563EB', border: 'none', padding: '0 40px',
                        boxShadow: '0 6px 16px rgba(37, 99, 235, 0.25)'
                    }}
                >
                    {mode === 'edit' ? 'CẬP NHẬT' : 'HOÀN TẤT'}
                </Button>
            ]}
        >
            <Form form={form} layout="vertical" onFinish={handleFinish} initialValues={{ passages: [{ questions: [{}, {}] }] }}>
                <Layout style={{ background: 'transparent', gap: 20 }}>
                    <Sider width={280} style={{ background: '#fff', borderRadius: 24, border: '1px solid #E2E8F0', padding: '20px', height: '75vh', overflowY: 'auto' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                            <Text strong style={{ color: '#64748B', fontSize: 12, textTransform: 'uppercase', letterSpacing: '1px' }}>Danh sách nhóm</Text>
                            <Button type="primary" shape="circle" size="small" icon={<PlusOutlined />} onClick={() => {
                                const current = form.getFieldValue('passages') || [];
                                form.setFieldValue('passages', [...current, { questions: [{}, {}] }]);
                            }} style={{ background: '#2563EB', border: 'none' }} />
                        </div>
                        <Form.List name="passages">
                            {(fields) => (
                                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                                    {fields.map((field, index) => (
                                        <div key={field.key} onClick={() => setCurrentInsightIndex(index)}
                                            style={{ 
                                                display: 'flex', alignItems: 'center', gap: 12, padding: '14px', 
                                                background: currentInsightIndex === index ? '#2563EB' : '#fff', 
                                                color: currentInsightIndex === index ? '#fff' : '#1E293B', 
                                                borderRadius: 16, cursor: 'pointer', 
                                                border: '1px solid #E2E8F0',
                                                transition: 'all 0.3s',
                                                boxShadow: currentInsightIndex === index ? '0 8px 16px rgba(37, 99, 235, 0.2)' : 'none'
                                            }}>
                                            <div style={{ 
                                                width: 28, height: 28, borderRadius: 8, 
                                                background: currentInsightIndex === index ? 'rgba(255,255,255,0.2)' : '#F1F5F9', 
                                                color: currentInsightIndex === index ? '#fff' : '#2563EB', 
                                                display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: 13 
                                            }}>{index + 1}</div>
                                            <div style={{ flex: 1, fontWeight: 700, fontSize: 14 }}>Nhóm {index + 1}</div>
                                            {aiDoneIndexes.includes(index) && <CheckCircleOutlined style={{ color: currentInsightIndex === index ? '#fff' : '#10B981' }} />}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </Form.List>
                        
                        <div style={{ marginTop: 'auto', paddingTop: 20 }}>
                            <Space direction="vertical" style={{ width: '100%' }} size="middle">
                                <Button block icon={<ThunderboltOutlined />} style={{ borderRadius: 12, height: 42, fontWeight: 600, color: '#475569' }}>Phân tích Tất cả</Button>
                                <Button block icon={<DeleteOutlined />} style={{ borderRadius: 12, height: 42, fontWeight: 600, color: '#EF4444' }}>Xóa Nhóm Hiện Tại</Button>
                            </Space>
                        </div>
                    </Sider>

                    <Content style={{ background: '#fff', borderRadius: 24, border: '1px solid #E2E8F0', padding: '32px', height: '75vh', overflowY: 'auto' }} className="custom-scrollbar">
                        <Form.List name="passages">
                            {(fields) => {
                                const field = fields[currentInsightIndex];
                                if (!field) return <Empty description="Chọn hoặc thêm nhóm mới" />;
                                return (
                                    <div key={field.key}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                                            <Space size="large">
                                                <div style={{ background: '#2563EB', color: '#fff', padding: '8px 24px', borderRadius: 12, fontWeight: 800, fontSize: 14 }}>NHÓM {currentInsightIndex + 1}</div>
                                                <Space>
                                                    <Text strong style={{ color: '#64748B', fontSize: 12 }}>TỪ CÂU:</Text>
                                                    <Form.Item name={[field.name, 'startQuestion']} noStyle><InputNumber style={{ width: 60, borderRadius: 8 }} /></Form.Item>
                                                    <Text strong style={{ color: '#64748B', fontSize: 12 }}>ĐẾN CÂU:</Text>
                                                    <Form.Item name={[field.name, 'endQuestion']} noStyle><InputNumber style={{ width: 60, borderRadius: 8 }} /></Form.Item>
                                                </Space>
                                            </Space>
                                            {currentPassageType === 'image' && (
                                                <Button type="primary" size="large" icon={<ThunderboltOutlined />}
                                                    onClick={() => handleMagicScan(currentInsightIndex)}
                                                    loading={isAiProcessing}
                                                    style={{ 
                                                        borderRadius: 12, 
                                                        height: 48, 
                                                        background: '#2563EB', 
                                                        fontWeight: 800, 
                                                        padding: '0 32px',
                                                        boxShadow: '0 6px 16px rgba(37, 99, 235, 0.25)',
                                                        border: 'none'
                                                    }}>
                                                    AI MAGIC SCAN NHÓM NÀY
                                                </Button>
                                            )}
                                        </div>

                                        <Form.Item label={<span style={{ fontWeight: 700, color: '#475569', fontSize: 13 }}>TIÊU ĐỀ ĐOẠN VĂN (VÍ DỤ: QUESTIONS 147-148 REFER TO...)</span>} name={[field.name, 'passageTitle']}>
                                            <ReactQuill theme="snow" style={{ height: 80, marginBottom: 40 }} 
                                                modules={{ toolbar: [['bold', 'italic', 'underline', { 'color': [] }]] }} 
                                                placeholder="Questions 147-148 refer to the following letter." />
                                        </Form.Item>

                                        <div style={{ marginBottom: 24 }}>
                                            <Form.Item name={[field.name, 'passageType']} initialValue="text" noStyle>
                                                <Radio.Group buttonStyle="solid">
                                                    <Radio.Button value="text" style={{ borderRadius: '8px 0 0 8px', height: 36, fontWeight: 800 }}>VĂN BẢN</Radio.Button>
                                                    <Radio.Button value="image" style={{ borderRadius: '0 8px 8px 0', height: 36, fontWeight: 800 }}>HÌNH ẢNH</Radio.Button>
                                                </Radio.Group>
                                            </Form.Item>
                                        </div>

                                        <Card title={
                                            <Space>
                                                <div style={{ color: '#2563EB', display: 'flex' }}>
                                                    {currentPassageType === 'text' ? <EditOutlined /> : <CameraOutlined />}
                                                </div>
                                                <span style={{ fontWeight: 800, fontSize: 14, color: '#1E293B' }}>
                                                    {currentPassageType === 'text' 
                                                        ? 'NHẬP LIỆU VĂN BẢN' 
                                                        : 'AI MAGIC SCAN - TỰ ĐỘNG NHẬN DIỆN TỪ ẢNH'}
                                                </span>
                                            </Space>
                                        } 
                                            style={{ borderRadius: 20, background: '#F8FAFC', border: '1px solid #E2E8F0', marginBottom: 40 }}
                                            styles={{ header: { borderBottom: 'none', padding: '16px 24px' }, body: { padding: '0 24px 24px' } }}>
                                            
                                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: 20 }}>
                                                {currentPassageType === 'text' ? (
                                                    <div style={{ background: '#fff', borderRadius: 16, padding: 20, border: '1px solid #E2E8F0' }}>
                                                        <Form.Item name={[field.name, 'passage']} label={<span style={{ fontWeight: 700, fontSize: 12 }}>NỘI DUNG VĂN BẢN</span>} style={{ marginBottom: 0 }}>
                                                            <ReactQuill theme="snow" style={{ height: 300, marginBottom: 40 }} modules={QUILL_MODULES} formats={QUILL_FORMATS} />
                                                        </Form.Item>
                                                    </div>
                                                ) : (
                                                    <div style={{ background: '#fff', borderRadius: 16, padding: 20, border: '1px solid #E2E8F0' }}>
                                                        <Space direction="vertical" style={{ width: '100%' }} size="large">
                                                            <div>
                                                                <Text strong style={{ fontSize: 11, color: '#64748B' }}>1. ẢNH ĐOẠN VĂN</Text>
                                                                <Dragger multiple showUploadList={false} action={`${api.defaults.baseURL}/upload/image`} name="image" headers={{ Authorization: `Bearer ${localStorage.getItem('admin_token')}` }} onChange={({ fileList }) => setPassageFileLists(prev => ({ ...prev, [currentInsightIndex]: fileList }))} style={{ background: '#F8FAFC', borderRadius: 12, border: '1px dashed #BFDBFE', padding: 12, marginTop: 8 }}>
                                                                    <CameraOutlined style={{ fontSize: 20, color: '#3B82F6' }} />
                                                                    <div style={{ fontSize: 12, color: '#64748B' }}>Thêm ảnh</div>
                                                                </Dragger>
                                                                <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                                                                    {getPreviewUrls(passageFileLists[currentInsightIndex]).map((url, i) => <div key={i} style={{ position: 'relative' }}><Image src={url} width={50} height={50} style={{ borderRadius: 8, objectFit: 'cover', border: '1px solid #E2E8F0' }} /><div style={{ position: 'absolute', top: -5, right: -5, background: '#EF4444', color: '#fff', borderRadius: '50%', width: 16, height: 16, fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>×</div></div>)}
                                                                </div>
                                                            </div>
                                                            <div>
                                                                <Text strong style={{ fontSize: 11, color: '#64748B' }}>2. ẢNH CÂU HỎI</Text>
                                                                <Dragger multiple showUploadList={false} action={`${api.defaults.baseURL}/upload/image`} name="image" headers={{ Authorization: `Bearer ${localStorage.getItem('admin_token')}` }} onChange={({ fileList }) => setQuestionFileLists(prev => ({ ...prev, [currentInsightIndex]: fileList }))} style={{ background: '#F8FAFC', borderRadius: 12, border: '1px dashed #BBF7D0', padding: 12, marginTop: 8 }}>
                                                                    <CameraOutlined style={{ fontSize: 20, color: '#22C55E' }} />
                                                                    <div style={{ fontSize: 12, color: '#64748B' }}>Thêm ảnh</div>
                                                                </Dragger>
                                                                <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                                                                    {getPreviewUrls(questionFileLists[currentInsightIndex]).map((url, i) => <div key={i} style={{ position: 'relative' }}><Image src={url} width={50} height={50} style={{ borderRadius: 8, objectFit: 'cover', border: '1px solid #E2E8F0' }} /><div style={{ position: 'absolute', top: -5, right: -5, background: '#EF4444', color: '#fff', borderRadius: '50%', width: 16, height: 16, fontSize: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>×</div></div>)}
                                                                </div>
                                                            </div>
                                                        </Space>
                                                    </div>
                                                )}

                                                <div style={{ background: '#fff', borderRadius: 16, padding: 20, border: '1px solid #E2E8F0', display: 'flex', flexDirection: 'column' }}>
                                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                                                        <Space><GlobalOutlined style={{ color: '#2563EB' }} /><span style={{ fontWeight: 800, fontSize: 13, color: '#475569' }}>BẢN DỊCH SONG NGỮ</span></Space>
                                                    </div>
                                                    <div style={{ background: '#F0F9FF', padding: '10px 16px', borderRadius: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                                                        <Text strong style={{ fontSize: 13, color: '#2563EB' }}>ĐOẠN VĂN</Text>
                                                        <Form.List name={[field.name, 'passageTranslationData']}>
                                                            {(_, { add }) => (
                                                                <Button size="small" type="primary" ghost icon={<PlusOutlined />} onClick={() => add()} style={{ borderRadius: 6, fontSize: 11, fontWeight: 700 }}>Thêm câu</Button>
                                                            )}
                                                        </Form.List>
                                                    </div>
                                                    <div style={{ flex: 1, overflowY: 'auto', maxHeight: 350, paddingRight: 8 }} className="custom-scrollbar">
                                                        <Form.List name={[field.name, 'passageTranslationData']}>
                                                            {(transFields, { remove }) => (
                                                                <>
                                                                    {transFields.length === 0 && <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} />}
                                                                    {transFields.map((tf, tIdx) => (
                                                                        <div key={tf.key} style={{ padding: '16px 0', borderBottom: '1px dashed #BFDBFE', position: 'relative' }}>
                                                                            <Row gutter={12} align="middle">
                                                                                <Col flex="40px">
                                                                                    <Tag style={{ background: '#E0F2FE', color: '#0369A1', border: 'none', fontWeight: 800, margin: 0, borderRadius: 4, width: '100%', textAlign: 'center' }}>EN</Tag>
                                                                                </Col>
                                                                                <Col flex="auto">
                                                                                    <Form.Item name={[tf.name, 'en']} noStyle><Input variant="borderless" style={{ fontWeight: 500, padding: 0 }} /></Form.Item>
                                                                                </Col>
                                                                            </Row>
                                                                            <Row gutter={12} align="middle" style={{ marginTop: 8 }}>
                                                                                <Col flex="40px">
                                                                                    <Text strong style={{ color: '#059669', fontSize: 12, width: '100%', textAlign: 'center', display: 'block' }}>VI</Text>
                                                                                </Col>
                                                                                <Col flex="auto">
                                                                                    <Form.Item name={[tf.name, 'vi']} noStyle><Input variant="borderless" style={{ fontStyle: 'italic', color: '#059669', padding: 0 }} /></Form.Item>
                                                                                </Col>
                                                                            </Row>
                                                                            <Button 
                                                                                type="text" danger icon={<DeleteOutlined />} 
                                                                                size="small" onClick={() => remove(tIdx)}
                                                                                style={{ position: 'absolute', top: 12, right: -8, opacity: 0.3 }}
                                                                                onMouseEnter={(e) => e.currentTarget.style.opacity = '1'}
                                                                                onMouseLeave={(e) => e.currentTarget.style.opacity = '0.3'}
                                                                            />
                                                                        </div>
                                                                    ))}
                                                                </>
                                                            )}
                                                        </Form.List>
                                                    </div>
                                                </div>
                                            </div>
                                        </Card>

                                        <Divider titlePlacement="left"><span style={{ fontWeight: 800, color: '#1E293B', fontSize: 14 }}>CHI TIẾT NỘI DUNG</span></Divider>

                                        <Tabs defaultActiveKey="questions" items={[
                                            {
                                                key: 'questions',
                                                label: <span style={{ fontWeight: 700, fontSize: 13 }}><EditOutlined /> CÂU HỎI CHI TIẾT</span>,
                                                children: (
                                                    <Form.List name={[field.name, 'questions']}>
                                                        {(qFields) => (
                                                            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                                                                {qFields.map((qf, _qi) => (
                                                                    <Card key={qf.key} style={{ borderRadius: 24, border: '1px solid #E2E8F0', overflow: 'hidden', boxShadow: '0 4px 12px rgba(0,0,0,0.03)' }}>
                                                                        <div style={{ background: '#F8FAFC', padding: '16px 24px', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                                            <Space size="large">
                                                                                <Space><Text strong style={{ color: '#1E293B', fontSize: 13, fontWeight: 800 }}>CÂU:</Text>
                                                                                <Form.Item name={[qf.name, 'questionNumber']} noStyle><InputNumber style={{ width: 70, borderRadius: 10, fontWeight: 800 }} /></Form.Item></Space>
                                                                                <Space><Text strong style={{ color: '#1E293B', fontSize: 13, fontWeight: 800 }}>ĐÁP ÁN:</Text>
                                                                                <Form.Item name={[qf.name, 'correctAnswer']} noStyle><Select options={[{ value: 'A' }, { value: 'B' }, { value: 'C' }, { value: 'D' }]} style={{ width: 80, fontWeight: 800 }} /></Form.Item></Space>
                                                                            </Space>
                                                                            <Form.Item name={[qf.name, 'questionText']} style={{ margin: 0, flex: 1, marginLeft: 32 }}>
                                                                                <Input placeholder="Nội dung câu hỏi (Nếu có)" style={{ borderRadius: 10, height: 40 }} />
                                                                            </Form.Item>
                                                                        </div>

                                                                        <div style={{ padding: 24 }}>
                                                                            <Row gutter={[16, 24]}>
                                                                                {['A', 'B', 'C', 'D'].map(opt => (
                                                                                    <Col span={6} key={opt}>
                                                                                        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                                                                                            <Text strong style={{ fontSize: 11, color: '#64748B' }}>LỰA CHỌN {opt}</Text>
                                                                                            <Form.Item name={[qf.name, `option${opt}`]} noStyle><Input style={{ borderRadius: 10, fontWeight: 600 }} /></Form.Item>
                                                                                            <Text strong style={{ fontSize: 10, color: '#3B82F6', marginTop: 4 }}>DỊCH {opt}</Text>
                                                                                            <Form.Item name={[qf.name, 'optionTranslations', opt]} noStyle><Input style={{ borderRadius: 10, fontSize: 12, fontStyle: 'italic' }} /></Form.Item>
                                                                                        </div>
                                                                                    </Col>
                                                                                ))}
                                                                            </Row>

                                                                            <div style={{ marginTop: 32, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
                                                                                <Card size="small" title={<Space><InfoCircleOutlined style={{ color: '#3B82F6' }} /><Text strong style={{ fontSize: 12 }}>PHÂN TÍCH</Text></Space>} styles={{ body: { padding: 12 } }} style={{ borderRadius: 16, background: '#EFF6FF', border: '1px solid #DBEAFE' }}>
                                                                                    <Form.Item name={[qf.name, 'analysis']} noStyle>
                                                                                        <Input.TextArea rows={4} placeholder="Phân tích ngữ pháp/từ vựng..." style={{ borderRadius: 12, border: 'none', background: 'transparent' }} />
                                                                                    </Form.Item>
                                                                                </Card>
                                                                                <Card size="small" title={<Space><FileSearchOutlined style={{ color: '#10B981' }} /><Text strong style={{ fontSize: 12 }}>BẰNG CHỨNG</Text></Space>} styles={{ body: { padding: 12 } }} style={{ borderRadius: 16, background: '#ECFDF5', border: '1px solid #D1FAE5' }}>
                                                                                    <Form.Item name={[qf.name, 'evidence']} noStyle>
                                                                                        <Input.TextArea rows={4} placeholder="Trích dẫn câu chứa đáp án..." style={{ borderRadius: 12, border: 'none', background: 'transparent' }} />
                                                                                    </Form.Item>
                                                                                </Card>
                                                                            </div>
                                                                        </div>
                                                                    </Card>
                                                                ))}
                                                            </div>
                                                        )}
                                                    </Form.List>
                                                )
                                            },
                                            {
                                                key: 'vocabulary',
                                                label: <span style={{ fontWeight: 700, fontSize: 13 }}><BookOutlined /> TỪ VỰNG HỆ THỐNG</span>,
                                                children: (
                                                    <div style={{ padding: 24, background: '#fff', borderRadius: 20, border: '1px solid #E2E8F0' }}>
                                                        <Form.List name={[field.name, 'keyVocabulary']}>
                                                            {(vFields, { add, remove }) => (
                                                                <>
                                                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                                                                        <Space><BookOutlined style={{ color: '#2563EB' }} /><Text strong style={{ fontSize: 14 }}>DANH SÁCH TỪ VỰNG NHẬP TAY</Text></Space>
                                                                        <Button type="primary" ghost icon={<PlusOutlined />} onClick={() => add()} style={{ borderRadius: 8, fontWeight: 700, boxShadow: '0 4px 10px rgba(37, 99, 235, 0.1)' }}>Thêm từ mới</Button>
                                                                    </div>
                                                                    {vFields.length === 0 && <Empty description="Chưa có từ vựng. Hãy nhấn nút Thêm từ mới." />}
                                                                    <Row gutter={[16, 16]}>
                                                                        {vFields.map((vf) => (
                                                                            <Col span={12} key={vf.key}>
                                                                                <Card size="small" style={{ borderRadius: 12, border: '1px solid #DBEAFE', background: '#F8FAFC' }}
                                                                                    extra={<Button type="text" danger icon={<DeleteOutlined />} onClick={() => remove(vf.name)} size="small" />}>
                                                                                    <Row gutter={8}>
                                                                                        <Col span={8}><Form.Item name={[vf.name, 'word']} noStyle><Input placeholder="Từ vựng" style={{ borderRadius: 6 }} /></Form.Item></Col>
                                                                                        <Col span={6}><Form.Item name={[vf.name, 'type']} noStyle><Input placeholder="Loại" style={{ borderRadius: 6 }} /></Form.Item></Col>
                                                                                        <Col span={10}><Form.Item name={[vf.name, 'pronunciation']} noStyle><Input placeholder="Phiên âm" style={{ borderRadius: 6 }} /></Form.Item></Col>
                                                                                    </Row>
                                                                                    <Form.Item name={[vf.name, 'meaning']} style={{ marginTop: 8, marginBottom: 0 }}><Input placeholder="Nghĩa của từ" style={{ borderRadius: 6 }} /></Form.Item>
                                                                                </Card>
                                                                            </Col>
                                                                        ))}
                                                                    </Row>
                                                                </>
                                                            )}
                                                        </Form.List>
                                                    </div>
                                                )
                                            }
                                        ]} />
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