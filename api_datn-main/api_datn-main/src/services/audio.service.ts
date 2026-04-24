import ffmpeg from 'fluent-ffmpeg';
import ffmpegPath from 'ffmpeg-static';
const ffprobePath = require('ffprobe-static');
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

if (ffmpegPath) {
    console.log('--- AUDIO SERVICE: SETTING FF_MPEG PATH ---');
    console.log('FF_MPEG PATH:', ffmpegPath);
    ffmpeg.setFfmpegPath(ffmpegPath);
} else {
    console.warn('--- AUDIO SERVICE: FF_MPEG_STATIC PATH NOT FOUND, USING SYSTEM DEFAULT ---');
}

if (ffprobePath) {
    const actualFfprobePath = typeof ffprobePath === 'string' ? ffprobePath : ffprobePath.path;
    console.log('--- AUDIO SERVICE: SETTING FF_PROBE PATH ---');
    console.log('FF_PROBE PATH:', actualFfprobePath);
    ffmpeg.setFfprobePath(actualFfprobePath);
} else {
    console.warn('--- AUDIO SERVICE: FF_PROBE_STATIC PATH NOT FOUND ---');
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
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                // Sanitize filename: use UUID + original extension or just .mp3
                const ext = path.extname(file.originalname) || '.mp3';
                const tempInputPath = path.join(tempDir, `input_${uuidv4()}${ext}`);
                
                fs.writeFileSync(tempInputPath, file.buffer);
                inputPaths.push(tempInputPath);
                console.log(`Temp input file created: ${tempInputPath}`);
            }

            return new Promise((resolve, reject) => {
                const command = ffmpeg();

                inputPaths.forEach(p => {
                    command.input(p);
                });

                command
                    .on('start', (commandLine) => {
                        console.log('--- FFmpeg COMMAND START ---');
                        console.log('Spawned FFmpeg with command: ' + commandLine);
                    })
                    .on('error', (err, _stdout, stderr) => {
                        console.error('--- FFmpeg ERROR ---');
                        console.error('Error message:', err.message);
                        console.error('FFmpeg stderr:', stderr);
                        this.cleanup(inputPaths, outputPath);
                        reject(new Error(`FFmpeg failed: ${err.message}`));
                    })
                    .on('end', () => {
                        console.log('--- FFmpeg MERGE FINISHED ---');
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
