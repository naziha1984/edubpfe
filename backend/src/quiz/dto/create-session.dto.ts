import { IsMongoId, IsNotEmpty } from 'class-validator';

export class CreateSessionDto {
  @IsMongoId()
  @IsNotEmpty()
  kidId: string;

  @IsMongoId()
  @IsNotEmpty()
  lessonId: string;
}
