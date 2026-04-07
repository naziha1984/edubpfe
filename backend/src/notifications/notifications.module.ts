import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from '@nestjs/schedule';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { NotificationsCron } from './notifications.cron';
import { NotificationsGateway } from './notifications.gateway';
import { AuthModule } from '../auth/auth.module';
import {
  Notification,
  NotificationSchema,
} from './schemas/notification.schema';
import { Assignment, AssignmentSchema } from './schemas/assignment.schema';
import {
  ClassMembership,
  ClassMembershipSchema,
} from '../classes/schemas/class-membership.schema';
import { Progress, ProgressSchema } from '../quiz/schemas/progress.schema';
import { Kid, KidSchema } from '../kids/schemas/kid.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: Assignment.name, schema: AssignmentSchema },
      { name: ClassMembership.name, schema: ClassMembershipSchema },
      { name: Progress.name, schema: ProgressSchema },
      { name: Kid.name, schema: KidSchema },
    ]),
    ScheduleModule.forRoot(),
    AuthModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsCron, NotificationsGateway],
  exports: [NotificationsService],
})
export class NotificationsModule {}
