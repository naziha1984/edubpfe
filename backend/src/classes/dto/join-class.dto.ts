import { IsString, IsNotEmpty, IsMongoId } from "class-validator";

export class JoinClassDto {
  @IsString()
  @IsNotEmpty()
  classCode: string;

  @IsMongoId()
  @IsNotEmpty()
  kidId: string;
}
