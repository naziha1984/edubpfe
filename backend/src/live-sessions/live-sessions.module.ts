import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { LiveSessionsController } from './live-sessions.controller';
import { KidLiveSessionsController } from './kid-live-sessions.controller';
import { LiveSessionsService } from './live-sessions.service';
import { LiveSession, LiveSessionSchema } from './schemas/live-session.schema';
import { ClassesModule } from '../classes/classes.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: LiveSession.name, schema: LiveSessionSchema },
    ]),
    ClassesModule,
    NotificationsModule,
  ],
  controllers: [LiveSessionsController, KidLiveSessionsController],
  providers: [LiveSessionsService],
  exports: [LiveSessionsService],
})
export class LiveSessionsModule {}
