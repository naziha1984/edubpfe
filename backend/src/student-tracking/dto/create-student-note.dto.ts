import { IsOptional, IsString, MaxLength } from "class-validator";

export class CreateStudentNoteDto {
  @IsOptional()
  @IsString()
  @MaxLength(1200)
  behavior?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  participation?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  homeworkQuality?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  comprehension?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1800)
  recommendations?: string;
}
