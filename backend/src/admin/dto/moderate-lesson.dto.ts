import { IsIn, IsOptional, IsString, MaxLength } from "class-validator";

export class ModerateLessonDto {
  @IsString()
  @IsIn(["APPROVED", "FLAGGED", "HIDDEN"])
  status: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  moderationNote?: string;
}
