import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsMongoId,
  IsDateString,
  IsUrl,
} from "class-validator";

export class CreateLiveSessionDto {
  @IsMongoId()
  @IsNotEmpty()
  classId: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsDateString()
  @IsNotEmpty()
  scheduledAt: string;

  @IsUrl()
  @IsNotEmpty()
  meetingUrl: string;
}
