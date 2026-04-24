import React, { useState, useEffect } from 'react';
import {
    Table, Button, Card, Typography, Space, Modal, Form,
    Input, Select, message, Tag, Tooltip, Avatar,
    InputNumber,
    Row, Col, Drawer
} from 'antd';
import {
    PlusOutlined, EditOutlined,
    UserOutlined, TeamOutlined, BookOutlined,
    SearchOutlined, ReloadOutlined,
    EyeOutlined, DownloadOutlined,
    LockOutlined, UnlockOutlined,
    CloseCircleOutlined, UserSwitchOutlined,
    BarChartOutlined
} from '@ant-design/icons';
import { classApi, userApi } from '../services/api';
import type { Class, User } from '../services/api';

const { Text, Title } = Typography;

const modernShadow = '0 10px 30px -5px rgba(15, 23, 42, 0.05)';

const ClassManagement: React.FC = () => {
    const [classes, setClasses] = useState<Class[]>([]);
    const [teachers, setTeachers] = useState<User[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingClass, setEditingClass] = useState<Class | null>(null);
    const [form] = Form.useForm();
    const [searchText, setSearchText] = useState('');
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [selectedClass, setSelectedClass] = useState<Class | null>(null);
    const [students, setStudents] = useState<any[]>([]);
    const [loadingStudents, setLoadingStudents] = useState(false);

    // HR Management states
    const [availableStudents, setAvailableStudents] = useState<any[]>([]);
    const [searchingStudents, setSearchingStudents] = useState(false);
    const [selectedStudentToAdd, setSelectedStudentToAdd] = useState<string | null>(null);
    const [changeTeacherModalVisible, setChangeTeacherModalVisible] = useState(false);
    const [targetClassForTeacher, setTargetClassForTeacher] = useState<Class | null>(null);

    // Fetch data
    const fetchData = async () => {
        setLoading(true);
        try {
            const [classRes, teacherRes] = await Promise.all([
                classApi.list(),
                userApi.list(1, 100, 'TEACHER')
            ]);

            if (classRes.success) setClasses(classRes.data);
            if (teacherRes.success) setTeachers(teacherRes.users);
        } catch (error) {
            message.error('Lỗi khi tải dữ liệu');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleOpenModal = (record?: Class) => {
        if (record) {
            setEditingClass(record);
            form.setFieldsValue({
                className: record.className,
                classCode: record.classCode,
                description: record.description,
                teacherId: record.teacher?.id || record.teacherId,
                maxCapacity: record.maxCapacity || 30,
                status: record.status
            });
        } else {
            setEditingClass(null);
            form.resetFields();
        }
        setModalVisible(true);
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            let res;
            if (editingClass) {
                res = await classApi.update(editingClass.id, values);
            } else {
                res = await classApi.create(values);
            }

            if (res.success) {
                message.success(`${editingClass ? 'Cập nhật' : 'Tạo'} lớp học thành công`);
                setModalVisible(false);
                setSearchText(''); // Clear search
                fetchData();
            } else {
                message.error(res.message || 'Có lỗi xảy ra');
            }
        } catch (error) {
            // validate failed
        }
    };

    const handleUpdateStatus = async (id: string, status: string, className: string) => {
        try {
            const res = await classApi.toggleStatus(id, status as any);
            if (res.success) {
                message.success(`Đã chuyển trạng thái lớp ${className} thành ${status}`);
                fetchData();
            } else {
                message.error(res.message || 'Lỗi khi cập nhật trạng thái');
            }
        } catch (error) {
            message.error('Lỗi hệ thống');
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

    const handleExportExcel = async (classId: string, className: string) => {
        try {
            const messageHide = message.loading('Đang xuất file Excel...', 0);
            const blob = await classApi.exportClassPerformance(classId);
            messageHide();

            const url = window.URL.createObjectURL(new Blob([blob]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Báo_cáo_lớp_${className.replace(/\s+/g, '_')}.xlsx`);
            document.body.appendChild(link);
            link.click();
            link.parentNode?.removeChild(link);
            window.URL.revokeObjectURL(url);

            message.success('Xuất file thành công!');
        } catch (error) {
            console.error(error);
            message.error('Lỗi khi xuất file Excel');
        }
    };

    const fetchAvailableStudents = async (search: string = '') => {
        setSearchingStudents(true);
        try {
            const res = await classApi.getAvailableStudents(search);
            if (res.success) {
                setAvailableStudents(res.data);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setSearchingStudents(false);
        }
    };

    const handleAddStudent = async () => {
        if (!selectedStudentToAdd || !selectedClass) return;
        try {
            const res = await classApi.addStudent(selectedClass.id, selectedStudentToAdd);
            if (res.success) {
                message.success('Đã thêm học viên vào lớp');
                setSelectedStudentToAdd(null);
                handleViewStudents(selectedClass); // Refresh student list
                fetchData(); // Refresh class list to update counts
            } else {
                message.error(res.message);
            }
        } catch (error) {
            message.error('Lỗi khi thêm học viên');
        }
    };

    const handleRemoveStudent = async (studentId: string) => {
        if (!selectedClass) return;
        try {
            const res = await classApi.removeStudent(selectedClass.id, studentId);
            if (res.success) {
                message.success('Đã mời học viên ra khỏi lớp');
                handleViewStudents(selectedClass); // Refresh list
                fetchData(); // Refresh counts
            } else {
                message.error(res.message);
            }
        } catch (error) {
            message.error('Lỗi hệ thống');
        }
    };

    const filteredClasses = classes.filter(c =>
        c.className.toLowerCase().includes(searchText.toLowerCase()) ||
        (c.classCode && c.classCode.toLowerCase().includes(searchText.toLowerCase()))
    );

    const columns = [
        {
            title: 'Mã lớp',
            dataIndex: 'classCode',
            key: 'classCode',
            align: 'center' as const,
            render: (code: string) => <Tag color="blue" style={{ fontWeight: 500 }}>{code || '-'}</Tag>,
            width: 120,
        },
        {
            title: 'Tên lớp học',
            dataIndex: 'className',
            key: 'className',
            width: 200,
            align: 'center' as const,
            render: (text: string) => <Text strong style={{ color: '#1E3A8A' }}>{text}</Text>,
        },
        {
            title: 'Giáo viên phụ trách',
            key: 'teacher',
            width: 220,
            align: 'center' as const,
            render: (_: any, record: Class) => (
                <Space style={{ width: '100%', justifyContent: 'center' }}>
                    <Avatar
                        size="small"
                        src={record.teacher?.avatarUrl ? (record.teacher.avatarUrl.startsWith('http') ? record.teacher.avatarUrl : `http://localhost:3000${record.teacher.avatarUrl}`) : undefined}
                        icon={<UserOutlined />}
                    />
                    <span>{record.teacher?.name || 'Chưa gán'}</span>
                    <Tooltip title="Điều chuyển giáo viên">
                        <Button
                            type="text"
                            size="small"
                            icon={<UserSwitchOutlined style={{ color: '#6366F1' }} />}
                            onClick={() => {
                                setTargetClassForTeacher(record);
                                setChangeTeacherModalVisible(true);
                            }}
                        />
                    </Tooltip>
                </Space>
            ),
        },
        {
            title: 'Sĩ số',
            dataIndex: 'studentCount',
            key: 'studentCount',
            align: 'center' as const,
            render: (count: number) => (
                <Space>
                    <TeamOutlined style={{ color: '#64748B' }} />
                    <Text>{count || 0} học viên</Text>
                </Space>
            ),
            width: 150,
        },
        {
            title: 'Trạng thái',
            dataIndex: 'status',
            key: 'status',
            width: 160,
            align: 'center' as const,
            render: (status: string) => {
                let color = 'default';
                let text = 'Không xác định';
                switch (status) {
                    case 'ACTIVE': color = 'success'; text = 'Đang hoạt động'; break;
                    case 'INACTIVE': color = 'default'; text = 'Tạm dừng'; break;
                    case 'LOCKED': color = 'warning'; text = 'Đã khóa'; break;
                    case 'ARCHIVED': color = 'error'; text = 'Đã lưu trữ'; break;
                }
                return <Tag color={color} style={{ borderRadius: 6, fontWeight: 500 }}>{text}</Tag>;
            },
        },
        {
            title: 'Hành động',
            key: 'action',
            width: 180,
            align: 'center' as const,
            render: (_: any, record: Class) => (
                <Space size="middle">
                    <Tooltip title="Xem học viên">
                        <Button
                            type="text"
                            style={{ background: '#DBEAFE', borderRadius: '8px' }}
                            icon={<EyeOutlined style={{ color: '#2563EB' }} />}
                            onClick={() => handleViewStudents(record)}
                        />
                    </Tooltip>
                    <Tooltip title="Chỉnh sửa">
                        <Button
                            type="text"
                            style={{ background: '#ECFDF5', borderRadius: '8px' }}
                            icon={<EditOutlined style={{ color: '#059669' }} />}
                            onClick={() => handleOpenModal(record)}
                        />
                    </Tooltip>
                    <Tooltip title={record.status === 'LOCKED' ? "Mở khóa lớp" : "Khóa lớp"}>
                        <Button
                            type="text"
                            style={{
                                background: record.status === 'LOCKED' ? '#FEF3C7' : '#FFEDD5',
                                borderRadius: '8px'
                            }}
                            icon={record.status === 'LOCKED' ?
                                <UnlockOutlined style={{ color: '#D97706' }} /> :
                                <LockOutlined style={{ color: '#EA580C' }} />
                            }
                            onClick={() => handleUpdateStatus(
                                record.id,
                                record.status === 'LOCKED' ? 'ACTIVE' : 'LOCKED',
                                record.className
                            )}
                        />
                    </Tooltip>
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
            dataIndex: 'username',
            key: 'username',
            width: 120,
            render: (text: string) => <Tag color="blue" style={{ borderRadius: 6, fontWeight: 500 }}>{text || '-'}</Tag>
        },
        {
            title: 'Họ và tên',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span style={{ fontWeight: 600, color: '#1E293B' }}>{text}</span>
        },
        {
            title: 'Listening',
            dataIndex: 'estimatedListening',
            key: 'estimatedListening',
            align: 'center' as const,
            render: (val: number) => <Tag color="cyan">{val || 0}</Tag>
        },
        {
            title: 'Reading',
            dataIndex: 'estimatedReading',
            key: 'estimatedReading',
            align: 'center' as const,
            render: (val: number) => <Tag color="purple">{val || 0}</Tag>
        },
        {
            title: 'Tổng điểm',
            dataIndex: 'estimatedScore',
            key: 'estimatedScore',
            align: 'center' as const,
            render: (val: number) => <Tag color="volcano" style={{ fontWeight: 'bold' }}>{val || 0}</Tag>
        },
        {
            title: 'Hành động',
            key: 'action',
            width: 80,
            render: (_: any, record: any) => (
                <Tooltip title="Xóa">
                    <Button
                        type="link"
                        danger
                        style={{ padding: 0, fontWeight: 600 }}
                        onClick={() => {
                            Modal.confirm({
                                title: 'Xác nhận mời học viên ra khỏi lớp?',
                                content: `Bạn có chắc chắn muốn xóa học viên ${record.name} khỏi lớp này không?`,
                                okText: 'Đồng ý',
                                okType: 'danger',
                                cancelText: 'Hủy',
                                onOk: () => handleRemoveStudent(record.id)
                            });
                        }}
                    >
                        Xoá
                    </Button>
                </Tooltip>
            )
        }
    ];

    const stats = {
        totalClasses: classes.length,
        totalStudents: classes.reduce((acc: number, c: any) => acc + (c.studentCount || 0), 0),
        activeTeachers: new Set(classes.map((c: any) => c.teacher?.id).filter(id => id)).size,
        activeClasses: classes.filter(c => c.status === 'ACTIVE').length,
    };

    const teacherMetrics = teachers.map((t: any) => {
        const myClasses = classes.filter(c => c.teacherId === t.id || c.teacher?.id === t.id);
        const totalStudents = myClasses.reduce((acc: number, c) => acc + (c.studentCount || 0), 0);
        return {
            ...t,
            classCount: myClasses.length,
            studentCount: totalStudents
        };
    }).sort((a: any, b: any) => b.classCount - a.classCount);

    const teacherColumns = [
        {
            title: 'Giáo viên',
            key: 'teacher',
            render: (t: any) => (
                <Space>
                    <Avatar src={t.avatarUrl} icon={<UserOutlined />} />
                    <Text strong>{t.name}</Text>
                </Space>
            )
        },
        {
            title: 'Số lớp',
            dataIndex: 'classCount',
            key: 'classCount',
            align: 'center' as const,
            render: (count: number) => <Tag color="blue">{count} lớp</Tag>
        },
        {
            title: 'Tổng học viên',
            dataIndex: 'studentCount',
            key: 'studentCount',
            align: 'center' as const,
            render: (count: number) => <Tag color="green">{count} HV</Tag>
        }
    ];

    return (
        <div style={{ padding: '24px', background: '#F8FAFC', minHeight: '100vh' }}>
            {/* Statistics Cards */}
            <Row gutter={24} style={{ marginBottom: 32 }}>
                <Col xs={24} lg={16}>
                    <Card
                        title={
                            <Space size={10}>
                                <BarChartOutlined style={{ color: '#2563EB' }} />
                                <span style={{ fontWeight: 800, color: '#1E293B' }}>TỔNG QUAN HỆ THỐNG</span>
                            </Space>
                        }
                        styles={{ body: { padding: '24px' } }}
                        style={{ borderRadius: 24, border: 'none', boxShadow: modernShadow, height: '100%' }}
                    >
                        <Row gutter={24}>
                            <Col span={8}>
                                <div style={{ textAlign: 'center' }}>
                                    <div style={{ color: '#64748B', fontSize: 12, fontWeight: 600, marginBottom: 8 }}>TỔNG LỚP HỌC</div>
                                    <div style={{ fontSize: 32, fontWeight: 800, color: '#2563EB' }}>{stats.totalClasses}</div>
                                    <div style={{ marginTop: 8 }}>
                                        <Tag color="success" style={{ borderRadius: 10 }}>{stats.activeClasses} đang mở</Tag>
                                    </div>
                                </div>
                            </Col>
                            <Col span={8}>
                                <div style={{ textAlign: 'center', borderLeft: '1px solid #E2E8F0', borderRight: '1px solid #E2E8F0' }}>
                                    <div style={{ color: '#64748B', fontSize: 12, fontWeight: 600, marginBottom: 8 }}>TỔNG HỌC VIÊN</div>
                                    <div style={{ fontSize: 32, fontWeight: 800, color: '#059669' }}>{stats.totalStudents}</div>
                                    <div style={{ marginTop: 8 }}>
                                        <Text type="secondary" style={{ fontSize: 12 }}>~{(stats.totalStudents / (stats.totalClasses || 1)).toFixed(1)} HV/lớp</Text>
                                    </div>
                                </div>
                            </Col>
                            <Col span={8}>
                                <div style={{ textAlign: 'center' }}>
                                    <div style={{ color: '#64748B', fontSize: 12, fontWeight: 600, marginBottom: 8 }}>ĐỘI NGŨ GV</div>
                                    <div style={{ fontSize: 32, fontWeight: 800, color: '#DC2626' }}>{stats.activeTeachers}</div>
                                    <div style={{ marginTop: 8 }}>
                                        {teacherMetrics.length > 0 && (
                                            <Tooltip title={`GV bận nhất: ${teacherMetrics[0].name}`}>
                                                <Avatar.Group size="small">
                                                    {teacherMetrics.slice(0, 3).map((t: any) => (
                                                        <Avatar key={t.id} src={t.avatarUrl} icon={<UserOutlined />} />
                                                    ))}
                                                    {teacherMetrics.length > 3 && <Avatar style={{ backgroundColor: '#f56a00' }}>+{teacherMetrics.length - 3}</Avatar>}
                                                </Avatar.Group>
                                            </Tooltip>
                                        )}
                                    </div>
                                </div>
                            </Col>
                        </Row>
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card
                        title={<span style={{ fontWeight: 800, color: '#1E293B' }}>HIỆU SUẤT GIÁO VIÊN</span>}
                        styles={{ body: { padding: 0 } }}
                        style={{ borderRadius: 24, border: 'none', boxShadow: modernShadow, height: '100%' }}
                    >
                        <Table
                            dataSource={teacherMetrics.slice(0, 4)}
                            columns={teacherColumns}
                            pagination={false}
                            size="small"
                            rowKey="id"
                        />
                    </Card>
                </Col>
            </Row>

            <div style={{ marginBottom: 16 }}>
                <Button
                    type="primary"
                    icon={<PlusOutlined />}
                    onClick={() => handleOpenModal()}
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
                    Thêm lớp học mới
                </Button>
            </div>

            <Card
                style={{
                    marginBottom: 24,
                    borderRadius: 20,
                    border: 'none',
                    boxShadow: modernShadow
                }}
                styles={{ body: { padding: '20px 24px' } }}
            >
                <Space size="middle">
                    <Input
                        placeholder="Tìm kiếm theo tên lớp hoặc mã lớp..."
                        prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
                        size="large"
                        allowClear
                        onChange={e => setSearchText(e.target.value)}
                        style={{ width: 320, borderRadius: 8 }}
                    />
                    <Button
                        size="large"
                        icon={<ReloadOutlined />}
                        onClick={fetchData}
                        loading={loading}
                        style={{ borderRadius: '10px' }}
                    >
                        Làm mới
                    </Button>
                </Space>
            </Card>

            <Card
                style={{
                    borderRadius: 20,
                    border: 'none',
                    boxShadow: modernShadow,
                    overflow: 'hidden'
                }}
                styles={{ body: { padding: 0 } }}
            >
                <Table
                    columns={columns}
                    dataSource={filteredClasses}
                    rowKey="id"
                    loading={loading}
                    pagination={{ pageSize: 10 }}
                    scroll={{ x: 'max-content' }}
                />
            </Card>

            <Modal
                title={<Title level={4}>{editingClass ? 'Chỉnh sửa lớp học' : 'Thêm lớp học mới'}</Title>}
                open={modalVisible}
                onOk={handleSubmit}
                onCancel={() => setModalVisible(false)}
                okText={editingClass ? 'Cập nhật' : 'Tạo mới'}
                cancelText="Hủy"
                width={800}
            >
                <Form form={form} layout="vertical">
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item label="Tên lớp học" name="className" rules={[{ required: true }]}>
                                <Input prefix={<BookOutlined />} placeholder="Ví dụ: TOEIC 650+" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Giáo viên" name="teacherId" rules={[{ required: true }]}>
                                <Select placeholder="Chọn giáo viên">
                                    {teachers.map(t => (
                                        <Select.Option key={t.id} value={t.id}>{t.name}</Select.Option>
                                    ))}
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item label="Sĩ số tối đa" name="maxCapacity" rules={[{ required: true, message: 'Vui lòng nhập sĩ số tối đa' }]}>
                                <InputNumber 
                                    min={1} 
                                    max={200} 
                                    style={{ width: '100%' }} 
                                    placeholder="Vd: 30"
                                />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Trạng thái" name="status" initialValue="ACTIVE">
                                <Select>
                                    <Select.Option value="ACTIVE">Đang hoạt động</Select.Option>
                                    <Select.Option value="LOCKED">Khóa</Select.Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>
                </Form>
            </Modal>

            <Drawer
                title={
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                        <span>Học viên lớp: <strong style={{ color: '#2563EB' }}>{selectedClass?.className}</strong></span>
                        {JSON.parse(localStorage.getItem('admin_user') || '{}').role === 'TEACHER' && (
                            <Button
                                type="primary"
                                icon={<DownloadOutlined />}
                                onClick={() => selectedClass && handleExportExcel(selectedClass.id, selectedClass.className)}
                                style={{ background: '#10B981', borderRadius: 8 }}
                            >
                                Xuất Excel
                            </Button>
                        )}
                    </div>
                }
                placement="right"
                size="large"
                onClose={() => setDrawerVisible(false)}
                open={drawerVisible}
                styles={{ body: { padding: '24px' } }}
            >
                <Card
                    variant="borderless"
                    style={{ background: '#F8FAFC', borderRadius: 16, marginBottom: 24 }}
                    styles={{ body: { padding: '20px' } }}
                >
                    <Title level={5} style={{ marginBottom: 16, fontSize: 14 }}>THÊM HỌC VIÊN</Title>
                    <Space.Compact style={{ width: '100%' }}>
                        <Select
                            showSearch
                            allowClear
                            placeholder="Nhập tên học viên..."
                            style={{ flex: 1 }}
                            size="large"
                            value={selectedStudentToAdd}
                            onChange={setSelectedStudentToAdd}
                            onSearch={fetchAvailableStudents}
                            onFocus={() => fetchAvailableStudents()}
                            loading={searchingStudents}
                            suffixIcon={selectedStudentToAdd ? (
                                <Tooltip title="Xóa để tìm tên khác">
                                    <CloseCircleOutlined
                                        style={{ cursor: 'pointer', color: '#94A3B8', fontSize: 16 }}
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            setSelectedStudentToAdd(null);
                                        }}
                                    />
                                </Tooltip>
                            ) : null}
                        >
                            {availableStudents.map(s => (
                                <Select.Option key={s.id} value={s.id}>
                                    <Space>
                                        <Avatar size="small" src={s.avatarUrl} icon={<UserOutlined />} />
                                        <span>{s.name} ({s.username})</span>
                                    </Space>
                                </Select.Option>
                            ))}
                        </Select>
                        <Button type="primary" size="large" onClick={handleAddStudent} disabled={!selectedStudentToAdd}>Thêm</Button>
                    </Space.Compact>
                </Card>

                <Title level={5} style={{ fontSize: 14, marginBottom: 16 }}>HỌC VIÊN HIỆN TẠI</Title>
                <Table
                    columns={studentColumns}
                    dataSource={students}
                    rowKey="id"
                    loading={loadingStudents}
                    pagination={false}
                    size="middle"
                />
            </Drawer>

            <Modal
                title={
                    <Space>
                        <UserSwitchOutlined style={{ color: '#6366F1' }} />
                        <span style={{ fontWeight: 700 }}>Điều chuyển giáo viên: {targetClassForTeacher?.className}</span>
                    </Space>
                }
                open={changeTeacherModalVisible}
                onCancel={() => setChangeTeacherModalVisible(false)}
                footer={null}
                centered
                width={500}
            >
                <div style={{ padding: '20px 0' }}>
                    <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                        Chọn giáo viên mới để phụ trách lớp này.
                    </Text>
                    <Select
                        placeholder="Chọn giáo viên mới..."
                        style={{ width: '100%' }}
                        size="large"
                        defaultValue={targetClassForTeacher?.teacher?.id}
                        onChange={async (teacherId) => {
                            if (!targetClassForTeacher) return;
                            try {
                                const res = await classApi.update(targetClassForTeacher.id, { teacherId });
                                if (res.success) {
                                    message.success('Điều chuyển giáo viên thành công');
                                    setChangeTeacherModalVisible(false);
                                    fetchData();
                                } else {
                                    message.error(res.message);
                                }
                            } catch (error) {
                                message.error('Lỗi khi điều chuyển giáo viên');
                            }
                        }}
                    >
                        {teachers.map(t => (
                            <Select.Option key={t.id} value={t.id}>
                                <Space>
                                    <Avatar size="small" src={t.avatarUrl} icon={<UserOutlined />} />
                                    {t.name}
                                </Space>
                            </Select.Option>
                        ))}
                    </Select>
                </div>
            </Modal>
        </div>
    );
};

export default ClassManagement;
