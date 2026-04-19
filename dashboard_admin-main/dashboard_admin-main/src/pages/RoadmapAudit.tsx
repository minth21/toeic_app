import React, { useEffect, useState } from 'react';
import {
    Table,
    Card,
    Button,
    Drawer,
    Typography,
    Space,
    Avatar,
    Tag,
    Row,
    Col,
    Statistic,
    Input,
    message,
    Popconfirm,
    Result
} from 'antd';
import {
    AuditOutlined,
    CheckCircleOutlined,
    ClockCircleOutlined,
    UserOutlined,
    SafetyCertificateOutlined,
    CloudUploadOutlined,
    SaveOutlined,
    BulbOutlined,
    TrophyOutlined,
    HistoryOutlined,
    EyeOutlined
} from '@ant-design/icons';
import { useForm, Controller } from 'react-hook-form';
import { aiApi } from '../services/api';
import { useTheme } from '../hooks/useThemeContext';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const modernShadow = '0 10px 30px -5px rgba(15, 23, 42, 0.05)';

interface RoadmapForm {
    summary: string;
    teacherNote: string;
    auditNote: string;
}

const RoadmapAudit: React.FC = () => {
    const { theme } = useTheme();
    const isDark = theme === 'dark';
    const [data, setData] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedRoadmap, setSelectedRoadmap] = useState<any>(null);
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const { control, handleSubmit, reset } = useForm<RoadmapForm>({
        defaultValues: {
            summary: '',
            teacherNote: '',
            auditNote: ''
        }
    });

    useEffect(() => {
        fetchRoadmaps();
    }, []);

    const fetchRoadmaps = async () => {
        setLoading(true);
        try {
            const res = await aiApi.getRoadmapsAdmin();
            if (res.success) {
                setData(res.data);
            }
        } catch (error) {
            console.error('Failed to fetch roadmaps:', error);
            message.error('Không thể tải danh sách lộ trình');
        } finally {
            setLoading(false);
        }
    };

    const handleOpenAudit = (record: any) => {
        setSelectedRoadmap(record);
        reset({
            summary: record.summary || '',
            teacherNote: record.teacherNote || '',
            auditNote: record.auditNote || ''
        });
        setDrawerVisible(true);
    };

    const onUpdate = async (formData: RoadmapForm) => {
        if (!selectedRoadmap) return;
        setSubmitting(true);
        try {
            const res = await aiApi.updateRoadmap(selectedRoadmap.id, {
                summary: formData.summary,
                teacherNote: formData.teacherNote
            });
            if (res.success) {
                message.success('Đã lưu thay đổi bản nháp');
                fetchRoadmaps();
            } else {
                message.error(res.message || 'Lỗi khi cập nhật');
            }
        } catch (error) {
            message.error('Lỗi hệ thống');
        } finally {
            setSubmitting(false);
        }
    };

    const onApprove = async (formData: RoadmapForm) => {
        if (!selectedRoadmap) return;
        setSubmitting(true);
        try {
            // Đầu tiên lưu thay đổi nội dung (nếu Admin có sửa)
            await aiApi.updateRoadmap(selectedRoadmap.id, {
                summary: formData.summary,
                teacherNote: formData.teacherNote
            });

            // Sau đó gọi API phê duyệt
            const res = await aiApi.approveRoadmap(selectedRoadmap.id, formData.auditNote);
            if (res.success) {
                message.success('Đã phê duyệt và công bố lộ trình thành công!');
                setDrawerVisible(false);
                fetchRoadmaps();
            } else {
                message.error(res.message || 'Lỗi khi công bố');
            }
        } catch (error) {
            message.error('Lỗi hệ thống');
        } finally {
            setSubmitting(false);
        }
    };

    const onReject = async (formData: RoadmapForm) => {
        if (!selectedRoadmap) return;
        if (!formData.auditNote) {
            message.warning('Vui lòng nhập lý do từ chối');
            return;
        }
        setSubmitting(true);
        try {
            const res = await aiApi.rejectRoadmap(selectedRoadmap.id, formData.auditNote);
            if (res.success) {
                message.success('Đã từ chối lộ trình và gửi phản hồi cho Giáo viên');
                setDrawerVisible(false);
                fetchRoadmaps();
            } else {
                message.error(res.message || 'Lỗi khi từ chối');
            }
        } catch (error) {
            message.error('Lỗi hệ thống');
        } finally {
            setSubmitting(false);
        }
    };

    const handleQuickApprove = async (record: any) => {
        setSubmitting(true);
        setSelectedRoadmap(record);
        try {
            const res = await aiApi.approveRoadmap(record.id, 'Phê duyệt nhanh');
            if (res.success) {
                message.success('Đã phê duyệt lộ trình thành công!');
                fetchRoadmaps();
            } else {
                message.error(res.message || 'Lỗi khi phê duyệt');
            }
        } catch (error) {
            message.error('Lỗi hệ thống');
        } finally {
            setSubmitting(false);
            setSelectedRoadmap(null);
        }
    };

    const columns = [
        {
            title: 'Học viên',
            key: 'user',
            render: (_: any, record: any) => (
                <Space size="middle">
                    <Avatar
                        size={48}
                        src={record.user?.avatarUrl}
                        icon={<UserOutlined />}
                        style={{ border: '2px solid #E2E8F0' }}
                    />
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <Text strong style={{ fontSize: 15, color: '#1E293B' }}>{record.user?.name}</Text>
                        <Text type="secondary" style={{ fontSize: 12 }}>@{record.user?.username}</Text>
                    </div>
                </Space>
            )
        },
        {
            title: 'Tiêu đề Lộ trình',
            dataIndex: 'title',
            key: 'title',
            render: (text: string) => (
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#3B82F6' }} />
                    <Text strong style={{ color: '#334155' }}>{text}</Text>
                </div>
            )
        },
        {
            title: 'Trạng thái',
            dataIndex: 'status',
            key: 'status',
            width: 180,
            render: (status: string) => {
                switch(status) {
                    case 'PUBLISHED':
                        return <Tag icon={<CheckCircleOutlined />} color="success" style={{ borderRadius: 12, padding: '2px 12px', fontWeight: 600 }}>ĐÃ CÔNG BỐ</Tag>;
                    case 'PENDING':
                        return <Tag icon={<ClockCircleOutlined />} color="warning" style={{ borderRadius: 12, padding: '2px 12px', fontWeight: 600 }}>CHỜ DUYỆT</Tag>;
                    case 'REJECTED':
                        return <Tag icon={<AuditOutlined />} color="error" style={{ borderRadius: 12, padding: '2px 12px', fontWeight: 600 }}>BỊ TỪ CHỐI</Tag>;
                    default:
                        return <Tag icon={<HistoryOutlined />} color="default" style={{ borderRadius: 12, padding: '2px 12px', fontWeight: 600 }}>BẢN NHÁP</Tag>;
                }
            }
        },
        {
            title: 'Thời gian tạo',
            dataIndex: 'createdAt',
            key: 'createdAt',
            render: (date: string) => (
                <Text type="secondary" style={{ fontSize: 13 }}>
                    {dayjs(date).format('HH:mm - DD/MM/YYYY')}
                </Text>
            )
        },
        {
            title: 'Thao tác',
            key: 'action',
            align: 'right' as const,
            render: (_: any, record: any) => (
                <Space>
                    <Button
                        icon={<EyeOutlined />}
                        onClick={() => handleOpenAudit(record)}
                        style={{
                            borderRadius: 10,
                            background: '#F1F5F9',
                            border: '1px solid #E2E8F0',
                            color: '#475569',
                            fontWeight: 600
                        }}
                    >
                        {record.isPublished ? 'Xem lại' : 'Xem chi tiết'}
                    </Button>
                    {record.status === 'PENDING' && (
                        <Popconfirm
                            title="Phê duyệt lộ trình"
                            description="Bạn có chắc muốn phê duyệt lộ trình này với nội dung hiện tại không?"
                            onConfirm={() => handleQuickApprove(record)}
                            okText="Duyệt"
                            cancelText="Hủy"
                            okButtonProps={{
                                loading: submitting && selectedRoadmap?.id === record.id,
                                style: { borderRadius: 6, background: '#10B981' }
                            }}
                            cancelButtonProps={{ style: { borderRadius: 6 } }}
                        >
                            <Button
                                type="primary"
                                icon={<CheckCircleOutlined />}
                                loading={submitting && selectedRoadmap?.id === record.id}
                                style={{
                                    borderRadius: 10,
                                    background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                                    border: 'none',
                                    boxShadow: '0 4px 12px rgba(16, 185, 129, 0.2)',
                                    fontWeight: 600
                                }}
                            >
                                Duyệt nhanh
                            </Button>
                        </Popconfirm>
                    )}
                </Space>
            )
        }
    ];

    return (
        <div style={{ padding: '24px', background: '#F8FAFC', minHeight: '100vh' }}>
            <Card
                title={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0' }}>
                        <div style={{
                            width: 40, height: 40, borderRadius: 12,
                            background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff'
                        }}>
                            <AuditOutlined style={{ fontSize: 20 }} />
                        </div>
                        <div>
                            <Title level={4} style={{ margin: 0 }}>Kiểm duyệt Lộ trình AI</Title>
                            <Text type="secondary" style={{ fontSize: 12 }}>Phê duyệt và tối ưu hóa lộ trình học tập do AI đề xuất</Text>
                        </div>
                    </div>
                }
                styles={{ body: { padding: 0 } }}
                style={{ borderRadius: 24, border: 'none', boxShadow: modernShadow, overflow: 'hidden' }}
            >
                <Table
                    columns={columns}
                    dataSource={data}
                    loading={loading}
                    rowKey="id"
                    pagination={{
                        pageSize: 10,
                        style: { padding: '16px 24px' }
                    }}
                />
            </Card>

            <Drawer
                title={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <SafetyCertificateOutlined style={{ color: '#6366F1', fontSize: 24 }} />
                        <span style={{ fontSize: 22, fontWeight: 800, letterSpacing: '-0.5px' }}>Kiểm duyệt & Hiệu chỉnh Lộ trình</span>
                    </div>
                }
                placement="right"
                width={950}
                onClose={() => setDrawerVisible(false)}
                open={drawerVisible}
                maskClosable={!submitting}
                styles={{
                    header: { borderBottom: '1px solid #F1F5F9' },
                    body: { padding: 0, background: '#F8FAFC' }
                }}
                footer={
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, padding: '16px 24px', background: '#fff', borderTop: '1px solid #F1F5F9' }}>
                        <Button
                            size="large"
                            style={{ borderRadius: 10 }}
                            onClick={() => setDrawerVisible(false)}
                            disabled={submitting}
                        >
                            Hủy bỏ
                        </Button>
                        {selectedRoadmap?.status === 'PENDING' && (
                            <>
                                <Button
                                    size="large"
                                    icon={<SaveOutlined />}
                                    loading={submitting}
                                    onClick={handleSubmit(onUpdate)}
                                    style={{ borderRadius: 10, background: '#F1F5F9', border: '1px solid #E2E8F0', color: '#475569' }}
                                >
                                    Cập nhật nội dung
                                </Button>
                                <Button
                                    danger
                                    size="large"
                                    icon={<AuditOutlined />}
                                    loading={submitting}
                                    onClick={handleSubmit(onReject)}
                                    style={{ borderRadius: 10 }}
                                >
                                    Từ chối
                                </Button>
                                <Button
                                    type="primary"
                                    size="large"
                                    icon={<CloudUploadOutlined />}
                                    loading={submitting}
                                    onClick={handleSubmit(onApprove)}
                                    style={{
                                        borderRadius: 10,
                                        background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                                        border: 'none',
                                        boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)'
                                    }}
                                >
                                    Phê duyệt & Công bố
                                </Button>
                            </>
                        )}
                    </div>
                }
            >
                {selectedRoadmap ? (
                    <div style={{ padding: '0 0 40px 0' }}>
                        {/* Scoreboard Section */}
                        <div style={{ background: isDark ? 'rgba(30, 41, 59, 0.5)' : '#fff', padding: '32px 24px', borderBottom: `1px solid ${isDark ? '#334155' : '#F1F5F9'}`, marginBottom: 32 }}>
                            <Row gutter={32}>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ background: isDark ? 'rgba(59, 130, 246, 0.1)' : '#EFF6FF', borderRadius: 24, border: `1px solid ${isDark ? 'rgba(59, 130, 246, 0.2)' : '#DBEAFE'}` }}>
                                        <Statistic
                                            title={<span style={{ color: isDark ? '#93C5FD' : '#1E40AF', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.8px' }}>Điểm mục tiêu</span>}
                                            value={selectedRoadmap.content?.targetScore || 0}
                                            prefix={<TrophyOutlined style={{ color: '#3B82F6', marginRight: 8 }} />}
                                            suffix={<span style={{ fontSize: 16, marginLeft: 4, fontWeight: 600 }}>pts</span>}
                                            valueStyle={{ color: isDark ? '#60A5FA' : '#1E3A8A', fontWeight: 900, fontSize: 32 }}
                                        />
                                    </Card>
                                </Col>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ background: isDark ? 'rgba(139, 92, 246, 0.1)' : '#F5F3FF', borderRadius: 24, border: `1px solid ${isDark ? 'rgba(139, 92, 246, 0.2)' : '#EDE9FE'}` }}>
                                        <Statistic
                                            title={<span style={{ color: isDark ? '#C4B5FD' : '#5B21B6', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.8px' }}>Thời gian dự kiến</span>}
                                            value={selectedRoadmap.content?.estimatedTimeToTarget || 'N/A'}
                                            prefix={<ClockCircleOutlined style={{ color: '#8B5CF6', marginRight: 8 }} />}
                                            valueStyle={{ color: isDark ? '#A78BFA' : '#4C1D95', fontWeight: 900, fontSize: 26 }}
                                        />
                                    </Card>
                                </Col>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ background: isDark ? 'rgba(16, 185, 129, 0.1)' : '#ECFDF5', borderRadius: 24, border: `1px solid ${isDark ? 'rgba(16, 185, 129, 0.2)' : '#D1FAE5'}` }}>
                                        <Statistic
                                            title={<span style={{ color: isDark ? '#6EE7B7' : '#065F46', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.8px' }}>Trình độ hiện tại</span>}
                                            value={selectedRoadmap.content?.currentLevel || 'N/A'}
                                            prefix={<BulbOutlined style={{ color: '#10B981', marginRight: 8 }} />}
                                            valueStyle={{ color: isDark ? '#34D399' : '#064E3B', fontWeight: 900, fontSize: 26 }}
                                        />
                                    </Card>
                                </Col>
                            </Row>
                        </div>

                        {/* Content Sections */}
                        <div style={{ padding: '0 24px' }}>
                            <Space direction="vertical" size={32} style={{ width: '100%' }}>
                                {/* Summary Editor */}
                                <Card variant="borderless" style={{ background: '#fff', borderRadius: 20, boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                                        <div style={{ width: 4, height: 18, background: '#3B82F6', borderRadius: 2 }} />
                                        <Title level={5} style={{ margin: 0 }}>Tóm tắt lộ trình</Title>
                                    </div>
                                    <Controller
                                        name="summary"
                                        control={control}
                                        render={({ field }) => (
                                            <Input.TextArea
                                                {...field}
                                                rows={4}
                                                placeholder="Nội dung tóm tắt cho học viên..."
                                                style={{ borderRadius: 12, padding: 12, fontSize: 14 }}
                                            />
                                        )}
                                    />
                                </Card>

                                {/* Teacher Note Editor */}
                                <Card variant="borderless" style={{ background: '#F8FAFC', borderRadius: 20, border: '1px dashed #E2E8F0' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                                        <div style={{ width: 4, height: 18, background: '#8B5CF6', borderRadius: 2 }} />
                                        <Title level={5} style={{ margin: 0 }}>Lời khuyên từ Giáo viên</Title>
                                    </div>
                                    <Controller
                                        name="teacherNote"
                                        control={control}
                                        render={({ field }) => (
                                            <Input.TextArea
                                                {...field}
                                                rows={4}
                                                placeholder="Dặn dò học viên (Cần thiết trước khi công bố)..."
                                                style={{ borderRadius: 12, padding: 12, fontSize: 14 }}
                                            />
                                        )}
                                    />
                                </Card>

                                {/* Audit/Reject Note */}
                                <Card variant="borderless" style={{ background: '#FFF7ED', borderRadius: 20, border: '1px solid #FFEDD5' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                                        <div style={{ width: 4, height: 18, background: '#F59E0B', borderRadius: 2 }} />
                                        <Title level={5} style={{ margin: 0 }}>Phản hồi Kiểm duyệt (Gửi cho GV)</Title>
                                    </div>
                                    <Controller
                                        name="auditNote"
                                        control={control}
                                        render={({ field }) => (
                                            <Input.TextArea
                                                {...field}
                                                rows={3}
                                                placeholder="Lý do từ chối hoặc góp ý thêm khi phê duyệt..."
                                                style={{ borderRadius: 12, padding: 12, fontSize: 14 }}
                                            />
                                        )}
                                    />
                                </Card>

                                {/* Steps Visualization */}
                                {selectedRoadmap.content?.steps && (
                                    <div style={{ marginTop: 16 }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24 }}>
                                            <div style={{ width: 4, height: 18, background: '#10B981', borderRadius: 2 }} />
                                            <Title level={5} style={{ margin: 0 }}>Lộ trình thực thi chi tiết</Title>
                                        </div>
                                        {selectedRoadmap.content.steps.map((step: any, index: number) => (
                                            <div key={index} style={{ display: 'flex', gap: 20, marginBottom: 32, position: 'relative' }}>
                                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                                                    <div style={{
                                                        width: 36, height: 36, borderRadius: '50%', background: '#3B82F6',
                                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                        color: '#fff', fontWeight: 'bold', zIndex: 2
                                                    }}>
                                                        {index + 1}
                                                    </div>
                                                    {index !== selectedRoadmap.content.steps.length - 1 && (
                                                        <div style={{ width: 2, flex: 1, background: '#E2E8F0', margin: '4px 0' }} />
                                                    )}
                                                </div>
                                                <div style={{ flex: 1, paddingBottom: 10 }}>
                                                    <Text strong style={{ fontSize: 16, display: 'block', marginBottom: 4 }}>{step.title}</Text>
                                                    <Paragraph type="secondary" style={{ margin: 0 }}>{step.description}</Paragraph>
                                                    {step.duration && <Tag color="blue" style={{ marginTop: 8, borderRadius: 6 }}>{step.duration}</Tag>}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </Space>
                        </div>
                    </div>
                ) : (
                    <Result status="info" title="Vui lòng chọn lộ trình để kiểm duyệt" />
                )}
            </Drawer>
        </div>
    );
};

export default RoadmapAudit;
