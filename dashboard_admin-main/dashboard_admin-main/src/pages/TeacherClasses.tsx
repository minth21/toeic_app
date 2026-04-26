import React, { useState, useEffect } from 'react';
import {
    Table, Card, Button, Input, Space, Tag, Typography,
    Row, Col, Statistic, Progress, Drawer, Tabs,
    Avatar, message, Divider, Modal
} from 'antd';
import {
    SearchOutlined, UserOutlined, BookOutlined,
    HistoryOutlined,
    BulbOutlined, EditOutlined, SaveOutlined,
    PlusOutlined, DeleteOutlined, SendOutlined, TeamOutlined, DownloadOutlined, EyeOutlined, ReloadOutlined, CommentOutlined
} from '@ant-design/icons';
import { useForm, useFieldArray, Controller } from 'react-hook-form';
import { classApi, teacherApi, aiApi } from '../services/api';
import type { Class } from '../services/api';
import { useTheme } from '../hooks/useThemeContext';
import AiTimelineView from '../components/AiTimelineView';

const { Search } = Input;

export default function TeacherClasses() {
    const [classes, setClasses] = useState<Class[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');

    const [drawerVisible, setDrawerVisible] = useState(false);
    const [selectedClass, setSelectedClass] = useState<Class | null>(null);
    const [students, setStudents] = useState<any[]>([]);
    const [loadingStudents, setLoadingStudents] = useState(false);

    const [historyVisible, setHistoryVisible] = useState(false);
    const [selectedStudent, setSelectedStudent] = useState<any>(null);
    const [studentHistory, setStudentHistory] = useState<any[]>([]);
    const [loadingHistory, setLoadingHistory] = useState(false);
    const [activeHistoryTab, setActiveHistoryTab] = useState('1');

    const [selectedRoadmapId, setSelectedRoadmapId] = useState<string | null>(null);
    const [currentRoadmap, setCurrentRoadmap] = useState<any>(null);
    const [roadmapRefreshTrigger, setRoadmapRefreshTrigger] = useState(0);
    const [publishing, setPublishing] = useState(false);
    const [savingDraft, setSavingDraft] = useState(false);
    const [teacherNote, setTeacherNote] = useState('');
    const [analyzingRoadmap, setAnalyzingRoadmap] = useState(false);
    
    // States cho gửi ý kiến chủ động
    const [opinionModalVisible, setOpinionModalVisible] = useState(false);
    const [opinionContent, setOpinionContent] = useState('');
    const [sendingOpinion, setSendingOpinion] = useState(false);

    // Tính toán thống kê
    const stats = {
        totalClasses: classes.length,
        totalStudents: classes.reduce((acc: number, c: Class) => acc + (c.studentCount || 0), 0)
    };

    // Lọc lớp học theo tìm kiếm
    const filteredClasses = classes.filter(c =>
        c.className.toLowerCase().includes(searchText.toLowerCase()) ||
        (c.classCode && c.classCode.toLowerCase().includes(searchText.toLowerCase()))
    );

    const { control, handleSubmit, reset } = useForm({
        defaultValues: {
            summary: '',
            roadmap: [] as any[]
        }
    });

    const { fields, append, remove } = useFieldArray({
        control,
        name: "roadmap"
    });

    const [attemptModalVisible, setAttemptModalVisible] = useState(false);
    const [selectedAttempt, setSelectedAttempt] = useState<any>(null);
    const [loadingAttempt, setLoadingAttempt] = useState(false);

    useEffect(() => {
        fetchMyClasses();
    }, []);

    const theme = useTheme();
    const isDark = theme.theme === 'dark';

    const fetchMyClasses = async () => {
        setLoading(true);
        try {
            const response = await classApi.getMyClasses();
            if (response.success) {
                setClasses(response.data);
            } else {
                message.error('Không thể tải danh sách lớp học');
            }
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi tải danh sách lớp học');
        } finally {
            setLoading(false);
        }
    };

    const handleViewStudents = async (record: Class) => {
        setSelectedClass(record);
        setDrawerVisible(true);
        setLoadingStudents(true);
        try {
            const response = await classApi.getStudents(record.id);
            if (response.success) {
                setStudents(response.data);
            } else {
                message.error('Không thể tải danh sách học viên');
            }
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi tải danh sách học viên');
        } finally {
            setLoadingStudents(false);
        }
    };

    const handleViewHistory = async (student: any) => {
        setSelectedStudent(student);
        setHistoryVisible(true);
        setLoadingHistory(true);
        setActiveHistoryTab('1');
        try {
            // Reset form và roadmap state trước khi load học viên mới
            reset({
                summary: '',
                roadmap: []
            });
            setSelectedRoadmapId(null);
            setCurrentRoadmap(null);
            setTeacherNote('');

            const response = await teacherApi.getStudentProgress(student.id);
            if (response.success) {
                setStudentHistory(response.data);
            } else {
                message.error('Không thể tải lịch sử làm bài');
            }
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi tải lịch sử làm bài');
        } finally {
            setLoadingHistory(false);
        }
    };

    const handlePublishRoadmap = async (data: any) => {
        if (!selectedRoadmapId) return;
        setPublishing(true);
        try {
            const res = await aiApi.submitRoadmap(selectedRoadmapId, {
                teacherNote,
                summary: data.summary,
                content: {
                    ...currentRoadmap?.content,
                    summary: data.summary,
                    roadmap: data.roadmap.map((r: any) => ({
                        ...r,
                        focus: typeof r.focus === 'string' ? r.focus.split(',').map((s: string) => s.trim()).filter((s: string) => s !== '') : r.focus
                    }))
                }
            });
            if (res.success) {
                message.success('Đã gửi yêu cầu phê duyệt cho Admin thành công!');
                setSelectedRoadmapId(null);
                setRoadmapRefreshTrigger(prev => prev + 1);
            }
        } catch (error) {
            message.error('Lỗi khi gửi lộ trình');
        } finally {
            setPublishing(false);
        }
    };

    const handleViewAttemptDetail = async (attemptId: string) => {
        setLoadingAttempt(true);
        setAttemptModalVisible(true);
        try {
            const response = await teacherApi.getAttemptDetail(attemptId);
            if (response.success) {
                setSelectedAttempt(response.data);
            } else {
                message.error('Không thể tải chi tiết bài làm');
            }
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi tải chi tiết bài làm');
        } finally {
            setLoadingAttempt(false);
        }
    };

    const handleGenerateRoadmap = async (userId: string) => {
        setAnalyzingRoadmap(true);
        // Reset sạch sẽ dữ liệu cũ của học viên trước đó
        setSelectedRoadmapId(null);
        setCurrentRoadmap(null);
        setTeacherNote('');
        reset({ summary: '', roadmap: [] });

        try {
            const response = await aiApi.assessRoadmap(userId);
            if (response.success) {
                message.success('Phân tích lộ trình thành công!');
                setRoadmapRefreshTrigger(prev => prev + 1);
                setActiveHistoryTab('2');
            } else {
                message.error(response.message || 'Lỗi khi phân tích lộ trình');
            }
        } catch (error: any) {
            message.error(error.response?.data?.message || 'Lỗi khi gọi AI');
        } finally {
            setAnalyzingRoadmap(false);
        }
    };

    const openOpinionModal = (student: any) => {
        setSelectedStudent(student);
        setOpinionContent('');
        setOpinionModalVisible(true);
    };

    const handleSendOpinion = async () => {
        if (!selectedStudent || !opinionContent.trim() || !selectedClass) return;
        setSendingOpinion(true);
        try {
            const { feedbackApi } = await import('../services/api');
            const res = await feedbackApi.sendTeacherOpinion({
                userId: selectedStudent.id,
                classId: selectedClass.id,
                content: opinionContent.trim()
            });
            if (res.success) {
                message.success('Đã gửi nhận xét tới học viên thành công!');
                setOpinionModalVisible(false);
            }
        } catch (error) {
            message.error('Lỗi khi gửi nhận xét');
        } finally {
            setSendingOpinion(false);
        }
    };

    const handleSaveDraft = async (data: any) => {
        if (!selectedRoadmapId) return;
        setSavingDraft(true);
        try {
            const res = await aiApi.updateRoadmap(selectedRoadmapId, {
                teacherNote,
                summary: data.summary,
                content: {
                    ...currentRoadmap?.content,
                    summary: data.summary,
                    roadmap: data.roadmap.map((r: any) => ({
                        ...r,
                        focus: typeof r.focus === 'string' ? r.focus.split(',').map((s: string) => s.trim()).filter((s: string) => s !== '') : r.focus
                    }))
                }
            });
            if (res.success) {
                message.success('Lưu bản nháp thành công!');
                setRoadmapRefreshTrigger(prev => prev + 1);
            }
        } catch (error) {
            message.error('Lỗi khi lưu bản nháp');
        } finally {
            setSavingDraft(false);
        }
    };

    const handleExportStudentPdf = async (studentId: string, studentName: string) => {
        try {
            const hide = message.loading('Đang khởi tạo tệp PDF...', 0);
            const { teacherApi } = await import('../services/api');
            const blob = await teacherApi.exportStudentHistoryPdf(studentId);
            hide();

            const url = window.URL.createObjectURL(new Blob([blob]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Báo_cáo_${studentName.replace(/\s+/g, '_')}.pdf`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            message.success('Xuất file PDF thành công');
        } catch (error) {
            message.error('Lỗi khi xuất file PDF');
        }
    };

    const handleExportExcel = async (classId: string, className: string) => {
        try {
            const messageHide = message.loading('Đang xuất file Excel...', 0);
            const blob = await classApi.exportClassPerformance(classId);
            messageHide();

            // Create a link and trigger download
            const url = window.URL.createObjectURL(new Blob([blob]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Báo_cáo_lớp_${className.replace(/\s+/g, '_')}.xlsx`);
            document.body.appendChild(link);
            link.click();

            // Cleanup
            link.parentNode?.removeChild(link);
            window.URL.revokeObjectURL(url);

            message.success('Xuất file Excel thành công!');
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi xuất file Excel');
        }
    };

    const classColumns = [
        {
            title: 'STT',
            key: 'index',
            width: 70,
            render: (_: any, __: any, index: number) => index + 1,
        },
        {
            title: 'Mã lớp',
            dataIndex: 'classCode',
            key: 'classCode',
            render: (text: string) => <Tag color="blue">{text}</Tag>,
        },
        {
            title: 'Tên lớp',
            dataIndex: 'className',
            key: 'className',
            render: (text: string) => <strong style={{ color: 'var(--text-primary)' }}>{text}</strong>,
        },
        {
            title: 'Sĩ số',
            dataIndex: 'studentCount',
            key: 'studentCount',
            render: (count: number) => (
                <Space>
                    <TeamOutlined style={{ color: '#10B981' }} />
                    <span style={{ fontWeight: 600 }}>{count || 0} học viên</span>
                </Space>
            ),
        },
        {
            title: 'Ngày tạo',
            dataIndex: 'createdAt',
            key: 'createdAt',
            render: (date: string) => new Date(date).toLocaleDateString('vi-VN'),
        },
        {
            title: 'Hành động',
            key: 'action',
            render: (_: any, record: Class) => (
                <Space size="middle">
                    <Button
                        type="primary"
                        icon={<EyeOutlined />}
                        onClick={() => handleViewStudents(record)}
                        style={{
                            borderRadius: 6,
                            background: 'linear-gradient(135deg, #3B82F6 0%, #2563EB 100%)',
                            border: 'none',
                            boxShadow: '0 4px 14px rgba(59, 130, 246, 0.35)',
                            fontWeight: 600
                        }}
                    >
                        Xem học viên
                    </Button>
                    <Button
                        icon={<DownloadOutlined />}
                        onClick={() => handleExportExcel(record.id, record.className)}
                        style={{
                            borderRadius: 6,
                            borderColor: '#10B981',
                            color: '#10B981',
                            boxShadow: 'var(--card-shadow)',
                            fontWeight: 600
                        }}
                    >
                        Tải Excel
                    </Button>
                </Space>
            ),
        },
    ];

    const studentColumns = [
        {
            title: 'STT',
            key: 'index',
            width: 60,
            render: (_: any, __: any, index: number) => index + 1,
        },
        {
            title: 'Mã HV',
            key: 'username',
            width: 120,
            render: (record: any) => (
                <Tag color="blue" style={{ borderRadius: 6, fontWeight: 500, border: 'none', padding: '2px 10px' }}>
                    {record.username || record.user?.username || '-'}
                </Tag>
            )
        },
        {
            title: 'Họ và tên',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{text}</span>
        },
        {
            title: 'Mục tiêu',
            dataIndex: 'targetScore',
            key: 'targetScore',
            align: 'center' as const,
            render: (val: number) => <Tag color="cyan" style={{ fontWeight: 600 }}>{val || '-'}</Tag>
        },
        {
            title: 'Điểm tổng',
            dataIndex: 'estimatedScore',
            key: 'estimatedScore',
            align: 'center' as const,
            render: (val: number) => <Tag color="volcano" style={{ fontWeight: 800 }}>{val || 0}</Tag>
        },
        {
            title: 'Gap',
            key: 'gap',
            align: 'center' as const,
            render: (record: any) => {
                const target = record.targetScore || 0;
                const estimated = record.estimatedScore || 0;
                const attempts = record._count?.testAttempts || record.totalAttempts || 0;

                if (target === 0) return <Tag color="default">Chưa đặt mục tiêu</Tag>;
                if (attempts === 0) return <Tag color="blue" style={{ fontWeight: 600 }}>CHƯA LÀM</Tag>;

                const gap = target - estimated;
                return gap > 0 ? (
                    <Tag color="orange" style={{ fontWeight: 600 }}>-{gap}</Tag>
                ) : (
                    <Tag color="green" style={{ fontWeight: 600 }}>PASS</Tag>
                );
            }
        },
        {
            title: 'Số bài làm',
            key: 'totalAttempts',
            align: 'center' as const,
            render: (record: any) => <Tag color="blue">{record._count?.testAttempts || record.totalAttempts || 0}</Tag>
        },
        {
            title: 'Hành động',
            key: 'action',
            width: 220,
            render: (record: any) => (
                <Space>
                    <Button
                        type="link"
                        icon={<EyeOutlined />}
                        onClick={() => handleViewHistory(record)}
                        style={{ fontWeight: 500 }}
                    >
                        Lịch sử
                    </Button>
                    <Button
                        type="link"
                        icon={<CommentOutlined />}
                        onClick={() => openOpinionModal(record)}
                        style={{ fontWeight: 500, color: '#10B981' }}
                    >
                        Gửi ý kiến
                    </Button>
                </Space>
            )
        }
    ];

    const historyColumns = [
        {
            title: 'Ngày làm',
            dataIndex: 'createdAt',
            key: 'createdAt',
            render: (date: string) => new Date(date).toLocaleString('vi-VN'),
        },
        {
            title: 'Loại bài',
            key: 'testType',
            render: (record: any) => record.test?.title || record.part?.partName || 'Luyện tập lẻ'
        },
        {
            title: 'Số câu đúng',
            key: 'score',
            align: 'center' as const,
            render: (record: any) => `${record.correctCount}/${record.totalQuestions}`
        },
        {
            title: 'Điểm',
            dataIndex: 'totalScore',
            key: 'totalScore',
            align: 'center' as const,
            render: (val: number) => <Tag color="blue" style={{ fontWeight: 'bold' }}>{val || 0}</Tag>
        },
        {
            title: 'Hành động',
            key: 'action',
            width: 120,
            align: 'center' as const,
            render: (record: any) => (
                <Button
                    type="link"
                    icon={<EyeOutlined />}
                    onClick={() => handleViewAttemptDetail(record.id)}
                >
                    Chi tiết
                </Button>
            )
        }
    ];

    return (
        <div style={{ padding: '24px', background: 'var(--bg-primary)', minHeight: '100vh' }}>


            {/* Statistics Cards */}
            <Row gutter={24} style={{ marginBottom: 32 }} justify="center">
                {[
                    { title: 'Tổng số lớp dạy', value: stats.totalClasses, icon: <TeamOutlined />, color: '#1D4ED8', bg: 'linear-gradient(135deg, #DBEAFE 0%, #EFF6FF 100%)' },
                    { title: 'Tổng số học viên', value: stats.totalStudents, icon: <BookOutlined />, color: '#047857', bg: 'linear-gradient(135deg, #D1FAE5 0%, #ECFDF5 100%)' },
                ].map((item, index) => (
                    <Col xs={24} sm={12} md={8} key={index}>
                        <Card
                            hoverable
                            style={{
                                borderRadius: 24,
                                border: 'none',
                                background: 'var(--bg-surface)',
                                boxShadow: 'var(--card-shadow)',
                                transition: 'all 0.3s ease'
                            }}
                            styles={{ body: { padding: '24px' } }}
                        >
                            <div style={{ display: 'flex', alignItems: 'center', gap: 20, justifyContent: 'center' }}>
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
                                <div style={{ textAlign: 'center' }}>
                                    <div style={{ fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', fontSize: 12, letterSpacing: '0.5px', marginBottom: 4 }}>
                                        {item.title}
                                    </div>
                                    <div style={{ color: 'var(--text-primary)', fontWeight: 700, fontSize: 28, lineHeight: 1 }}>
                                        {item.value}
                                    </div>
                                </div>
                            </div>
                        </Card>
                    </Col>
                ))}
            </Row>

            {/* Actions & Search Card */}
            <Card
                style={{
                    marginBottom: 24,
                    borderRadius: 20,
                    border: 'none',
                    background: isDark ? '#1E293B' : '#FFFFFF',
                    boxShadow: 'var(--card-shadow)'
                }}
                styles={{ body: { padding: '20px 24px' } }}
            >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 16 }}>
                    <Search
                        placeholder="Tìm theo tên lớp hoặc mã lớp"
                        allowClear
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchText(e.target.value)}
                        style={{ width: 400 }}
                        size="large"
                        prefix={<SearchOutlined style={{ color: 'var(--text-muted)' }} />}
                    />
                    <Button
                        size="large"
                        icon={<ReloadOutlined />}
                        onClick={fetchMyClasses}
                        loading={loading}
                        style={{
                            borderRadius: 10,
                            fontWeight: 600,
                            border: '1px solid var(--border-color)',
                            boxShadow: 'var(--card-shadow)'
                        }}
                    >
                        Làm mới
                    </Button>
                </div>
            </Card>

            {/* Table Card */}
            <Card style={{ borderRadius: 24, border: 'none', boxShadow: 'var(--card-shadow)', overflow: 'hidden', background: 'var(--bg-surface)' }} styles={{ body: { padding: 0 } }}>
                <Table
                    columns={classColumns}
                    dataSource={filteredClasses}
                    rowKey="id"
                    loading={loading}
                    pagination={{ pageSize: 10 }}
                    size="large"
                />
            </Card>

            {/* Drawer danh sách học viên */}
            <Drawer
                title={
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                        <span>Học viên lớp: <strong style={{ color: '#2563EB' }}>{selectedClass?.className}</strong></span>
                        <Button
                            type="primary"
                            icon={<DownloadOutlined />}
                            onClick={() => selectedClass && handleExportExcel(selectedClass.id, selectedClass.className)}
                            style={{
                                background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                                border: 'none',
                                borderRadius: 8,
                                marginRight: 24,
                                height: 40,
                                fontWeight: 600,
                                boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)'
                            }}
                        >
                            Xuất file  Excel lớp
                        </Button>
                    </div>
                }
                placement="right"
                size="large"
                onClose={() => setDrawerVisible(false)}
                open={drawerVisible}
                styles={{ header: { borderBottom: '1px solid #F1F5F9' } }}
            >
                <Tabs
                    defaultActiveKey="students"
                    items={[
                        {
                            key: 'students',
                            label: (
                                <Space>
                                    <TeamOutlined />
                                    <span>Học viên ({students.length})</span>
                                </Space>
                            ),
                            children: (
                                <Table
                                    columns={studentColumns}
                                    dataSource={students}
                                    rowKey="id"
                                    loading={loadingStudents}
                                    pagination={false}
                                    size="middle"
                                    style={{ marginTop: 16 }}
                                />
                            )
                        },
                    ]}
                />
            </Drawer>

            {/* Drawer lịch sử chi tiết học viên */}
            <Drawer
                title={
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                        <Space size="middle">
                            <Avatar src={selectedStudent?.avatarUrl} icon={<UserOutlined />} />
                            <div>
                                <div style={{ fontSize: 16, fontWeight: 700 }}>{selectedStudent?.name}</div>
                                <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Lịch sử luyện tập TOEIC</div>
                            </div>
                        </Space>
                        <Space>
                            <Button
                                type="primary"
                                icon={<BulbOutlined />}
                                loading={analyzingRoadmap}
                                onClick={() => handleGenerateRoadmap(selectedStudent.id)}
                                style={{
                                    borderRadius: 8,
                                    background: 'linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)',
                                    border: 'none',
                                    boxShadow: '0 4px 14px rgba(99, 102, 241, 0.35)',
                                    fontWeight: 600
                                }}
                            >
                                Phân tích lộ trình
                            </Button>
                            <Button
                                type="primary"
                                danger
                                icon={<DownloadOutlined />}
                                onClick={() => handleExportStudentPdf(selectedStudent.id, selectedStudent.name)}
                                style={{
                                    borderRadius: 8,
                                    marginRight: 24,
                                    background: 'linear-gradient(135deg, #EF4444 0%, #DC2626 100%)',
                                    border: 'none',
                                    boxShadow: '0 4px 14px rgba(239, 68, 68, 0.35)'
                                }}
                            >
                                Xuất file PDF
                            </Button>
                        </Space>
                    </div>
                }
                placement="right"
                size="large"
                onClose={() => {
                    setHistoryVisible(false);
                    // Dọn dẹp dữ liệu để không bị "leak" sang học viên khác
                    setSelectedRoadmapId(null);
                    setCurrentRoadmap(null);
                    setTeacherNote('');
                    reset({ summary: '', roadmap: [] });
                }}
                open={historyVisible}
                styles={{ header: { borderBottom: '1px solid #F1F5F9', padding: '16px 24px' } }}
            >
                {/* TOEIC Burn Down Analysis Card - Linear Header */}
                {selectedStudent?.targetScore > 0 && (
                    <Card
                        style={{
                            marginBottom: 24,
                            borderRadius: 16,
                            background: isDark ? 'var(--bg-secondary)' : 'linear-gradient(135deg, #F8FAFC 0%, #FFFFFF 100%)',
                            border: `1px solid var(--border-color)`,
                            boxShadow: '0 4px 12px rgba(0,0,0,0.05)'
                        }}
                    >
                        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <div>
                                <span style={{ color: 'var(--text-muted)', fontSize: 12, fontWeight: 700, letterSpacing: '1px', textTransform: 'uppercase' }}>⚡ TOEIC Burn Down</span>
                                <h3 style={{ margin: 0, color: 'var(--text-primary)', fontWeight: 800 }}>Mục tiêu: {selectedStudent.targetScore} điểm</h3>
                            </div>
                            <Tag color="blue" style={{ borderRadius: 6, fontWeight: 700, padding: '4px 12px', fontSize: 14 }}>
                                {selectedStudent.targetScore > 0
                                    ? Math.min(100, Math.round(((selectedStudent.estimatedScore || 0) / selectedStudent.targetScore) * 100))
                                    : 0}%
                            </Tag>
                        </div>

                        <Progress
                            percent={selectedStudent.targetScore > 0
                                ? Math.min(100, Math.round(((selectedStudent.estimatedScore || 0) / selectedStudent.targetScore) * 100))
                                : 0}
                            status="active"
                            size={['100%', 14]}
                            strokeColor={{
                                '0%': '#4F46E5',
                                '100%': '#10B981',
                            }}
                            style={{ marginBottom: 20 }}
                        />

                        <Row gutter={24}>
                            <Col span={8}>
                                <Statistic title="Điểm tổng" value={selectedStudent.estimatedScore || 0} suffix={`/ ${selectedStudent?.targetScore || 990}`} styles={{ content: { color: 'var(--text-primary)', fontWeight: 800, fontSize: 20 } }} />
                            </Col>
                            <Col span={8}>
                                <Statistic title="Số bài làm" value={selectedStudent.totalAttempts || 0} styles={{ content: { color: '#6366F1', fontWeight: 800, fontSize: 20 } }} />
                            </Col>
                            <Col span={8}>
                                <Statistic
                                    title="Khoảng cách đích"
                                    value={selectedStudent?.targetScore > 0 ? Math.max(0, selectedStudent.targetScore - (selectedStudent.estimatedScore || 0)) : 'Không có'}
                                    styles={{ content: { color: '#EF4444', fontWeight: 800, fontSize: 20 } }}
                                    prefix={<BulbOutlined style={{ marginRight: 4, fontSize: 16 }} />}
                                />
                            </Col>
                        </Row>
                    </Card>
                )}

                <Tabs
                    activeKey={activeHistoryTab}
                    onChange={setActiveHistoryTab}
                    type="card"
                    style={{ marginTop: 8 }}
                    items={[
                        {
                            key: '1',
                            label: (
                                <Space>
                                    <HistoryOutlined />
                                    <span>Lịch sử điểm số</span>
                                </Space>
                            ),
                            children: (
                                <Table
                                    columns={historyColumns}
                                    dataSource={studentHistory}
                                    rowKey="id"
                                    loading={loadingHistory}
                                    pagination={{ pageSize: 12 }}
                                    size="small"
                                    style={{ marginTop: 8 }}
                                />
                            )
                        },
                        {
                            key: '2',
                            label: (
                                <Space>
                                    <BulbOutlined />
                                    <span>Lộ trình cá nhân hóa</span>
                                </Space>
                            ),
                            children: (
                                <div style={{ marginTop: 16 }}>
                                    <AiTimelineView
                                        userId={selectedStudent?.id}
                                        isDark={isDark}
                                        hideHeader={true}
                                        refreshTrigger={roadmapRefreshTrigger}
                                        onDataLoaded={(latestRoadmap: any) => {
                                            // Nếu roadmap mới nhất chưa public, hiện form duyệt
                                            if (latestRoadmap && (latestRoadmap.status === 'DRAFT' || latestRoadmap.status === 'REJECTED')) {
                                                setSelectedRoadmapId(latestRoadmap.id);
                                                setCurrentRoadmap(latestRoadmap);
                                                setTeacherNote(latestRoadmap.teacherNote || '');

                                                // Initialize form with existing data
                                                const content = latestRoadmap.content;
                                                reset({
                                                    summary: latestRoadmap.summary || content?.summary || '',
                                                    roadmap: (content?.roadmap || []).map((step: any) => ({
                                                        ...step,
                                                        // Convert array focus to comma string for easy editing
                                                        focus: Array.isArray(step.focus) ? step.focus.join(', ') : step.focus
                                                    }))
                                                });
                                            } else {
                                                setSelectedRoadmapId(null);
                                                setCurrentRoadmap(null);
                                            }
                                        }}
                                    />

                                    {selectedRoadmapId && (
                                        <Card
                                            title={
                                                <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: '#4338CA' }}>
                                                    <EditOutlined />
                                                    <span style={{ marginRight: 12 }}>BIÊN TẬP LỘ TRÌNH</span>
                                                    {currentRoadmap?.status === 'REJECTED' && (
                                                        <Tag color="error" style={{ fontSize: 12 }}>BỊ TỪ CHỐI</Tag>
                                                    )}
                                                    {currentRoadmap?.status === 'DRAFT' && (
                                                        <Tag color="cyan" style={{ fontSize: 12 }}>BẢN NHÁP</Tag>
                                                    )}
                                                    {currentRoadmap?.status === 'PENDING' && (
                                                        <Tag color="processing" style={{ fontSize: 12 }}>ĐANG CHỜ DUYỆT</Tag>
                                                    )}
                                                </div>
                                            }
                                            style={{
                                                marginTop: 24,
                                                borderRadius: 20,
                                                border: '2px solid #6366F1',
                                                background: '#FFFFFF',
                                                boxShadow: '0 20px 25px -5px rgba(99, 102, 241, 0.1)'
                                            }}
                                            styles={{ body: { padding: '24px' } }}
                                        >
                                            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                                                {currentRoadmap?.status === 'REJECTED' && currentRoadmap?.auditNote && (
                                                    <div style={{ padding: '12px 16px', background: '#FEF2F2', border: '1px solid #FEE2E2', borderRadius: 12, marginBottom: 8 }}>
                                                        <Typography.Text type="danger" strong>Lý do từ chối từ Admin:</Typography.Text>
                                                        <div style={{ color: '#991B1B', fontSize: 13, marginTop: 4 }}>{currentRoadmap.auditNote}</div>
                                                    </div>
                                                )}

                                                {/* Summary Section */}
                                                <div>
                                                    <Typography.Text strong style={{ display: 'block', marginBottom: 8, color: '#1E293B' }}>
                                                        1. Nhận xét tổng quan (Học viên sẽ thấy phần này đầu tiên)
                                                    </Typography.Text>
                                                    <Controller
                                                        name="summary"
                                                        control={control}
                                                        render={({ field: { value, onChange, onBlur } }) => (
                                                            <Input.TextArea
                                                                value={value}
                                                                onChange={onChange}
                                                                onBlur={onBlur}
                                                                placeholder="Nhập nhận xét tổng quan kỹ năng của học viên..."
                                                                rows={4}
                                                                style={{ borderRadius: 12, border: '1px solid #E2E8F0' }}
                                                            />
                                                        )}
                                                    />
                                                </div>

                                                <Divider style={{ margin: '8px 0' }} />

                                                {/* Phases Section */}
                                                <div>
                                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                                                        <Typography.Text strong style={{ color: '#1E293B' }}>
                                                            2. Các giai đoạn lộ trình (Phases)
                                                        </Typography.Text>
                                                        <Button
                                                            type="dashed"
                                                            icon={<PlusOutlined />}
                                                            onClick={() => append({ phase: 'Giai đoạn mới', duration: '4 tuần', focus: '', expertTips: '' })}
                                                            style={{ borderRadius: 8 }}
                                                        >
                                                            Thêm giai đoạn
                                                        </Button>
                                                    </div>

                                                    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                                                        {fields.map((fieldItem: any, index: number) => (
                                                            <Card
                                                                key={fieldItem.id}
                                                                size="small"
                                                                style={{
                                                                    borderRadius: 12,
                                                                    border: '1px solid #F1F5F9',
                                                                    background: '#F8FAFC'
                                                                }}
                                                                title={`Giai đoạn ${index + 1}`}
                                                                extra={
                                                                    <Button
                                                                        type="text"
                                                                        danger
                                                                        icon={<DeleteOutlined />}
                                                                        onClick={() => remove(index)}
                                                                    />
                                                                }
                                                            >
                                                                <Row gutter={[16, 16]}>
                                                                    <Col span={16}>
                                                                        <Typography.Text type="secondary" style={{ fontSize: 12 }}>Tên giai đoạn</Typography.Text>
                                                                        <Controller
                                                                            name={`roadmap.${index}.phase` as any}
                                                                            control={control}
                                                                            render={({ field: { value, onChange } }) => (
                                                                                <Input value={value} onChange={onChange} placeholder="Ví dụ: Bức phá kỹ năng Listening" style={{ borderRadius: 8, marginTop: 4 }} />
                                                                            )}
                                                                        />
                                                                    </Col>
                                                                    <Col span={8}>
                                                                        <Typography.Text type="secondary" style={{ fontSize: 12 }}>Thời lượng</Typography.Text>
                                                                        <Controller
                                                                            name={`roadmap.${index}.duration` as any}
                                                                            control={control}
                                                                            render={({ field: { value, onChange } }) => (
                                                                                <Input value={value} onChange={onChange} placeholder="Ví dụ: 4-6 tuần" style={{ borderRadius: 8, marginTop: 4 }} />
                                                                            )}
                                                                        />
                                                                    </Col>
                                                                    <Col span={24}>
                                                                        <Typography.Text type="secondary" style={{ fontSize: 12 }}>Nội dung trọng tâm (Phân cách bằng dấu phẩy)</Typography.Text>
                                                                        <Controller
                                                                            name={`roadmap.${index}.focus` as any}
                                                                            control={control}
                                                                            render={({ field: { value, onChange } }) => (
                                                                                <Input.TextArea value={value} onChange={onChange} placeholder="Ví dụ: Nghe chép chính tả, Học từ vựng Part 1, ..." rows={2} style={{ borderRadius: 8, marginTop: 4 }} />
                                                                            )}
                                                                        />
                                                                    </Col>
                                                                </Row>
                                                            </Card>
                                                        ))}
                                                    </div>
                                                </div>

                                                <Divider style={{ margin: '8px 0' }} />

                                                {/* Teacher Note Component */}
                                                <div>
                                                    <Typography.Text strong style={{ display: 'block', marginBottom: 8, color: '#1E293B' }}>
                                                        3. Ghi chú
                                                    </Typography.Text>
                                                    <Input.TextArea
                                                        placeholder="Ví dụ: Thầy thấy em làm Part 5 rất tốt, nhưng hãy tập trung thêm từ vựng chuyên ngành trong giai đoạn 1 nhé..."
                                                        rows={3}
                                                        value={teacherNote}
                                                        onChange={(e) => setTeacherNote(e.target.value)}
                                                        style={{ borderRadius: 12, border: '1px solid #E2E8F0' }}
                                                    />
                                                </div>

                                                <Row gutter={16}>
                                                    <Col span={12}>
                                                        <Button
                                                            icon={<SaveOutlined />}
                                                            block
                                                            size="large"
                                                            loading={savingDraft}
                                                            onClick={handleSubmit(handleSaveDraft)}
                                                            style={{ height: 48, borderRadius: 12, fontWeight: 600 }}
                                                        >
                                                            Lưu bản nháp
                                                        </Button>
                                                    </Col>
                                                    <Col span={12}>
                                                        <Button
                                                            type="primary"
                                                            icon={<SendOutlined />}
                                                            block
                                                            size="large"
                                                            loading={publishing}
                                                            disabled={currentRoadmap?.status === 'PENDING'}
                                                            onClick={handleSubmit(handlePublishRoadmap)}
                                                            style={{
                                                                height: 48,
                                                                borderRadius: 12,
                                                                background: currentRoadmap?.status === 'PENDING' 
                                                                    ? '#9ca3af' 
                                                                    : 'linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)',
                                                                border: 'none',
                                                                fontWeight: 700,
                                                                boxShadow: currentRoadmap?.status === 'PENDING' ? 'none' : '0 4px 14px rgba(99, 102, 241, 0.35)'
                                                            }}
                                                        >
                                                            {currentRoadmap?.status === 'PENDING' ? 'ĐANG CHỜ DUYỆT' : 'Gửi Admin duyệt'}
                                                        </Button>
                                                    </Col>
                                                </Row>

                                                <div style={{ textAlign: 'center', marginTop: 8 }}>
                                                    <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                                                        * Lộ trình sẽ được Admin phê duyệt trước khi gửi đến học viên.
                                                    </Typography.Text>
                                                </div>
                                            </Space>
                                        </Card>
                                    )}
                                </div>
                            )
                        }
                    ]}
                />
            </Drawer>

            {/* Modal Chi tiết lượt làm bài */}
            <Drawer
                title={
                    <div style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        width: '100%',
                    }}>
                        <div style={{ display: 'flex', flexDirection: 'column' }}>
                            <span style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 500, textTransform: 'uppercase', letterSpacing: '1px' }}>Chi tiết kết quả</span>
                            <strong style={{ fontSize: 18, color: '#1E293B' }}>{selectedAttempt?.test?.title || selectedAttempt?.part?.partName}</strong>
                        </div>
                        {selectedAttempt && (
                            <div style={{
                                background: 'linear-gradient(135deg, #EEF2FF 0%, #E0E7FF 100%)',
                                padding: '8px 16px',
                                borderRadius: 12,
                                border: '1px solid #C7D2FE',
                                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                            }}>
                                <span style={{ color: '#4338CA', fontWeight: 700, fontSize: 14 }}>
                                    {selectedAttempt.totalScore} Điểm | {selectedAttempt.correctCount}/{selectedAttempt.totalQuestions} Câu
                                </span>
                            </div>
                        )}
                    </div>
                }
                placement="right"
                width={850}
                onClose={() => setAttemptModalVisible(false)}
                open={attemptModalVisible}
                loading={loadingAttempt}
                headerStyle={{
                    background: 'linear-gradient(to right, #F8FAFC, #FFFFFF)',
                    borderBottom: '1px solid #E2E8F0',
                    padding: '20px 24px'
                }}
                bodyStyle={{ background: '#FDFDFD' }}
            >
                {selectedAttempt && (
                    <div style={{ padding: '0 4px' }}>
                        {/* AI Insight Card with Premium Shadow */}
                        <div style={{
                            marginBottom: 32,
                            padding: '24px',
                            background: isDark ? '#1E293B' : '#FFFFFF',
                            borderRadius: 24,
                            border: '1px solid rgba(191, 219, 254, 0.5)',
                            boxShadow: '0 20px 25px -5px rgba(59, 130, 246, 0.08), 0 10px 10px -5px rgba(59, 130, 246, 0.04)',
                            position: 'relative',
                            overflow: 'hidden'
                        }}>
                            <div style={{
                                position: 'absolute',
                                top: 0,
                                left: 0,
                                width: '4px',
                                height: '100%',
                                background: 'linear-gradient(to bottom, #6366F1, #A855F7)'
                            }} />

                            <Row gutter={24} align="middle">
                                <Col span={7} style={{ borderRight: '1px solid #F1F5F9', textAlign: 'center' }}>
                                    <div style={{ color: 'var(--text-muted)', fontSize: 12, fontWeight: 600, marginBottom: 8, textTransform: 'uppercase' }}>Thời gian làm</div>
                                    <div style={{ fontSize: 32, fontWeight: 800, color: '#1E293B' }}>
                                        {Math.floor((selectedAttempt.durationSeconds || 0) / 60)}<span style={{ fontSize: 16, fontWeight: 500, color: 'var(--text-muted)', marginLeft: 4 }}>phút</span>
                                    </div>
                                </Col>
                                <Col span={17} style={{ paddingLeft: 24 }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                                        <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#6366F1' }} />
                                        <span style={{ fontSize: 13, color: '#6366F1', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Nhận xét của AI</span>
                                    </div>
                                    <div style={{ fontSize: 15, lineHeight: '1.6', color: '#475569', fontStyle: 'italic' }}>
                                        "{selectedAttempt.aiAnalysis ? JSON.parse(selectedAttempt.aiAnalysis).shortFeedback : 'Hệ thống đang phân tích chi tiết bài làm của bạn...'}"
                                    </div>
                                </Col>
                            </Row>
                        </div>

                        <h4 style={{ marginBottom: 16, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                            <BookOutlined /> DANH SÁCH CÂU HỎI & ĐÁP ÁN
                        </h4>

                        <Table
                            dataSource={selectedAttempt.details || []}
                            rowKey="id"
                            pagination={false}
                            size="small"
                            columns={[
                                {
                                    title: 'Câu',
                                    dataIndex: ['question', 'questionNumber'],
                                    key: 'num',
                                    width: 60,
                                    render: (num) => <strong>#{num}</strong>
                                },
                                {
                                    title: 'Kiến thức trọng tâm',
                                    key: 'type',
                                    width: 160,
                                    render: (record: any) => (
                                        <Tag
                                            color="blue"
                                            style={{
                                                fontSize: 11,
                                                borderRadius: 6,
                                                border: 'none',
                                                background: '#EFF6FF',
                                                color: '#1D4ED8',
                                                fontWeight: 600
                                            }}
                                        >
                                            {record.question?.topic_tag || 'Tổng hợp'}
                                        </Tag>
                                    )
                                },
                                {
                                    title: 'Học viên',
                                    dataIndex: 'userAnswer',
                                    key: 'userAnswer',
                                    align: 'center',
                                    width: 100,
                                    render: (ans: string, record: any) => {
                                        const isCorrect = ans?.trim().toUpperCase() === record.question?.correctAnswer?.trim().toUpperCase();
                                        return (
                                            <div style={{
                                                width: 32,
                                                height: 32,
                                                borderRadius: '50%',
                                                background: isCorrect ? '#DCFCE7' : '#FEE2E2',
                                                color: isCorrect ? '#15803D' : '#B91C1C',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                fontWeight: 800,
                                                fontSize: 14,
                                                margin: '0 auto',
                                                boxShadow: isCorrect ? '0 2px 4px rgba(22, 163, 74, 0.1)' : '0 2px 4px rgba(220, 38, 38, 0.1)'
                                            }}>
                                                {ans || '-'}
                                            </div>
                                        )
                                    }
                                },
                                {
                                    title: 'Chuẩn',
                                    dataIndex: ['question', 'correctAnswer'],
                                    key: 'correct',
                                    align: 'center',
                                    width: 80,
                                    render: (ans) => (
                                        <span style={{ color: '#3B82F6', fontWeight: 700, fontSize: 15 }}>{ans}</span>
                                    )
                                }
                            ]}
                        />
                    </div>
                )}
            </Drawer>

            {/* Modal Gửi ý kiến chủ động */}
            <Modal
                title={
                    <Space>
                        <CommentOutlined style={{ color: '#10B981' }} />
                        <span>Gửi nhận xét tới học viên: <strong>{selectedStudent?.name}</strong></span>
                    </Space>
                }
                open={opinionModalVisible}
                onOk={handleSendOpinion}
                onCancel={() => setOpinionModalVisible(false)}
                okText="Gửi nhận xét"
                cancelText="Hủy"
                confirmLoading={sendingOpinion}
                width={500}
                centered
            >
                <div style={{ marginBottom: 12 }}>
                    <Typography.Text type="secondary">
                        Nhận xét này sẽ xuất hiện trong mục "Ý kiến giáo viên" trên ứng dụng của học viên.
                    </Typography.Text>
                </div>
                <Input.TextArea
                    rows={5}
                    value={opinionContent}
                    onChange={(e) => setOpinionContent(e.target.value)}
                    placeholder="Nhập nội dung nhận xét, lời khuyên hoặc góp ý cho học viên..."
                    style={{ borderRadius: 12, padding: 12 }}
                />
            </Modal>
        </div>
    );
}
