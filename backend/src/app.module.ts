import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule } from './config/config.module';
import { DatabaseModule } from './database/database.module';
import { LoggerService } from './common/logger/logger.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { KidsModule } from './kids/kids.module';
import { SubjectsModule } from './subjects/subjects.module';
import { QuizModule } from './quiz/quiz.module';
import { ClassesModule } from './classes/classes.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { RewardsModule } from './rewards/rewards.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ChatbotModule } from './chatbot/chatbot.module';
import { AdminModule } from './admin/admin.module';
import { AssignmentsModule } from './assignments/assignments.module';
import { LiveSessionsModule } from './live-sessions/live-sessions.module';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    UsersModule,
    AuthModule,
    KidsModule,
    SubjectsModule,
    QuizModule,
    ClassesModule,
    AnalyticsModule,
    RewardsModule,
    NotificationsModule,
    ChatbotModule,
    AdminModule,
    AssignmentsModule,
    LiveSessionsModule,
  ],
  controllers: [AppController],
  providers: [AppService, LoggerService],
})
export class AppModule {}
