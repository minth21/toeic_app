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
    TrophyOutlined,
    HistoryOutlined,
    EyeOutlined,
    SearchOutlined,
    ReloadOutlined,
    FilterOutlined
} from '@ant-design/icons';
import { useForm, Controller } from 'react-hook-form';
import { aiApi } from '../services/api';
import { useTheme } from '../hooks/useThemeContext';
import dayjs from 'dayjs';

const { Search } = Input;

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

    // Filtering states
    const [searchText, setSearchText] = useState('');
    const [statusFilter, setStatusFilter] = useState('ALL');

    const { control, handleSubmit, reset } = useForm<RoadmapForm>({
        defaultValues: {
            summary: '',
            teacherNote: '',
            auditNote: ''
        }
    });

    const stats = {
        total: data.length,
        pending: data.filter(r => r.status === 'PENDING').length,
        published: data.filter(r => r.status === 'PUBLISHED').length,
        rejected: data.filter(r => r.status === 'REJECTED').length,
    };

    // Client-side filtering logic
    const filteredData = data.filter(item => {
        const matchesSearch = !searchText ||
            item.user?.name?.toLowerCase().includes(searchText.toLowerCase()) ||
            item.user?.username?.toLowerCase().includes(searchText.toLowerCase()) ||
            item.title?.toLowerCase().includes(searchText.toLowerCase());

        const matchesStatus = statusFilter === 'ALL' || item.status === statusFilter;

        return matchesSearch && matchesStatus;
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
            width: 220,
            align: 'center' as const,
            render: (_: any, record: any) => (
                <Space size="middle" style={{ width: '100%', justifyContent: 'center' }}>
                    <Avatar
                        size={48}
                        src={record.user?.avatarUrl}
                        icon={<UserOutlined />}
                        style={{ border: '2px solid #E2E8F0' }}
                    />
                    <div style={{ display: 'flex', flexDirection: 'column', textAlign: 'left' }}>
                        <Text strong style={{ fontSize: 15, color: '#1E293B' }}>{record.user?.name}</Text>
                        <Text type="secondary" style={{ fontSize: 12 }}>@{record.user?.username}</Text>
                    </div>
                </Space>
            )
        },
        {
            title: 'Tên lộ trình',
            dataIndex: 'title',
            key: 'title',
            width: 200,
            align: 'center' as const,
            render: (text: string) => (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
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
            align: 'center' as const,
            render: (status: string) => {
                switch (status) {
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
            width: 160,
            align: 'center' as const,
            render: (date: string) => (
                <Text type="secondary" style={{ fontSize: 13 }}>
                    {dayjs(date).format('HH:mm - DD/MM/YYYY')}
                </Text>
            )
        },
        {
            title: 'Thao tác',
            key: 'action',
            width: 180,
            align: 'center' as const,
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
        <div style={{ padding: '32px', background: isDark ? '#0F172A' : '#F8FAFC', minHeight: '100vh' }}>
            {/* Premium Header */}
            <div style={{ marginBottom: 32, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                </div>
                <Button
                    type="primary"
                    icon={<ReloadOutlined />}
                    onClick={fetchRoadmaps}
                    loading={loading}
                    size="large"
                    style={{
                        borderRadius: 12,
                        fontWeight: 600,
                        background: isDark ? '#1E293B' : '#fff',
                        color: isDark ? '#F1F5F9' : '#475569',
                        border: `1px solid ${isDark ? '#334155' : '#E2E8F0'}`,
                        boxShadow: '0 2px 4px rgba(0,0,0,0.02)',
                        height: 48,
                        padding: '0 20px'
                    }}
                >
                    Làm mới dữ liệu
                </Button>
            </div>

            {/* Overview Stats Cards */}
            <Row gutter={24} style={{ marginBottom: 32 }}>
                {[
                    { title: 'Tổng lộ trình', value: stats.total, icon: <AuditOutlined />, color: '#6366F1', bg: 'linear-gradient(135deg, #EEF2FF 0%, #E0E7FF 100%)' },
                    { title: 'Đang đợi duyệt', value: stats.pending, icon: <ClockCircleOutlined />, color: '#F59E0B', bg: 'linear-gradient(135deg, #FFFBEB 0%, #FEF3C7 100%)' },
                    { title: 'Đã duyệt', value: stats.published, icon: <CheckCircleOutlined />, color: '#10B981', bg: 'linear-gradient(135deg, #ECFDF5 0%, #D1FAE5 100%)' },
                    { title: 'Cần sửa đổi', value: stats.rejected, icon: <AuditOutlined />, color: '#EF4444', bg: 'linear-gradient(135deg, #FEF2F2 0%, #FEE2E2 100%)' },
                ].map((item, index) => (
                    <Col xs={24} sm={12} md={6} key={index}>
                        <Card
                            hoverable
                            style={{
                                borderRadius: 24,
                                border: 'none',
                                background: isDark ? '#1E293B' : '#fff',
                                boxShadow: modernShadow,
                                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
                            }}
                            bodyStyle={{ padding: '24px' }}
                        >
                            <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
                                <div style={{
                                    width: 64,
                                    height: 64,
                                    borderRadius: 18,
                                    background: item.bg,
                                    color: item.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: 28,
                                    boxShadow: 'inset 0 2px 4px rgba(255,255,255,0.3)'
                                }}>
                                    {item.icon}
                                </div>
                                <div style={{ flex: 1 }}>
                                    <div style={{ fontWeight: 700, color: '#64748B', textTransform: 'uppercase', fontSize: 11, letterSpacing: '0.8px', marginBottom: 4 }}>
                                        {item.title}
                                    </div>
                                    <div style={{ color: isDark ? '#F1F5F9' : '#1E293B', fontWeight: 800, fontSize: 30, lineHeight: 1 }}>
                                        {item.value}
                                    </div>
                                </div>
                            </div>
                        </Card>
                    </Col>
                ))}
            </Row>

            {/* Filters Section */}
            <Card
                style={{
                    marginBottom: 24,
                    borderRadius: 20,
                    border: 'none',
                    background: isDark ? '#1E293B' : '#fff',
                    boxShadow: modernShadow
                }}
                bodyStyle={{ padding: '20px 24px' }}
            >
                <Row gutter={16} align="middle">
                    <Col xs={24} md={12}>
                        <Search
                            placeholder="Tìm theo tên học viên hoặc tên lộ trình..."
                            allowClear
                            onChange={(e) => setSearchText(e.target.value)}
                            onSearch={setSearchText}
                            style={{ width: '100%' }}
                            size="large"
                            prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
                        />
                    </Col>
                    <Col xs={24} md={12}>
                        <Space size="middle" style={{ width: '100%', justifyContent: 'flex-end' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                                <FilterOutlined style={{ color: '#64748B' }} />
                                <Text strong style={{ color: '#64748B' }}>Lọc trạng thái:</Text>
                                <Space direction="horizontal" size={8}>
                                    {[
                                        { label: 'Tất cả', value: 'ALL', color: 'blue' },
                                        { label: 'Chờ duyệt', value: 'PENDING', color: 'orange' },
                                        { label: 'Đã duyệt', value: 'PUBLISHED', color: 'green' },
                                        { label: 'Từ chối', value: 'REJECTED', color: 'red' }
                                    ].map(btn => (
                                        <Tag.CheckableTag
                                            key={btn.value}
                                            checked={statusFilter === btn.value}
                                            onChange={() => setStatusFilter(btn.value)}
                                            style={{
                                                padding: '4px 12px',
                                                borderRadius: 8,
                                                fontSize: 13,
                                                border: statusFilter === btn.value ? 'none' : '1px solid #E2E8F0',
                                                background: statusFilter === btn.value ? undefined : 'transparent'
                                            }}
                                        >
                                            {btn.label}
                                        </Tag.CheckableTag>
                                    ))}
                                </Space>
                            </div>
                        </Space>
                    </Col>
                </Row>
            </Card>

            {/* Table Section */}
            <Card
                styles={{ body: { padding: 0 } }}
                style={{
                    borderRadius: 24,
                    border: 'none',
                    boxShadow: modernShadow,
                    overflow: 'hidden',
                    background: isDark ? '#1E293B' : '#fff'
                }}
            >
                <Table
                    columns={columns}
                    dataSource={filteredData}
                    loading={loading}
                    rowKey="id"
                    pagination={{
                        pageSize: 10,
                        showSizeChanger: true,
                        showTotal: (total) => <span style={{ fontWeight: 600, color: '#64748B' }}>Tổng cộng {total} lộ trình</span>,
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
                        >
                            {selectedRoadmap?.status === 'PENDING' ? 'Hủy bỏ' : 'Đóng'}
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
                                <Col span={12}>
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
                                <Col span={12}>
                                    <Card variant="borderless" style={{ background: isDark ? 'rgba(139, 92, 246, 0.1)' : '#F5F3FF', borderRadius: 24, border: `1px solid ${isDark ? 'rgba(139, 92, 246, 0.2)' : '#EDE9FE'}` }}>
                                        <Statistic
                                            title={<span style={{ color: isDark ? '#C4B5FD' : '#5B21B6', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.8px' }}>Thời gian dự kiến</span>}
                                            value={selectedRoadmap.content?.estimatedTimeToTarget || 'Không có'}
                                            prefix={<ClockCircleOutlined style={{ color: '#8B5CF6', marginRight: 8 }} />}
                                            valueStyle={{ color: isDark ? '#A78BFA' : '#4C1D95', fontWeight: 900, fontSize: 26 }}
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
                                                disabled={selectedRoadmap?.status !== 'PENDING'}
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
                                                disabled={selectedRoadmap?.status !== 'PENDING'}
                                            />
                                        )}
                                    />
                                </Card>

                                {/* Audit/Reject Note */}
                                <Card variant="borderless" style={{ background: '#FFF7ED', borderRadius: 20, border: '1px solid #FFEDD5' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                                        <div style={{ width: 4, height: 18, background: '#F59E0B', borderRadius: 2 }} />
                                        <Title level={5} style={{ margin: 0 }}>Phản hồi kiểm duyệt</Title>
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
                                                disabled={selectedRoadmap?.status !== 'PENDING'}
                                            />
                                        )}
                                    />
                                </Card>

                                {/* Steps Visualization (Roadmap Phases) */}
                                {(selectedRoadmap.content?.roadmap || selectedRoadmap.content?.steps) && (
                                    <div style={{ marginTop: 16 }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24 }}>
                                            <div style={{ width: 4, height: 18, background: '#6366F1', borderRadius: 2 }} />
                                            <Title level={5} style={{ margin: 0 }}>Lộ trình thực thi chi tiết</Title>
                                        </div>
                                        {(selectedRoadmap.content.roadmap || selectedRoadmap.content.steps).map((step: any, index: number, arr: any[]) => (
                                            <div key={index} style={{ display: 'flex', gap: 20, marginBottom: 32, position: 'relative' }}>
                                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                                                    <div style={{
                                                        width: 40, height: 40, borderRadius: '12px', background: '#EEF2FF',
                                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                        color: '#4F46E5', fontWeight: 'bold', zIndex: 2, border: '1px solid #E0E7FF'
                                                    }}>
                                                        {index + 1}
                                                    </div>
                                                    {index !== arr.length - 1 && (
                                                        <div style={{ width: 2, flex: 1, background: '#F1F5F9', margin: '4px 0' }} />
                                                    )}
                                                </div>
                                                <div style={{ flex: 1, paddingBottom: 10 }}>
                                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
                                                        <Text strong style={{ fontSize: 16, color: '#1E293B' }}>
                                                            {step.phase || step.title}
                                                        </Text>
                                                        {(step.duration) && (
                                                            <Tag color="blue" style={{ borderRadius: 6, margin: 0 }}>{step.duration}</Tag>
                                                        )}
                                                    </div>
                                                    <Paragraph style={{ color: '#64748B', marginBottom: 12 }}>
                                                        {step.expertTips || step.description}
                                                    </Paragraph>

                                                    {step.focus && (
                                                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                                                            {(Array.isArray(step.focus) ? step.focus : (step.focus || '').split(',')).map((f: string, i: number) => (
                                                                f.trim() && <Tag key={i} style={{ borderRadius: 4, border: 'none', background: '#F8FAFC', color: '#64748B', fontSize: 11 }}>
                                                                    # {f.trim()}
                                                                </Tag>
                                                            ))}
                                                        </div>
                                                    )}
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
