import React, { useState } from 'react';
import { Upload, Button, message, Badge } from 'antd';
import { SoundOutlined, UploadOutlined, DeleteOutlined } from '@ant-design/icons';
import AudioPlayer from './AudioPlayer';

interface AudioBannerBaseProps {
    /** URL of the currently saved audio (from server) */
    currentAudioUrl?: string | null;
    /** If true, shows the player without a "Change" button (post-submit view) */
    readOnly?: boolean;
}

interface AudioBannerSingleProps extends AudioBannerBaseProps {
    multiple?: false;
    newAudioFile?: File | null;
    onAudioFileChange: (file: File | null) => void;
}

interface AudioBannerMultipleProps extends AudioBannerBaseProps {
    multiple: true;
    newAudioFile?: File | File[] | null;
    onAudioFileChange: (file: File | File[] | null) => void;
}

type AudioBannerProps = AudioBannerSingleProps | AudioBannerMultipleProps;

/**
 * A reusable audio section for Listening modals (Part 1-4).
 */
const AudioBanner: React.FC<AudioBannerProps> = (props) => {
    const {
        currentAudioUrl,
        newAudioFile,
        onAudioFileChange,
        readOnly = false,
        multiple = false,
    } = props as any; // Cast to any to bypass complex union destructuring issues in JSX
    const [localPreviewUrl, setLocalPreviewUrl] = useState<string | null>(null);
    const [localPreviewUrl2, setLocalPreviewUrl2] = useState<string | null>(null);

    // For single file mode

    const handleBeforeUpload = (file: File) => {
        if (multiple) {
            const currentFiles = Array.isArray(newAudioFile) ? [...newAudioFile] : [];
            if (currentFiles.length >= 2) {
                message.warning('Chỉ hỗ trợ gộp tối đa 2 file audio');
                return false;
            }

            const newFiles = [...currentFiles, file];
            onAudioFileChange(newFiles);

            const preview = URL.createObjectURL(file);
            if (newFiles.length === 1) setLocalPreviewUrl(preview);
            else setLocalPreviewUrl2(preview);
        } else {
            const preview = URL.createObjectURL(file);
            setLocalPreviewUrl(preview);
            onAudioFileChange(file);
        }
        return false; // Prevent auto-upload
    };

    const handleRemove = (index?: number) => {
        if (multiple && typeof index === 'number') {
            const currentFiles = Array.isArray(newAudioFile) ? [...newAudioFile] : [];
            currentFiles.splice(index, 1);
            onAudioFileChange(currentFiles.length > 0 ? currentFiles : null);

            if (index === 0) {
                if (localPreviewUrl) URL.revokeObjectURL(localPreviewUrl);
                setLocalPreviewUrl(localPreviewUrl2);
                setLocalPreviewUrl2(null);
            } else {
                if (localPreviewUrl2) URL.revokeObjectURL(localPreviewUrl2);
                setLocalPreviewUrl2(null);
            }
        } else {
            if (localPreviewUrl) URL.revokeObjectURL(localPreviewUrl);
            setLocalPreviewUrl(null);
            onAudioFileChange(null);
        }
    };

    const files = Array.isArray(newAudioFile) ? newAudioFile : [];

    return (
        <div style={{ marginBottom: 16 }}>
            {/* 1. PERMANENT CURRENT AUDIO DISPLAY (Highest Priority) */}
            {!!currentAudioUrl && (
                <div style={{ marginBottom: 20 }}>
                    <div style={{ 
                        display: 'flex', 
                        alignItems: 'center', 
                        gap: 8, 
                        marginBottom: 8 
                    }}>
                        <Badge status="success" />
                        <span style={{ 
                            color: '#059669', 
                            fontWeight: 800, 
                            fontSize: 12, 
                            textTransform: 'uppercase', 
                            letterSpacing: '0.5px' 
                        }}>
                            Âm thanh hiện tại trên hệ thống
                        </span>
                    </div>
                    <div style={{ 
                        display: 'flex', 
                        alignItems: 'center', 
                        gap: 12, 
                        padding: '12px', 
                        background: '#F0FDF4', 
                        borderRadius: 12, 
                        border: '1px solid #BBF7D0',
                        boxShadow: '0 2px 4px rgba(5, 150, 105, 0.05)'
                    }}>
                        <div style={{ 
                            width: 32, 
                            height: 32, 
                            borderRadius: 8, 
                            background: '#DCFCE7', 
                            display: 'flex', 
                            alignItems: 'center', 
                            justifyContent: 'center',
                            color: '#059669'
                        }}>
                            <SoundOutlined />
                        </div>
                        <div style={{ flex: 1 }}><AudioPlayer src={currentAudioUrl} /></div>
                    </div>
                    {/* Debug URL for admin if needed (comment out if not) */}
                    <div style={{ fontSize: 10, color: '#94A3B8', marginTop: 4, fontStyle: 'italic' }}>
                        URL: {currentAudioUrl.substring(0, 50)}...
                    </div>
                </div>
            )}

            {/* 2. ACTIONS / NEW UPLOAD SECTION */}
            {multiple ? (
                // --- Multiple Files UI ---
                <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <div style={{ color: '#1E40AF', fontWeight: 700, fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}>
                            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#3B82F6' }} />
                            {files.length > 0 ? 'DỮ LIỆU CHUẨN BỊ GỘP' : 'CÀI ĐẶT AUDIO MỚI'}
                        </div>
                        {!readOnly && (
                            <Upload beforeUpload={handleBeforeUpload} showUploadList={false} accept="audio/*">
                                <Button size="small" icon={<UploadOutlined />} disabled={files.length >= 2} style={{ borderRadius: 8, fontWeight: 600 }}>
                                    {files.length === 0 ? 'Chọn file đầu tiên' : `Thêm phần ${files.length + 1}`}
                                </Button>
                            </Upload>
                        )}
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                        {files.map((_, idx) => (
                            <div key={idx} style={{
                                display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
                                background: '#F0F9FF', borderRadius: 10, border: '1px solid #BAE6FD'
                            }}>
                                <div style={{ fontWeight: 800, color: '#0284C7', minWidth: 60, fontSize: 12 }}>PHẦN {idx + 1}</div>
                                <div style={{ flex: 1 }}>
                                    <AudioPlayer src={idx === 0 ? localPreviewUrl! : localPreviewUrl2!} />
                                </div>
                                {!readOnly && (
                                    <Button type="text" danger icon={<DeleteOutlined />} onClick={() => handleRemove(idx)} />
                                )}
                            </div>
                        ))}
                        {files.length === 0 && (
                            <div style={{ 
                                padding: '16px', textAlign: 'center', background: '#F8FAFC', 
                                borderRadius: 12, border: '1px dashed #CBD5E1', color: '#64748B', fontSize: 13 
                            }}>
                                {currentAudioUrl 
                                    ? "Chọn tối đa 2 file audio mới nếu bạn muốn thay thế file hiện tại."
                                    : "Chưa có audio. Vui lòng chọn file để bắt đầu."}
                            </div>
                        )}
                    </div>
                </div>
            ) : (
                // --- Single File UI ---
                <div>
                    {localPreviewUrl && (
                        <div style={{ marginBottom: 12 }}>
                            <div style={{ color: '#F59E0B', fontWeight: 700, fontSize: 11, textTransform: 'uppercase', marginBottom: 6, letterSpacing: '0.5px' }}>
                                File chuẩn bị thay thế:
                            </div>
                            <div style={{
                                display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
                                background: '#FFFBEB', borderRadius: 12, border: '1px solid #FDE68A'
                            }}>
                                <div style={{ flex: 1 }}><AudioPlayer src={localPreviewUrl} /></div>
                                {!readOnly && (
                                    <Button type="text" danger icon={<DeleteOutlined />} onClick={() => handleRemove()} />
                                )}
                            </div>
                        </div>
                    )}

                    {!readOnly && !localPreviewUrl && (
                        <Upload beforeUpload={handleBeforeUpload} showUploadList={false} accept="audio/*">
                            <Button
                                icon={<UploadOutlined />}
                                style={{ borderRadius: 10, fontWeight: 600, width: '100%', height: 40, border: '1px dashed #CBD5E1', color: '#475569' }}
                            >
                                {currentAudioUrl ? 'Thay đổi file audio' : 'Tải lên file audio'}
                            </Button>
                        </Upload>
                    )}
                </div>
            )}
        </div>
    );
};

export default AudioBanner;
