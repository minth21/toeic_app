import { Typography, Card, Space, Spin, Avatar, Tag, Modal, Skeleton, Divider, Empty, Row, Col, Progress, Button, Flex } from 'antd';
import {
    FileTextOutlined,
    QuestionCircleOutlined,
    UserOutlined,
    ReloadOutlined,
    BookOutlined,
    CrownOutlined,
    CheckCircleOutlined,
    RiseOutlined,
    FallOutlined,
    MessageOutlined,
    BarChartOutlined,
} from '@ant-design/icons';
import { Column } from '@ant-design/plots';
import { useOutletContext, useSearchParams, useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { dashboardApi } from '../services/api';
import { useTheme } from '../hooks/useThemeContext';

const { Title, Text } = Typography;

interface TopStudent {
    id: string;
    name: string;
    email: string;
    avatarUrl?: string;
    estimatedScore: number;
    estimatedListening: number;
    estimatedReading: number;
}

interface RecentSubmission {
    id: string;
    userId: string;
    score: number;
    totalQuestions: number;
    toeicScore: number;
    createdAt: string;
    user: { name: string; avatarUrl?: string };
    part: { partName: string; test: { title: string } };
}

interface DashboardStats {
    users: number;
    tests: number;
    classes: number;
    questions: number;
    averageScore: number;
    totalSubmissions: number;
    topStudents: TopStudent[];
    recentSubmissions: RecentSubmission[];
}

interface User {
    name: string;
    email: string;
    role: string;
}

export default function Overview() {
    const { user } = useOutletContext<{ user: User }>();
    const navigate = useNavigate();
    const { theme } = useTheme();
    const isDark = theme === 'dark';
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [classStats, setClassStats] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    // Submission Detail Modal States
    const [searchParams, setSearchParams] = useSearchParams();
    const [submissionModalVisible, setSubmissionModalVisible] = useState(false);
    const [selectedSubmission, setSelectedSubmission] = useState<any>(null);
    const [submissionLoading, setSubmissionLoading] = useState(false);

    useEffect(() => {
        // Only fetch stats if user is ADMIN or SPECIALIST
        const canViewDashboard = user.role === 'ADMIN' || user.role === 'SPECIALIST';

        if (!canViewDashboard) {
            setLoading(false);
            return;
        }

        const fetchStats = async () => {
            try {
                const [statsRes, classRes] = await Promise.all([
                    dashboardApi.getStats(),
                    dashboardApi.getClassComparison()
                ]);

                if (statsRes.success) {
                    setStats(statsRes.data as any);
                }

                if (classRes.success) {
                    setClassStats(classRes.data);
                }
            } catch (error) {
                console.error('Failed to fetch dashboard stats:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, [user.role]);

    // Handle deep linking for submissionId
    useEffect(() => {
        const submissionId = searchParams.get('submissionId');
        if (submissionId) {
            setSubmissionModalVisible(true);
            loadSubmissionDetail(submissionId);
        }
    }, [searchParams]);

    const loadSubmissionDetail = async (id: string) => {
        setSubmissionLoading(true);
        try {
            const response = await dashboardApi.getSubmissionDetail(id);
            if (response.success) {
                setSelectedSubmission(response.data);
            } else {
                setSelectedSubmission(null);
            }
        } catch (error) {
            console.error('Failed to fetch submission detail:', error);
            setSelectedSubmission(null);
        } finally {
            setSubmissionLoading(false);
        }
    };

    const handleCloseModal = () => {
        setSubmissionModalVisible(false);
        // Cleanup URL parameter
        const newParams = new URLSearchParams(searchParams);
        newParams.delete('submissionId');
        setSearchParams(newParams);

        // Short delay before clearing data to avoid flicker during close animation
        setTimeout(() => setSelectedSubmission(null), 300);
    };

    if (!user) return null;

    const canViewFullDashboard = user.role === 'ADMIN' || user.role === 'SPECIALIST';

    return (
        <div style={{ padding: '0 0 40px' }}>
            <div style={{ marginBottom: 32 }}>
                <Title level={2} style={{ color: 'var(--text-primary)', margin: 0, fontWeight: 700, letterSpacing: '-1px' }}>
                    Chào mừng trở lại, {user.name}!
                </Title>
                <Text style={{ color: 'var(--text-secondary)', fontSize: 16, fontWeight: 500 }}>
                    Nơi tạo ra và quản lý đề thi TOEIC cho học viên ôn luyện.
                </Text>
            </div>

            <Flex vertical gap={32} style={{ width: '100%' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 24 }}>
                    {loading ? (
                        <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '40px' }}>
                            <Spin size="large" />
                        </div>
                    ) : stats && (
                        [
                            { title: 'Người dùng', count: (stats?.users ?? 0).toLocaleString(), icon: <UserOutlined />, color: '#3B82F6', bg: isDark ? 'rgba(59, 130, 246, 0.1)' : '#EFF6FF' },
                            { title: 'Đề thi', count: (stats?.tests ?? 0).toLocaleString(), icon: <FileTextOutlined />, color: '#10B981', bg: isDark ? 'rgba(16, 185, 129, 0.1)' : '#ECFDF5' },
                            { title: 'Lớp học', count: (stats?.classes ?? 0).toLocaleString(), icon: <BookOutlined />, color: '#F43F5E', bg: isDark ? 'rgba(244, 63, 94, 0.1)' : '#FFF1F2' },
                            { title: 'Câu hỏi', count: (stats?.questions ?? 0).toLocaleString(), icon: <QuestionCircleOutlined />, color: '#F59E0B', bg: isDark ? 'rgba(245, 158, 11, 0.1)' : '#FFFBEB' },
                        ].map((item, index) => (
                            <Card
                                key={index}
                                variant="borderless"
                                hoverable
                                style={{
                                    borderRadius: 24,
                                    boxShadow: 'var(--card-shadow)',
                                    transition: 'all 0.3s ease',
                                    background: isDark ? 'var(--bg-surface)' : 'linear-gradient(135deg, #FFFFFF 0%, #FAFCFF 100%)',
                                    backdropFilter: isDark ? 'blur(10px)' : 'none',
                                }}
                            >
                                <Space size={20} align="center" style={{ width: '100%', justifyContent: 'space-between' }}>
                                    <div>
                                        <Text style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'block', marginBottom: 4, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                            {item.title}
                                        </Text>
                                        <Title level={2} style={{ margin: 0, color: 'var(--text-primary)', fontWeight: 700 }}>
                                            {item.count}
                                        </Title>
                                    </div>
                                    <div style={{
                                        width: 48,
                                        height: 48,
                                        borderRadius: 14,
                                        background: item.bg,
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        fontSize: 20,
                                        color: item.color
                                    }}>
                                        {item.icon}
                                    </div>
                                </Space>
                            </Card>
                        )))}
                </div>

                {canViewFullDashboard && (
                    <>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 24, marginBottom: 24 }}>
                            {/* Class Performance Comparison Chart */}
                            <Card
                                variant="borderless"
                                title={
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
                                        <div style={{ width: 32, height: 32, borderRadius: 8, background: isDark ? '#1E293B' : '#E0F2FE', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0EA5E9' }}>
                                            <BarChartOutlined />
                                        </div>
                                        <span style={{ fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>SO SÁNH HIỆU SUẤT GIỮA CÁC LỚP</span>
                                    </div>
                                }
                                style={{
                                    borderRadius: 24,
                                    border: `1px solid var(--border-color)`,
                                    boxShadow: 'var(--card-shadow)',
                                    background: 'var(--bg-surface)',
                                }}
                            >
                                {classStats.length > 0 ? (
                                    <Column
                                        data={classStats}
                                        xField="className"
                                        yField="averageScore"
                                        colorField="className"
                                        label={{
                                            text: (d: any) => `${d.averageScore} pts`,
                                            textBaseline: 'bottom',
                                            position: 'top',
                                            style: {
                                                fill: isDark ? '#F1F5F9' : '#0F172A',
                                                fontWeight: 700,
                                            }
                                        }}
                                        style={{
                                            maxWidth: 80,
                                            radiusTopLeft: 10,
                                            radiusTopRight: 10,
                                        }}
                                        tooltip={{
                                            items: [
                                                { channel: 'y', name: 'Điểm trung bình' },
                                                (d: any) => ({ name: 'Sĩ số hiện tại', value: `${d.studentCount} học viên` })
                                            ]
                                        }}
                                        axis={{
                                            x: { title: false },
                                            y: { title: false }
                                        }}
                                    />
                                ) : (
                                    <div style={{ textAlign: 'center', padding: '40px' }}>
                                        <Empty description="Chưa có dữ liệu so sánh lớp học" />
                                    </div>
                                )}
                            </Card>
                        </div>

                        {/* Recent Submissions Section */}
                        <Card
                            variant="borderless"
                            title={
                                <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 0' }}>
                                    <div style={{ width: 32, height: 32, borderRadius: 8, background: isDark ? '#334155' : '#F5F3FF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: isDark ? '#A78BFA' : '#8B5CF6' }}>
                                        <ReloadOutlined />
                                    </div>
                                    <span style={{ fontWeight: 600, color: isDark ? '#F1F5F9' : '#1E3A8A' }}>Hoạt động làm bài gần đây</span>
                                </div>
                            }
                            style={{
                                borderRadius: 24,
                                border: `1px solid var(--border-color)`,
                                boxShadow: 'var(--card-shadow)',
                                background: 'var(--bg-surface)',
                                backdropFilter: isDark ? 'blur(10px)' : 'none',
                            }}
                        >
                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
                                {loading ? <Spin /> : (stats?.recentSubmissions || []).map((sub) => (
                                    <div
                                        key={sub.id}
                                        onClick={() => navigate(`/dashboard?submissionId=${sub.id}`)}
                                        style={{
                                            padding: '16px',
                                            background: 'var(--bg-secondary)',
                                            borderRadius: 16,
                                            border: `1px solid var(--border-color)`,
                                            cursor: 'pointer',
                                            transition: 'transform 0.2s, box-shadow 0.2s'
                                        }}
                                        onMouseEnter={(e) => {
                                            e.currentTarget.style.transform = 'translateY(-2px)';
                                            e.currentTarget.style.boxShadow = '0 10px 15px -3px rgba(0, 0, 0, 0.1)';
                                        }}
                                        onMouseLeave={(e) => {
                                            e.currentTarget.style.transform = 'none';
                                            e.currentTarget.style.boxShadow = 'none';
                                        }}
                                    >
                                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                                            <Space>
                                                <Avatar size="small" src={sub.user.avatarUrl} icon={<UserOutlined />} />
                                                <Text strong style={{ fontSize: 13, color: 'var(--text-primary)' }}>{sub.user.name}</Text>
                                            </Space>
                                            <Tag color="blue">{sub.score}/{sub.totalQuestions} câu</Tag>
                                        </div>
                                        <div style={{ color: isDark ? '#93C5FD' : '#1E3A8A', fontWeight: 600, fontSize: 13, marginBottom: 4 }}>
                                            {sub.part.test.title}
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11 }}>
                                            <Text type="secondary">{sub.part.partName}</Text>
                                            <Text type="danger" strong>+{sub.toeicScore} pts</Text>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </Card>
                    </>
                )}
            </Flex>

            {/* Submission Detail Modal */}
            <Modal
                title={
                    <div style={{ borderBottom: `1px solid var(--border-color)`, paddingBottom: 16, marginBottom: 0 }}>
                        <Space size={12}>
                            <Avatar size="large" src={selectedSubmission?.user?.avatarUrl} icon={<UserOutlined />} style={{ backgroundColor: '#3B82F6' }} />
                            <div>
                                <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)' }}>{selectedSubmission?.user?.name || (submissionLoading ? 'Đang tải...' : 'Không xác định')}</div>
                                <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Chi tiết kết quả thực hiện bài thi</div>
                            </div>
                        </Space>
                    </div>
                }
                open={submissionModalVisible}
                onCancel={handleCloseModal}
                footer={[
                    <Button key="close" type="primary" onClick={handleCloseModal} style={{ borderRadius: 8, height: 40, padding: '0 24px' }}>
                        Đóng
                    </Button>
                ]}
                width={800}
                styles={{ body: { overflowY: 'auto', maxHeight: 'calc(100vh - 250px)', padding: '24px' } }}
                centered
            >
                <Skeleton active loading={submissionLoading} avatar paragraph={{ rows: 8 }}>
                    {selectedSubmission ? (
                        <div style={{ animation: 'fadeIn 0.5s ease-in-out' }}>
                            {/* Summary Header Cards */}
                            <Row gutter={[16, 16]}>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ textAlign: 'center', background: isDark ? 'rgba(59, 130, 246, 0.1)' : '#F0F9FF', borderRadius: 16 }}>
                                        <Text type="secondary" style={{ fontSize: 12, display: 'block', color: 'var(--text-secondary)' }}>KẾT QUẢ</Text>
                                        <Title level={3} style={{ margin: '8px 0', color: isDark ? 'var(--text-primary)' : '#1E40AF' }}>
                                            {selectedSubmission.correctCount} / {selectedSubmission.totalQuestions}
                                        </Title>
                                        <Tag color="blue" icon={<CheckCircleOutlined />}>Số câu đúng</Tag>
                                    </Card>
                                </Col>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ textAlign: 'center', background: isDark ? 'rgba(244, 63, 94, 0.1)' : '#FEF2F2', borderRadius: 16 }}>
                                        <Text type="secondary" style={{ fontSize: 12, display: 'block', color: 'var(--text-secondary)' }}>TỔNG ĐIỂM (EST.)</Text>
                                        <Title level={3} style={{ margin: '8px 0', color: isDark ? '#F87171' : '#991B1B' }}>
                                            {selectedSubmission.totalScore} pts
                                        </Title>
                                        <div style={{ fontSize: 11, color: '#ef4444', fontWeight: 600 }}>Tương đương mức {selectedSubmission.totalScore >= 700 ? 'Expert' : selectedSubmission.totalScore >= 450 ? 'Intermediate' : 'Beginner'}</div>
                                    </Card>
                                </Col>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ textAlign: 'center', background: 'var(--bg-secondary)', borderRadius: 16 }}>
                                        <Text type="secondary" style={{ fontSize: 12, display: 'block', color: 'var(--text-secondary)' }}>THỜI GIAN</Text>
                                        <Title level={3} style={{ margin: '8px 0', color: 'var(--text-primary)' }}>
                                            {Math.floor(selectedSubmission.durationSeconds / 60)}:{String(selectedSubmission.durationSeconds % 60).padStart(2, '0')}
                                        </Title>
                                        <Tag icon={<ReloadOutlined />}>Phút/Giây</Tag>
                                    </Card>
                                </Col>
                            </Row>

                            <Divider orientation={"left" as any} style={{ margin: '32px 0 16px' }}>
                                <Space style={{ color: 'var(--text-primary)' }}><CrownOutlined style={{ color: '#F59E0B' }} /> AI Coach Assessment</Space>
                            </Divider>

                            {/* AI Assessment Integration */}
                            {selectedSubmission.aiAnalysis ? (() => {
                                let analysis: any = {};
                                try {
                                    analysis = typeof selectedSubmission.aiAnalysis === 'string'
                                        ? JSON.parse(selectedSubmission.aiAnalysis)
                                        : selectedSubmission.aiAnalysis;
                                } catch (e) {
                                    console.error("AI Analysis Parse Error", e);
                                }

                                return (
                                    <Flex vertical gap={20} style={{ width: '100%' }}>
                                        {/* Skill Progress Breakdown */}
                                        {analysis.skills && (
                                            <Card variant="borderless" size="small" style={{ borderRadius: 16, border: `1px solid var(--border-color)`, background: isDark ? 'rgba(30, 41, 59, 0.5)' : '#FFFFFF' }}>
                                                <Row gutter={[24, 16]}>
                                                    {Object.entries(analysis.skills).map(([skill, val]: [string, any]) => (
                                                        <Col span={12} key={skill}>
                                                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                                                                <Text strong style={{ textTransform: 'capitalize', fontSize: 12, color: 'var(--text-primary)' }}>{skill === 'grammar' ? 'Ngữ pháp' : skill === 'vocabulary' ? 'Từ vựng' : skill === 'inference' ? 'Suy luận' : 'Ý chính'}</Text>
                                                                <Text type="secondary" style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{val}/10 pts</Text>
                                                            </div>
                                                            <Progress percent={val * 10} showInfo={false} strokeColor={val >= 7 ? '#10B981' : val >= 5 ? '#F59E0B' : '#EF4444'} />
                                                        </Col>
                                                    ))}
                                                </Row>
                                            </Card>
                                        )}

                                        {/* Strengths and Weaknesses */}
                                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                                            <div style={{ background: isDark ? 'rgba(16, 185, 129, 0.1)' : '#F0FDF4', padding: '16px', borderRadius: 16 }}>
                                                <div style={{ color: isDark ? '#34D399' : '#166534', fontWeight: 800, fontSize: 12, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
                                                    <RiseOutlined /> ĐIỂM MẠNH
                                                </div>
                                                <ul style={{ paddingLeft: 16, margin: 0, color: isDark ? '#A7F3D0' : '#166534', fontSize: 13 }}>
                                                    {analysis.strengths?.map((s: string, idx: number) => <li key={idx}>{s}</li>) || <li>Chưa có ghi nhận</li>}
                                                </ul>
                                            </div>
                                            <div style={{ background: isDark ? 'rgba(244, 63, 94, 0.1)' : '#FFF1F2', padding: '16px', borderRadius: 16 }}>
                                                <div style={{ color: isDark ? '#FB7185' : '#9F1239', fontWeight: 800, fontSize: 12, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
                                                    <FallOutlined /> CẦN CẢI THIỆN
                                                </div>
                                                <ul style={{ paddingLeft: 16, margin: 0, color: isDark ? '#FECDD3' : '#9F1239', fontSize: 13 }}>
                                                    {analysis.weaknesses?.map((w: string, idx: number) => <li key={idx}>{w}</li>) || <li>Chưa có ghi nhận</li>}
                                                </ul>
                                            </div>
                                        </div>

                                        {/* Detailed Feedback */}
                                        <Card
                                            variant="borderless"
                                            size="small"
                                            title={<Space style={{ color: 'var(--text-primary)' }}><MessageOutlined /> Nhận xét chuyên sâu từ AI Coach</Space>}
                                            style={{ borderRadius: 16, background: 'var(--bg-secondary)' }}
                                        >
                                            <div style={{ fontSize: 14, color: 'var(--text-primary)', lineHeight: 1.6 }}
                                                dangerouslySetInnerHTML={{ __html: analysis.detailedAssessment || analysis.shortFeedback || 'Chưa có phân tích chi tiết.' }}
                                            />
                                        </Card>
                                    </Flex>
                                );
                            })() : (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={<span style={{ color: 'var(--text-secondary)' }}>AI đang phân tích bài làm của học viên này...</span>} />
                            )}

                            <Divider orientation={"left" as any} style={{ margin: '32px 0 16px' }}>
                                <Space style={{ color: 'var(--text-primary)' }}><FileTextOutlined style={{ color: '#3B82F6' }} /> Thông tin bài thi</Space>
                            </Divider>

                            <div style={{ background: 'var(--bg-secondary)', padding: '20px', borderRadius: 16, border: `1px solid var(--border-color)` }}>
                                <Row gutter={[24, 12]}>
                                    <Col span={12}>
                                        <div style={{ color: 'var(--text-secondary)', fontSize: 12 }}>Đề thi</div>
                                        <div style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{selectedSubmission.part?.test?.title || 'TOEIC-TEST Official'}</div>
                                    </Col>
                                    <Col span={12}>
                                        <div style={{ color: 'var(--text-secondary)', fontSize: 12 }}>Phần thi</div>
                                        <div style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{selectedSubmission.part?.partName} (Part {selectedSubmission.part?.partNumber})</div>
                                    </Col>
                                    <Col span={12}>
                                        <div style={{ color: 'var(--text-secondary)', fontSize: 12 }}>Ngày nộp</div>
                                        <div style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{new Date(selectedSubmission.createdAt).toLocaleString('vi-VN')}</div>
                                    </Col>
                                    <Col span={12}>
                                        <div style={{ color: 'var(--text-secondary)', fontSize: 12 }}>ID Bài làm</div>
                                        <div style={{ fontFamily: 'monospace', fontSize: 11, color: 'var(--text-secondary)' }}>{selectedSubmission.id}</div>
                                    </Col>
                                </Row>
                            </div>
                        </div>
                    ) : !submissionLoading && (
                        <Empty description={<span style={{ color: 'var(--text-secondary)' }}>Không tìm thấy thông tin bài làm này hoặc học viên đã xóa.</span>} />
                    )}
                </Skeleton>
            </Modal>
        </div >
    );
}
