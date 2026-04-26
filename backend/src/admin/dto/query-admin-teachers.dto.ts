import { IsIn, IsOptional, IsString, MaxLength } from "class-validator";

export class QueryAdminTeachersDto {
  @IsOptional()
  @IsString()
  @IsIn(["PENDING", "ACCEPTED", "REJECTED"])
  status?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  search?: string;
}
