import React, { useState, useEffect } from 'react';
import { Modal, Button, Typography, Space, Input, Row, Col, Card, Select, Badge, message } from 'antd';
import {
    AudioOutlined,
    FileExcelOutlined,
    DownloadOutlined,
    CheckCircleFilled,
    EditOutlined
} from '@ant-design/icons';
import * as XLSX from 'xlsx';
import { partApi } from '../services/api';
import AudioBanner from './AudioBanner';

const { Title, Text } = Typography;
const { TextArea } = Input;
const { Option } = Select;

interface CreatePart2BulkModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    testId: string;
    partId: string;
    currentAudioUrl?: string;
    partNumber?: number;
    initialData?: any[];
}

interface Part2Question {
    questionNumber: number;
    questionText: string;
    optionA: string;
    optionB: string;
    optionC: string;
    correctAnswer: string;
    explanation: string;
}

const CreatePart2BulkModal: React.FC<CreatePart2BulkModalProps> = ({
    open,
    onCancel,
    onSuccess,
    testId,
    partId,
    currentAudioUrl,
    initialData
}) => {
    const [questions, setQuestions] = useState<Part2Question[]>([]);
    const [activeQuestionIndex, setActiveQuestionIndex] = useState(0);
    const [loading, setLoading] = useState(false);
    const [excelImporting, setExcelImporting] = useState(false);
    const [audioFile, setAudioFile] = useState<File | null>(null);

    useEffect(() => {
        if (open) {
            if (initialData && initialData.length > 0) {
                const mappedQuestions = initialData.map((row: any, index: number) => ({
                    questionNumber: row['Số câu'] || row['questionNumber'] || (index + 7),
                    questionText: String(row['Câu hỏi'] || row['questionText'] || ''),
                    optionA: String(row['A'] || row['optionA'] || ''),
                    optionB: String(row['B'] || row['optionB'] || ''),
                    optionC: String(row['C'] || row['optionC'] || ''),
                    correctAnswer: String(row['Đáp án'] || row['Đáp án đúng'] || row['correctAnswer'] || '').toUpperCase(),
                    explanation: String(row['Giải thích'] || row['explanation'] || '')
                }));

                const finalQuestions = Array.from({ length: 25 }, (_, i) => ({
                    questionNumber: i + 7,
                    questionText: '',
                    optionA: '',
                    optionB: '',
                    optionC: '',
                    correctAnswer: '',
                    explanation: ''
                }));

                mappedQuestions.forEach((q, i) => {
                    if (i < 25) finalQuestions[i] = q;
                });
                setQuestions(finalQuestions);
            } else {
                const initialQuestions = Array.from({ length: 25 }, (_, i) => ({
                    questionNumber: i + 7,
                    questionText: '',
                    optionA: '',
                    optionB: '',
                    optionC: '',
                    correctAnswer: '',
                    explanation: ''
                }));
                setQuestions(initialQuestions);
            }
            setActiveQuestionIndex(0);
            setAudioFile(null);
        }
    }, [open, initialData]);

    const handleQuestionChange = (index: number, field: keyof Part2Question, value: string) => {
        const newQuestions = [...questions];
        newQuestions[index] = { ...newQuestions[index], [field]: value };
        setQuestions(newQuestions);
    };

    const handleExcelImport = async (file: File) => {
        setExcelImporting(true);
        try {
            const reader = new FileReader();
            reader.onload = (e) => {
                const data = e.target?.result;
                const workbook = XLSX.read(data, { type: 'binary' });
                const sheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[sheetName];
                const json = XLSX.utils.sheet_to_json(worksheet);

                const mappedQuestions = json.map((row: any, index) => ({
                    questionNumber: row['Số câu'] || row['questionNumber'] || (index + 7),
                    questionText: String(row['Câu hỏi'] || row['questionText'] || ''),
                    optionA: String(row['A'] || row['optionA'] || ''),
                    optionB: String(row['B'] || row['optionB'] || ''),
                    optionC: String(row['C'] || row['optionC'] || ''),
                    correctAnswer: String(row['Đáp án'] || row['correctAnswer'] || '').toUpperCase(),
                    explanation: String(row['Giải thích'] || row['explanation'] || '')
                }));

                // Pad or trim to 25 questions
                const finalQuestions = [...questions];
                mappedQuestions.forEach((q, i) => {
                    if (i < 25) {
                        finalQuestions[i] = q;
                    }
                });

                setQuestions(finalQuestions);
                message.success(`Đã nhập ${mappedQuestions.length} câu hỏi từ Excel`);
            };
            reader.readAsBinaryString(file);
        } catch (error) {
            message.error('Lỗi khi đọc file Excel');
        } finally {
            setExcelImporting(false);
        }
    };

    const handleDownloadTemplate = () => {
        const template = [
            { 'Số câu': 7, 'Câu hỏi': 'Who is the manager?', 'A': 'John Doe', 'B': 'The office', 'C': 'By car', 'Đáp án': 'A', 'Giải thích': 'Manager is John Doe' }
        ];
        const ws = XLSX.utils.json_to_sheet(template);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Part2');
        XLSX.writeFile(wb, 'Part2.xlsx');
    };

    const handleSubmit = async () => {
        const filledQuestions = questions.filter(q => q.questionText.trim() !== '' && q.correctAnswer);

        if (filledQuestions.length === 0) {
            message.warning('Vui lòng nhập ít nhất một câu hỏi');
            return;
        }

        setLoading(true);
        try {
            const formData = new FormData();
            formData.append('testId', testId);
            formData.append('partId', partId);
            formData.append('questions', JSON.stringify(filledQuestions));
            if (audioFile) {
                formData.append('audio', audioFile);
            }

            await partApi.importQuestions(partId, formData);
            message.success('Đã lưu thành công các câu hỏi Part 2');
            onSuccess();
            onCancel();
        } catch (error: any) {
            message.error(error.message || 'Lỗi khi lưu câu hỏi');
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
                <div style={{ width: 300, background: '#fff', borderRight: '1px solid #E2E8F0', display: 'flex', flexDirection: 'column' }}>
                    <div style={{ padding: '24px 20px', borderBottom: '1px solid #F1F5F9' }}>
                        <Title level={4} style={{ margin: 0, color: '#1E293B', display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div style={{ width: 32, height: 32, background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 16 }}>
                                <AudioOutlined />
                            </div>
                            Nhập câu hỏi Part 2
                        </Title>
                        <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                            Questions 7 - 31 (25 total)
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
                                loading={excelImporting}
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
                            const isFilled = q.questionText.trim() !== '' && q.correctAnswer;
                            const isActive = activeQuestionIndex === idx;

                            return (
                                <div
                                    key={q.questionNumber}
                                    onClick={() => setActiveQuestionIndex(idx)}
                                    style={{
                                        padding: '10px 14px',
                                        borderRadius: 10,
                                        marginBottom: 6,
                                        cursor: 'pointer',
                                        transition: 'all 0.2s',
                                        background: isActive ? '#FFFBEB' : 'transparent',
                                        border: isActive ? '1px solid #FDE68A' : '1px solid transparent',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'space-between'
                                    }}
                                >
                                    <Space size={10}>
                                        <Badge count={q.questionNumber} color={isActive ? '#D97706' : '#94A3B8'} style={{ boxShadow: 'none' }} />
                                        <span style={{ fontWeight: isActive ? 600 : 500, color: isActive ? '#92400E' : '#64748B', fontSize: 13 }}>
                                            Câu hỏi {q.questionNumber}
                                        </span>
                                    </Space>
                                    {isFilled && <CheckCircleFilled style={{ color: '#10B981', fontSize: 14 }} />}
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
                            style={{ borderRadius: 12, height: 48, fontWeight: 700, background: 'linear-gradient(135deg, #2563EB 0%, #1E3A8A 100%)', border: 'none', boxShadow: '0 4px 12px rgba(37, 99, 235, 0.2)' }}
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
                        <div style={{ maxWidth: 800, margin: '0 auto' }}>
                            <Card
                                title={
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                                        <div style={{ width: 40, height: 40, borderRadius: 10, background: '#EFF6FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563EB' }}>
                                            <EditOutlined />
                                        </div>
                                        <div>
                                            <div style={{ fontSize: 16, fontWeight: 700, color: '#1E3A8A' }}>Câu {currentQ?.questionNumber}</div>
                                            <div style={{ fontSize: 12, color: '#475569', fontWeight: 400 }}>Nhập transcript và các lựa chọn đáp án</div>
                                        </div>
                                    </div>
                                }
                                style={{ borderRadius: 20, boxShadow: '0 15px 35px -5px rgba(37, 99, 235, 0.15)' }}
                            >
                                <Space direction="vertical" size={24} style={{ width: '100%' }}>
                                    <div>
                                        <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Transcript (Câu hỏi / Câu khẳng định)</Text>
                                        <TextArea
                                            placeholder="Nhập nội dung câu hỏi nghe được..."
                                            rows={3}
                                            value={currentQ?.questionText}
                                            onChange={(e) => handleQuestionChange(activeQuestionIndex, 'questionText', e.target.value)}
                                            style={{ borderRadius: 12, padding: 12, fontSize: 15 }}
                                        />
                                    </div>

                                    <Row gutter={16}>
                                        <Col span={8}>
                                            <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Lựa chọn A</Text>
                                            <Input
                                                prefix={<Text type="secondary">A</Text>}
                                                value={currentQ?.optionA}
                                                onChange={(e) => handleQuestionChange(activeQuestionIndex, 'optionA', e.target.value)}
                                                placeholder="Lựa chọn A"
                                                style={{ borderRadius: 8 }}
                                            />
                                        </Col>
                                        <Col span={8}>
                                            <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Lựa chọn B</Text>
                                            <Input
                                                prefix={<Text type="secondary">B</Text>}
                                                value={currentQ?.optionB}
                                                onChange={(e) => handleQuestionChange(activeQuestionIndex, 'optionB', e.target.value)}
                                                placeholder="Lựa chọn B"
                                                style={{ borderRadius: 8 }}
                                            />
                                        </Col>
                                        <Col span={8}>
                                            <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Lựa chọn C</Text>
                                            <Input
                                                prefix={<Text type="secondary">C</Text>}
                                                value={currentQ?.optionC}
                                                onChange={(e) => handleQuestionChange(activeQuestionIndex, 'optionC', e.target.value)}
                                                placeholder="Lựa chọn C"
                                                style={{ borderRadius: 8 }}
                                            />
                                        </Col>
                                    </Row>

                                    <Row gutter={16} align="middle">
                                        <Col span={12}>
                                            <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Đáp án đúng</Text>
                                            <Select
                                                placeholder="Chọn đáp án"
                                                style={{ width: '100%' }}
                                                size="large"
                                                value={currentQ?.correctAnswer}
                                                onChange={(val) => handleQuestionChange(activeQuestionIndex, 'correctAnswer', val)}
                                            >
                                                <Option value="A">Đáp án A</Option>
                                                <Option value="B">Đáp án B</Option>
                                                <Option value="C">Đáp án C</Option>
                                            </Select>
                                        </Col>
                                        <Col span={12}>
                                            <div style={{ marginTop: 24, padding: '12px 16px', background: '#F8FAFC', borderRadius: 12, border: '1px solid #E2E8F0' }}>
                                                <Text type="secondary" style={{ fontSize: 12 }}>
                                                    * Part 2 chỉ có 3 lựa chọn A, B, C. Đáp án D sẽ được bỏ qua.
                                                </Text>
                                            </div>
                                        </Col>
                                    </Row>
                                    <div>
                                        <Text strong style={{ display: 'block', marginBottom: 8, color: '#475569' }}>Giải thích chi tiết</Text>
                                        <TextArea
                                            placeholder="Nhập lời giải thích hoặc bản dịch cho câu hỏi này..."
                                            rows={4}
                                            value={currentQ?.explanation}
                                            onChange={(e) => handleQuestionChange(activeQuestionIndex, 'explanation', e.target.value)}
                                            style={{ borderRadius: 12, padding: 12 }}
                                        />
                                    </div>

                                </Space>
                            </Card>

                            <div style={{ marginTop: 24, display: 'flex', justifyContent: 'space-between' }}>
                                <Button
                                    disabled={activeQuestionIndex === 0}
                                    onClick={() => setActiveQuestionIndex(activeQuestionIndex - 1)}
                                    size="large"
                                    style={{ borderRadius: 10 }}
                                >
                                    Câu trước
                                </Button>
                                <Button
                                    type="primary"
                                    disabled={activeQuestionIndex === questions.length - 1}
                                    onClick={() => setActiveQuestionIndex(activeQuestionIndex + 1)}
                                    size="large"
                                    style={{ borderRadius: 10, background: 'linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%)', border: 'none', boxShadow: '0 4px 12px rgba(37, 99, 235, 0.2)' }}
                                >
                                    Câu tiếp theo
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </Modal>
    );
};

export default CreatePart2BulkModal;
