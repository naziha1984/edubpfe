import {
  IsArray,
  ArrayMinSize,
  IsInt,
  IsString,
  IsOptional,
  IsEnum,
  Min,
} from "class-validator";
import { QuizDifficulty } from "../schemas/quiz-question.schema";

export class CreateQuizQuestionDto {
  @IsString()
  question: string;

  @IsArray()
  @ArrayMinSize(2)
  @IsString({ each: true })
  options: string[];

  @IsInt()
  @Min(0)
  correctAnswer: number;

  @IsOptional()
  @IsEnum(QuizDifficulty)
  difficulty?: QuizDifficulty;

  @IsOptional()
  @IsString()
  explanation?: string;
}
