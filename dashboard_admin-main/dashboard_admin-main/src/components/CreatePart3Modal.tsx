import { useState, useEffect } from 'react';
import { Modal, Form, Input, Select, message, Button, Row, Col, Upload, Image, Typography, Tabs, Divider, Space } from 'antd';
import { 
    SoundOutlined, 
    DeleteOutlined, 
    CheckCircleOutlined, 
    InboxOutlined,
    TranslationOutlined,
    BookOutlined,
    PlusOutlined
} from '@ant-design/icons';
import ReactQuill from 'react-quill-new';
import 'quill/dist/quill.snow.css';
import api, { uploadApi, questionApi } from '../services/api';
import AudioBanner from './AudioBanner';
import { QUILL_MODULES, QUILL_FORMATS } from '../utils/editorUtils';

const { Option } = Select;
const { Text } = Typography;

interface CreatePart3ModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    partNumber: number; // 3 or 4
    partName?: string;
    mode?: 'add' | 'edit';
    initialData?: any;
    currentAudioUrl?: string; // ✅ New
}

export default function CreatePart3Modal({ open, onCancel, onSuccess, partId, partNumber, partName, mode = 'add', initialData, currentAudioUrl }: CreatePart3ModalProps) {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [audioFiles, setAudioFiles] = useState<File | File[] | null>(null);
    const [graphicFile, setGraphicFile] = useState<File | null>(null);
    const [graphicPreview, setGraphicPreview] = useState<string | null>(null);
    const [nextQuestionNumber, setNextQuestionNumber] = useState<number>(1);
    const [activeTab, setActiveTab] = useState('translation');


    const defaultStart = partNumber === 3 ? 32 : 71;

    useEffect(() => {
        if (open && partId) {
            if (mode === 'edit' && initialData) {
                const firstQ = initialData.questions?.[0] || {};
                
                // Parse Vocabulary
                let vocab = [];
                if (firstQ.keyVocabulary) {
                    try {
                        vocab = typeof firstQ.keyVocabulary === 'string' ? JSON.parse(firstQ.keyVocabulary) : firstQ.keyVocabulary;
                    } catch (e) { console.error('Parse vocab error', e); }
                }

                // Parse Translation Data
                let translations = [];
                if (firstQ.passageTranslationData) {
                    try {
                        const raw = typeof firstQ.passageTranslationData === 'string' ? JSON.parse(firstQ.passageTranslationData) : firstQ.passageTranslationData;
                        if (Array.isArray(raw) && raw[0]?.items) {
                            translations = raw[0].items;
                        }
                    } catch (e) { console.error('Parse translation error', e); }
                }

                form.setFieldsValue({
                    transcript: initialData.transcript || initialData.passage || firstQ.transcript || '',
                    questions: initialData.questions,
                    keyVocabulary: Array.isArray(vocab) ? vocab : [],
                    translationSentences: translations
                });

                if (initialData.passageImageUrl || firstQ.passageImageUrl) {
                    setGraphicPreview(initialData.passageImageUrl || firstQ.passageImageUrl);
                }
            } else {
                fetchNextQuestionNumber();
                // Tự động tạo 3 câu hỏi với số câu tiếp theo
                const startNum = nextQuestionNumber > 1 ? nextQuestionNumber : defaultStart;
                form.setFieldsValue({
                    questions: [
                        { questionNumber: startNum, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A' },
                        { questionNumber: startNum + 1, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A' },
                        { questionNumber: startNum + 2, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A' }
                    ],
                    keyVocabulary: [],
                    translationSentences: []
                });
            }
        } else {
            form.resetFields();
            setAudioFiles(null);
            setGraphicFile(null);
            setGraphicPreview(null);
        }
    }, [open, partId, mode, initialData]);

    const fetchNextQuestionNumber = async () => {
        if (!partId) return;
        try {
            const response = await api.get(`/parts/${partId}/questions`);
            if (response.data.success) {
                const questions = response.data.questions;
                if (questions.length > 0) {
                    const maxNum = Math.max(...questions.map((q: any) => q.questionNumber));
                    const nextNum = maxNum + 1;
                    setNextQuestionNumber(nextNum);
                    
                    // Nếu đang ở chế độ thêm mới và chưa có câu hỏi nào trong form, tự điền luôn
                    if (mode === 'add') {
                        form.setFieldsValue({
                            questions: [
                                { questionNumber: nextNum, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A' },
                                { questionNumber: nextNum + 1, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A' },
                                { questionNumber: nextNum + 2, questionText: '', optionA: '', optionB: '', optionC: '', optionD: '', correctAnswer: 'A' }
                            ]
                        });
                    }
                } else {
                    setNextQuestionNumber(defaultStart);
                }
            }
        } catch (error) {
            console.error('Error fetching questions:', error);
        }
    };

    useEffect(() => {
        if (open && mode === 'add' && nextQuestionNumber !== 1) {
            const initialQuestions = [0, 1, 2].map(i => ({
                questionNumber: nextQuestionNumber + i,
                questionText: '',
                optionA: '',
                optionB: '',
                optionC: '',
                optionD: '',
                correctAnswer: undefined
            }));
            form.setFieldsValue({ questions: initialQuestions });
        }
    }, [open, nextQuestionNumber, mode]);

    // Excel import handled at PartDetail level

    const handleGraphicBeforeUpload = (file: File) => {
        const preview = URL.createObjectURL(file);
        setGraphicPreview(preview);
        setGraphicFile(file);
        return false;
    };

    const handleSubmit = async (values: any) => {
        if (!partId) return;

        if (mode === 'add' && (!audioFiles || (Array.isArray(audioFiles) && audioFiles.length === 0))) {
            message.error('Vui lòng upload ít nhất 1 file âm thanh!');
            return;
        }

        const minQ = partNumber === 3 ? 32 : 71;
        const maxQ = partNumber === 3 ? 70 : 100;
        const outOfRange = values.questions.filter((q: any) => q.questionNumber < minQ || q.questionNumber > maxQ);
        if (outOfRange.length > 0) {
            message.error(`Câu hỏi Part ${partNumber} phải nằm trong khoảng từ ${minQ} đến ${maxQ}`);
            return;
        }

        try {
            setLoading(true);

            let audioUrl = mode === 'edit' ? (initialData?.audioUrl || initialData.questions?.[0]?.audioUrl || '') : '';
            if (audioFiles) {
                if (Array.isArray(audioFiles) && audioFiles.length === 2) {
                    message.loading({ content: 'Đang gộp và upload âm thanh...', key: 'upload' });
                    const mergeRes = await uploadApi.mergeAudio(audioFiles);
                    if (!mergeRes.success) throw new Error(mergeRes.message || 'Gộp âm thanh thất bại');
                    audioUrl = mergeRes.url;
                } else {
                    message.loading({ content: 'Đang upload âm thanh...', key: 'upload' });
                    const fileToUpload = Array.isArray(audioFiles) ? audioFiles[0] : audioFiles;
                    const audioRes = await uploadApi.audio(fileToUpload);
                    if (!audioRes.success) throw new Error(audioRes.message || 'Upload âm thanh thất bại');
                    audioUrl = audioRes.url;
                }
            }

            let graphicUrl = mode === 'edit' ? (initialData?.passageImageUrl || initialData.questions?.[0]?.passageImageUrl || '') : '';
            if (graphicFile) {
                const imgRes = await uploadApi.image(graphicFile);
                if (imgRes.success) graphicUrl = imgRes.url;
            }

            const keyVocabularyJson = JSON.stringify(values.keyVocabulary || []);
            const passageTranslationDataJson = JSON.stringify([
                {
                    type: 'passage',
                    label: 'Transcript',
                    items: values.translationSentences || []
                }
            ]);

            const questionsPayload = values.questions.map((q: any) => ({
                id: q.id,
                questionNumber: q.questionNumber,
                questionText: q.questionText,
                optionA: q.optionA,
                optionB: q.optionB,
                optionC: q.optionC,
                optionD: q.optionD,
                correctAnswer: q.correctAnswer,
                explanation: values.transcript,
                audioUrl: audioUrl,
                transcript: values.transcript,
                keyVocabulary: keyVocabularyJson,
                passageTranslationData: passageTranslationDataJson
            }));

            let passageHtml = `<audio src="${audioUrl}"></audio>`;
            if (graphicUrl) {
                passageHtml += `<p><img src="${graphicUrl}" style="max-width: 100%; display: block; margin: 10px auto;" /></p>`;
            }

            const payload = {
                passage: passageHtml,
                questions: questionsPayload,
                audioUrl: audioUrl,
                transcript: values.transcript,
                passageImageUrl: graphicUrl,
                keyVocabulary: keyVocabularyJson,
                passageTranslationData: passageTranslationDataJson
            };

            if (mode === 'edit' && initialData) {
                message.loading({ content: 'Đang cập nhật nhóm câu hỏi...', key: 'upload' });
                if (initialData.questions && initialData.questions.length > 0) {
                    await Promise.all(initialData.questions.map((q: any) => questionApi.delete(q.id)));
                }
            }

            const response = await api.post(`/parts/${partId}/questions/batch`, payload);

            if (response.data.success) {
                message.success({ content: mode === 'edit' ? 'Cập nhật nhóm thành công!' : `Tạo nhóm Part ${partNumber} thành công!`, key: 'upload' });
                form.resetFields();
                setAudioFiles(null);
                setGraphicFile(null);
                setGraphicPreview(null);
                onSuccess();
                onCancel();
            } else {
                message.error(response.data.message);
            }

        } catch (error: any) {
            console.error('Error saving group:', error);
            message.error(error.message || 'Có lỗi xảy ra');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{
                        width: 40, height: 40, borderRadius: 12,
                        background: 'linear-gradient(135deg, #1E293B 0%, #334155 100%)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        boxShadow: '0 4px 12px rgba(30, 41, 59, 0.2)'
                    }}>
                        <SoundOutlined style={{ color: '#fff', fontSize: 20 }} />
                    </div>
                    <div>
                        <span style={{ fontSize: 19, fontWeight: 850, color: '#1E293B', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                            {mode === 'edit' ? `CHỈNH SỬA NHÓM PART ${partNumber}` : (partName || `THÊM NHÓM PART ${partNumber}`)}
                        </span>
                        <Text type="secondary" style={{ fontSize: 11, fontWeight: 600, display: 'block', marginTop: -2 }}>
                            {mode === 'edit' ? 'Cập nhật Audio, Transcript và Từ vựng' : 'Quản lý bài nghe chuyên sâu (Manual & AI Support)'}
                        </Text>
                    </div>
                </div>
            }
            open={open} onCancel={onCancel} footer={null} width={1350} centered maskClosable={false}
            styles={{ body: { padding: '24px 32px', maxHeight: '85vh', overflowY: 'auto' } }}
        >
            <Form form={form} layout="vertical" onFinish={handleSubmit} requiredMark={false}>
                {/* ─── AUDIO SECTION ─── */}
                <div style={{ marginBottom: 24 }}>
                    <AudioBanner 
                        currentAudioUrl={currentAudioUrl || initialData?.audioUrl || initialData?.questions?.[0]?.audioUrl} 
                        newAudioFile={audioFiles}
                        onAudioFileChange={setAudioFiles}
                        multiple={true}
                    />
                </div>

                <Row gutter={28}>
                    {/* ─── LEFT COLUMN: TRANSCRIPT & MEDIA ─── */}
                    <Col span={13}>
                        <div style={{ background: '#F8FAFC', borderRadius: 20, padding: 24, border: '1px solid #E2E8F0', height: '100%' }}>
                            <div style={{ fontWeight: 800, color: '#1E293B', marginBottom: 20, display: 'flex', alignItems: 'center', gap: 10, fontSize: 15 }}>
                                <div style={{ width: 6, height: 20, background: '#3B82F6', borderRadius: 3 }} />
                                1. NỘI DUNG BÀI NGHE & BẢN DỊCH
                            </div>

                            <Row gutter={16} style={{ marginBottom: 24 }}>
                                <Col span={16}>
                                    <Text strong style={{ color: '#475569', display: 'block', marginBottom: 8, fontSize: 13 }}>Nội dung Transcript:</Text>
                                    <Form.Item name="transcript" rules={[{ required: true, message: 'Vui lòng nhập transcript' }]} style={{ marginBottom: 0 }}>
                                        <ReactQuill theme="snow" modules={QUILL_MODULES} formats={QUILL_FORMATS} placeholder="Nhập nội dung hội thoại..." style={{ height: 260, marginBottom: 42, background: '#FFF', borderRadius: 12 }} />
                                    </Form.Item>
                                </Col>
                                <Col span={8}>
                                    <Text strong style={{ color: '#475569', display: 'block', marginBottom: 8, fontSize: 13 }}>Ảnh minh họa (Graphic):</Text>
                                    <Upload beforeUpload={handleGraphicBeforeUpload} showUploadList={false} accept="image/*">
                                        <div style={{
                                            width: '100%', height: 260, borderRadius: 16, border: graphicPreview ? '1px solid #E2E8F0' : '2px dashed #CBD5E1',
                                            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                                            cursor: 'pointer', background: '#FFF', overflow: 'hidden', transition: 'all 0.3s'
                                        }}>
                                            {graphicPreview ? (
                                                <div style={{ position: 'relative', width: '100%', height: '100%' }}>
                                                    <Image src={graphicPreview} preview={false} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                                                    <div style={{ position: 'absolute', top: 8, right: 8 }}>
                                                        <Button danger type="primary" shape="circle" size="small" icon={<DeleteOutlined />} onClick={(e) => { e.stopPropagation(); setGraphicPreview(null); setGraphicFile(null); }} />
                                                    </div>
                                                </div>
                                            ) : (
                                                <>
                                                    <InboxOutlined style={{ fontSize: 32, color: '#94A3B8' }} />
                                                    <span style={{ fontSize: 12, color: '#94A3B8', marginTop: 10, fontWeight: 500 }}>Bấm để chọn ảnh</span>
                                                </>
                                            )}
                                        </div>
                                    </Upload>
                                </Col>
                            </Row>

                            <Divider style={{ margin: '16px 0' }} />

                            <Tabs 
                                activeKey={activeTab} 
                                onChange={setActiveTab}
                                type="card"
                                className="premium-tabs"
                                items={[
                                    {
                                        key: 'translation',
                                        label: <span style={{ fontWeight: 700 }}><TranslationOutlined /> Bản dịch song ngữ</span>,
                                        children: (
                                            <div style={{ padding: '12px 4px' }}>
                                                <Form.List name="translationSentences">
                                                    {(fields, { add, remove }) => (
                                                        <>
                                                            {fields.map(({ key, name, ...restField }) => (
                                                                <div key={key} style={{ display: 'flex', gap: 10, marginBottom: 12, background: '#fff', padding: 12, borderRadius: 12, border: '1px solid #E2E8F0' }}>
                                                                    <div style={{ flex: 1 }}>
                                                                        <Form.Item {...restField} name={[name, 'en']} style={{ marginBottom: 8 }}><Input.TextArea autoSize placeholder="English sentence..." style={{ borderRadius: 8, fontSize: 13 }} /></Form.Item>
                                                                        <Form.Item {...restField} name={[name, 'vi']} style={{ marginBottom: 0 }}><Input.TextArea autoSize placeholder="Bản dịch tiếng Việt..." style={{ borderRadius: 8, fontSize: 13, background: '#F0F9FF' }} /></Form.Item>
                                                                    </div>
                                                                    <Button type="text" danger icon={<DeleteOutlined />} onClick={() => remove(name)} style={{ alignSelf: 'center' }} />
                                                                </div>
                                                            ))}
                                                            <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />} style={{ borderRadius: 10, height: 44, fontWeight: 600 }}>Thêm câu dịch</Button>
                                                        </>
                                                    )}
                                                </Form.List>
                                            </div>
                                        )
                                    },
                                    {
                                        key: 'vocab',
                                        label: <span style={{ fontWeight: 700 }}><BookOutlined /> Từ vựng (Flashcards)</span>,
                                        children: (
                                            <div style={{ padding: '12px 4px' }}>
                                                <Form.List name="keyVocabulary">
                                                    {(fields, { add, remove }) => (
                                                        <>
                                                            <Row gutter={10} style={{ marginBottom: 8, padding: '0 8px' }}>
                                                                <Col span={6}><Text type="secondary" style={{ fontSize: 11, fontWeight: 700 }}>TỪ VỰNG</Text></Col>
                                                                <Col span={3}><Text type="secondary" style={{ fontSize: 11, fontWeight: 700 }}>LOẠI</Text></Col>
                                                                <Col span={5}><Text type="secondary" style={{ fontSize: 11, fontWeight: 700 }}>PHIÊN ÂM</Text></Col>
                                                                <Col span={8}><Text type="secondary" style={{ fontSize: 11, fontWeight: 700 }}>NGHĨA</Text></Col>
                                                            </Row>
                                                            {fields.map(({ key, name, ...restField }) => (
                                                                <div key={key} style={{ display: 'flex', gap: 8, marginBottom: 10, alignItems: 'center' }}>
                                                                    <Form.Item {...restField} name={[name, 'word']} style={{ marginBottom: 0, flex: 6 }} rules={[{ required: true }]}><Input placeholder="Word" style={{ borderRadius: 6 }} /></Form.Item>
                                                                    <Form.Item {...restField} name={[name, 'type']} style={{ marginBottom: 0, flex: 3 }}><Input placeholder="n, v..." style={{ borderRadius: 6 }} /></Form.Item>
                                                                    <Form.Item {...restField} name={[name, 'ipa']} style={{ marginBottom: 0, flex: 5 }}><Input placeholder="/ipa/" style={{ borderRadius: 6 }} /></Form.Item>
                                                                    <Form.Item {...restField} name={[name, 'meaning']} style={{ marginBottom: 0, flex: 8 }} rules={[{ required: true }]}><Input placeholder="Nghĩa..." style={{ borderRadius: 6 }} /></Form.Item>
                                                                    <Button type="text" danger icon={<DeleteOutlined />} onClick={() => remove(name)} />
                                                                </div>
                                                            ))}
                                                            <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />} style={{ borderRadius: 10, height: 44, fontWeight: 600 }}>Thêm từ vựng mới</Button>
                                                        </>
                                                    )}
                                                </Form.List>
                                            </div>
                                        )
                                    }
                                ]}
                            />
                        </div>
                    </Col>

                    {/* ─── RIGHT COLUMN: 3 QUESTIONS ─── */}
                    <Col span={11}>
                        <div style={{ background: '#FFF', borderRadius: 20, padding: 24, border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.03)', height: '100%' }}>
                            <div style={{ fontWeight: 800, color: '#1E293B', marginBottom: 24, display: 'flex', alignItems: 'center', gap: 10, fontSize: 15 }}>
                                <div style={{ width: 6, height: 20, background: '#1E293B', borderRadius: 3 }} />
                                2. CHI TIẾT 3 CÂU HỎI
                            </div>

                            <Form.List name="questions">
                                {(fields) => (
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                                        {fields.map((field, index) => (
                                            <div key={field.key} style={{ padding: 20, borderRadius: 18, background: '#F8FAFC', border: '1px solid #E2E8F0', position: 'relative' }}>
                                                <div style={{ position: 'absolute', top: -11, left: 20, background: '#1E293B', color: '#fff', padding: '2px 14px', borderRadius: 20, fontSize: 12, fontWeight: 800, boxShadow: '0 4px 8px rgba(0,0,0,0.15)' }}>
                                                    CÂU {form.getFieldValue(['questions', index, 'questionNumber']) || (nextQuestionNumber + index)}
                                                </div>

                                                <Space direction="vertical" style={{ width: '100%', marginTop: 10 }} size={16}>
                                                    <div style={{ display: 'flex', gap: 12 }}>
                                                         <Form.Item {...field} name={[field.name, 'questionNumber']} label={<span style={{ fontSize: 12, fontWeight: 800, color: '#475569' }}>Số câu</span>} rules={[{ required: true }]} style={{ marginBottom: 0, width: 80 }}>
                                                            <Input type="number" style={{ borderRadius: 10 }} />
                                                        </Form.Item>
                                                        <Form.Item {...field} name={[field.name, 'questionText']} label={<span style={{ fontSize: 12, fontWeight: 800, color: '#475569' }}>Nội dung câu hỏi</span>} rules={[{ required: true }]} style={{ marginBottom: 0, flex: 1 }}>
                                                            <Input placeholder="Nhập câu hỏi..." size="large" style={{ borderRadius: 10 }} />
                                                        </Form.Item>
                                                    </div>

                                                    <Row gutter={[12, 12]}>
                                                        {['A', 'B', 'C', 'D'].map(opt => (
                                                            <Col span={12} key={opt}>
                                                                <Form.Item {...field} name={[field.name, `option${opt}`]} style={{ marginBottom: 0 }} rules={[{ required: true }]}>
                                                                    <Input prefix={<b style={{ color: '#94A3B8', marginRight: 6 }}>{opt}</b>} placeholder={`Đáp án ${opt}`} style={{ borderRadius: 8 }} />
                                                                </Form.Item>
                                                            </Col>
                                                        ))}
                                                    </Row>

                                                    <Form.Item {...field} name={[field.name, 'correctAnswer']} label={<span style={{ fontSize: 12, fontWeight: 800, color: '#475569' }}>Đáp án đúng</span>} rules={[{ required: true }]} style={{ marginBottom: 0 }}>
                                                        <Select placeholder="Chọn đáp án đúng" size="large" style={{ borderRadius: 10 }}>
                                                            {['A', 'B', 'C', 'D'].map(o => <Option key={o} value={o}>Đáp án {o}</Option>)}
                                                        </Select>
                                                    </Form.Item>
                                                </Space>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </Form.List>
                        </div>
                    </Col>
                </Row>

                <div style={{ textAlign: 'right', marginTop: 40, paddingTop: 24, borderTop: '1px solid #E2E8F0', display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
                    <Button onClick={onCancel} size="large" style={{ borderRadius: 12, padding: '0 32px', fontWeight: 600 }}>Hủy bỏ</Button>
                    <Button
                        type="primary" htmlType="submit" loading={loading} size="large" icon={<CheckCircleOutlined />}
                        style={{
                            borderRadius: 12, padding: '0 40px', fontWeight: 700,
                            background: mode === 'edit' ? 'linear-gradient(135deg, #059669 0%, #10B981 100%)' : 'linear-gradient(135deg, #1E293B 0%, #334155 100%)',
                            border: 'none', boxShadow: '0 8px 16px rgba(30, 41, 59, 0.25)', height: 50
                        }}
                    >
                        {mode === 'edit' ? 'CẬP NHẬT NHÓM' : 'LƯU NHÓM CÂU HỎI'}
                    </Button>
                </div>
            </Form>
        </Modal>
    );
}
