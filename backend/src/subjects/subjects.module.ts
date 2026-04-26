import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { SubjectsController } from "./subjects.controller";
import { LessonsController } from "./lessons.controller";
import { SubjectsService } from "./subjects.service";
import { LessonsService } from "./lessons.service";
import { Subject, SubjectSchema } from "./schemas/subject.schema";
import { Lesson, LessonSchema } from "./schemas/lesson.schema";
import {
  LessonReview,
  LessonReviewSchema,
} from "./schemas/lesson-review.schema";
import {
  QuizQuestion,
  QuizQuestionSchema,
} from "../quiz/schemas/quiz-question.schema";
import { QuizQuestionCountService } from "./quiz-question-count.service";
import { Kid, KidSchema } from "../kids/schemas/kid.schema";
import { NotificationsModule } from "../notifications/notifications.module";
import { RewardsModule } from "../rewards/rewards.module";
import { User, UserSchema } from "../users/schemas/user.schema";
import {
  ClassMembership,
  ClassMembershipSchema,
} from "../classes/schemas/class-membership.schema";
import {
  KidTeacherSelection,
  KidTeacherSelectionSchema,
} from "../kids/schemas/kid-teacher-selection.schema";

@Module({
  imports: [
    NotificationsModule,
    RewardsModule,
    MongooseModule.forFeature([
      { name: Subject.name, schema: SubjectSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: LessonReview.name, schema: LessonReviewSchema },
      { name: Kid.name, schema: KidSchema },
      { name: User.name, schema: UserSchema },
      { name: ClassMembership.name, schema: ClassMembershipSchema },
      { name: KidTeacherSelection.name, schema: KidTeacherSelectionSchema },
      { name: QuizQuestion.name, schema: QuizQuestionSchema },
    ]),
  ],
  controllers: [SubjectsController, LessonsController],
  providers: [SubjectsService, LessonsService, QuizQuestionCountService],
  exports: [SubjectsService, LessonsService],
})
export class SubjectsModule {}
