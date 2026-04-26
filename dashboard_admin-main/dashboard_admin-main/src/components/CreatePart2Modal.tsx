import { useState, useEffect } from 'react';
import {
    Modal,
    Form,
    Input,
    Select,
    message,
    Button,
    InputNumber,
    Alert,
    Row,
    Col,
    Typography
} from 'antd';
import { 
    CheckCircleOutlined,
    QuestionCircleOutlined,
    FileTextOutlined
} from '@ant-design/icons';
import api, { uploadApi } from '../services/api';
import AudioBanner from './AudioBanner';

const { Option } = Select;
const { Text } = Typography;

interface CreatePart2ModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    currentAudioUrl?: string; // New prop
    partName?: string;
    partNumber?: number;
}

export default function CreatePart2Modal({ open, onCancel, onSuccess, partId, currentAudioUrl, partName, partNumber }: CreatePart2ModalProps) {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [audioFile, setAudioFile] = useState<File | null>(null); // ✅ New
    const [nextQuestionNumber, setNextQuestionNumber] = useState<number>(1);

    useEffect(() => {
        if (open && partId) {
            fetchNextQuestionNumber();
        } else {
            form.resetFields();
            setAudioFile(null);
        }
    }, [open, partId]);

    const fetchNextQuestionNumber = async () => {
        if (!partId) return;
        try {
            const response = await api.get(`/parts/${partId}/questions`);
            if (response.data.success) {
                const questions = response.data.questions;
                if (questions.length > 0) {
                    const maxNum = Math.max(...questions.map((q: any) => q.questionNumber));
                    setNextQuestionNumber(maxNum + 1);
                    form.setFieldsValue({ questionNumber: maxNum + 1 });
                } else {
                    setNextQuestionNumber(1);
                    form.setFieldsValue({ questionNumber: 1 });
                }
            }
        } catch (error) {
            console.error('Error fetching questions:', error);
        }
    };


    const handleSubmit = async (values: any) => {
        if (!partId) return;

        try {
            setLoading(true);

            let audioUrl = currentAudioUrl; 

            if (audioFile) {
                const audioRes = await uploadApi.audio(audioFile);
                if (!audioRes.success) {
                    throw new Error(audioRes.message || 'Upload âm thanh thất bại');
                }
                audioUrl = audioRes.url;
            }

            const payload = {
                questionNumber: values.questionNumber,
                audioUrl: audioUrl,
                correctAnswer: values.correctAnswer,
                questionText: values.questionText,
                optionA: values.optionA,
                optionB: values.optionB,
                optionC: values.optionC,
                optionD: null, // Part 2 only has 3 options
                explanation: values.explanation,
            };

            const response = await api.post(`/parts/${partId}/questions`, payload);

            if (response.data.success) {
                message.success('Tạo câu hỏi thành công!');
                form.resetFields();
                setAudioFile(null);
                onSuccess();
                onCancel();
            } else {
                message.error(response.data.message);
            }

        } catch (error: any) {
            console.error('Error creating question:', error);
            message.error(error.message || 'Có lỗi xảy ra');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{
                        width: 36,
                        height: 36,
                        borderRadius: 10,
                        background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        boxShadow: '0 4px 10px rgba(37, 99, 235, 0.2)'
                    }}>
                        <QuestionCircleOutlined style={{ color: '#fff', fontSize: 18 }} />
                    </div>
                    <div>
                        <span style={{
                            fontSize: 18,
                            fontWeight: 800,
                            background: 'linear-gradient(to right, #1E3A8A, #3B82F6)',
                            WebkitBackgroundClip: 'text',
                            WebkitTextFillColor: 'transparent',
                            letterSpacing: '0.5px',
                            display: 'block'
                        }}>
                            {partName
                                ? (partName.toUpperCase().startsWith('PART') ? partName : `PART ${partNumber}: ${partName}`)
                                : 'TẠO CÂU HỎI PART 2'}
                        </span>
                        <Text type="secondary" style={{ fontSize: 11, fontWeight: 500, marginTop: -4, display: 'block', color: '#3B82F6' }}>
                            Thêm câu hỏi Question-Response (3 lựa chọn)
                        </Text>
                    </div>
                </div>
            }
            open={open}
            onCancel={onCancel}
            footer={null}
            width={700}
            centered
            maskClosable={false}
            styles={{ body: { padding: '24px 32px' } }}
        >
            <Form
                form={form}
                layout="vertical"
                onFinish={handleSubmit}
                initialValues={{ 
                    questionNumber: nextQuestionNumber,
                    questionText: 'Listen to the question and mark your answer.',
                    optionA: '(A)',
                    optionB: '(B)',
                    optionC: '(C)'
                }}
                requiredMark={false}
            >
                <div style={{ marginBottom: 24 }}>
                    <AudioBanner 
                        currentAudioUrl={currentAudioUrl} 
                        newAudioFile={audioFile}
                        onAudioFileChange={setAudioFile}
                        multiple={false}
                    />
                </div>

                <Alert
                    message={<Text strong style={{ color: '#1E40AF' }}>Part 2: Question-Response Strategy</Text>}
                    description={
                        <span style={{ fontSize: 13, color: '#475569' }}>
                            Nhập Tapescript tiếng Anh cho cả câu hỏi và 3 đáp án. Part này rèn luyện phản xạ nghe gốc, không sử dụng AI dịch tự động.
                        </span>
                    }
                    type="info"
                    showIcon
                    style={{ marginBottom: 24, borderRadius: 12, border: '1px solid #BFDBFE' }}
                />

                <Row gutter={24}>
                    <Col span={12}>
                        <Form.Item
                            label={<span style={{ fontWeight: 600, color: '#475569' }}>Số thứ tự câu hỏi</span>}
                            name="questionNumber"
                            rules={[{ required: true, message: 'Vui lòng nhập số câu hỏi' }]}
                        >
                            <InputNumber min={1} max={200} style={{ width: '100%', borderRadius: 8 }} size="large" />
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item
                            label={<span style={{ fontWeight: 600, color: '#475569' }}>Đáp án đúng</span>}
                            name="correctAnswer"
                            rules={[{ required: true, message: 'Chọn đáp án đúng' }]}
                        >
                            <Select placeholder="Chọn đáp án" size="large" style={{ borderRadius: 8 }}>
                                <Option value="A">Đáp án A</Option>
                                <Option value="B">Đáp án B</Option>
                                <Option value="C">Đáp án C</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                {/* Xóa bỏ phần upload cũ ở đây vì đã có AudioBanner */}

                <div style={{ 
                    marginTop: 24, padding: '20px', background: '#FFF', 
                    borderRadius: 16, border: '1px solid #BFDBFE', boxShadow: '0 4px 12px rgba(37, 99, 235, 0.02)' 
                }}>
                    <div style={{ fontWeight: 700, color: '#1E3A8A', marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                        <FileTextOutlined style={{ color: '#2563EB' }} /> Nội dung Tapescript
                    </div>
                    
                    <Form.Item
                        label={<span style={{ fontWeight: 600, color: '#475569' }}>Câu hỏi (Transcript)</span>}
                        name="questionText"
                        rules={[{ required: true, message: 'Vui lòng nhập Tapescript câu hỏi' }]}
                    >
                        <Input.TextArea rows={2} placeholder="Ví dụ: Where is the marketing convention being held?" style={{ borderRadius: 8 }} />
                    </Form.Item>

                    <Row gutter={12}>
                        <Col span={8}>
                            <Form.Item label={<span style={{ fontWeight: 600, fontSize: 12 }}>A</span>} name="optionA" rules={[{ required: true }]}>
                                <Input placeholder="A..." style={{ borderRadius: 6 }} />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item label={<span style={{ fontWeight: 600, fontSize: 12 }}>B</span>} name="optionB" rules={[{ required: true }]}>
                                <Input placeholder="B..." style={{ borderRadius: 6 }} />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item label={<span style={{ fontWeight: 600, fontSize: 12 }}>C</span>} name="optionC" rules={[{ required: true }]}>
                                <Input placeholder="C..." style={{ borderRadius: 6 }} />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Form.Item
                        label={<span style={{ fontWeight: 600, color: '#475569' }}>Giải thích / Mẹo làm bài (Tùy chọn)</span>}
                        name="explanation"
                        style={{ marginTop: 8 }}
                    >
                        <Input.TextArea rows={3} placeholder="Ghi chú thêm cho học viên..." style={{ borderRadius: 8 }} />
                    </Form.Item>
                </div>

                <div style={{ 
                    textAlign: 'right', marginTop: 32, paddingTop: 20, 
                    borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'flex-end', gap: 12 
                }}>
                    <Button onClick={onCancel} size="large" style={{ borderRadius: 10, fontWeight: 600, minWidth: 100 }}>
                        Hủy bỏ
                    </Button>
                    <Button 
                        type="primary" htmlType="submit" loading={loading} size="large" icon={<CheckCircleOutlined />}
                        style={{ 
                            borderRadius: 10, fontWeight: 700, minWidth: 160,
                            background: 'linear-gradient(135deg, #2563EB 0%, #1E3A8A 100%)',
                            border: 'none', boxShadow: '0 4px 14px rgba(37, 99, 235, 0.25)'
                        }}
                    >
                        LƯU CÂU HỎI
                    </Button>
                </div>
            </Form>
        </Modal>
    );
}
