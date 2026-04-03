import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { RewardsController } from './rewards.controller';
import { RewardsService } from './rewards.service';
import { BadgeService } from './badge.service';
import { Reward, RewardSchema } from './schemas/reward.schema';
import { Badge, BadgeSchema } from './schemas/badge.schema';
import {
  RewardHistory,
  RewardHistorySchema,
} from './schemas/reward-history.schema';
import { KidsModule } from '../kids/kids.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Reward.name, schema: RewardSchema },
      { name: Badge.name, schema: BadgeSchema },
      { name: RewardHistory.name, schema: RewardHistorySchema },
    ]),
    KidsModule,
  ],
  controllers: [RewardsController],
  providers: [RewardsService, BadgeService],
  exports: [RewardsService],
})
export class RewardsModule {}
