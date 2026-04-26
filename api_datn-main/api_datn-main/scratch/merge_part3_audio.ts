import { prisma } from '../src/config/prisma';
import { v2 as cloudinary } from 'cloudinary';
import ffmpeg from 'fluent-ffmpeg';
import ffmpegPath from 'ffmpeg-static';
import * as fs from 'fs';
import * as path from 'path';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import * as dotenv from 'dotenv';

dotenv.config();

// Configure
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

if (ffmpegPath) {
  ffmpeg.setFfmpegPath(ffmpegPath);
}

async function downloadFile(url: string, dest: string) {
  const response = await axios({
    method: 'GET',
    url: url,
    responseType: 'stream'
  });
  const writer = fs.createWriteStream(dest);
  response.data.pipe(writer);
  return new Promise<void>((resolve, reject) => {
    writer.on('finish', () => resolve());
    writer.on('error', reject);
  });
}

async function main() {
  console.log('--- Bắt đầu quy trình gộp Audio Part 3 - Test 1 ---');

  // 1. Tìm Part 3 của Test 1
  const part = await prisma.part.findFirst({
    where: {
      partNumber: 3,
      test: { title: { contains: 'Test 1', mode: 'insensitive' } }
    },
    include: { test: true }
  });

  if (!part) {
    console.error('Không tìm thấy Part 3 của Test 1 trong Database.');
    return;
  }
  console.log(`Đã tìm thấy Part ID: ${part.id} thuộc đề: ${part.test.title}`);

  // 2. Tìm link 2 file trên Cloudinary
  // Giả định tên file là publicId hoặc nằm trong URL
  const file1Name = 'Test01_Part3_1';
  const file2Name = 'Test01_Part3_2';

  // Thử tìm trong DB trước (CloudinaryAsset table)
  const assets = await prisma.cloudinaryAsset.findMany({
    where: {
      OR: [
        { publicId: { contains: file1Name, mode: 'insensitive' } },
        { publicId: { contains: file2Name, mode: 'insensitive' } },
        { url: { contains: file1Name, mode: 'insensitive' } },
        { url: { contains: file2Name, mode: 'insensitive' } }
      ]
    }
  });

  let url1 = assets.find(a => a.publicId.includes(file1Name) || a.url.includes(file1Name))?.url;
  let url2 = assets.find(a => a.publicId.includes(file2Name) || a.url.includes(file2Name))?.url;

  // Nếu không thấy trong DB, thử lấy trực tiếp từ Cloudinary bằng cách liệt kê toàn bộ (mở rộng loại tài nguyên)
  if (!url1 || !url2) {
    console.log('Không tìm thấy link trong DB, đang quét vét cạn Cloudinary (Video, Raw, Image)...');
    try {
      const resourceTypes = ['video', 'raw', 'image'];
      let allResources: any[] = [];
      
      for (const rType of resourceTypes) {
        let nextCursor: string | undefined = undefined;
        console.log(`Đang quét loại: ${rType}...`);
        
        for (let i = 0; i < 3; i++) { // Quét 300 file mỗi loại
          const result: any = await cloudinary.api.resources({
            resource_type: rType,
            type: 'upload',
            max_results: 100,
            next_cursor: nextCursor
          });
          
          allResources = allResources.concat(result.resources.map((r: any) => ({ ...r, rType })));
          nextCursor = result.next_cursor;
          if (!nextCursor) break;
        }
      }

      console.log(`Đã quét tổng cộng ${allResources.length} file trên Cloudinary.`);

      if (!url1) {
        const match = allResources.find((a: any) => 
          a.public_id.toLowerCase().includes(file1Name.toLowerCase()) || 
          (a.original_filename && a.original_filename.toLowerCase().includes(file1Name.toLowerCase()))
        );
        url1 = match?.secure_url;
      }
      
      if (!url2) {
        const match = allResources.find((a: any) => 
          a.public_id.toLowerCase().includes(file2Name.toLowerCase()) || 
          (a.original_filename && a.original_filename.toLowerCase().includes(file2Name.toLowerCase()))
        );
        url2 = match?.secure_url;
      }

      if (!url1 || !url2) {
          console.log('Vẫn chưa thấy. Danh sách tên file gốc/public_id khả nghi:');
          allResources.slice(0, 50).forEach(a => {
              if (a.public_id.includes('toeic') || (a.original_filename && a.original_filename.includes('Test'))) {
                  console.log(`- [${a.rType}] ID: ${a.public_id}, Original: ${a.original_filename || 'N/A'}`);
              }
          });
      }
    } catch (err) {
      console.warn('Lỗi khi quét vét cạn Cloudinary:', err);
    }
  }

  if (!url1 || !url2) {
    console.error('Không tìm thấy đủ 2 file audio trên Cloudinary.');
    console.log('URL 1:', url1);
    console.log('URL 2:', url2);
    return;
  }

  console.log('Đã tìm thấy link:');
  console.log('File 1:', url1);
  console.log('File 2:', url2);

  // 3. Tải và Gộp
  const tempDir = path.join(process.cwd(), 'temp_merge');
  if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir);

  const path1 = path.join(tempDir, 'file1.mp3');
  const path2 = path.join(tempDir, 'file2.mp3');
  const mergedPath = path.join(tempDir, `merged_${uuidv4()}.mp3`);

  console.log('Đang tải file về server tạm...');
  await downloadFile(url1, path1);
  await downloadFile(url2, path2);

  console.log('Đang gộp file...');
  await new Promise<void>((resolve, reject) => {
    ffmpeg()
      .input(path1)
      .input(path2)
      .on('error', reject)
      .on('end', () => resolve())
      .mergeToFile(mergedPath, tempDir);
  });

  // 4. Upload lên Cloudinary
  console.log('Đang upload file đã gộp lên Cloudinary...');
  const uploadResult = await cloudinary.uploader.upload(mergedPath, {
    folder: 'toeic_practice/exam-audio',
    resource_type: 'video',
    public_id: `Test01_Part3_Merged_${uuidv4().substring(0, 8)}`
  });

  console.log('Upload thành công! Link mới:', uploadResult.secure_url);

  // 5. Cập nhật Database
  await prisma.part.update({
    where: { id: part.id },
    data: { audioUrl: uploadResult.secure_url }
  });

  // Lưu log vào CloudinaryAsset
  await prisma.cloudinaryAsset.create({
    data: {
      publicId: uploadResult.public_id,
      url: uploadResult.secure_url,
      resourceType: 'video',
      folder: uploadResult.folder,
      format: uploadResult.format,
      bytes: uploadResult.bytes
    }
  });

  console.log('--- Quy trình hoàn tất! Part 3 đã được cập nhật audio mới. ---');

  // Cleanup
  fs.unlinkSync(path1);
  fs.unlinkSync(path2);
  fs.unlinkSync(mergedPath);
}

main()
  .catch(e => {
    console.error('Lỗi quy trình:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
