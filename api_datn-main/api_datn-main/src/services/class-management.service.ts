import { prisma } from '../config/prisma';
const p = prisma as any;
import { CreateClassMaterialDto, CreateClassSessionDto } from '../dto/class-management.dto';
import { uploadFileToCloudinary, saveAssetToDb } from '../config/cloudinary.config';
import { MaterialType } from '@prisma/client';

export class ClassManagementService {
  /**
   * --- MATERIALS MANAGEMENT ---
   */

  async getMaterials(classId: string, userId?: string) {
    const materials = await prisma.classMaterial.findMany({
      where: { classId },
      include: {
        userProgress: userId ? {
            where: { userId }
        } : undefined
      },
      orderBy: { createdAt: 'desc' },
    });

    return materials.map(m => {
        const { userProgress, ...rest } = m as any;
        return {
            ...rest,
            isCompleted: userProgress && userProgress.length > 0 ? userProgress[0].isCompleted : false
        };
    });
  }

  async addMaterial(classId: string, teacherId: string, dto: CreateClassMaterialDto, file?: Express.Multer.File) {
    // 1. Verify class ownership
    await this.verifyClassTeacher(classId, teacherId);

    let finalUrl = dto.url || '';

    // 2. Handle Case: Upload to Cloudinary (for PDF or Direct Video)
    if (file && (dto.type === MaterialType.PDF || dto.type === MaterialType.VIDEO)) {
      // Create subfolder based on type (e.g., class_materials/pdf)
      const subFolder = `class_materials/${dto.type.toLowerCase()}s`;
      const uploadRes = await uploadFileToCloudinary(file.buffer, subFolder);
      
      // Log to DB (Antigravity Audit Log)
      await saveAssetToDb(uploadRes, teacherId);
      
      finalUrl = uploadRes.secure_url;
    }

    // 3. Create Record
    return prisma.classMaterial.create({
      data: {
        title: dto.title,
        description: dto.description,
        type: dto.type,
        category: dto.category || 'MATERIAL',
        url: finalUrl,
        classId,
      },
    });
  }

  async deleteMaterial(materialId: string, teacherId: string) {
    const material = await prisma.classMaterial.findUnique({
      where: { id: materialId },
      include: { class: true },
    });

    if (!material) throw new Error('Không tìm thấy tài liệu');
    if ((material.class as any).teacherId !== teacherId) throw new Error('Không có quyền xóa');

    return prisma.classMaterial.delete({ where: { id: materialId } });
  }

  async toggleMaterialStatus(materialId: string, userId: string) {
    const progress = await prisma.userMaterialProgress.findUnique({
      where: { userId_materialId: { userId, materialId } }
    });

    if (progress) {
      return prisma.userMaterialProgress.update({
        where: { id: progress.id },
        data: { isCompleted: !progress.isCompleted }
      });
    } else {
      return prisma.userMaterialProgress.create({
        data: {
          userId,
          materialId,
          isCompleted: true
        }
      });
    }
  }

  /**
   * --- SESSIONS (SCHEDULE) MANAGEMENT ---
   */

  async getSessions(classId: string) {
    return p.classSession.findMany({
      where: { classId },
      orderBy: { sessionDate: 'asc' },
    });
  }

  async addSession(classId: string, teacherId: string, dto: CreateClassSessionDto) {
    await this.verifyClassTeacher(classId, teacherId);

    return p.classSession.create({
      data: {
        classId,
        title: dto.title,
        description: dto.description,
        sessionDate: new Date(dto.sessionDate),
        startTime: dto.startTime,
        endTime: dto.endTime,
        location: dto.location,
      },
    });
  }

  async deleteSession(sessionId: string, teacherId: string) {
    const session = await p.classSession.findUnique({
      where: { id: sessionId },
      include: { class: true },
    });

    if (!session) throw new Error('Không tìm thấy buổi học');
    if ((session.class as any).teacherId !== teacherId) throw new Error('Không có quyền xóa');

    return p.classSession.delete({
      where: { id: sessionId },
    });
  }

  /**
   * --- HELPERS ---
   */

  private async verifyClassTeacher(classId: string, teacherId: string) {
    const clazz = await prisma.class.findUnique({
      where: { id: classId },
      select: { teacherId: true },
    });

    if (!clazz) throw new Error('Không tìm thấy lớp học');
    if (clazz.teacherId !== teacherId) {
      throw new Error('Bạn không phải là giáo viên quản lý lớp này');
    }
  }
}
