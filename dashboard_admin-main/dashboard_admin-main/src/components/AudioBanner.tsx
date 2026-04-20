import React, { useState } from 'react';
import { Upload, Button, message } from 'antd';
import { SoundOutlined, UploadOutlined, DeleteOutlined } from '@ant-design/icons';
import AudioPlayer from './AudioPlayer';

interface AudioBannerProps {
    /** URL of the currently saved audio (from server) */
    currentAudioUrl?: string | null;
    /** The new file(s) selected by user (not yet uploaded) */
    newAudioFile?: File | File[] | null;
    /** Called when user selects a new audio file */
    onAudioFileChange: (file: File | File[] | null) => void;
    /** If true, shows the player without a "Change" button (post-submit view) */
    readOnly?: boolean;
    /** If true, allows selecting 2 files for merging (Part 1 & Part 2) */
    multiple?: boolean;
}

/**
 * A reusable audio section for Listening modals (Part 1-4).
 */
const AudioBanner: React.FC<AudioBannerProps> = ({
    currentAudioUrl,
    newAudioFile,
    onAudioFileChange,
    readOnly = false,
    multiple = false,
}) => {
    const [localPreviewUrl, setLocalPreviewUrl] = useState<string | null>(null);
    const [localPreviewUrl2, setLocalPreviewUrl2] = useState<string | null>(null);

    const hasAudio = !!(currentAudioUrl || newAudioFile || localPreviewUrl);
    
    // For single file mode
    const displayUrl = localPreviewUrl || currentAudioUrl || '';

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

    // --- Multiple Files UI ---
    if (multiple) {
        const files = Array.isArray(newAudioFile) ? newAudioFile : [];
        return (
            <div style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                    <div style={{ color: '#1E40AF', fontWeight: 700, fontSize: 13 }}>
                        CHẾ ĐỘ GỘP ÂM THANH (DÀNH CHO PART 3/4 DÀI)
                    </div>
                    {!readOnly && (
                        <Upload beforeUpload={handleBeforeUpload} showUploadList={false} accept="audio/*">
                            <Button size="small" icon={<UploadOutlined />} disabled={files.length >= 2} style={{ borderRadius: 8 }}>
                                Thêm phần audio ({files.length}/2)
                            </Button>
                        </Upload>
                    )}
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {files.map((_, idx) => (
                        <div key={idx} style={{
                            display: 'flex', alignItems: 'center', gap: 12, padding: '8px 12px',
                            background: '#F0F9FF', borderRadius: 10, border: '1px solid #BAE6FD'
                        }}>
                            <div style={{ fontWeight: 800, color: '#0284C7', minWidth: 60 }}>PHẦN {idx + 1}</div>
                            <div style={{ flex: 1 }}>
                                <AudioPlayer src={idx === 0 ? localPreviewUrl! : localPreviewUrl2!} />
                            </div>
                            {!readOnly && (
                                <Button type="text" danger icon={<DeleteOutlined />} onClick={() => handleRemove(idx)} />
                            )}
                        </div>
                    ))}
                    {files.length === 0 && !currentAudioUrl && (
                        <div style={{ padding: '20px', textAlign: 'center', background: '#F8FAFC', borderRadius: 10, border: '1px dashed #CBD5E1', color: '#64748B' }}>
                            Chưa có audio nào. Hãy chọn tối đa 2 file để gộp.
                        </div>
                    )}
                    {currentAudioUrl && files.length === 0 && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 12px', background: '#F8FAFC', borderRadius: 10, border: '1px solid #E2E8F0' }}>
                            <div style={{ fontWeight: 800, color: '#10B981', minWidth: 60 }}>ĐÃ CÓ</div>
                            <div style={{ flex: 1 }}><AudioPlayer src={currentAudioUrl} /></div>
                        </div>
                    )}
                </div>
            </div>
        );
    }

    // --- Single File UI (Backward Compatibility) ---
    if (hasAudio) {
        return (
            <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                padding: '12px 16px',
                background: '#F8FAFC',
                borderRadius: 12,
                border: '1px solid #E2E8F0',
                marginBottom: 16,
            }}>
                <div style={{
                    width: 40,
                    height: 40,
                    borderRadius: 10,
                    background: 'linear-gradient(135deg, #10B981 0%, #059669 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#FFF',
                    fontSize: 12,
                    fontWeight: 800,
                    flexShrink: 0,
                    boxShadow: '0 3px 8px rgba(16, 185, 129, 0.25)',
                }}>
                    AUDIO
                </div>
                <div style={{ flex: 1 }}>
                    <AudioPlayer src={displayUrl} />
                </div>
                {!readOnly && (
                    <Upload
                        beforeUpload={handleBeforeUpload}
                        showUploadList={false}
                        accept="audio/*"
                    >
                        <Button
                            size="small"
                            style={{
                                borderRadius: 8,
                                fontWeight: 600,
                                background: '#F1F5F9',
                                color: '#475569',
                                border: '1px solid #E2E8F0',
                                flexShrink: 0,
                            }}
                        >
                            Thay đổi
                        </Button>
                    </Upload>
                )}
            </div>
        );
    }

    return (
        <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '10px 16px',
            background: 'linear-gradient(135deg, #EFF6FF 0%, #DBEAFE 100%)',
            borderRadius: 10,
            border: '1px solid #BFDBFE',
            marginBottom: 16,
        }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: '#1E40AF', fontWeight: 600, fontSize: 14 }}>
                <SoundOutlined style={{ fontSize: 16 }} />
                <span>Audio:</span>
                <span style={{ color: '#DC2626', fontWeight: 700 }}>Chưa có audio. Vui lòng upload!</span>
            </div>
            <Upload
                beforeUpload={handleBeforeUpload}
                showUploadList={false}
                accept="audio/*"
            >
                <Button icon={<UploadOutlined />} style={{ borderRadius: 8, fontWeight: 600, background: '#fff', borderColor: '#93C5FD' }}>
                    Upload audio
                </Button>
            </Upload>
        </div>
    );
};

export default AudioBanner;
