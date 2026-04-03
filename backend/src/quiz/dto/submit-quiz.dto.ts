import {
  IsMongoId,
  IsNotEmpty,
  IsArray,
  IsNumber,
  ArrayMinSize,
} from 'class-validator';

export class AnswerDto {
  @IsNumber()
  questionIndex: number;

  @IsNumber()
  selectedAnswer: number;
}

export class SubmitQuizDto {
  @IsMongoId()
  @IsNotEmpty()
  sessionId: string;

  @IsArray()
  @ArrayMinSize(1)
  answers: AnswerDto[];
}
