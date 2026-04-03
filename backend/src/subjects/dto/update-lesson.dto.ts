import {
  IsString,
  IsOptional,
  IsNumber,
  IsBoolean,
  IsMongoId,
} from 'class-validator';

export class UpdateLessonDto {
  @IsMongoId()
  @IsOptional()
  subjectId?: string;

  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  content?: string;

  @IsNumber()
  @IsOptional()
  order?: number;

  @IsString()
  @IsOptional()
  level?: string;

  @IsString()
  @IsOptional()
  language?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
