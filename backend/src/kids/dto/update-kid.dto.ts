import { IsString, IsOptional, IsDateString, IsBoolean } from 'class-validator';

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

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
