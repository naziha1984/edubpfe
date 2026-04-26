import { IsOptional, IsString, MaxLength } from "class-validator";

export class ReviewTeacherDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  rejectionReason?: string;
}
