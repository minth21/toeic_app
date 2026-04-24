import { v2 as cloudinary } from 'cloudinary';
import * as dotenv from 'dotenv';

dotenv.config();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function listAudioFiles() {
    console.log('--- ĐANG LIỆT KÊ AUDIO TRONG THƯ MỤC toeic_practice/exam-audio ---');
    try {
        const result = await cloudinary.api.resources({
            type: 'upload',
            resource_type: 'video', // Audio được Cloudinary coi là video
            prefix: 'toeic_practice/exam-audio',
            max_results: 100
        });

        if (result.resources && result.resources.length > 0) {
            result.resources.forEach((res: any) => {
                console.log(`- Public ID: ${res.public_id}`);
                console.log(`  URL: ${res.secure_url}`);
            });
        } else {
            console.log('Không tìm thấy file nào trong thư mục này.');
        }
        
        // Thử search rộng hơn với original_filename
        console.log('\n--- THỬ SEARCH THEO TÊN FILE GỐC (original_filename) ---');
        const searchResult = await cloudinary.search
            .expression('original_filename:Test01*')
            .execute();
            
        if (searchResult.resources && searchResult.resources.length > 0) {
            searchResult.resources.forEach((res: any) => {
                console.log(`- [FOUND] Public ID: ${res.public_id}`);
                console.log(`  Original Filename: ${res.original_filename}`);
                console.log(`  URL: ${res.secure_url}`);
            });
        } else {
            console.log('Search theo original_filename cũng không thấy "Test01".');
        }

    } catch (error) {
        console.error('Lỗi khi truy vấn Cloudinary:', error);
    }
}

listAudioFiles();
