import React, { useState, useEffect } from 'react';
import { Card, Table, Button, Space, message, Drawer, Tag, Row, Col, Input, Avatar, Tabs, Progress, Statistic } from 'antd';
import { TeamOutlined, DownloadOutlined, EyeOutlined, ReloadOutlined, BookOutlined, UserOutlined } from '@ant-design/icons';
import { classApi } from '../services/api';
import type { Class } from '../services/api';

const { Search } = Input;
import { SearchOutlined, HistoryOutlined, BulbOutlined } from '@ant-design/icons';
import { useTheme } from '../hooks/useThemeContext';
import AiTimelineView from '../components/AiTimelineView';

export default function TeacherClasses() {
    const [classes, setClasses] = useState<Class[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');

    const [drawerVisible, setDrawerVisible] = useState(false);
    const [selectedClass, setSelectedClass] = useState<Class | null>(null);
    const [students, setStudents] = useState<any[]>([]);
    const [loadingStudents, setLoadingStudents] = useState(false);

    // Dành cho xem lịch sử chi tiết học viên
    const [historyVisible, setHistoryVisible] = useState(false);
    const [selectedStudent, setSelectedStudent] = useState<any>(null);
    const [studentHistory, setStudentHistory] = useState<any[]>([]);
    const [loadingHistory, setLoadingHistory] = useState(false);
    const [activeHistoryTab, setActiveHistoryTab] = useState('1');
    const [roadmapRefreshTrigger, setRoadmapRefreshTrigger] = useState(0);

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
        setActiveHistoryTab('1'); // Reset to history tab when opening
        try {
            const { teacherApi } = await import('../services/api');
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

    const [analyzingRoadmap, setAnalyzingRoadmap] = useState(false);
    const handleGenerateRoadmap = async (userId: string) => {
        setAnalyzingRoadmap(true);
        try {
            const { aiApi } = await import('../services/api');
            const response = await aiApi.assessRoadmap(userId);
            if (response.success) {
                message.success('Phân tích lộ trình thành công!');
                // Reload timeline
                window.dispatchEvent(new CustomEvent('reloadTimeline'));
                // Auto switch to roadmap tab
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
            const messageHide = message.loading('Đang xuất báo cáo Excel...', 0);
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

            message.success('Xuất báo cáo thành công!');
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi xuất báo cáo Excel');
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

                if (target === 0) return <Tag color="default">N/A Target</Tag>;
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
            width: 140,
            render: (record: any) => (
                <Button
                    type="link"
                    icon={<EyeOutlined />}
                    onClick={() => handleViewHistory(record)}
                    style={{ fontWeight: 500 }}
                >
                    Lịch sử
                </Button>
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
                            bodyStyle={{ padding: '24px' }}
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
                bodyStyle={{ padding: '20px 24px' }}
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
            <Card style={{ borderRadius: 24, border: 'none', boxShadow: 'var(--card-shadow)', overflow: 'hidden', background: 'var(--bg-surface)' }} bodyStyle={{ padding: 0 }}>
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
                            Xuất báo cáo Excel lớp
                        </Button>
                    </div>
                }
                placement="right"
                width={900}
                onClose={() => setDrawerVisible(false)}
                open={drawerVisible}
                headerStyle={{ borderBottom: '1px solid #F1F5F9' }}
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
                                Xuất báo cáo & Lộ trình
                            </Button>
                        </Space>
                    </div>
                }
                placement="right"
                width={700}
                onClose={() => setHistoryVisible(false)}
                open={historyVisible}
                headerStyle={{ borderBottom: '1px solid #F1F5F9', padding: '16px 24px' }}
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
                            strokeWidth={14}
                            strokeColor={{
                                '0%': '#4F46E5',
                                '100%': '#10B981',
                            }}
                            style={{ marginBottom: 20 }}
                        />

                        <Row gutter={24}>
                            <Col span={8}>
                                <Statistic title="Điểm tổng" value={selectedStudent.estimatedScore || 0} suffix="/ 990" valueStyle={{ color: 'var(--text-primary)', fontWeight: 800, fontSize: 20 }} />
                            </Col>
                            <Col span={8}>
                                <Statistic title="Số bài làm" value={selectedStudent.totalAttempts || 0} valueStyle={{ color: '#6366F1', fontWeight: 800, fontSize: 20 }} />
                            </Col>
                            <Col span={8}>
                                <Statistic
                                    title="Khoảng cách đích"
                                    value={selectedStudent?.targetScore > 0 ? Math.max(0, selectedStudent.targetScore - (selectedStudent.estimatedScore || 0)) : 'N/A'}
                                    valueStyle={{ color: '#EF4444', fontWeight: 800, fontSize: 20 }}
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
                                    />
                                </div>
                            )
                        }
                    ]}
                />
            </Drawer>
        </div>
    );
}
