import { useState, useEffect } from 'react';
import {
    Table,
    Input,
    Select,
    Button,
    Space,
    Tag,
    Modal,
    Form,
    message,
    Card,
    Row,
    Col,
    InputNumber,
    Segmented,
    theme,
} from 'antd';
import { useNavigate, useOutletContext } from 'react-router-dom';
import {
    SearchOutlined,
    EditOutlined,
    PlusOutlined,
    FileTextOutlined,
    ReloadOutlined,
    BookOutlined,
    LockOutlined,
    UnlockOutlined,
    EyeOutlined,
    ClockCircleOutlined,
    QuestionCircleOutlined,
    PlusCircleOutlined,
    SafetyCertificateOutlined,
    CheckCircleOutlined,
    UndoOutlined,
    FlagOutlined,
    DeleteOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';

const { Search } = Input;
const { Option } = Select;
import { testApi, complaintApi } from '../services/api';
import { useTheme } from '../hooks/useThemeContext';

interface Exam {
    id: string;
    title: string;
    testType: 'LISTENING' | 'READING';
    difficulty: 'A1_A2' | 'B1_B2' | 'C1';
    duration: number; // in minutes
    totalQuestions: number;
    listeningQuestions: number;
    readingQuestions: number;
    status: 'PENDING' | 'ACTIVE' | 'LOCKED';
    createdAt: string;
    updatedAt: string;
}

export default function ExamBank() {
    const { user } = useOutletContext<{ user: any }>();
    const isAdmin = user?.role === 'ADMIN';
    const isSpecialist = user?.role === 'SPECIALIST';
    const isTeacher = user?.role === 'TEACHER';
    
    // GV and CV can only create and edit
    const canEditOrCreate = isAdmin || isSpecialist || isTeacher;

    const navigate = useNavigate();
    const [exams, setExams] = useState<Exam[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');
    const [difficultyFilter, setDifficultyFilter] = useState<string>('ALL');
    const [statusFilter, setStatusFilter] = useState<string>('ALL');
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [total, setTotal] = useState(0);
    const [editModalVisible, setEditModalVisible] = useState(false);
    const [createModalVisible, setCreateModalVisible] = useState(false);
    const [editingExam, setEditingExam] = useState<Exam | null>(null);
    const [form] = Form.useForm();
    const [createForm] = Form.useForm();
    const [complaintForm] = Form.useForm();

    const [complaintModalVisible, setComplaintModalVisible] = useState(false);
    const [selectedExamForComplaint, setSelectedExamForComplaint] = useState<Exam | null>(null);

    // Statistics
    const [stats, setStats] = useState({
        total: 0,
        pending: 0,
        active: 0,
        locked: 0,
    });

    const { theme: currentTheme } = useTheme();
    const isDark = currentTheme === 'dark';
    const { token } = theme.useToken();

    // Cấu hình bóng đổ hiện đại (Ánh xanh dương cực nhẹ hoặc bóng tối trầm)
    const modernShadow = isDark 
        ? `0 10px 30px -5px rgba(0, 0, 0, 0.5), 0 4px 10px -6px rgba(0, 0, 0, 0.3)`
        : '0 10px 30px -5px rgba(37, 99, 235, 0.08), 0 4px 10px -6px rgba(37, 99, 235, 0.04)';

    const fetchExams = async () => {
        setLoading(true);
        try {
            const data = await testApi.list(page, pageSize, difficultyFilter, statusFilter, searchText);

            if (data.success) {
                const tests = data.data || [];
                setExams(tests);
                setTotal(data.meta.pagination?.total || 0);

                if (data.meta.stats) {
                    setStats({
                        total: data.meta.stats.total || 0,
                        pending: data.meta.stats.pending || 0,
                        active: data.meta.stats.active || 0,
                        locked: data.meta.stats.locked || 0,
                    });
                }
            }
            // Không hiển thị lỗi nếu success: false - table sẽ tự show empty state
        } catch (error) {
            console.error('Error fetching exams:', error);
            // Quietly handle empty/unavailable state
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchExams();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [page, pageSize, difficultyFilter, statusFilter, searchText]);

    const handleSearch = (value: string) => {
        setSearchText(value);
        setPage(1);
    };

    const handleEdit = (exam: Exam) => {
        setEditingExam(exam);
        form.setFieldsValue({
            title: exam.title,
            testType: exam.testType,
            difficulty: exam.difficulty,
            duration: exam.duration,
            totalQuestions: exam.totalQuestions,
            status: exam.status,
        });
        setEditModalVisible(true);
    };

    const handleEditSubmit = async (values: any) => {
        if (!editingExam) return;
        try {
            const data = await testApi.update(editingExam.id, values);
            if (data.success) {
                message.success('Cập nhật thành công');
                setEditModalVisible(false);
                setSearchText('');
                setPage(1);
                fetchExams();
            } else {
                message.error(data.message || 'Cập nhật thất bại');
            }
        } catch (error) {
            console.error('Error updating exam:', error);
            message.error('Có lỗi xảy ra khi cập nhật');
        }
    };

    const handleOpenCreateModal = () => {
        createForm.resetFields();
        createForm.setFieldsValue({
            testType: 'LISTENING',
            difficulty: 'B1_B2',
            status: 'PENDING',
            duration: 120,
            totalQuestions: 100,
        });
        setCreateModalVisible(true);
    };

    const handleCreateSubmit = async (values: any) => {
        try {
            const payload = { ...values, status: values.status || 'PENDING' };
            const data = await testApi.create(payload);
            if (data.success) {
                message.success('Tạo đề thi thành công!');
                setCreateModalVisible(false);
                setSearchText(''); // Clear search
                setPage(1); // Reset about to page 1 for new test
                fetchExams();
            } else {
                message.error(data.message || 'Không thể tạo đề thi');
            }
        } catch (error) {
            console.error('Error creating exam:', error);
            message.error('Có lỗi xảy ra khi tạo đề thi');
        }
    };

    const handleApprove = async (examId: string, examTitle: string) => {
        Modal.confirm({
            title: 'Duyệt đề thi',
            content: `Xác nhận duyệt và xuất bản đề thi "${examTitle}"? Nội dung sẽ hiển thị ngay lập tức trên ứng dụng.`,
            okText: 'Duyệt & Xuất bản',
            okType: 'primary',
            cancelText: 'Hủy',
            onOk: async () => {
                try {
                    const data = await testApi.approveFull(examId);
                    if (data.success) {
                        message.success('Duyệt thành công');
                        fetchExams();
                    } else {
                        message.error(data.message || 'Duyệt thất bại');
                    }
                } catch (error) {
                    console.error('Error approving exam:', error);
                    message.error('Có lỗi xảy ra khi duyệt đề thi');
                }
            },
        });
    };

    const handleToggleStatus = async (examId: string, examTitle: string, currentStatus: string) => {
        const isLocking = currentStatus === 'ACTIVE';
        Modal.confirm({
            title: isLocking ? 'Xác nhận khóa' : 'Xác nhận khôi phục',
            content: isLocking
                ? `Bạn có chắc chắn muốn vô hiệu hóa đề thi "${examTitle}"? (Học viên sẽ không nhìn thấy nữa)`
                : `Bạn có chắc chắn muốn khôi phục đề thi "${examTitle}" về trạng thái hoạt động?`,
            okText: isLocking ? 'Khóa bài' : 'Khôi phục',
            okType: isLocking ? 'danger' : 'primary',
            cancelText: 'Hủy',
            onOk: async () => {
                try {
                    const data = await testApi.toggleLock(examId);
                    if (data.success) {
                        message.success(isLocking ? 'Khóa thành công' : 'Khôi phục thành công');
                        fetchExams();
                    } else {
                        message.error(data.message || 'Thao tác thất bại');
                    }
                } catch (error) {
                    console.error('Error toggling exam status:', error);
                    message.error('Có lỗi xảy ra khi cập nhật trạng thái');
                }
            },
        });
    };

    const handleDeleteExam = async (examId: string, examTitle: string) => {
        Modal.confirm({
            title: 'Xóa đề thi',
            content: `Xác nhận xóa vĩnh viễn đề thi "${examTitle}" và toàn bộ dữ liệu liên quan? Hành động không thể hoàn tác.`,
            okText: 'Xác nhận xóa',
            okType: 'danger',
            cancelText: 'Hủy',
            onOk: async () => {
                try {
                    const data = await testApi.delete(examId);
                    if (data.success) {
                        message.success('Xóa thành công');
                        fetchExams();
                    } else {
                        message.error(data.message || 'Xóa thất bại');
                    }
                } catch (error) {
                    console.error('Error deleting exam:', error);
                    message.error('Có lỗi xảy ra khi xóa đề thi');
                }
            },
        });
    };


    const handleOpenComplaint = (exam: Exam) => {
        setSelectedExamForComplaint(exam);
        complaintForm.resetFields();
        setComplaintModalVisible(true);
    };

    const handleComplaintSubmit = async (values: any) => {
        if (!selectedExamForComplaint) return;
        try {
            const data = await complaintApi.send({
                testId: selectedExamForComplaint.id,
                content: values.content
            });
            if (data.success) {
                message.success('Gửi góp ý thành công!');
                setComplaintModalVisible(false);
            } else {
                message.error(data.message || 'Không thể gửi góp ý');
            }
        } catch (error) {
            console.error('Error sending complaint:', error);
            message.error('Có lỗi xảy ra khi gửi góp ý');
        }
    };

    const columns: ColumnsType<Exam> = [
        {
            title: 'Tên đề thi',
            dataIndex: 'title',
            key: 'title',
            width: 220,
            align: 'center' as const,
            render: (title: string) => (
                <div style={{ fontWeight: 700, color: token.colorText, fontSize: '14px', textAlign: 'center' }}>
                    {title}
                </div>
            ),
        },
        {
            title: 'Loại bài',
            key: 'testType',
            width: 140,
            align: 'center' as const,
            render: (_, record: Exam) => {
                const hasListening = record.listeningQuestions > 0;
                const hasReading = record.readingQuestions > 0;
                let type = 'Luyện tổng hợp';
                let color = 'cyan';
                if (hasListening && !hasReading) { type = 'Listening'; color = 'blue'; }
                else if (!hasListening && hasReading) { type = 'Reading'; color = 'green'; }
                return <Tag color={color} style={{ borderRadius: '6px', fontWeight: 600, padding: '2px 10px' }}>{type}</Tag>;
            },
        },
        {
            title: 'Độ khó',
            dataIndex: 'difficulty',
            key: 'difficulty',
            width: 120,
            align: 'center' as const,
            render: (difficulty: string) => {
                const difficultyConfig: { [key: string]: { color: string; label: string } } = {
                    A1_A2: { color: 'success', label: 'A1-A2' },
                    B1_B2: { color: 'warning', label: 'B1-B2' },
                    C1: { color: 'error', label: 'C1' },
                };
                const config = difficultyConfig[difficulty] || { color: 'default', label: difficulty };
                return <Tag color={config.color} style={{ borderRadius: '6px', fontWeight: 600 }}>{config.label}</Tag>;
            },
        },
        {
            title: 'Thời gian',
            dataIndex: 'duration',
            key: 'duration',
            width: 120,
            align: 'center' as const,
            render: (duration: number) => <span style={{ fontWeight: 600, color: token.colorTextSecondary }}>{duration} phút</span>,
        },
        {
            title: 'Tổng câu hỏi',
            dataIndex: 'totalQuestions',
            key: 'totalQuestions',
            width: 120,
            align: 'center' as const,
            render: (total: number) => <span style={{ fontWeight: 600, color: token.colorTextSecondary }}>{total}</span>,
        },
        {
            title: 'Trạng thái',
            dataIndex: 'status',
            key: 'status',
            width: 140,
            align: 'center' as const,
            render: (status: string) => {
                const statusConfig: { [key: string]: { color: string; label: string; icon: any; bg: string } } = {
                    PENDING: { color: '#D97706', label: 'Chờ duyệt', icon: <ClockCircleOutlined />, bg: isDark ? 'rgba(217, 119, 6, 0.15)' : '#FFFBEB' },
                    ACTIVE: { color: '#059669', label: 'Hoạt động', icon: <UnlockOutlined />, bg: isDark ? 'rgba(5, 150, 105, 0.15)' : '#ECFDF5' },
                    LOCKED: { color: '#DC2626', label: 'Đã khóa', icon: <LockOutlined />, bg: isDark ? 'rgba(220, 38, 38, 0.15)' : '#FEF2F2' },
                };
                const config = statusConfig[status] || { color: 'var(--text-secondary)', label: status, icon: null, bg: 'var(--bg-secondary)' };
                return (
                    <div style={{
                        background: config.bg, color: config.color, padding: '4px 12px',
                        borderRadius: '20px', display: 'inline-flex', alignItems: 'center',
                        fontWeight: 600, gap: '6px', fontSize: '12px', border: `1px solid ${config.color}20`
                    }}>
                        {config.icon} {config.label}
                    </div>
                );
            },
        },
        {
            title: 'Ngày tạo',
            dataIndex: 'createdAt',
            key: 'createdAt',
            width: 120,
            align: 'center' as const,
            render: (date: string) => <span style={{ color: token.colorTextSecondary }}>{new Date(date).toLocaleDateString('vi-VN')}</span>,
        },
        {
            title: 'Hành động',
            key: 'actions',
            width: 180,
            align: 'center' as const,
            render: (_, record) => (
                <Space>
                    <Button
                        type="text"
                        style={{ color: '#2563EB', background: isDark ? 'rgba(37, 99, 235, 0.15)' : '#DBEAFE', borderRadius: '8px' }}
                        icon={<EyeOutlined />}
                        onClick={() => navigate(`/exam-bank/${record.id}`)}
                        title="Xem chi tiết"
                    />
                    {canEditOrCreate && (
                        <Button
                            type="text"
                            style={{ color: '#059669', background: isDark ? 'rgba(5, 150, 105, 0.15)' : '#D1FAE5', borderRadius: '8px' }}
                            icon={<EditOutlined />}
                            onClick={() => handleEdit(record)}
                            title="Chỉnh sửa"
                        />
                    )}
                    {isAdmin && record.status === 'PENDING' && (
                        <Button
                            type="text"
                            style={{ color: '#D97706', background: isDark ? 'rgba(217, 119, 6, 0.15)' : '#FFFBEB', borderRadius: '8px' }}
                            icon={<CheckCircleOutlined />}
                            onClick={() => handleApprove(record.id, record.title)}
                            title="Duyệt bài"
                        />
                    )}
                    {isAdmin && record.status === 'LOCKED' && (
                        <Button
                            type="text"
                            style={{ color: '#2563EB', background: isDark ? 'rgba(37, 99, 235, 0.15)' : '#DBEAFE', borderRadius: '8px' }}
                            icon={<UndoOutlined />}
                            onClick={() => handleToggleStatus(record.id, record.title, record.status)}
                            title="Khôi phục"
                        />
                    )}
                    {isAdmin && record.status === 'ACTIVE' && (
                        <Button
                            type="text"
                            style={{ color: '#DC2626', background: isDark ? 'rgba(220, 38, 38, 0.15)' : '#FEE2E2', borderRadius: '8px' }}
                            icon={<LockOutlined />}
                            onClick={() => handleToggleStatus(record.id, record.title, record.status)}
                            title="Khóa bài"
                        />
                    )}
                    {isAdmin && (
                        <Button
                            type="text"
                            style={{ color: '#DC2626', background: isDark ? 'rgba(220, 38, 38, 0.15)' : '#FEE2E2', borderRadius: '8px' }}
                            icon={<DeleteOutlined />}
                            onClick={() => handleDeleteExam(record.id, record.title)}
                            title="Xóa đề thi"
                        />
                    )}

                    {user?.role === 'TEACHER' && (
                         <Button
                            type="text"
                            style={{ color: '#D97706', background: isDark ? 'rgba(217, 119, 6, 0.15)' : '#FEF3C7', borderRadius: '8px' }}
                            icon={<FlagOutlined />}
                            onClick={() => handleOpenComplaint(record)}
                            title="Góp ý bài thi"
                        />
                    )}
                </Space>
            ),
        },
    ];

    return (
        // Đổi màu nền wrapper thành xám nhạt để làm nổi bật các Card màu trắng
        <div style={{ padding: '24px', background: token.colorBgLayout, minHeight: '100vh' }}>

            {/* Statistics Cards */}
            <Row gutter={24} style={{ marginBottom: 32 }}>
                {[
                    { title: 'Tổng đề thi', value: stats.total, icon: <BookOutlined />, color: '#3B82F6', bg: isDark ? 'rgba(59, 130, 246, 0.1)' : '#EFF6FF' },
                    { title: 'Chờ duyệt', value: stats.pending, icon: <ClockCircleOutlined />, color: '#D97706', bg: isDark ? 'rgba(217, 119, 6, 0.1)' : '#FFFBEB' },
                    { title: 'Hoạt động', value: stats.active, icon: <UnlockOutlined />, color: '#10B981', bg: isDark ? 'rgba(16, 185, 129, 0.1)' : '#ECFDF5' },
                    { title: 'Đang khóa', value: stats.locked, icon: <LockOutlined />, color: '#EF4444', bg: isDark ? 'rgba(239, 68, 68, 0.1)' : '#FEF2F2' },
                ].map((item, index) => (
                    <Col xs={24} sm={12} md={6} key={index}>
                        <Card
                            hoverable
                            style={{
                                borderRadius: 24,
                                border: `1px solid ${token.colorBorder}`,
                                background: token.colorBgContainer,
                                boxShadow: modernShadow,
                                transition: 'all 0.3s ease'
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
                                    boxShadow: 'inset 0 2px 4px rgba(255,255,255,0.5)'
                                }}>
                                    {item.icon}
                                </div>
                                <div>
                                    <div style={{ fontWeight: 700, color: token.colorTextSecondary, textTransform: 'uppercase', fontSize: 13, letterSpacing: '0.5px', marginBottom: 4 }}>
                                        {item.title}
                                    </div>
                                    <div style={{ color: token.colorText, fontWeight: 800, fontSize: 32, lineHeight: 1 }}>
                                        {item.value}
                                    </div>
                                </div>
                            </div>
                        </Card>
                    </Col>
                ))}
            </Row>

            {/* Primary Action */}
            {canEditOrCreate && (
                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'flex-start' }}>
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={handleOpenCreateModal}
                        size="large"
                        style={{
                            borderRadius: 12,
                            fontWeight: 600,
                            height: 48,
                            padding: '0 24px',
                            background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                            border: 'none',
                            boxShadow: '0 4px 14px rgba(37, 99, 235, 0.35)',
                        }}
                    >
                        Thêm đề thi mới
                    </Button>
                </div>
            )}

            {/* Actions & Filters */}
            <Card
                style={{
                    marginBottom: 24,
                    borderRadius: 20,
                    border: `1px solid ${token.colorBorder}`,
                    background: token.colorBgContainer,
                    boxShadow: modernShadow
                }}
                bodyStyle={{ padding: '20px 24px' }}
            >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 16 }}>
                    <Space size="small">
                        <Search
                            placeholder="Tìm kiếm..."
                            allowClear
                            onSearch={handleSearch}
                            style={{ width: 320 }}
                            size="large"
                            prefix={<SearchOutlined style={{ color: 'var(--text-muted)' }} />}
                        />
                        <Select
                            size="large"
                            value={difficultyFilter}
                            onChange={(value) => {
                                setDifficultyFilter(value);
                            }}
                            style={{ width: 130 }}
                            dropdownStyle={{ borderRadius: '12px' }}
                        >
                            <Option value="ALL">Mức độ</Option>
                            <Option value="A1_A2">A1-A2</Option>
                            <Option value="B1_B2">B1-B2</Option>
                            <Option value="C1">C1</Option>
                        </Select>
                        <Segmented
                            size="large"
                            value={statusFilter}
                            onChange={(value) => {
                                setStatusFilter(value as string);
                            }}
                            options={[
                                { label: 'Tất cả', value: 'ALL' },
                                { label: 'Chờ', value: 'PENDING' },
                                { label: 'Hiện', value: 'ACTIVE' },
                                { label: 'Khóa', value: 'LOCKED' },
                            ]}
                            style={{
                                borderRadius: '12px',
                                padding: '4px',
                                background: 'var(--bg-secondary)',
                                fontWeight: 600,
                                fontSize: '13px',
                                boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.05)',
                                color: 'var(--text-secondary)'
                            }}
                        />
                        <Button
                            size="large"
                            icon={<ReloadOutlined />}
                            onClick={fetchExams}
                            loading={loading}
                            style={{ borderRadius: '10px', color: 'var(--text-secondary)', fontWeight: 600 }}
                        />
                    </Space>
                </div>
            </Card>

            {/* Table */}
            <Card
                style={{
                    borderRadius: 20,
                    border: `1px solid ${token.colorBorderSecondary}`, // Dùng border nhẹ hơn
                    boxShadow: modernShadow,
                    overflow: 'hidden',
                    background: token.colorBgContainer
                }}
                bodyStyle={{ padding: 0 }}
            >
                <Table
                    columns={columns}
                    dataSource={exams}
                    rowKey="id"
                    loading={loading}
                    className="premium-table"
                    pagination={{
                        current: page,
                        pageSize: pageSize,
                        total: total,
                        showSizeChanger: true,
                        showTotal: (total) => <span style={{ fontWeight: 600, color: token.colorTextSecondary }}>Tổng {total} đề thi</span>,
                        onChange: (page, pageSize) => {
                            setPage(page);
                            setPageSize(pageSize);
                        },
                        style: { 
                            padding: '16px 24px', 
                            margin: 0, 
                            borderTop: `1px solid ${token.colorBorderSecondary}`,
                            background: isDark ? 'transparent' : '#F8FAFC' // Tạo dải màu nhẹ ở chân card cho chuyên nghiệp
                        }
                    }}
                    style={{ background: 'transparent' }}
                />
            </Card>

            <style>{`
                .premium-table .ant-table {
                    background: transparent !important;
                }
                .premium-table .ant-table-container {
                    border-radius: 20px !important;
                }
                .premium-table .ant-table-thead > tr > th {
                    background: ${isDark ? '#1E293B' : '#F8FAFC'} !important;
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                }
                /* Sửa lỗi màu nền cho cột cố định (Hành động) */
                .premium-table .ant-table-cell-fix-right,
                .premium-table .ant-table-cell-fix-left {
                    background: inherit !important;
                }
                .premium-table .ant-table-thead > tr > th.ant-table-cell-fix-right {
                    background: ${isDark ? '#1E293B' : '#F8FAFC'} !important;
                }
                .premium-table .ant-table-tbody > tr > td {
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                }
                .premium-table .ant-table-tbody > tr:last-child > td {
                    border-bottom: none !important;
                }
                /* Khử bo góc mặc định của AntD để khớp với Card */
                .premium-table .ant-table-container,
                .premium-table .ant-table-content,
                .premium-table table {
                    border-radius: 20px !important;
                }
            `}</style>

            {/* Edit Modal */}
            <Modal
                title={
                    <Space style={{ marginBottom: 8 }}>
                        <div style={{
                            width: 36,
                            height: 36,
                            borderRadius: 10,
                            background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#fff',
                            fontSize: 18,
                            boxShadow: '0 4px 10px rgba(16, 185, 129, 0.2)'
                        }}>
                            <EditOutlined />
                        </div>
                        <span style={{ fontSize: 20, color: token.colorText, fontWeight: 800 }}>Chỉnh sửa đề thi</span>
                    </Space>
                }
                open={editModalVisible}
                onCancel={() => setEditModalVisible(false)}
                onOk={() => form.submit()}
                okText="Lưu thay đổi"
                cancelText="Hủy"
                width={850}
                centered
                okButtonProps={{
                    style: {
                        borderRadius: 10,
                        background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                        border: 'none',
                        height: 40,
                        padding: '0 24px',
                        fontWeight: 600,
                        boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)'
                    }
                }}
                cancelButtonProps={{ style: { borderRadius: 10, height: 40 } }}
            >
                <Form form={form} layout="vertical" onFinish={handleEditSubmit} style={{ marginTop: 24 }}>
                    <Row gutter={24}>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Tên đề thi</span>} name="title" rules={[{ required: true, message: 'Vui lòng nhập tên đề thi' }]}>
                                <Input size="large" prefix={<FileTextOutlined style={{ color: '#94A3B8' }} />} style={{ borderRadius: 10 }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Loại bài thi</span>} name="testType" rules={[{ required: true, message: 'Vui lòng chọn loại bài' }]}>
                                <Select size="large" style={{ borderRadius: 10 }} suffixIcon={<QuestionCircleOutlined style={{ color: '#94A3B8' }} />}>
                                    <Option value="LISTENING">Listening</Option>
                                    <Option value="READING">Reading</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={24}>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Độ khó</span>} name="difficulty" rules={[{ required: true, message: 'Vui lòng chọn độ khó' }]}>
                                <Select size="large" style={{ borderRadius: 10 }} suffixIcon={<SafetyCertificateOutlined style={{ color: '#94A3B8' }} />}>
                                    <Option value="A1_A2">A1-A2</Option>
                                    <Option value="B1_B2">B1-B2</Option>
                                    <Option value="C1">C1</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            {isAdmin && (
                                <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Trạng thái hiển thị</span>} name="status" rules={[{ required: true, message: 'Vui lòng chọn trạng thái' }]}>
                                    <Select size="large" style={{ borderRadius: 10 }}>
                                        <Option value="PENDING">Chờ duyệt</Option>
                                        <Option value="ACTIVE">Hoạt động</Option>
                                        <Option value="LOCKED">Đã khóa</Option>
                                    </Select>
                                </Form.Item>
                            )}
                        </Col>
                    </Row>

                    <Row gutter={24}>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Thời gian làm bài (phút)</span>} name="duration" rules={[{ required: true, message: 'Vui lòng nhập thời gian' }]}>
                                <InputNumber size="large" min={1} prefix={<ClockCircleOutlined style={{ color: '#94A3B8' }} />} style={{ width: '100%', borderRadius: 10 }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Tổng số câu hỏi</span>} name="totalQuestions" rules={[{ required: true, message: 'Vui lòng nhập tổng câu hỏi' }]}>
                                <InputNumber size="large" min={1} prefix={<BookOutlined style={{ color: '#94A3B8' }} />} style={{ width: '100%', borderRadius: 10 }} />
                            </Form.Item>
                        </Col>
                    </Row>
                </Form>
            </Modal>

            {/* Create Modal */}
            <Modal
                title={
                    <Space style={{ marginBottom: 8 }}>
                        <div style={{
                            width: 36,
                            height: 36,
                            borderRadius: 10,
                            background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#fff',
                            fontSize: 18,
                            boxShadow: '0 4px 10px rgba(37, 99, 235, 0.2)'
                        }}>
                            <PlusCircleOutlined />
                        </div>
                        <span style={{ fontSize: 20, color: token.colorText, fontWeight: 800 }}>Tạo đề thi mới</span>
                    </Space>
                }
                open={createModalVisible}
                onCancel={() => setCreateModalVisible(false)}
                onOk={() => createForm.submit()}
                okText="Tạo đề thi"
                cancelText="Hủy"
                width={850}
                centered
                okButtonProps={{
                    style: {
                        borderRadius: 10,
                        background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                        border: 'none',
                        height: 40,
                        padding: '0 24px',
                        fontWeight: 600,
                        boxShadow: '0 4px 14px rgba(37, 99, 235, 0.35)'
                    }
                }}
                cancelButtonProps={{ style: { borderRadius: 10, height: 40 } }}
            >
                <Form form={createForm} layout="vertical" onFinish={handleCreateSubmit} style={{ marginTop: 24 }}>
                    <Row gutter={24}>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Tên đề thi</span>} name="title" rules={[{ required: true, message: 'Vui lòng nhập tên đề thi' }]}>
                                <Input size="large" placeholder="Ví dụ: TOEIC-TEST 1" prefix={<FileTextOutlined style={{ color: '#94A3B8' }} />} style={{ borderRadius: 10 }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Loại bài thi</span>} name="testType" rules={[{ required: true, message: 'Vui lòng chọn loại bài' }]}>
                                <Select size="large" style={{ borderRadius: 10 }} suffixIcon={<QuestionCircleOutlined style={{ color: '#94A3B8' }} />}>
                                    <Option value="LISTENING">Listening (Nghe)</Option>
                                    <Option value="READING">Reading (Đọc)</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={24}>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Độ khó</span>} name="difficulty" rules={[{ required: true, message: 'Vui lòng chọn độ khó' }]}>
                                <Select size="large" style={{ borderRadius: 10 }} suffixIcon={<SafetyCertificateOutlined style={{ color: '#94A3B8' }} />}>
                                    <Option value="A1_A2">A1-A2</Option>
                                    <Option value="B1_B2">B1-B2</Option>
                                    <Option value="C1">C1</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Thời gian làm bài (phút)</span>} name="duration" rules={[{ required: true, message: 'Vui lòng nhập thời gian' }]}>
                                <InputNumber size="large" min={1} placeholder="120" prefix={<ClockCircleOutlined style={{ color: '#94A3B8' }} />} style={{ width: '100%', borderRadius: 10 }} />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={24}>
                        <Col span={12}>
                            <Form.Item label={<span style={{ fontWeight: 600, color: '#475569' }}>Tổng số câu hỏi</span>} name="totalQuestions" rules={[{ required: true, message: 'Vui lòng nhập tổng câu hỏi' }]}>
                                <InputNumber size="large" min={1} placeholder="200" prefix={<BookOutlined style={{ color: '#94A3B8' }} />} style={{ width: '100%', borderRadius: 10 }} />
                            </Form.Item>
                        </Col>
                    </Row>
                </Form>
            </Modal>

            {/* Complaint Modal */}
            <Modal
                title={
                    <Space style={{ marginBottom: 8 }}>
                        <div style={{
                            width: 36,
                            height: 36,
                            borderRadius: 10,
                            background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#fff',
                            fontSize: 18,
                            boxShadow: '0 4px 10px rgba(245, 158, 11, 0.2)'
                        }}>
                            <FlagOutlined />
                        </div>
                        <span style={{ fontSize: 20, color: token.colorText, fontWeight: 800 }}>Góp ý sai sót bài thi</span>
                    </Space>
                }
                open={complaintModalVisible}
                onCancel={() => setComplaintModalVisible(false)}
                onOk={() => complaintForm.submit()}
                okText="Gửi góp ý"
                cancelText="Hủy"
                width={600}
                centered
                okButtonProps={{
                    style: {
                        borderRadius: 10,
                        background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
                        border: 'none',
                        height: 40,
                        padding: '0 24px',
                        fontWeight: 600,
                        boxShadow: '0 4px 14px rgba(245, 158, 11, 0.35)'
                    }
                }}
                cancelButtonProps={{ style: { borderRadius: 10, height: 40 } }}
            >
                <div style={{ marginBottom: 20, padding: '12px 16px', background: isDark ? '#334155' : '#FEF3C7', borderRadius: 12, border: '1px solid #F59E0B40' }}>
                    <div style={{ fontWeight: 600, color: '#B45309', marginBottom: 4 }}>📌 Bài thi: {selectedExamForComplaint?.title}</div>
                    <div style={{ fontSize: 13, color: '#92400E' }}>
                        Góp ý của bạn sẽ được gửi trực tiếp đến Chuyên viên và Admin để xem xét và sửa lỗi.
                    </div>
                </div>

                <Form form={complaintForm} layout="vertical" onFinish={handleComplaintSubmit}>
                    <Form.Item 
                        label={<span style={{ fontWeight: 600 }}>Nội dung góp ý chi tiết</span>} 
                        name="content" 
                        rules={[{ required: true, message: 'Vui lòng nhập nội dung góp ý' }]}
                    >
                        <Input.TextArea 
                            rows={5} 
                            placeholder="Ví dụ: Câu 147 đáp án A mới là đúng, hoặc Audio Part 1 bị rè..."
                            style={{ borderRadius: 12 }}
                        />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}