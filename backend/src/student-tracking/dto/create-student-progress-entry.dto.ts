import {
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from "class-validator";

export class CreateStudentProgressEntryDto {
  @IsInt()
  @Min(0)
  @Max(100)
  progressPercent: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  comprehensionScore?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  homeworkScore?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  participationScore?: number;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1600)
  note?: string;
}
