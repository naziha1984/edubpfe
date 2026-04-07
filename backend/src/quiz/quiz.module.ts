import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { QuizController } from './quiz.controller';
import { ProgressController } from './progress.controller';
import { QuizService } from './quiz.service';
import { ProgressService } from './progress.service';
import { QuizSession, QuizSessionSchema } from './schemas/quiz-session.schema';
import { Progress, ProgressSchema } from './schemas/progress.schema';
import {
  QuizQuestion,
  QuizQuestionSchema,
} from './schemas/quiz-question.schema';
import { SubjectsModule } from '../subjects/subjects.module';
import { KidsModule } from '../kids/kids.module';
import { RewardsModule } from '../rewards/rewards.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ClassesModule } from '../classes/classes.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: QuizSession.name, schema: QuizSessionSchema },
      { name: Progress.name, schema: ProgressSchema },
      { name: QuizQuestion.name, schema: QuizQuestionSchema },
    ]),
    SubjectsModule,
    KidsModule,
    RewardsModule,
    NotificationsModule,
    ClassesModule,
  ],
  controllers: [QuizController, ProgressController],
  providers: [QuizService, ProgressService],
  exports: [QuizService, ProgressService],
})
export class QuizModule {}
