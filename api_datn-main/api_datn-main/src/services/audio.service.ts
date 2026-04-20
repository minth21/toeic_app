import ffmpeg from 'fluent-ffmpeg';
import ffmpegPath from 'ffmpeg-static';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

if (ffmpegPath) {
    ffmpeg.setFfmpegPath(ffmpegPath);
}

export class AudioService {
    /**
     * Merges multiple audio files into one.
     * @param files Array of Multer files
     * @returns Path to the merged file
     */
    static async mergeAudioFiles(files: Express.Multer.File[]): Promise<string> {
        if (!files || files.length === 0) {
            throw new Error('No files provided for merging');
        }

        const tempDir = path.join(process.cwd(), 'temp_audio');
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir, { recursive: true });
        }

        const inputPaths: string[] = [];
        const outputFileName = `merged_${uuidv4()}.mp3`;
        const outputPath = path.join(tempDir, outputFileName);

        try {
            // Write buffers to temp files
            for (const file of files) {
                const tempInputPath = path.join(tempDir, `input_${uuidv4()}_${file.originalname}`);
                fs.writeFileSync(tempInputPath, file.buffer);
                inputPaths.push(tempInputPath);
            }

            return new Promise((resolve, reject) => {
                const command = ffmpeg();

                inputPaths.forEach(p => {
                    command.input(p);
                });

                command
                    .on('error', (err) => {
                        console.error('FFmpeg error:', err);
                        this.cleanup(inputPaths, outputPath);
                        reject(new Error('Failed to merge audio files'));
                    })
                    .on('end', () => {
                        // Cleanup input files but keep the output file for upload
                        this.cleanup(inputPaths);
                        resolve(outputPath);
                    })
                    .mergeToFile(outputPath, tempDir);
            });
        } catch (error) {
            this.cleanup(inputPaths, outputPath);
            throw error;
        }
    }

    private static cleanup(inputPaths: string[], outputPath?: string) {
        inputPaths.forEach(p => {
            if (fs.existsSync(p)) fs.unlinkSync(p);
        });
        if (outputPath && fs.existsSync(outputPath)) {
            fs.unlinkSync(outputPath);
        }
    }

    /**
     * Helper to delete the merged file after upload to Cloudinary
     */
    static async deleteTempFile(filePath: string) {
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
        }
    }
}
