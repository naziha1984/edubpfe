import { IsMongoId, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';
import { QuizDifficulty } from '../schemas/quiz-question.schema';

export class CreateSessionDto {
  @IsMongoId()
  @IsNotEmpty()
  kidId: string;

  @IsMongoId()
  @IsNotEmpty()
  lessonId: string;

  @IsOptional()
  @IsEnum(QuizDifficulty)
  difficulty?: QuizDifficulty;
}
