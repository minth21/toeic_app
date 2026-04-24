import { v2 as cloudinary } from 'cloudinary';
import * as dotenv from 'dotenv';

dotenv.config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function listAllResources() {
  console.log('--- DANH SÁCH 50 FILE MỚI NHẤT TRÊN CLOUDINARY ---');
  const result = await cloudinary.api.resources({
    resource_type: 'video',
    type: 'upload',
    max_results: 50,
    direction: 'desc'
  });

  result.resources.forEach((r: any) => {
    console.log(`- [${r.created_at}] ID: ${r.public_id}`);
    console.log(`  URL: ${r.secure_url}`);
  });
}

listAllResources().catch(console.error);
