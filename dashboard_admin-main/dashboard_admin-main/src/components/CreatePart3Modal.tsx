import { useState, useEffect } from 'react';
import { Modal, Form, Input, Select, message, Button, InputNumber, Card, Space, Tooltip, Row, Col, Divider, Upload, Image, Tag, Typography } from 'antd';
import { FileExcelOutlined, SoundOutlined, PicCenterOutlined, MessageOutlined, DeleteOutlined, CloudUploadOutlined, CheckCircleOutlined } from '@ant-design/icons';
import * as XLSX from 'xlsx';
import ReactQuill from 'react-quill-new';
import 'quill/dist/quill.snow.css';
import api, { uploadApi } from '../services/api';
import AudioBanner from './AudioBanner';
import { QUILL_MODULES, QUILL_FORMATS } from '../utils/editorUtils';

const { Option } = Select;
const { Title, Text } = Typography;

interface CreatePart3ModalProps {
    open: boolean;
    onCancel: () => void;
    onSuccess: () => void;
    partId: string | null;
    partNumber: number; // 3 or 4
    partName?: string;
}

export default function CreatePart3Modal({ open, onCancel, onSuccess, partId, partNumber, partName }: CreatePart3ModalProps) {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [audioFiles, setAudioFiles] = useState<File | File[] | null>(null);
    const [graphicFile, setGraphicFile] = useState<File | null>(null);
    const [graphicPreview, setGraphicPreview] = useState<string | null>(null);
    const [nextQuestionNumber, setNextQuestionNumber] = useState<number>(1);

    const defaultStart = partNumber === 3 ? 32 : 71;

    useEffect(() => {
        if (open && partId) {
            fetchNextQuestionNumber();
        } else {
            form.resetFields();
            setAudioFiles(null);
            setGraphicFile(null);
            setGraphicPreview(null);
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
                } else {
                    setNextQuestionNumber(defaultStart);
                }
            }
        } catch (error) {
            console.error('Error fetching questions:', error);
        }
    };

    useEffect(() => {
        if (open) {
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
    }, [open, nextQuestionNumber]);

    const handleDownloadTemplate = () => {
        const rows = [
            { 'Nhóm': 1, 'Transcript nhóm': '', 'Số câu': defaultStart, 'Nội dung câu hỏi': '', 'A': '', 'B': '', 'C': '', 'D': '', 'Đáp án đúng': '' },
            { 'Nhóm': 1, 'Transcript nhóm': '', 'Số câu': defaultStart + 1, 'Nội dung câu hỏi': '', 'A': '', 'B': '', 'C': '', 'D': '', 'Đáp án đúng': '' },
            { 'Nhóm': 1, 'Transcript nhóm': '', 'Số câu': defaultStart + 2, 'Nội dung câu hỏi': '', 'A': '', 'B': '', 'C': '', 'D': '', 'Đáp án đúng': '' },
        ];
        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, `Part ${partNumber}`);
        XLSX.writeFile(wb, `Part${partNumber}_group_template.xlsx`);
    };

    const handleExcelImport = (file: File) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const data = new Uint8Array(e.target?.result as ArrayBuffer);
                const workbook = XLSX.read(data, { type: 'array' });
                const sheet = workbook.Sheets[workbook.SheetNames[0]];
                const rows: any[] = XLSX.utils.sheet_to_json(sheet);

                if (rows.length === 0) { message.error('File Excel trống!'); return; }

                const groupRows = rows.slice(0, 3);
                let transcript = String(groupRows[0]?.['Transcript nhóm'] || groupRows[0]?.['transcript'] || '');
                if (transcript && !transcript.includes('<p>')) {
                    transcript = `<p>${transcript}</p>`;
                }

                const newQuestions = groupRows.map((row: any, i: number) => ({
                    questionNumber: Number(row['Số câu'] || nextQuestionNumber + i),
                    questionText: String(row['Nội dung câu hỏi'] || row['questionText'] || ''),
                    optionA: String(row['A'] || row['optionA'] || ''),
                    optionB: String(row['B'] || row['optionB'] || ''),
                    optionC: String(row['C'] || row['optionC'] || ''),
                    optionD: String(row['D'] || row['optionD'] || ''),
                    correctAnswer: String(row['Đáp án đúng'] || row['correctAnswer'] || '').toUpperCase() || undefined,
                }));

                form.setFieldsValue({ transcript, questions: newQuestions });
                message.success('Đã nạp dữ liệu từ Excel! Nhớ upload audio trước khi lưu.');
            } catch (err: any) {
                message.error('Lỗi khi đọc file Excel: ' + err.message);
            }
        };
        reader.readAsArrayBuffer(file);
        return false;
    };

    const handleGraphicBeforeUpload = (file: File) => {
        const preview = URL.createObjectURL(file);
        setGraphicPreview(preview);
        setGraphicFile(file);
        return false;
    };

    const handleSubmit = async (values: any) => {
        if (!partId) return;

        if (!audioFiles || (Array.isArray(audioFiles) && audioFiles.length === 0)) {
            message.error('Vui lòng upload ít nhất 1 file âm thanh!');
            return;
        }

        try {
            setLoading(true);

            // 1. Handle Audio (Single or Merge)
            let audioUrl = '';
            if (Array.isArray(audioFiles) && audioFiles.length === 2) {
                // Merge Mode
                message.loading({ content: 'Đang gộp và upload âm thanh...', key: 'upload' });
                const mergeRes = await uploadApi.mergeAudio(audioFiles);
                if (!mergeRes.success) throw new Error(mergeRes.message || 'Gộp âm thanh thất bại');
                audioUrl = mergeRes.url;
            } else {
                // Single Mode
                message.loading({ content: 'Đang upload âm thanh...', key: 'upload' });
                const fileToUpload = Array.isArray(audioFiles) ? audioFiles[0] : audioFiles;
                const audioRes = await uploadApi.audio(fileToUpload);
                if (!audioRes.success) throw new Error(audioRes.message || 'Upload âm thanh thất bại');
                audioUrl = audioRes.url;
            }

            // 2. Handle Graphic Image (If any)
            let graphicUrl = '';
            if (graphicFile) {
                const imgRes = await uploadApi.image(graphicFile);
                if (imgRes.success) graphicUrl = imgRes.url;
            }

            // 3. Prepare Payload
            const questionsPayload = values.questions.map((q: any) => ({
                questionNumber: q.questionNumber,
                questionText: q.questionText,
                optionA: q.optionA,
                optionB: q.optionB,
                optionC: q.optionC,
                optionD: q.optionD,
                correctAnswer: q.correctAnswer,
                explanation: values.transcript,
                audioUrl: audioUrl,
                transcript: values.transcript
            }));

            // In Part 3/4, passage string often contains the audio tag and the graphic img tag
            let passageHtml = `<audio src="${audioUrl}"></audio>`;
            if (graphicUrl) {
                passageHtml += `<p><img src="${graphicUrl}" style="max-width: 100%; display: block; margin: 10px auto;" /></p>`;
            }

            const payload = {
                passage: passageHtml,
                questions: questionsPayload,
                audioUrl: audioUrl,
                transcript: values.transcript
            };

            const response = await api.post(`/parts/${partId}/questions/batch`, payload);

            if (response.data.success) {
                message.success({ content: `Tạo nhóm câu hỏi Part ${partNumber} thành công!`, key: 'upload' });
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
            console.error('Error creating group:', error);
            message.error(error.message || 'Có lỗi xảy ra');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{
                        width: 40, height: 40, borderRadius: 12,
                        background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff'
                    }}>
                        <SoundOutlined style={{ fontSize: 20 }} />
                    </div>
                    <div>
                        <Title level={4} style={{ margin: 0 }}>{partName || `THÊM NHÓM CÂU HỎI PART ${partNumber}`}</Title>
                        <Text type="secondary" style={{ fontSize: 12 }}>Quy trình tạo bài nghe cao cấp (Premium Manual Mode)</Text>
                    </div>
                </div>
            }
            open={open}
            onCancel={onCancel}
            footer={null}
            width={1100}
            style={{ top: 20 }}
            destroyOnClose={true}
            bodyStyle={{ padding: '0 24px 24px 24px' }}
        >
            <Form form={form} layout="vertical" onFinish={handleSubmit}>
                <Row gutter={24} style={{ marginTop: 24 }}>
                    {/* ─── LEFT COLUMN: AUDIO & CONTENT ─── */}
                    <Col span={14}>
                        <Card 
                            title={<Space><SoundOutlined /><span>Dữ liệu âm thanh & Nội dung</span></Space>}
                            extra={
                                <Space>
                                    <Tooltip title="Tải mẫu Excel">
                                        <Button size="small" icon={<FileExcelOutlined />} onClick={handleDownloadTemplate} />
                                    </Tooltip>
                                    <Upload beforeUpload={handleExcelImport} showUploadList={false} accept=".xlsx,.xls">
                                        <Button size="small" icon={<CloudUploadOutlined />}>Excel</Button>
                                    </Upload>
                                </Space>
                            }
                            style={{ borderRadius: 16, border: '1px solid #E2E8F0', height: '100%' }}
                        >
                            {/* Audio Banner */}
                            <AudioBanner
                                currentAudioUrl={null}
                                newAudioFile={audioFiles}
                                onAudioFileChange={setAudioFiles}
                                multiple={true}
                            />

                            <Divider orientation={"left" as any} style={{ margin: '16px 0' }}>
                                <Space><MessageOutlined /><span>Transcript & Graphic</span></Space>
                            </Divider>

                            {/* Graphic Image Upload */}
                            <div style={{ marginBottom: 20 }}>
                                <Text strong style={{ display: 'block', marginBottom: 8 }}>Ảnh minh họa (Graphic - nếu có):</Text>
                                <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
                                    <Upload
                                        beforeUpload={handleGraphicBeforeUpload}
                                        showUploadList={false}
                                        accept="image/*"
                                    >
                                        <div style={{
                                            width: 100, height: 100, borderRadius: 12, border: '2px dashed #CBD5E1',
                                            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                                            cursor: 'pointer', background: '#F8FAFC', transition: 'all 0.3s'
                                        }} className="hover:border-blue-500">
                                            {graphicPreview ? (
                                                <Image src={graphicPreview} preview={false} style={{ width: '100%', height: '100%', borderRadius: 10, objectFit: 'cover' }} />
                                            ) : (
                                                <>
                                                    <PicCenterOutlined style={{ fontSize: 24, color: '#94A3B8' }} />
                                                    <span style={{ fontSize: 10, color: '#94A3B8', marginTop: 4 }}>Thêm ảnh</span>
                                                </>
                                            )}
                                        </div>
                                    </Upload>
                                    {graphicPreview && (
                                        <Button type="text" danger icon={<DeleteOutlined />} onClick={() => { setGraphicPreview(null); setGraphicFile(null); }}>Xóa ảnh</Button>
                                    )}
                                </div>
                            </div>

                            {/* Transcript with Quill */}
                            <Form.Item label={<Text strong>Transcript bài nói:</Text>} name="transcript">
                                <ReactQuill
                                    theme="snow"
                                    modules={QUILL_MODULES}
                                    formats={QUILL_FORMATS}
                                    placeholder="Nhập nội dung hội thoại..."
                                    style={{ height: 200, marginBottom: 50, borderRadius: 12 }}
                                />
                            </Form.Item>
                        </Card>
                    </Col>

                    {/* ─── RIGHT COLUMN: QUESTIONS ─── */}
                    <Col span={10}>
                        <Card 
                            title={<Space><CheckCircleOutlined /><span>Danh sách 3 câu hỏi</span></Space>}
                            style={{ borderRadius: 16, border: '1px solid #E2E8F0', maxHeight: '70vh', overflowY: 'auto' }}
                            bodyStyle={{ padding: '16px' }}
                        >
                            <Form.List name="questions">
                                {(fields) => (
                                    <>
                                        {fields.map((field, index) => (
                                            <Card
                                                key={field.key}
                                                size="small"
                                                style={{ 
                                                    marginBottom: 16, borderRadius: 12, background: '#F8FAFC', 
                                                    border: '1px solid #E2E8F0', boxShadow: '0 2px 4px rgba(0,0,0,0.02)' 
                                                }}
                                                title={
                                                    <Space>
                                                        <Form.Item
                                                            noStyle
                                                            shouldUpdate={(prevValues, currentValues) =>
                                                                prevValues.questions?.[index]?.questionNumber !== currentValues.questions?.[index]?.questionNumber
                                                            }
                                                        >
                                                            {() => (
                                                                <Tag color="blue" style={{ borderRadius: 6 }}>
                                                                    Câu {form.getFieldValue(['questions', index, 'questionNumber']) || (index * 1 + 32)}
                                                                </Tag>
                                                            )}
                                                        </Form.Item>
                                                        <Form.Item {...field} name={[field.name, 'questionNumber']} noStyle>
                                                            <InputNumber size="small" bordered={false} style={{ fontWeight: 700, width: 50 }} />
                                                        </Form.Item>
                                                    </Space>
                                                }
                                            >
                                                <Form.Item {...field} name={[field.name, 'questionText']} rules={[{ required: true, message: 'Nhập nội dung câu hỏi' }]}>
                                                    <Input placeholder="Nội dung câu hỏi..." style={{ borderRadius: 8 }} />
                                                </Form.Item>

                                                <Row gutter={[8, 8]}>
                                                    <Col span={12}>
                                                        <Form.Item {...field} name={[field.name, 'optionA']} label="A" style={{ marginBottom: 8 }}>
                                                            <Input size="small" style={{ borderRadius: 6 }} />
                                                        </Form.Item>
                                                    </Col>
                                                    <Col span={12}>
                                                        <Form.Item {...field} name={[field.name, 'optionB']} label="B" style={{ marginBottom: 8 }}>
                                                            <Input size="small" style={{ borderRadius: 6 }} />
                                                        </Form.Item>
                                                    </Col>
                                                    <Col span={12}>
                                                        <Form.Item {...field} name={[field.name, 'optionC']} label="C" style={{ marginBottom: 8 }}>
                                                            <Input size="small" style={{ borderRadius: 6 }} />
                                                        </Form.Item>
                                                    </Col>
                                                    <Col span={12}>
                                                        <Form.Item {...field} name={[field.name, 'optionD']} label="D" style={{ marginBottom: 8 }}>
                                                            <Input size="small" style={{ borderRadius: 6 }} />
                                                        </Form.Item>
                                                    </Col>
                                                </Row>

                                                <Form.Item {...field} name={[field.name, 'correctAnswer']} label={<Text strong style={{ fontSize: 12 }}>Đáp án đúng:</Text>} rules={[{ required: true }]} style={{ marginTop: 8, marginBottom: 0 }}>
                                                    <Select size="small" style={{ width: '100%', borderRadius: 6 }}>
                                                        <Option value="A">A</Option>
                                                        <Option value="B">B</Option>
                                                        <Option value="C">C</Option>
                                                        <Option value="D">D</Option>
                                                    </Select>
                                                </Form.Item>
                                            </Card>
                                        ))}
                                    </>
                                )}
                            </Form.List>
                        </Card>
                    </Col>
                </Row>

                <div style={{ marginTop: 24, display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
                    <Button onClick={onCancel} style={{ borderRadius: 10, width: 120 }}>Hủy</Button>
                    <Button 
                        type="primary" 
                        htmlType="submit" 
                        loading={loading}
                        style={{ 
                            borderRadius: 10, width: 200, height: 40,
                            background: 'linear-gradient(135deg, #2563EB 0%, #1E40AF 100%)', 
                            border: 'none', fontWeight: 700, boxShadow: '0 4px 12px rgba(37, 99, 235, 0.3)'
                        }}
                    >
                        TẠO NHÓM CÂU HỎI
                    </Button>
                </div>
            </Form>
        </Modal>
    );
}
