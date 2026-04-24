import { useState, useEffect } from 'react';
import { Table, Tag, Button, Space, Card, Typography, Modal, Form, Input, message, Badge, Tooltip } from 'antd';
import { KeyOutlined, CheckCircleOutlined, CloseCircleOutlined, ClockCircleOutlined, EyeOutlined } from '@ant-design/icons';
import { passwordRequestApi } from '../services/api';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

const PasswordResetManagement = () => {
    const [requests, setRequests] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [isFulfillModalVisible, setIsFulfillModalVisible] = useState(false);
    const [isRejectModalVisible, setIsRejectModalVisible] = useState(false);
    const [isDetailModalVisible, setIsDetailModalVisible] = useState(false);
    const [selectedRequest, setSelectedRequest] = useState<any>(null);
    const [form] = Form.useForm();

    const fetchRequests = async () => {
        setLoading(true);
        try {
            const response = await passwordRequestApi.list();
            if (response.success) {
                setRequests(response.data);
            } else {
                message.error(response.message || 'Lỗi lấy danh sách yêu cầu');
            }
        } catch (error) {
            console.error('Error fetching requests:', error);
            message.error('Lỗi kết nối máy chủ');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchRequests();
    }, []);

    const handleFulfill = async (values: any) => {
        if (!selectedRequest) return;
        try {
            const response = await passwordRequestApi.fulfill(selectedRequest.id, values);
            if (response.success) {
                message.success('Đã cấp mật khẩu mới thành công!');
                setIsFulfillModalVisible(false);
                form.resetFields();
                fetchRequests();
            } else {
                message.error(response.message || 'Lỗi thực hiện yêu cầu');
            }
        } catch (error) {
            message.error('Lỗi kết nối máy chủ');
        }
    };

    const handleReject = async (values: any) => {
        if (!selectedRequest) return;
        try {
            const response = await passwordRequestApi.reject(selectedRequest.id, values);
            if (response.success) {
                message.success('Đã từ chối yêu cầu');
                setIsRejectModalVisible(false);
                form.resetFields();
                fetchRequests();
            } else {
                message.error(response.message || 'Lỗi từ chối yêu cầu');
            }
        } catch (error) {
            message.error('Lỗi kết nối máy chủ');
        }
    };

    const columns = [
        {
            title: 'Người dùng',
            dataIndex: 'username',
            key: 'username',
            render: (text: string, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text strong>{record.user?.name || 'N/A'}</Text>
                    <Text type="secondary" style={{ fontSize: '12px' }}>@{text}</Text>
                </Space>
            ),
        },
        {
            title: 'Email/Lý do',
            dataIndex: 'reason',
            key: 'reason',
            render: (text: string, record: any) => (
                <Space direction="vertical" size={0}>
                    <Text type="secondary">{record.email || 'Không có email'}</Text>
                    <Tooltip title={text}>
                        <Typography.Paragraph ellipsis={{ rows: 1 }} style={{ maxWidth: 200, marginBottom: 0 }}>
                            {text}
                        </Typography.Paragraph>
                    </Tooltip>
                </Space>
            ),
        },
        {
            title: 'Trạng thái',
            dataIndex: 'status',
            key: 'status',
            render: (status: string) => {
                let color = 'gold';
                let icon = <ClockCircleOutlined />;
                let label = 'Đang chờ';

                if (status === 'COMPLETED') {
                    color = 'success';
                    icon = <CheckCircleOutlined />;
                    label = 'Đã xử lý';
                } else if (status === 'REJECTED') {
                    color = 'error';
                    icon = <CloseCircleOutlined />;
                    label = 'Đã từ chối';
                }

                return <Tag icon={icon} color={color}>{label}</Tag>;
            },
        },
        {
            title: 'Ngày yêu cầu',
            dataIndex: 'createdAt',
            key: 'createdAt',
            render: (date: string) => dayjs(date).format('HH:mm DD/MM/YYYY'),
        },
        {
            title: 'Thao tác',
            key: 'action',
            render: (_: any, record: any) => (
                <Space>
                    <Tooltip title="Xem chi tiết">
                        <Button 
                            icon={<EyeOutlined />} 
                            onClick={() => {
                                setSelectedRequest(record);
                                setIsDetailModalVisible(true);
                            }}
                        />
                    </Tooltip>
                    {record.status === 'PENDING' && (
                        <>
                            <Button 
                                type="primary" 
                                icon={<KeyOutlined />}
                                onClick={() => {
                                    setSelectedRequest(record);
                                    setIsFulfillModalVisible(true);
                                }}
                                style={{ borderRadius: '8px' }}
                            >
                                Cấp mật khẩu
                            </Button>
                            <Button 
                                danger
                                onClick={() => {
                                    setSelectedRequest(record);
                                    setIsRejectModalVisible(true);
                                }}
                                style={{ borderRadius: '8px' }}
                            >
                                Từ chối
                            </Button>
                        </>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: '24px' }}>
            <Card 
                title={
                    <Space>
                        <KeyOutlined style={{ color: '#3B82F6' }} />
                        <Title level={4} style={{ margin: 0 }}>Quản lý yêu cầu cấp lại mật khẩu</Title>
                    </Space>
                }
                extra={
                    <Badge count={requests.filter(r => r.status === 'PENDING').length}>
                        <Text type="secondary">Yêu cầu chưa xử lý</Text>
                    </Badge>
                }
                style={{ borderRadius: '16px', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
            >
                <Table 
                    columns={columns} 
                    dataSource={requests} 
                    rowKey="id" 
                    loading={loading}
                    pagination={{ pageSize: 10 }}
                />
            </Card>

            {/* Modal Cấp mật khẩu */}
            <Modal
                title="Cấp mật khẩu mới"
                open={isFulfillModalVisible}
                onCancel={() => setIsFulfillModalVisible(false)}
                onOk={() => form.submit()}
                okText="Xác nhận cấp"
                cancelText="Hủy"
                destroyOnClose
            >
                <Form form={form} layout="vertical" onFinish={handleFulfill}>
                    <div style={{ marginBottom: '16px', padding: '12px', background: '#f0f7ff', borderRadius: '8px' }}>
                        <Text>Cấp mật khẩu mới cho: <Text strong>{selectedRequest?.username}</Text></Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: '12px' }}>
                            Hệ thống sẽ ép người dùng đổi mật khẩu này ngay khi đăng nhập thành công.
                        </Text>
                    </div>
                    <Form.Item
                        name="newPassword"
                        label="Mật khẩu mới"
                        rules={[{ required: true, message: 'Vui lòng nhập mật khẩu mới' }, { min: 6, message: 'Tối thiểu 6 ký tự' }]}
                    >
                        <Input.Password placeholder="Nhập mật khẩu Admin cấp" prefix={<KeyOutlined />} />
                    </Form.Item>
                    <Form.Item
                        name="adminNote"
                        label="Ghi chú (Tùy chọn)"
                    >
                        <Input.TextArea placeholder="Ghi chú cho người dùng..." rows={2} />
                    </Form.Item>
                </Form>
            </Modal>

            {/* Modal Từ chối */}
            <Modal
                title="Từ chối yêu cầu"
                open={isRejectModalVisible}
                onCancel={() => setIsRejectModalVisible(false)}
                onOk={() => form.submit()}
                okText="Xác nhận từ chối"
                okButtonProps={{ danger: true }}
                cancelText="Hủy"
                destroyOnClose
            >
                <Form form={form} layout="vertical" onFinish={handleReject}>
                    <Form.Item
                        name="adminNote"
                        label="Lý do từ chối"
                        rules={[{ required: true, message: 'Vui lòng nhập lý do' }]}
                    >
                        <Input.TextArea placeholder="VD: Thông tin không khớp, vui lòng liên hệ trực tiếp..." rows={3} />
                    </Form.Item>
                </Form>
            </Modal>

            {/* Modal Chi tiết */}
            <Modal
                title="Chi tiết yêu cầu"
                open={isDetailModalVisible}
                onCancel={() => setIsDetailModalVisible(false)}
                footer={null}
            >
                {selectedRequest && (
                    <Space direction="vertical" style={{ width: '100%' }} size="middle">
                        <Card size="small" style={{ background: '#f8fafc' }}>
                            <Title level={5}>Thông tin yêu cầu</Title>
                            <Text>Người dùng: <Text strong>{selectedRequest.user?.name} (@{selectedRequest.username})</Text></Text><br />
                            <Text>Email: <Text strong>{selectedRequest.email || 'N/A'}</Text></Text><br />
                            <Text>Thời gian: <Text strong>{dayjs(selectedRequest.createdAt).format('HH:mm DD/MM/YYYY')}</Text></Text><br />
                            <Text>Lý do: <Text italic>"{selectedRequest.reason}"</Text></Text>
                        </Card>
                        
                        {selectedRequest.status !== 'PENDING' && (
                            <Card size="small" style={{ background: selectedRequest.status === 'COMPLETED' ? '#f6ffed' : '#fff1f0' }}>
                                <Title level={5}>Kết quả xử lý</Title>
                                <Text>Trạng thái: <Tag color={selectedRequest.status === 'COMPLETED' ? 'success' : 'error'}>
                                    {selectedRequest.status === 'COMPLETED' ? 'Đã cấp mật khẩu' : 'Đã từ chối'}
                                </Tag></Text><br />
                                <Text>Ghi chú của Admin: <Text strong>{selectedRequest.adminNote || 'Không có ghi chú'}</Text></Text>
                            </Card>
                        )}
                    </Space>
                )}
            </Modal>
        </div>
    );
};

export default PasswordResetManagement;
