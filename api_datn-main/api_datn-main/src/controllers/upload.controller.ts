import { Request, Response, NextFunction } from 'express';
import { uploadExamImageToCloudinary, uploadAudioToCloudinary, uploadAudioFileToCloudinary, saveAssetToDb } from '../config/cloudinary.config';
import { AudioService } from '../services/audio.service';

/**
 * Upload image to Cloudinary (Exam Images)
 */
export const uploadExamImage = async (req: Request, res: Response, next: NextFunction) => {
    try {
        if (!req.file) {
            res.status(400).json({ success: false, message: 'No file uploaded' });
            return;
        }

        const result = await uploadExamImageToCloudinary(req.file.buffer);
        
        // Log to DB (Antigravity Audit Log)
        await saveAssetToDb(result, (req as any).user?.id);

        res.status(200).json({
            success: true,
            message: 'Image uploaded successfully',
            url: result.secure_url,
            publicId: result.public_id
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Upload audio to Cloudinary
 */
export const uploadAudio = async (req: Request, res: Response, next: NextFunction) => {
    try {
        if (!req.file) {
            res.status(400).json({ success: false, message: 'No file uploaded' });
            return;
        }

        const result = await uploadAudioToCloudinary(req.file.buffer);

        // Log to DB (Antigravity Audit Log)
        await saveAssetToDb(result, (req as any).user?.id);

        res.status(200).json({
            success: true,
            message: 'Audio uploaded successfully',
            url: result.secure_url,
            publicId: result.public_id
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Merge multiple audio files and upload to Cloudinary
 */
export const mergeAudio = async (req: Request, res: Response, next: NextFunction) => {
    let mergedPath: string | null = null;
    try {
        const files = req.files as Express.Multer.File[];
        if (!files || files.length < 2) {
            res.status(400).json({ success: false, message: 'At least 2 audio files are required for merging' });
            return;
        }

        // 1. Merge files using AudioService
        mergedPath = await AudioService.mergeAudioFiles(files);

        // 2. Upload merged file to Cloudinary
        const result = await uploadAudioFileToCloudinary(mergedPath);

        // 3. Log to DB
        await saveAssetToDb(result, (req as any).user?.id);

        // 4. Cleanup temp file
        await AudioService.deleteTempFile(mergedPath);
        mergedPath = null;

        res.status(200).json({
            success: true,
            message: 'Audio merged and uploaded successfully',
            url: result.secure_url,
            publicId: result.public_id
        });
    } catch (error) {
        // Ensure cleanup on error
        if (mergedPath) {
            await AudioService.deleteTempFile(mergedPath).catch(console.error);
        }
        next(error);
    }
};
