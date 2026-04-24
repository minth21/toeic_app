import { Request, Response } from 'express';
import { passwordRequestService } from '../../services/admin/password-request.service';
import { successResponse, errorResponse } from '../../utils/response';
import { HTTP_STATUS } from '../../config/constants';
import { logger } from '../../utils/logger';

export class PasswordRequestController {
    /**
     * GET /api/admin/password-requests
     */
    async getRequests(req: Request, res: Response) {
        try {
            const { status } = req.query;
            const requests = await passwordRequestService.getRequests(status as string);
            return successResponse(res, requests, 'Lấy danh sách yêu cầu thành công');
        } catch (error) {
            logger.error('Controller error in getRequests:', error);
            return errorResponse(res, 'Lỗi lấy danh sách yêu cầu');
        }
    }

    /**
     * POST /api/admin/password-requests/:id/fulfill
     */
    async fulfillRequest(req: Request, res: Response) {
        try {
            const { id } = req.params;
            const { newPassword, adminNote } = req.body;

            if (!newPassword) {
                return errorResponse(res, 'Mật khẩu mới là bắt buộc', HTTP_STATUS.BAD_REQUEST);
            }

            const result = await passwordRequestService.fulfillRequest(id, newPassword, adminNote);

            if (!result.success) {
                return errorResponse(res, result.message || 'Lỗi thực hiện yêu cầu');
            }

            return successResponse(res, null, result.message);
        } catch (error) {
            logger.error('Controller error in fulfillRequest:', error);
            return errorResponse(res, 'Lỗi thực hiện yêu cầu');
        }
    }

    /**
     * POST /api/admin/password-requests/:id/reject
     */
    async rejectRequest(req: Request, res: Response) {
        try {
            const { id } = req.params;
            const { adminNote } = req.body;

            if (!adminNote) {
                return errorResponse(res, 'Ghi chú lý do từ chối là bắt buộc', HTTP_STATUS.BAD_REQUEST);
            }

            const result = await passwordRequestService.rejectRequest(id, adminNote);

            if (!result.success) {
                return errorResponse(res, result.message || 'Lỗi từ chối yêu cầu');
            }

            return successResponse(res, null, result.message);
        } catch (error) {
            logger.error('Controller error in rejectRequest:', error);
            return errorResponse(res, 'Lỗi từ chối yêu cầu');
        }
    }
}

export const passwordRequestController = new PasswordRequestController();
