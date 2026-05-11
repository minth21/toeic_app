import { emailTransporter } from '../../config/email.config';
import { logger } from '../../utils/logger';

/**
 * Email Service - Gửi email sử dụng Nodemailer
 */
export class EmailService {
    /**
     * Gửi email reset password với OTP code
     */
    async sendPasswordResetEmail(
        email: string,
        otpCode: string,
        userName: string
    ): Promise<boolean> {
        try {
            const mailOptions = {
                from: `${process.env.SMTP_FROM_NAME || 'TOEIC-TEST App'} <${process.env.SMTP_FROM_EMAIL}>`,
                to: email,
                subject: 'Mã xác thực đặt lại mật khẩu - TOEIC-TEST App',
                html: this.getPasswordResetEmailTemplate(userName, otpCode),
            };

            const info = await emailTransporter.sendMail(mailOptions);
            logger.info(`Password reset email sent to ${email}. MessageId: ${info.messageId}`);
            return true;
        } catch (error) {
            logger.error('Error sending password reset email:', error);
            return false;
        }
    }

    /**
     * Email template cho password reset
     */
    private getPasswordResetEmailTemplate(userName: string, otpCode: string): string {
        return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đặt lại mật khẩu</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333333;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
            color: #ffffff;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content {
            padding: 40px 30px;
        }
        .otp-box {
            background-color: #f0f9ff;
            border: 2px dashed #3b82f6;
            border-radius: 8px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
        }
        .otp-label {
            font-size: 14px;
            color: #64748b;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .otp-code {
            font-size: 42px;
            font-weight: bold;
            color: #1e3a8a;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
        }
        .warning {
            background-color: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .warning p {
            margin: 0;
            font-size: 14px;
            color: #92400e;
        }
        .instructions {
            margin: 20px 0;
        }
        .instructions ol {
            padding-left: 20px;
        }
        .instructions li {
            margin: 10px 0;
        }
        .footer {
            background-color: #f8fafc;
            padding: 20px 30px;
            text-align: center;
            font-size: 12px;
            color: #64748b;
            border-top: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Đặt lại mật khẩu</h1>
        </div>
        <div class="content">
            <p>Xin chào <strong>${userName}</strong>,</p>
            <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản TOEIC-TEST App của bạn.</p>
            
            <div class="otp-box">
                <div class="otp-label">Mã xác thực của bạn</div>
                <div class="otp-code">${otpCode}</div>
            </div>

            <div class="warning">
                <p><strong>⏰ Quan trọng:</strong> Mã này chỉ có hiệu lực trong <strong>15 phút</strong>.</p>
            </div>

            <div class="instructions">
                <p><strong>Hướng dẫn đặt lại mật khẩu:</strong></p>
                <ol>
                    <li>Mở ứng dụng TOEIC-TEST App</li>
                    <li>Nhập mã xác thực <strong>${otpCode}</strong> vào màn hình đặt lại mật khẩu</li>
                    <li>Tạo mật khẩu mới của bạn</li>
                    <li>Hoàn tất và đăng nhập với mật khẩu mới</li>
                </ol>
            </div>

            <div class="warning">
                <p><strong>🛡️ Lưu ý bảo mật:</strong> Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này và đảm bảo tài khoản của bạn được bảo mật.</p>
            </div>
        </div>
        <div class="footer">
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            <p>&copy; 2024 TOEIC-TEST App. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
        `;
    }

    /**
     * Gửi email xác nhận đã nhận yêu cầu cấp lại mật khẩu cho Học viên
     */
    async sendPasswordRequestConfirmation(
        email: string,
        userName: string
    ): Promise<boolean> {
        try {
            const mailOptions = {
                from: `${process.env.SMTP_FROM_NAME || 'Antigravity'} <${process.env.SMTP_FROM_EMAIL}>`,
                to: email,
                subject: 'Xác nhận yêu cầu cấp lại mật khẩu - Antigravity',
                html: `
                    <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;">
                        <div style="background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%); color: #fff; padding: 20px; text-align: center;">
                            <h2 style="margin: 0;">Xác nhận yêu cầu</h2>
                        </div>
                        <div style="padding: 20px;">
                            <p>Xin chào <strong>${userName}</strong>,</p>
                            <p>Chúng tôi đã ghi nhận yêu cầu cấp lại mật khẩu cho tài khoản của bạn.</p>
                            <div style="background-color: #f8fafc; border-left: 4px solid #3b82f6; padding: 15px; margin: 20px 0;">
                                <p style="margin: 0;">Yêu cầu này đã được chuyển đến Quản trị viên (Admin) để xử lý. Vui lòng chờ đợi, Admin sẽ liên hệ hoặc cấp lại mật khẩu mới cho bạn trong thời gian sớm nhất.</p>
                            </div>
                            <p>Nếu bạn không thực hiện yêu cầu này, vui lòng báo lại cho Trung tâm ngay lập tức.</p>
                            <p>Trân trọng,<br>Đội ngũ Antigravity</p>
                        </div>
                    </div>
                `,
            };

            const info = await emailTransporter.sendMail(mailOptions);
            logger.info(`Password request confirmation email sent to ${email}. MessageId: ${info.messageId}`);
            return true;
        } catch (error) {
            logger.error('Error sending password request confirmation email:', error);
            return false;
        }
    }

    /**
     * Gửi email thông báo cho Admin khi có yêu cầu cấp lại mật khẩu
     */
    async sendAdminAlert(
        adminEmail: string,
        userName: string,
        reason: string
    ): Promise<boolean> {
        try {
            const mailOptions = {
                from: `${process.env.SMTP_FROM_NAME || 'Antigravity'} <${process.env.SMTP_FROM_EMAIL}>`,
                to: adminEmail,
                subject: '[CẢNH BÁO] Có yêu cầu cấp lại mật khẩu mới',
                html: `
                    <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;">
                        <div style="background: #ef4444; color: #fff; padding: 20px; text-align: center;">
                            <h2 style="margin: 0;">Yêu cầu hỗ trợ mới</h2>
                        </div>
                        <div style="padding: 20px;">
                            <p>Thông báo từ Hệ thống,</p>
                            <p>Người dùng <strong>${userName}</strong> vừa gửi một yêu cầu cấp lại mật khẩu.</p>
                            <div style="background-color: #fef2f2; border: 1px solid #fca5a5; padding: 15px; border-radius: 4px; margin: 20px 0;">
                                <p style="margin: 0; color: #991b1b;"><strong>Lý do/Ghi chú:</strong> ${reason}</p>
                            </div>
                            <p>Vui lòng đăng nhập vào trang Quản trị (Admin Dashboard) để kiểm tra và xử lý yêu cầu này.</p>
                        </div>
                    </div>
                `,
            };

            await emailTransporter.sendMail(mailOptions);
            return true;
        } catch (error) {
            logger.error('Error sending admin alert email:', error);
            return false;
        }
    }
}

// Export singleton instance
export const emailService = new EmailService();
