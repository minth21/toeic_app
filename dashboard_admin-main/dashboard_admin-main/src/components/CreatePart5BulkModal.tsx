import { useState, useEffect } from 'react';
import { Modal, Button, Row, Col, Input, Typography, Space, Divider, message, Select, Alert, Tag, Tabs, Layout, Progress, Upload } from 'antd';
import {
    CheckCircleOutlined,
    FileTextOutlined,
    GlobalOutlined,
    BookOutlined,
    FileExcelOutlined,
    ExperimentOutlined,
    CloudUploadOutlined,
    InfoCircleOutlined,
    PlusOutlined,
    DeleteOutlined
} from '@ant-design/icons';
import ReactQuill from 'react-quill-new';
import 'quill/dist/quill.snow.css';
import * as XLSX from 'xlsx';
import { questionApi } from '../services/api';
import { useAIImport } from '../hooks/useAIImport';
import { QUILL_MODULES, QUILL_FORMATS } from '../utils/editorUtils';

const { Text } = Typography;
const { Option } = Select;
const { Sider, Content } = Layout;

interface Question {
    questionNumber: number;
    questionText: string;
    optionA: string;
    optionB: string;
    optionC: string;
    optionD: string;
    explanation?: string;
    questionTranslation?: string;
    optionTranslations?: any;
    keyVocabulary?: any;
    level?: string;
    correctAnswer: string;
}

interface CreatePart5BulkModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    initialData: any[];
    partId: string | null;
    importMode: 'new' | 'append' | 'replace';
    partNumber?: number;
}

export default function CreatePart5BulkModal({
    open,
    onCancel,
    onSuccess,
    initialData,
    partId,
    importMode
}: CreatePart5BulkModalProps) {
    const [questions, setQuestions] = useState<Question[]>([]);
    const [loading, setLoading] = useState(false);
    const [activeQuestionIndex, setActiveQuestionIndex] = useState(0);

    const {
        loading: aiLoading,
        isAiProcessing,
        aiProgress,
        batchLabel,
        handleEnrichPart5All
    } = useAIImport(questions, setQuestions, 5);

    useEffect(() => {
        if (open) {
            const finalQuestions: Question[] = Array.from({ length: 30 }, (_, i) => ({
                questionNumber: 101 + i,
                questionText: '',
                optionA: '',
                optionB: '',
                optionC: '',
                optionD: '',
                correctAnswer: 'A',
                explanation: '',
                questionTranslation: '',
                level: 'B1'
            }));

            if (initialData && initialData.length > 0) {
                initialData.forEach((row: any) => {
                    const qNum = Number(row['Số câu'] || row['questionNumber'] || 0);
                    if (qNum >= 101 && qNum <= 130) {
                        const idx = qNum - 101;
                        finalQuestions[idx] = {
                            ...finalQuestions[idx],
                            questionText: String(row['Nội dung câu hỏi'] || row['questionText'] || finalQuestions[idx].questionText),
                            optionA: String(row['A'] || row['optionA'] || finalQuestions[idx].optionA),
                            optionB: String(row['B'] || row['optionB'] || finalQuestions[idx].optionB),
                            optionC: String(row['C'] || row['optionC'] || finalQuestions[idx].optionC),
                            optionD: String(row['D'] || row['optionD'] || finalQuestions[idx].optionD),
                            correctAnswer: String(row['Đáp án'] || row['Đáp án đúng'] || row['correctAnswer'] || finalQuestions[idx].correctAnswer).toUpperCase(),
                            explanation: String(row['Giải thích'] || row['explanation'] || finalQuestions[idx].explanation),
                        };
                    }
                });
            }
            setQuestions(finalQuestions);
            setActiveQuestionIndex(0);
        }
    }, [open, initialData]);

    const handleQuestionChange = (index: number, field: keyof Question, val: any) => {
        const newQuestions = [...questions];
        (newQuestions[index] as any)[field] = val;
        setQuestions(newQuestions);
    };

    const handleDownloadTemplate = () => {
        const rows = [];
        for (let i = 101; i <= 130; i++) {
            rows.push({
                'Số câu': i,
                'Nội dung câu hỏi': '',
                'A': '',
                'B': '',
                'C': '',
                'D': '',
                'Đáp án đúng': '',
                'Giải thích': ''
            });
        }
        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Part5');
        XLSX.writeFile(wb, 'Part5.xlsx');
    };

    const handleExcelImport = (file: File) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const data = new Uint8Array(e.target?.result as ArrayBuffer);
                const workbook = XLSX.read(data, { type: 'array' });
                const sheet = workbook.Sheets[workbook.SheetNames[0]];
                const rows: any[] = XLSX.utils.sheet_to_json(sheet);

                if (rows.length === 0) {
                    message.error('File Excel trống!');
                    return;
                }

                const finalQuestions: Question[] = Array.from({ length: 30 }, (_, i) => ({
                    questionNumber: 101 + i,
                    questionText: '',
                    optionA: '',
                    optionB: '',
                    optionC: '',
                    optionD: '',
                    correctAnswer: 'A',
                    explanation: '',
                    questionTranslation: '',
                    level: 'B1'
                }));

                rows.forEach((row: any) => {
                    const qNum = Number(row['Số câu'] || row['questionNumber'] || 0);
                    if (qNum >= 101 && qNum <= 130) {
                        const idx = qNum - 101;
                        finalQuestions[idx] = {
                            ...finalQuestions[idx],
                            questionText: String(row['Nội dung câu hỏi'] || row['questionText'] || ''),
                            optionA: String(row['A'] || row['optionA'] || ''),
                            optionB: String(row['B'] || row['optionB'] || ''),
                            optionC: String(row['C'] || row['optionC'] || ''),
                            optionD: String(row['D'] || row['optionD'] || ''),
                            correctAnswer: String(row['Đáp án'] || row['Đáp án đúng'] || row['correctAnswer'] || 'A').toUpperCase(),
                            explanation: String(row['Giải thích'] || row['explanation'] || ''),
                        };
                    }
                });

                setQuestions(finalQuestions);
                setActiveQuestionIndex(0);
                message.success(`Nạp thành công ${rows.length} câu hỏi`);
            } catch (err: any) {
                message.error('Lỗi file Excel: ' + err.message);
            }
        };
        reader.readAsArrayBuffer(file);
        return false;
    };

    const handleCancel = () => {
        setQuestions([]);
        setActiveQuestionIndex(0);
        onCancel();
    };

    const handleSave = async () => {
        if (!partId) return;

        // Check range (101-130)
        const outOfRange = questions.filter((q: any) => q.questionNumber < 101 || q.questionNumber > 130);
        if (outOfRange.length > 0) {
            message.error('Câu hỏi Part 5 phải nằm trong khoảng từ 101 đến 130');
            return;
        }

        setLoading(true);
        try {
            const payload = {
                questions: questions.filter(q => q.questionText.trim() !== '').map(q => ({
                    ...q,
                    explanation: q.explanation || '',
                    questionTranslation: q.questionTranslation || '',
                    optionTranslations: typeof q.optionTranslations === 'string' ? q.optionTranslations : JSON.stringify(q.optionTranslations || {}),
                    keyVocabulary: typeof q.keyVocabulary === 'string' 
                        ? q.keyVocabulary 
                        : JSON.stringify((q.keyVocabulary || []).map((v: any) => ({
                            ...v,
                            ipa: (v.ipa || '').replace(/^\/+|\/+$/g, '').trim()
                        }))),
                })),
                mode: importMode
            };

            const response = await (questionApi as any).createBatch(partId, payload);

            if (response.success) {
                message.success(`Lưu thành công ${questions.length} câu hỏi`);
                onSuccess();
                onCancel();
            } else {
                throw new Error(response.message || 'Lưu thất bại');
            }
        } catch (error: any) {
            console.error('Save error:', error);
            message.error(error.message || 'Lỗi khi lưu câu hỏi');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }} className="page-animate">
                    <div style={{
                        width: 36, height: 36, borderRadius: 10,
                        background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        boxShadow: '0 4px 10px rgba(37, 99, 235, 0.2)'
                    }}>
                        <CloudUploadOutlined style={{ color: '#fff', fontSize: 18 }} />
                    </div>
                    <div>
                        <span style={{
                            fontSize: 18, fontWeight: 800,
                            background: 'linear-gradient(to right, #1E3A8A, #3B82F6)',
                            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
                            letterSpacing: '0.5px', display: 'block'
                        }}>
                            XEM TRƯỚC PART 5
                        </span>
                        <Text type="secondary" style={{ fontSize: 11, fontWeight: 500, marginTop: -4, display: 'block' }}>
                            {questions.length} câu hỏi đang chờ kiểm duyệt
                        </Text>
                    </div>
                </div>
            }
            open={open} onCancel={handleCancel} footer={null} width={1400} centered maskClosable={false}
            styles={{ body: { padding: '24px 32px' } }}
        >
            <div style={{ maxHeight: '85vh', overflowY: 'auto', paddingRight: 8 }} className="page-animate">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24, padding: '16px 24px', background: '#F0F7FF', borderRadius: 16, border: '1px solid #BFDBFE' }}>
                    <Space size="middle">
                        <Alert icon={<InfoCircleOutlined />} message="Mẹo: Dùng AI Magic để tự động tạo lời giải và từ vựng nhanh chóng." type="info" style={{ background: 'transparent', border: 'none', padding: 0 }} />
                    </Space>
                    <Space>
                        <Upload beforeUpload={handleExcelImport} showUploadList={false}>
                            <Button icon={<CloudUploadOutlined />} style={{ borderRadius: 8 }}>Nhập Excel</Button>
                        </Upload>
                        <Button icon={<FileExcelOutlined />} onClick={handleDownloadTemplate} style={{ borderRadius: 8 }}>Mẫu Excel</Button>
                        <Button type="primary" icon={<ExperimentOutlined />} loading={aiLoading} onClick={handleEnrichPart5All} style={{ background: 'linear-gradient(135deg, #7C3AED 0%, #5B21B6 100%)', border: 'none', borderRadius: 8, fontWeight: 700 }}>AI Magic</Button>
                    </Space>
                </div>

                {isAiProcessing && (
                    <div style={{ marginBottom: 24, padding: 20, background: '#F0F9FF', borderRadius: 16, border: '1px solid #BAE6FD' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                            <Text strong style={{ color: '#0369A1' }}><ExperimentOutlined spin /> {batchLabel}</Text>
                            <Text strong>{aiProgress}%</Text>
                        </div>
                        <Progress percent={aiProgress} status="active" strokeColor="#0EA5E9" />
                    </div>
                )}

                <Layout style={{ background: 'transparent', gap: 24 }}>
                    <Sider width={220} style={{ background: '#F0F7FF', borderRadius: 20, border: '1px solid #BFDBFE', padding: 16, height: 'fit-content' }}>
                        <Text strong style={{ display: 'block', marginBottom: 16, color: '#64748B', fontSize: 12, textTransform: 'uppercase' }}>Danh sách câu hỏi</Text>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: '60vh', overflowY: 'auto', paddingRight: 4 }}>
                            {questions.map((q, idx) => (
                                <div
                                    key={idx} onClick={() => setActiveQuestionIndex(idx)}
                                    style={{
                                        padding: '10px 14px', borderRadius: 10, cursor: 'pointer',
                                        background: activeQuestionIndex === idx ? '#2563EB' : 'transparent',
                                        color: activeQuestionIndex === idx ? '#fff' : '#1E40AF',
                                        fontWeight: 600, fontSize: 13, transition: 'all 0.2s',
                                        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                                        border: activeQuestionIndex === idx ? 'none' : '1px solid transparent'
                                    }}
                                >
                                    <span>Câu {q.questionNumber}</span>
                                    {q.explanation && <CheckCircleOutlined style={{ color: activeQuestionIndex === idx ? '#fff' : '#10B981', fontSize: 14 }} />}
                                </div>
                            ))}
                        </div>
                    </Sider>

                    <Content>
                        {questions[activeQuestionIndex] && (
                            <div style={{ background: '#FFF', borderRadius: 24, border: '1px solid #BFDBFE', padding: 32, boxShadow: '0 4px 24px rgba(37, 99, 235, 0.02)' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
                                    <Tag color="blue" style={{ padding: '4px 16px', borderRadius: 8, fontSize: 16, fontWeight: 800 }}>CÂU HỎI {questions[activeQuestionIndex].questionNumber}</Tag>
                                    <Space>
                                        <Text strong>Độ khó:</Text>
                                        <Select value={questions[activeQuestionIndex].level} onChange={(v) => handleQuestionChange(activeQuestionIndex, 'level', v)} style={{ width: 100 }}>
                                            <Option value="B1">Cơ bản</Option>
                                            <Option value="B2">Trung bình</Option>
                                            <Option value="C1">Nâng cao</Option>
                                        </Select>
                                        <Divider type="vertical" />
                                        <Text strong>Đáp án đúng:</Text>
                                        <Select value={questions[activeQuestionIndex].correctAnswer} onChange={(v) => handleQuestionChange(activeQuestionIndex, 'correctAnswer', v)} style={{ width: 80 }}>
                                            {['A', 'B', 'C', 'D'].map(o => <Option key={o} value={o}>{o}</Option>)}
                                        </Select>
                                    </Space>
                                </div>

                                <Row gutter={32}>
                                    <Col span={24}>
                                        <div style={{ marginBottom: 24 }}>
                                            <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 14, color: '#1E3A8A' }}><FileTextOutlined /> NỘI DUNG CÂU HỎI:</Text>
                                            <Input.TextArea
                                                value={questions[activeQuestionIndex].questionText}
                                                onChange={(e) => handleQuestionChange(activeQuestionIndex, 'questionText', e.target.value)}
                                                autoSize={{ minRows: 2 }}
                                                style={{ borderRadius: 12, fontSize: 15, fontWeight: 600, padding: 12, background: '#F0F7FF' }}
                                            />
                                        </div>

                                        <div style={{ marginBottom: 24 }}>
                                            <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 14, color: '#1E3A8A' }}><GlobalOutlined /> DỊCH NGHĨA:</Text>
                                            <Input.TextArea
                                                value={questions[activeQuestionIndex].questionTranslation}
                                                onChange={(e) => handleQuestionChange(activeQuestionIndex, 'questionTranslation', e.target.value)}
                                                placeholder="Bản dịch tiếng Việt..."
                                                autoSize={{ minRows: 2 }}
                                                style={{ borderRadius: 12, fontSize: 14, padding: 12, border: '1px solid #BFDBFE' }}
                                            />
                                        </div>

                                        <Row gutter={16} style={{ marginBottom: 32 }}>
                                            {['A', 'B', 'C', 'D'].map(opt => (
                                                <Col span={6} key={opt}>
                                                    <div style={{ padding: 12, background: '#F0F7FF', borderRadius: 12, border: '1px solid #BFDBFE' }}>
                                                        <Text strong style={{ color: '#64748B', display: 'block', marginBottom: 4, fontSize: 11 }}>LỰA CHỌN {opt}</Text>
                                                        <Input
                                                            value={(questions[activeQuestionIndex] as any)[`option${opt}`]}
                                                            onChange={(e) => handleQuestionChange(activeQuestionIndex, `option${opt}` as any, e.target.value)}
                                                            style={{ fontWeight: 600, borderRadius: 6 }}
                                                        />
                                                    </div>
                                                </Col>
                                            ))}
                                        </Row>

                                        <Tabs defaultActiveKey="explanation" type="card" className="premium-tabs">
                                            <Tabs.TabPane tab={<span><InfoCircleOutlined /> Lời giải chi tiết</span>} key="explanation">
                                                <div style={{ padding: 4 }}>
                                                    <ReactQuill
                                                        theme="snow"
                                                        value={questions[activeQuestionIndex].explanation || ''}
                                                        onChange={(val) => handleQuestionChange(activeQuestionIndex, 'explanation', val)}
                                                        modules={QUILL_MODULES} formats={QUILL_FORMATS}
                                                        style={{ height: 250, background: '#fff', borderRadius: 12 }}
                                                    />
                                                </div>
                                            </Tabs.TabPane>
                                            <Tabs.TabPane tab={<span><BookOutlined /> Từ vựng trọng tâm</span>} key="vocab">
                                                <div style={{ minHeight: 200, padding: 20, background: '#F0F7FF', borderRadius: 12 }}>
                                                    <div style={{ marginBottom: 16 }}>
                                                        <Alert 
                                                            message="Dữ liệu từ vựng sẽ được tự động xử lý để hỗ trợ tính năng Touch-to-Translate trên Mobile." 
                                                            type="info" showIcon style={{ borderRadius: 8 }} 
                                                        />
                                                    </div>
                                                    
                                                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                                                        {(() => {
                                                            const vocab = questions[activeQuestionIndex]?.keyVocabulary;
                                                            const vocabList = typeof vocab === 'string' ? (vocab ? JSON.parse(vocab) : []) : (vocab || []);
                                                            
                                                            if (!Array.isArray(vocabList) || vocabList.length === 0) {
                                                                return (
                                                                    <div style={{ width: '100%', textAlign: 'center', padding: '40px 0', background: '#fff', borderRadius: 12, border: '1px dashed #CBD5E1' }}>
                                                                        <BookOutlined style={{ fontSize: 24, color: '#94A3B8', marginBottom: 8 }} />
                                                                        <p style={{ color: '#94A3B8', margin: 0 }}>Chưa có từ vựng nào. Hãy sử dụng AI MAGIC hoặc thêm thủ công.</p>
                                                                    </div>
                                                                );
                                                            }

                                                            return vocabList.map((v: any, vIdx: number) => (
                                                                <div key={vIdx} style={{ 
                                                                    background: '#fff', padding: '10px 16px', borderRadius: 12, 
                                                                    border: '1px solid #BFDBFE', boxShadow: '0 2px 4px rgba(37, 99, 235, 0.02)',
                                                                    display: 'flex', alignItems: 'center', gap: 10
                                                                }}>
                                                                    <div>
                                                                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                                                            <Text strong style={{ color: '#1E293B', fontSize: 15 }}>{v.word || v.text}</Text>
                                                                            <Tag color="blue" style={{ margin: 0, fontSize: 10, lineHeight: '16px' }}>{v.type || v.pos || 'n'}</Tag>
                                                                        </div>
                                                                        <div style={{ fontSize: 12, color: '#64748B' }}>
                                                                            <span style={{ color: '#3B82F6', marginRight: 6 }}>{v.ipa}</span>
                                                                            <span>{v.meaning}</span>
                                                                        </div>
                                                                    </div>
                                                                    <Button 
                                                                        type="text" size="small" icon={<DeleteOutlined style={{ fontSize: 12 }} />} danger 
                                                                        onClick={() => {
                                                                            const newList = [...vocabList];
                                                                            newList.splice(vIdx, 1);
                                                                            handleQuestionChange(activeQuestionIndex, 'keyVocabulary', JSON.stringify(newList));
                                                                        }}
                                                                    />
                                                                </div>
                                                            ));
                                                        })()}
                                                        
                                                        <Button 
                                                            type="dashed" icon={<PlusOutlined />} 
                                                            style={{ height: 'auto', padding: '10px 20px', borderRadius: 12 }}
                                                            onClick={() => {
                                                                const vocab = questions[activeQuestionIndex]?.keyVocabulary;
                                                                const vocabList = typeof vocab === 'string' ? (vocab ? JSON.parse(vocab) : []) : (vocab || []);
                                                                const newItem = { word: 'New Word', type: 'n', ipa: '/.../', meaning: 'Nghĩa của từ' };
                                                                handleQuestionChange(activeQuestionIndex, 'keyVocabulary', JSON.stringify([...vocabList, newItem]));
                                                            }}
                                                        >
                                                            Thêm từ
                                                        </Button>
                                                    </div>
                                                </div>
                                            </Tabs.TabPane>
                                        </Tabs>
                                    </Col>
                                </Row>
                            </div>
                        )}
                    </Content>
                </Layout>

                <div style={{ marginTop: 40, paddingTop: 24, borderTop: '1px solid #E2E8F0', display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
                    <Button onClick={handleCancel} size="large" style={{ borderRadius: 12, width: 150, fontWeight: 600 }}>Hủy</Button>
                    <Button
                        type="primary" onClick={handleSave} loading={loading} size="large" icon={<CheckCircleOutlined />}
                        style={{ background: 'linear-gradient(135deg, #2563EB 0%, #1E3A8A 100%)', border: 'none', width: 300, fontWeight: 700, borderRadius: 12, boxShadow: '0 4px 14px rgba(37, 99, 235, 0.3)', height: 50 }}
                    >
                        XÁC NHẬN LƯU
                    </Button>
                </div>
            </div>
        </Modal>
    );
}
