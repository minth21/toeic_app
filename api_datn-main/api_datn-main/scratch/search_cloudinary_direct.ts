import { v2 as cloudinary } from 'cloudinary';
import * as dotenv from 'dotenv';

dotenv.config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function findInCloudinary() {
  console.log('--- ĐANG TÌM KIẾM TRỰC TIẾP TRÊN CLOUDINARY ---');
  
  // Thử tìm theo public_id hoặc folder
  const searchResult = await cloudinary.search
    .expression('Test01_Part3*')
    .execute();

  console.log(`Tìm thấy ${searchResult.total_count} file.`);
  searchResult.resources.forEach((r: any) => {
    console.log(`- Public ID: ${r.public_id}`);
    console.log(`  URL: ${r.secure_url}`);
  });
}

findInCloudinary().catch(console.error);
