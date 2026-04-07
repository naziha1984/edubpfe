import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SubjectsController } from './subjects.controller';
import { LessonsController } from './lessons.controller';
import { SubjectsService } from './subjects.service';
import { LessonsService } from './lessons.service';
import { Subject, SubjectSchema } from './schemas/subject.schema';
import { Lesson, LessonSchema } from './schemas/lesson.schema';
import {
  QuizQuestion,
  QuizQuestionSchema,
} from '../quiz/schemas/quiz-question.schema';
import { QuizQuestionCountService } from './quiz-question-count.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Subject.name, schema: SubjectSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: QuizQuestion.name, schema: QuizQuestionSchema },
    ]),
  ],
  controllers: [SubjectsController, LessonsController],
  providers: [SubjectsService, LessonsService, QuizQuestionCountService],
  exports: [SubjectsService, LessonsService],
})
export class SubjectsModule {}
