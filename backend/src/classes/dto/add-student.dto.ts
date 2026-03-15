import { IsMongoId, IsNotEmpty } from 'class-validator';

export class AddStudentDto {
  @IsMongoId()
  @IsNotEmpty()
  kidId: string;
}
