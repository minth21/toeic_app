import { MaterialType, MaterialCategory } from '@prisma/client';

export class CreateClassMaterialDto {
  title!: string;
  description?: string;
  type!: MaterialType;
  category?: MaterialCategory;
  url?: string;
}

export class CreateClassSessionDto {
  title!: string;
  description?: string;
  sessionDate!: string; // ISO string from frontend
  startTime?: string;
  endTime?: string;
  location?: string;
}
