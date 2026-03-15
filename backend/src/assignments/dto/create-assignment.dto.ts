import { IsString, IsNotEmpty, IsOptional, IsMongoId, IsDateString } from 'class-validator';

export class CreateAssignmentDto {
  @IsMongoId()
  @IsNotEmpty()
  classId: string;

  @IsMongoId()
  @IsOptional()
  lessonId?: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsDateString()
  @IsNotEmpty()
  dueDate: string;
}
