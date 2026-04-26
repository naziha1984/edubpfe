import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { AdminController } from "./admin.controller";
import { AdminService } from "./admin.service";
import { User, UserSchema } from "../users/schemas/user.schema";
import { Subject, SubjectSchema } from "../subjects/schemas/subject.schema";
import { Lesson, LessonSchema } from "../subjects/schemas/lesson.schema";
import { Kid, KidSchema } from "../kids/schemas/kid.schema";
import { NotificationsModule } from "../notifications/notifications.module";
import {
  Notification,
  NotificationSchema,
} from "../notifications/schemas/notification.schema";

@Module({
  imports: [
    NotificationsModule,
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Subject.name, schema: SubjectSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: Kid.name, schema: KidSchema },
      { name: Notification.name, schema: NotificationSchema },
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
