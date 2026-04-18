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
    HistoryOutlined
} from '@ant-design/icons';
import { useForm, Controller } from 'react-hook-form';
import { aiApi } from '../services/api';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const modernShadow = '0 10px 30px -5px rgba(15, 23, 42, 0.05)';

interface RoadmapForm {
    summary: string;
    teacherNote: string;
}

const RoadmapAudit: React.FC = () => {
    const [data, setData] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedRoadmap, setSelectedRoadmap] = useState<any>(null);
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const { control, handleSubmit, reset } = useForm<RoadmapForm>({
        defaultValues: {
            summary: '',
            teacherNote: ''
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
            teacherNote: record.teacherNote || ''
        });
        setDrawerVisible(true);
    };

    const onUpdate = async (formData: RoadmapForm) => {
        if (!selectedRoadmap) return;
        setSubmitting(true);
        try {
            const res = await aiApi.updateRoadmap(selectedRoadmap.id, formData);
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

    const onPublish = async (formData: RoadmapForm) => {
        if (!selectedRoadmap) return;
        setSubmitting(true);
        try {
            const res = await aiApi.publishRoadmap(selectedRoadmap.id, formData);
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
            dataIndex: 'isPublished',
            key: 'isPublished',
            width: 180,
            render: (isPublished: boolean) => (
                isPublished 
                ? <Tag icon={<CheckCircleOutlined />} color="success" style={{ borderRadius: 12, padding: '2px 12px', fontWeight: 600 }}>ĐÃ CÔNG BỐ</Tag>
                : <Tag icon={<HistoryOutlined />} color="processing" style={{ borderRadius: 12, padding: '2px 12px', fontWeight: 600 }}>BẢN NHÁP (AI)</Tag>
            )
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
                <Button 
                    type="primary" 
                    icon={<SafetyCertificateOutlined />} 
                    onClick={() => handleOpenAudit(record)}
                    style={{ 
                        borderRadius: 10, 
                        background: record.isPublished ? '#94A3B8' : 'linear-gradient(135deg, #6366F1 0%, #4338CA 100%)',
                        border: 'none',
                        boxShadow: '0 4px 12px rgba(99, 102, 241, 0.2)'
                    }}
                >
                    {record.isPublished ? 'Xem lại' : 'Kiểm duyệt'}
                </Button>
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
                        <SafetyCertificateOutlined style={{ color: '#6366F1', fontSize: 20 }} />
                        <span style={{ fontSize: 18, fontWeight: 700 }}>Audit & Biên tập Lộ trình</span>
                    </div>
                }
                placement="right"
                width={850}
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
                        <Button 
                            size="large" 
                            icon={<SaveOutlined />}
                            loading={submitting}
                            onClick={handleSubmit(onUpdate)}
                            style={{ borderRadius: 10, background: '#F1F5F9', border: '1px solid #E2E8F0', color: '#475569' }}
                        >
                            Lưu bản nháp
                        </Button>
                        <Button 
                            type="primary" 
                            size="large" 
                            icon={<CloudUploadOutlined />}
                            loading={submitting}
                            onClick={handleSubmit(onPublish)}
                            style={{ 
                                borderRadius: 10, 
                                background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                                border: 'none',
                                boxShadow: '0 4px 14px rgba(16, 185, 129, 0.35)'
                            }}
                        >
                            Phê duyệt & Công bố
                        </Button>
                    </div>
                }
            >
                {selectedRoadmap ? (
                    <div style={{ padding: '0 0 24px 0' }}>
                        {/* Scoreboard Section */}
                        <div style={{ background: '#fff', padding: '24px', borderBottom: '1px solid #F1F5F9', marginBottom: 24 }}>
                            <Row gutter={24}>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ background: '#EFF6FF', borderRadius: 16 }}>
                                        <Statistic 
                                            title={<span style={{ color: '#1E40AF', fontWeight: 600 }}>Điểm mục tiêu</span>}
                                            value={selectedRoadmap.content?.targetScore || 0}
                                            prefix={<TrophyOutlined style={{ color: '#3B82F6' }} />}
                                            suffix="pts"
                                            valueStyle={{ color: '#1E3A8A', fontWeight: 800 }}
                                        />
                                    </Card>
                                </Col>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ background: '#F5F3FF', borderRadius: 16 }}>
                                        <Statistic 
                                            title={<span style={{ color: '#5B21B6', fontWeight: 600 }}>Thời gian dự kiến</span>}
                                            value={selectedRoadmap.content?.estimatedTimeToTarget || 'N/A'}
                                            prefix={<ClockCircleOutlined style={{ color: '#8B5CF6' }} />}
                                            valueStyle={{ color: '#4C1D95', fontWeight: 800, fontSize: 20 }}
                                        />
                                    </Card>
                                </Col>
                                <Col span={8}>
                                    <Card variant="borderless" style={{ background: '#ECFDF5', borderRadius: 16 }}>
                                        <Statistic 
                                            title={<span style={{ color: '#065F46', fontWeight: 600 }}>Trình độ hiện tại</span>}
                                            value={selectedRoadmap.content?.currentLevel || 'N/A'}
                                            prefix={<BulbOutlined style={{ color: '#10B981' }} />}
                                            valueStyle={{ color: '#064E3B', fontWeight: 800, fontSize: 20 }}
                                        />
                                    </Card>
                                </Col>
                            </Row>
                        </div>

                        <div style={{ padding: '0 24px' }}>
                            <Space direction="vertical" size={24} style={{ width: '100%' }}>
                                {/* Summary Editor */}
                                <div>
                                    <div style={{ marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
                                        <div style={{ width: 4, height: 16, background: '#3B82F6', borderRadius: 2 }} />
                                        <Title level={5} style={{ margin: 0 }}>Tóm tắt lộ trình (AI Generated)</Title>
                                    </div>
                                    <Controller
                                        name="summary"
                                        control={control}
                                        render={({ field }) => (
                                            <Input.TextArea 
                                                {...field}
                                                rows={6}
                                                placeholder="Nội dung tóm tắt lộ trình..."
                                                style={{ 
                                                    borderRadius: 12, 
                                                    padding: 16, 
                                                    border: '1px solid #E2E8F0',
                                                    fontSize: 14,
                                                    lineHeight: 1.6
                                                }}
                                                autoSize={{ minRows: 4, maxRows: 10 }}
                                            />
                                        )}
                                    />
                                    <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                                        * Admin có thể sửa đổi tóm tắt này để phù hợp hơn với học viên.
                                    </Text>
                                </div>

                                {/* Teacher Note Editor */}
                                <div>
                                    <div style={{ marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
                                        <div style={{ width: 4, height: 16, background: '#10B981', borderRadius: 2 }} />
                                        <Title level={5} style={{ margin: 0 }}>Lời khuyên từ Giáo viên (Teacher Notes)</Title>
                                    </div>
                                    <Controller
                                        name="teacherNote"
                                        control={control}
                                        render={({ field }) => (
                                            <Input.TextArea 
                                                {...field}
                                                rows={4}
                                                placeholder="Nhập thêm lời khuyên cá nhân hóa cho học viên..."
                                                style={{ 
                                                    borderRadius: 12, 
                                                    padding: 16, 
                                                    border: '1px solid #E2E8F0',
                                                    fontSize: 14,
                                                    background: '#F0FDF4'
                                                }}
                                            />
                                        )}
                                    />
                                </div>

                                {/* Roadmap Steps Visualization */}
                                {selectedRoadmap.content?.steps && (
                                    <div style={{ marginTop: 8 }}>
                                        <div style={{ marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                                            <div style={{ width: 4, height: 16, background: '#F59E0B', borderRadius: 2 }} />
                                            <Title level={5} style={{ margin: 0 }}>Chi tiết các bước thực hiện</Title>
                                        </div>
                                        <Card variant="borderless" style={{ background: '#fff', borderRadius: 20, boxShadow: '0 4px 12px rgba(0,0,0,0.03)', border: '1px solid #F1F5F9' }}>
                                            <div style={{ padding: '8px 0' }}>
                                                {selectedRoadmap.content.steps.map((step: any, index: number) => (
                                                    <div key={index} style={{ 
                                                        display: 'flex', 
                                                        gap: 16, 
                                                        marginBottom: index === selectedRoadmap.content.steps.length - 1 ? 0 : 24,
                                                        position: 'relative'
                                                    }}>
                                                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                                                            <div style={{ 
                                                                width: 32, height: 32, borderRadius: 10, 
                                                                background: '#F1F5F9', border: '2px solid #E2E8F0',
                                                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                                fontWeight: 700, color: '#64748B', zIndex: 1
                                                            }}>
                                                                {index + 1}
                                                            </div>
                                                            {index !== selectedRoadmap.content.steps.length - 1 && (
                                                                <div style={{ width: 2, flex: 1, background: '#F1F5F9', margin: '4px 0' }} />
                                                            )}
                                                        </div>
                                                        <div style={{ flex: 1, paddingBottom: 8 }}>
                                                            <Text strong style={{ fontSize: 15, display: 'block', marginBottom: 4 }}>{step.title || `Giai đoạn ${index + 1}`}</Text>
                                                            <Paragraph type="secondary" style={{ fontSize: 13, margin: 0 }}>
                                                                {step.description || 'Chưa có mô tả chi tiết cho giai đoạn này.'}
                                                            </Paragraph>
                                                            {step.duration && <Tag style={{ marginTop: 8, borderRadius: 4 }}>{step.duration}</Tag>}
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </Card>
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
