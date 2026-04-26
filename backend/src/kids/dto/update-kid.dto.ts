import {
  IsString,
  IsOptional,
  IsDateString,
  IsBoolean,
  IsInt,
  Min,
  Max,
} from "class-validator";

export class UpdateKidDto {
  @IsString()
  @IsOptional()
  firstName?: string;

  @IsString()
  @IsOptional()
  lastName?: string;

  @IsDateString()
  @IsOptional()
  dateOfBirth?: string;

  @IsString()
  @IsOptional()
  grade?: string;

  @IsString()
  @IsOptional()
  school?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(6)
  schoolLevel?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
