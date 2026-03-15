import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { Progress, ProgressSchema } from '../quiz/schemas/progress.schema';
import { ClassMembership, ClassMembershipSchema } from '../classes/schemas/class-membership.schema';
import { ClassesModule } from '../classes/classes.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Progress.name, schema: ProgressSchema },
      { name: ClassMembership.name, schema: ClassMembershipSchema },
    ]),
    ClassesModule,
  ],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
