import { useState, useEffect } from 'react';
import { Modal, Input, Select, message, Upload, Button, Image, Row, Col, Card, Space, Typography, Badge } from 'antd';
import { UploadOutlined, DeleteOutlined, PictureOutlined, CheckCircleFilled, FileExcelOutlined, DownloadOutlined } from '@ant-design/icons';
import * as XLSX from 'xlsx';
import type { UploadFile } from 'antd/es/upload/interface';
import api, { uploadApi, partApi } from '../services/api';
import AudioBanner from './AudioBanner';

const { Option } = Select;
const { Text, Title } = Typography;

interface CreatePart1BulkModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    currentAudioUrl?: string;
    partName?: string;
    partNumber?: number;
    initialData?: any[];
}

interface QuestionDraft {
    id: number; // 1-6
    imageFile: UploadFile | null;
    previewImage: string;
    correctAnswer: string;
    transcriptA?: string;
    transcriptB?: string;
    transcriptC?: string;
    transcriptD?: string;
}

export default function CreatePart1BulkModal({ open, onCancel, onSuccess, partId, currentAudioUrl, initialData }: CreatePart1BulkModalProps) {
    const [loading, setLoading] = useState(false);
    const [audioFile, setAudioFile] = useState<File | null>(null);
    const [activeQuestionIndex, setActiveQuestionIndex] = useState(0);

    const initialQuestions: QuestionDraft[] = Array.from({ length: 6 }, (_, i) => ({
        id: i + 1,
        imageFile: null,
        previewImage: '',
        correctAnswer: ''
    }));

    const [questions, setQuestions] = useState<QuestionDraft[]>(initialQuestions);

    useEffect(() => {
        if (open) {
            if (initialData && initialData.length > 0) {
                const finalQuestions = [...initialQuestions];
                initialData.forEach((row: any) => {
                    const qId = Number(row['Số câu'] || row['questionNumber'] || 0);
                    if (qId >= 1 && qId <= 6) {
                        const idx = qId - 1;
                        finalQuestions[idx] = {
                            ...finalQuestions[idx],
                            correctAnswer: String(row['Đáp án'] || row['Đáp án đúng'] || row['correctAnswer'] || '').toUpperCase(),
                            transcriptA: String(row['A'] || row['optionA'] || ''),
                            transcriptB: String(row['B'] || row['optionB'] || ''),
                            transcriptC: String(row['C'] || row['optionC'] || ''),
                            transcriptD: String(row['D'] || row['optionD'] || '')
                        };
                    }
                });
                setQuestions(finalQuestions);
            } else {
                setQuestions(initialQuestions);
            }
            setActiveQuestionIndex(0);
            setAudioFile(null);
        }
    }, [open, initialData]);

    const handleUpdateQuestion = (index: number, field: keyof QuestionDraft, value: any) => {
        const newQuestions = [...questions];
        newQuestions[index] = { ...newQuestions[index], [field]: value };
        setQuestions(newQuestions);
    };

    const handleImageUpload = (index: number, file: UploadFile) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            const newQuestions = [...questions];
            newQuestions[index].imageFile = file;
            newQuestions[index].previewImage = e.target?.result as string;
            setQuestions(newQuestions);
        };
        reader.readAsDataURL(file as any);
        return false;
    };

    const handleRemoveImage = (index: number) => {
        const newQuestions = [...questions];
        newQuestions[index].imageFile = null;
        newQuestions[index].previewImage = '';
        setQuestions(newQuestions);
    };

    const handleExcelImport = (file: File) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            const data = e.target?.result;
            const workbook = XLSX.read(data, { type: 'binary' });
            const sheetName = workbook.SheetNames[0];
            const worksheet = workbook.Sheets[sheetName];
            const json = XLSX.utils.sheet_to_json(worksheet);

            const finalQuestions = [...initialQuestions];
            json.forEach((row: any) => {
                const qId = Number(row['Số câu'] || row['questionNumber'] || 0);
                if (qId >= 1 && qId <= 6) {
                    const idx = qId - 1;
                    finalQuestions[idx] = {
                        ...finalQuestions[idx],
                        correctAnswer: String(row['Đáp án'] || row['Đáp án đúng'] || row['correctAnswer'] || '').toUpperCase(),
                        transcriptA: String(row['A'] || row['optionA'] || ''),
                        transcriptB: String(row['B'] || row['optionB'] || ''),
                        transcriptC: String(row['C'] || row['optionC'] || ''),
                        transcriptD: String(row['D'] || row['optionD'] || '')
                    };
                }
            });

            setQuestions(finalQuestions);
            message.success(`Đã nhập ${json.length} câu hỏi từ Excel`);
        };
        reader.readAsBinaryString(file);
    };

    const handleDownloadTemplate = () => {
        const rows = initialQuestions.map(q => ({
            'Số câu': q.id,
            'A': '',
            'B': '',
            'C': '',
            'D': '',
            'Đáp án đúng': ''
        }));
        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Part1');
        XLSX.writeFile(wb, 'Part1_Template.xlsx');
    };

    const handleSubmit = async () => {
        if (!partId) return;


        try {
            setLoading(true);
            message.loading({ content: 'Đang lưu dữ liệu...', key: 'savePart1' });

            let finalAudioUrl = currentAudioUrl;
            if (audioFile) {
                const audioRes = await uploadApi.audio(audioFile as any);
                if (audioRes.success) {
                    finalAudioUrl = audioRes.url;
                    await partApi.update(partId, { audioUrl: finalAudioUrl });
                }
            }

            const validQuestions = questions.filter(q => q.imageFile && q.correctAnswer);
            if (validQuestions.length === 0) {
                message.warning('Không có câu hỏi nào hợp lệ để lưu (cần có ảnh và đáp án)');
                setLoading(false);
                return;
            }

            const createPromises = validQuestions.map(async (q) => {
                const imageRes = await uploadApi.image(q.imageFile as any);
                if (!imageRes.success) throw new Error(`Lỗi upload ảnh câu ${q.id}`);

                const payload = {
                    questionNumber: q.id,
                    imageUrl: imageRes.url,
                    audioUrl: null,
                    correctAnswer: q.correctAnswer,
                    questionText: 'Look at the picture and listen to the four statements.',
                    optionA: q.transcriptA || 'A',
                    optionB: q.transcriptB || 'B',
                    optionC: q.transcriptC || 'C',
                    optionD: q.transcriptD || 'D'
                };

                return api.post(`/parts/${partId}/questions`, payload);
            });

            await Promise.all(createPromises);
            message.success({ content: 'Đã tạo 6 câu hỏi Part 1 thành công!', key: 'savePart1' });
            onSuccess();
            onCancel();
        } catch (error: any) {
            message.error({ content: error.message || 'Lỗi khi lưu dữ liệu', key: 'savePart1' });
        } finally {
            setLoading(false);
        }
    };

    const currentQ = questions[activeQuestionIndex];

    return (
        <Modal
            title={null}
            open={open}
            onCancel={onCancel}
            width={1200}
            footer={null}
            destroyOnClose
            centered
            styles={{ body: { padding: 0, overflow: 'hidden', borderRadius: 20 } }}
        >
            <div style={{ display: 'flex', height: '85vh', background: '#F8FAFC' }} className="page-animate">
                {/* Sidebar */}
                <div style={{ width: 280, background: '#fff', borderRight: '1px solid #E2E8F0', display: 'flex', flexDirection: 'column' }}>
                    <div style={{ padding: '24px 20px', borderBottom: '1px solid #F1F5F9' }}>
                        <Title level={4} style={{ margin: 0, color: '#1E293B', display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div style={{ width: 32, height: 32, background: 'linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 16 }}>
                                <PictureOutlined />
                            </div>
                            Nhập câu hỏi Part 1
                        </Title>
                        <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                            6 Questions Photographs
                        </Text>
                    </div>

                    <div style={{ flex: 1, overflowY: 'auto', padding: '12px 16px' }}>
                        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
                            <Button
                                icon={<DownloadOutlined />}
                                onClick={handleDownloadTemplate}
                                style={{ flex: 1, borderRadius: 8, fontSize: 12 }}
                            >
                                Mẫu
                            </Button>
                            <Button
                                type="primary"
                                icon={<FileExcelOutlined />}
                                onClick={() => {
                                    const input = document.createElement('input');
                                    input.type = 'file';
                                    input.accept = '.xlsx,.xls';
                                    input.onchange = (e) => {
                                        const file = (e.target as HTMLInputElement).files?.[0];
                                        if (file) handleExcelImport(file);
                                    };
                                    input.click();
                                }}
                                style={{ flex: 2, borderRadius: 8, background: '#16A34A', border: 'none', fontSize: 12 }}
                            >
                                Nhập Excel
                            </Button>
                        </div>
                        {questions.map((q, idx) => {
                            const isDone = q.imageFile && q.correctAnswer;
                            const isActive = activeQuestionIndex === idx;

                            return (
                                <div
                                    key={q.id}
                                    onClick={() => setActiveQuestionIndex(idx)}
                                    style={{
                                        padding: '12px 16px',
                                        borderRadius: 12,
                                        marginBottom: 8,
                                        cursor: 'pointer',
                                        transition: 'all 0.2s',
                                        background: isActive ? '#EFF6FF' : 'transparent',
                                        border: isActive ? '1px solid #BFDBFE' : '1px solid transparent',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'space-between'
                                    }}
                                >
                                    <Space size={12}>
                                        <Badge count={q.id} color={isActive ? '#2563EB' : '#94A3B8'} style={{ boxShadow: 'none' }} />
                                        <span style={{ fontWeight: isActive ? 600 : 500, color: isActive ? '#1E40AF' : '#64748B' }}>
                                            Câu hỏi {q.id}
                                        </span>
                                    </Space>
                                    {isDone && <CheckCircleFilled style={{ color: '#10B981' }} />}
                                </div>
                            );
                        })}
                    </div>

                    <div style={{ padding: 20, borderTop: '1px solid #E0F2FE' }}>
                        <Button
                            type="primary"
                            block
                            size="large"
                            loading={loading}
                            onClick={handleSubmit}
                            style={{ borderRadius: 12, height: 48, fontWeight: 700, background: 'linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%)', border: 'none', boxShadow: '0 4px 12px rgba(37, 99, 235, 0.2)' }}
                        >
                            Lưu tất cả
                        </Button>
                        <Button block type="text" onClick={onCancel} style={{ marginTop: 8, color: '#3B82F6' }}>Hủy bỏ</Button>
                    </div>
                </div>

                {/* Content */}
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
                    <div style={{ padding: '16px 24px', background: '#fff', borderBottom: '1px solid #E2E8F0' }}>
                        <AudioBanner
                            currentAudioUrl={currentAudioUrl}
                            newAudioFile={audioFile}
                            onAudioFileChange={setAudioFile}
                            onDeleteCurrentAudio={async () => {
                                if (partId) {
                                    await partApi.update(partId, { audioUrl: null });
                                    message.success('Đã xóa audio hiện tại');
                                    onSuccess();
                                }
                            }}
                        />
                    </div>

                    <div style={{ flex: 1, overflowY: 'auto', padding: 32 }}>
                        <Row gutter={32}>
                            <Col span={12}>
                                <Card
                                    title={<span style={{ fontWeight: 700 }}>Hình ảnh minh họa</span>}
                                    style={{ borderRadius: 16, boxShadow: '0 10px 30px -5px rgba(37, 99, 235, 0.1)' }}
                                >
                                    <div style={{
                                        height: 350,
                                        border: '2px dashed #BFDBFE',
                                        borderRadius: 16,
                                        background: '#F0F7FF',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        position: 'relative',
                                        overflow: 'hidden'
                                    }}>
                                        {currentQ.previewImage ? (
                                            <>
                                                <Image src={currentQ.previewImage} style={{ maxWidth: '100%', maxHeight: 350, objectFit: 'contain' }} preview={false} />
                                                <div style={{ position: 'absolute', top: 12, right: 12, display: 'flex', gap: 8 }}>
                                                    <Upload
                                                        beforeUpload={(file) => handleImageUpload(activeQuestionIndex, file)}
                                                        showUploadList={false}
                                                        accept="image/*"
                                                    >
                                                        <Button icon={<UploadOutlined />} size="small" style={{ borderRadius: 8, background: 'rgba(255,255,255,0.9)' }}>Thay đổi</Button>
                                                    </Upload>
                                                    <Button
                                                        icon={<DeleteOutlined />}
                                                        size="small"
                                                        danger
                                                        style={{ borderRadius: 8, background: 'rgba(255,255,255,0.9)' }}
                                                        onClick={() => handleRemoveImage(activeQuestionIndex)}
                                                    />
                                                </div>
                                            </>
                                        ) : (
                                            <Upload.Dragger
                                                beforeUpload={(file) => handleImageUpload(activeQuestionIndex, file)}
                                                showUploadList={false}
                                                accept="image/*"
                                                style={{ width: '100%', height: '100%', background: 'transparent', border: 'none' }}
                                            >
                                                <div style={{ padding: 40 }}>
                                                    <PictureOutlined style={{ fontSize: 48, color: '#94A3B8', marginBottom: 16 }} />
                                                    <p style={{ fontSize: 16, fontWeight: 600, color: '#64748B', margin: 0 }}>Tải ảnh lên cho Câu {currentQ.id}</p>
                                                    <p style={{ fontSize: 13, color: '#94A3B8', marginTop: 4 }}>Kéo thả hoặc click để chọn ảnh</p>
                                                </div>
                                            </Upload.Dragger>
                                        )}
                                    </div>
                                </Card>
                            </Col>

                            <Col span={12}>
                                <Card
                                    title={<span style={{ fontWeight: 700, color: '#1E3A8A' }}>Đáp án & Transcript</span>}
                                    style={{ borderRadius: 16, boxShadow: '0 10px 30px -5px rgba(37, 99, 235, 0.15)' }}
                                >
                                    <Space direction="vertical" size={20} style={{ width: '100%' }}>
                                        <div>
                                            <Text strong style={{ display: 'block', marginBottom: 8, color: '#1E3A8A' }}>Đáp án đúng</Text>
                                            <Select
                                                value={currentQ.correctAnswer}
                                                onChange={(val) => handleUpdateQuestion(activeQuestionIndex, 'correctAnswer', val)}
                                                placeholder="Chọn đáp án đúng (A-D)"
                                                style={{ width: '100%' }}
                                                size="large"
                                            >
                                                {['A', 'B', 'C', 'D'].map(opt => <Option key={opt} value={opt}>Đáp án {opt}</Option>)}
                                            </Select>
                                        </div>

                                        <div>
                                            <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Transcripts (Tùy chọn)</Text>
                                            <Row gutter={[12, 12]}>
                                                <Col span={12}><Input addonBefore="A" value={currentQ.transcriptA} onChange={(e) => handleUpdateQuestion(activeQuestionIndex, 'transcriptA', e.target.value)} placeholder="A statement" /></Col>
                                                <Col span={12}><Input addonBefore="B" value={currentQ.transcriptB} onChange={(e) => handleUpdateQuestion(activeQuestionIndex, 'transcriptB', e.target.value)} placeholder="B statement" /></Col>
                                                <Col span={12}><Input addonBefore="C" value={currentQ.transcriptC} onChange={(e) => handleUpdateQuestion(activeQuestionIndex, 'transcriptC', e.target.value)} placeholder="C statement" /></Col>
                                                <Col span={12}><Input addonBefore="D" value={currentQ.transcriptD} onChange={(e) => handleUpdateQuestion(activeQuestionIndex, 'transcriptD', e.target.value)} placeholder="D statement" /></Col>
                                            </Row>
                                        </div>

                                    </Space>
                                </Card>
                            </Col>
                        </Row>
                    </div>
                </div>
            </div>
        </Modal>
    );
}
