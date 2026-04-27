import { useState, useEffect } from 'react';
import {
    Table,
    Tag,
    Space,
    Button,
    Card,
    Typography,
    message,
    Modal,
    theme,
    Avatar,
    Input,
} from 'antd';
import {
    CheckCircleOutlined,
    ClockCircleOutlined,
    ReloadOutlined,
    UserOutlined,
    TeamOutlined,
    SendOutlined,
    CommentOutlined,
} from '@ant-design/icons';
import { feedbackApi, type StudentFeedback } from '../services/api';
import type { ColumnsType } from 'antd/es/table';

const { Text, Paragraph } = Typography;
const { TextArea } = Input;

export default function ClassFeedbackManagement() {
    const [feedbacks, setFeedbacks] = useState<StudentFeedback[]>([]);
    const [loading, setLoading] = useState(false);
    const [replyModalVisible, setReplyModalVisible] = useState(false);
    const [selectedFeedback, setSelectedFeedback] = useState<StudentFeedback | null>(null);
    const [replyContent, setReplyContent] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const { token } = theme.useToken();

    const fetchFeedbacks = async () => {
        setLoading(true);
        try {
            const data = await feedbackApi.list();
            if (data.success) {
                setFeedbacks(data.data);
            }
        } catch (error) {
            console.error('Error fetching feedbacks:', error);
            message.error('Không thể tải danh sách ý kiến');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchFeedbacks();
    }, []);

    const openReplyModal = (feedback: StudentFeedback) => {
        setSelectedFeedback(feedback);
        setReplyContent(feedback.teacherReply || '');
        setReplyModalVisible(true);
    };

    const handleReply = async () => {
        if (!selectedFeedback || !replyContent.trim()) {
            message.warning('Vui lòng nhập nội dung phản hồi');
            return;
        }

        setSubmitting(true);
        try {
            const data = await feedbackApi.reply(selectedFeedback.id, replyContent.trim());
            if (data.success) {
                message.success('Đã gửi phản hồi cho học viên!');
                setReplyModalVisible(false);
                fetchFeedbacks();
            }
        } catch (error) {
            console.error('Error replying to feedback:', error);
            message.error('Lỗi khi gửi phản hồi');
        } finally {
            setSubmitting(false);
        }
    };

    const handleResolve = async (feedback: StudentFeedback) => {
        Modal.confirm({
            title: 'Xác nhận đã xử lý xong',
            content: `Xác nhận bạn đã xem và giải quyết ý kiến của học viên ${feedback.user?.name}?`,
            okText: 'Xác nhận xử lý',
            cancelText: 'Hủy',
            onOk: async () => {
                try {
                    const data = await feedbackApi.resolve(feedback.id);
                    if (data.success) {
                        message.success('Đã xử lý ý kiến học viên!');
                        fetchFeedbacks();
                    }
                } catch (error) {
                    console.error('Error resolving feedback:', error);
                    message.error('Có lỗi xảy ra');
                }
            },
        });
    };

    const columns: ColumnsType<StudentFeedback> = [
        {
            title: 'Học viên',
            key: 'user',
            width: 200,
            align: 'center' as const,
            render: (_, record) => (
                <Space style={{ width: '100%', justifyContent: 'center' }}>
                    <Avatar
                        src={record.user?.avatarUrl}
                        icon={<UserOutlined />}
                        style={{ backgroundColor: token.colorPrimary }}
                    />
                    <Space direction="vertical" size={0} style={{ textAlign: 'left' }}>
                        <Text strong>{record.user?.name}</Text>
                        <Text type="secondary" style={{ fontSize: '11px' }}>ID: {record.userId.substring(0, 8)}...</Text>
                    </Space>
                </Space>
            ),
        },
        {
            title: 'Lớp học',
            key: 'class',
            width: 180,
            align: 'center' as const,
            render: (_, record) => (
                <Space direction="vertical" size={0} style={{ width: '100%', justifyContent: 'center' }}>
                    <Text strong>
                        <TeamOutlined style={{ marginRight: 8, color: '#3B82F6' }} />
                        {record.class?.className}
                    </Text>
                    {record.class?.classCode && (
                        <Tag color="blue" style={{ fontSize: '10px', margin: 0 }}>{record.class.classCode}</Tag>
                    )}
                </Space>
            ),
        },
        {
            title: 'Nội dung & Phản hồi',
            key: 'content',
            align: 'center' as const,
            render: (_, record) => (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12, alignItems: 'center' }}>
                    <div style={{ textAlign: 'center' }}>
                        <Tag color="blue">Câu hỏi:</Tag>
                        <Paragraph style={{ margin: '4px 0 0 0', whiteSpace: 'pre-wrap' }}>{record.content}</Paragraph>
                    </div>
                    {record.teacherReply && (
                        <div style={{
                            padding: '10px 14px',
                            background: '#F0FDF4',
                            borderRadius: '12px',
                            borderLeft: '4px solid #22C55E',
                            textAlign: 'left',
                            maxWidth: '90%'
                        }}>
                            <Space align="start">
                                <CommentOutlined style={{ color: '#22C55E', marginTop: 4 }} />
                                <div>
                                    <Text strong style={{ color: '#166534', fontSize: '12px' }}>Phản hồi của Giáo viên:</Text>
                                    <Paragraph style={{ margin: '2px 0 0 0', color: '#166534', fontSize: '13px' }}>
                                        {record.teacherReply}
                                    </Paragraph>
                                    {record.repliedAt && (
                                        <Text type="secondary" style={{ fontSize: '10px' }}>
                                            {new Date(record.repliedAt).toLocaleString('vi-VN')}
                                        </Text>
                                    )}
                                </div>
                            </Space>
                        </div>
                    )}
                </div>
            ),
        },
        {
            title: 'Trạng thái',
            dataIndex: 'status',
            key: 'status',
            width: 130,
            align: 'center' as const,
            render: (status: string) => {
                const isPending = status === 'PENDING';
                return (
                    <Tag
                        icon={isPending ? <ClockCircleOutlined /> : <CheckCircleOutlined />}
                        color={isPending ? 'gold' : 'success'}
                        style={{ borderRadius: '20px', padding: '2px 12px', fontWeight: 600 }}
                    >
                        {isPending ? 'Đang chờ' : 'Đã xử lý'}
                    </Tag>
                );
            },
        },
        {
            title: 'Thao tác',
            key: 'actions',
            width: 180,
            align: 'center' as const,
            render: (_, record) => (
                <Space direction="vertical" style={{ width: '100%' }}>
                    <Button
                        block
                        type="primary"
                        icon={<SendOutlined />}
                        onClick={() => openReplyModal(record)}
                        style={{
                            borderRadius: '8px',
                            background: record.teacherReply ? '#64748B' : 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                            border: 'none'
                        }}
                    >
                        {record.teacherReply ? 'Sửa phản hồi' : 'Phản hồi'}
                    </Button>

                    {record.status === 'PENDING' && (
                        <Button
                            block
                            icon={<CheckCircleOutlined />}
                            onClick={() => handleResolve(record)}
                            style={{ borderRadius: '8px' }}
                        >
                            Đã xử lý
                        </Button>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: '24px', background: token.colorBgLayout, minHeight: '100vh' }}>
            <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography.Title level={3} style={{ margin: 0 }}>Quản lý ý kiến học viên</Typography.Title>
                <Button
                    icon={<ReloadOutlined />}
                    onClick={fetchFeedbacks}
                    loading={loading}
                    size="large"
                    style={{
                        borderRadius: 10,
                        fontWeight: 600,
                        border: '1px solid #E2E8F0',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
                    }}
                >
                    Làm mới
                </Button>
            </div>

            <Card
                style={{
                    borderRadius: 24,
                    boxShadow: '0 10px 30px -5px rgba(15, 23, 42, 0.05)',
                    border: 'none',
                    overflow: 'hidden'
                }}
                styles={{ body: { padding: 0 } }}
            >
                <Table
                    columns={columns}
                    dataSource={feedbacks}
                    rowKey="id"
                    loading={loading}
                    pagination={{
                        pageSize: 10,
                        showTotal: (total) => `Tổng cộng ${total} ý kiến`,
                        style: { padding: '16px 24px' }
                    }}
                />
            </Card>

            {/* Reply Modal */}
            <Modal
                title={
                    <Space>
                        <SendOutlined style={{ color: token.colorPrimary }} />
                        <span>Gửi phản hồi cho {selectedFeedback?.user?.name}</span>
                    </Space>
                }
                open={replyModalVisible}
                onOk={handleReply}
                onCancel={() => setReplyModalVisible(false)}
                okText="Gửi phản hồi"
                cancelText="Hủy"
                confirmLoading={submitting}
                width={600}
                centered
            >
                <div style={{ marginBottom: 16 }}>
                    <Text type="secondary">Nội dung học viên gửi:</Text>
                    <div style={{
                        marginTop: 8,
                        padding: '12px',
                        background: '#F8FAFC',
                        borderRadius: '8px',
                        border: '1px solid #E2E8F0',
                        fontStyle: 'italic'
                    }}>
                        "{selectedFeedback?.content}"
                    </div>
                </div>
                <div>
                    <Text strong>Câu trả lời của bạn:</Text>
                    <TextArea
                        rows={6}
                        value={replyContent}
                        onChange={(e) => setReplyContent(e.target.value)}
                        placeholder="Nhập lời giải đáp hoặc phản hồi tại đây..."
                        style={{ marginTop: 8, borderRadius: '8px' }}
                    />
                </div>
            </Modal>
        </div>
    );
}
