import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Reward, RewardDocument } from './schemas/reward.schema';
import { Badge, BadgeDocument, BadgeType } from './schemas/badge.schema';
import { RewardHistory, RewardHistoryDocument } from './schemas/reward-history.schema';
import { KidsService } from '../kids/kids.service';

@Injectable()
export class RewardsService {
  private readonly XP_PER_LEVEL = 1000; // 每级需要 1000 XP

  constructor(
    @InjectModel(Reward.name) private rewardModel: Model<RewardDocument>,
    @InjectModel(Badge.name) private badgeModel: Model<BadgeDocument>,
    @InjectModel(RewardHistory.name)
    private rewardHistoryModel: Model<RewardHistoryDocument>,
    private kidsService: KidsService,
  ) {}

  async getOrCreateReward(kidId: string): Promise<RewardDocument> {
    let reward = await this.rewardModel
      .findOne({ kidId: new Types.ObjectId(kidId) })
      .exec();

    if (!reward) {
      reward = new this.rewardModel({
        kidId: new Types.ObjectId(kidId),
        totalXP: 0,
        currentLevel: 0,
        currentStreak: 0,
        badges: [],
      });
      await reward.save();
    }

    return reward;
  }

  async addXP(
    kidId: string,
    xpAmount: number,
    source: string,
    sourceId?: string,
    description?: string,
  ): Promise<RewardDocument> {
    const reward = await this.getOrCreateReward(kidId);

    const oldLevel = reward.currentLevel;
    reward.totalXP += xpAmount;
    reward.currentLevel = Math.floor(reward.totalXP / this.XP_PER_LEVEL);

    // Check for level up badges
    await this.checkLevelUpBadges(reward);

    await reward.save();

    // Record in history
    const history = new this.rewardHistoryModel({
      kidId: new Types.ObjectId(kidId),
      xpEarned: xpAmount,
      source,
      sourceId,
      description,
    });
    await history.save();

    return reward;
  }

  async updateStreak(kidId: string): Promise<{ streak: number; xpEarned: number }> {
    const reward = await this.getOrCreateReward(kidId);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const lastStreakDate = reward.lastStreakDate
      ? new Date(reward.lastStreakDate)
      : null;
    if (lastStreakDate) {
      lastStreakDate.setHours(0, 0, 0, 0);
    }

    let xpEarned = 0;

    if (!lastStreakDate) {
      // First streak
      reward.currentStreak = 1;
      reward.lastStreakDate = today;
      xpEarned = 10; // First day bonus
    } else {
      const daysDiff = Math.floor(
        (today.getTime() - lastStreakDate.getTime()) / (1000 * 60 * 60 * 24),
      );

      if (daysDiff === 0) {
        // Already checked in today
        return { streak: reward.currentStreak, xpEarned: 0 };
      } else if (daysDiff === 1) {
        // Consecutive day
        reward.currentStreak += 1;
        reward.lastStreakDate = today;
        xpEarned = 10 + reward.currentStreak * 2; // Base 10 + streak bonus
      } else {
        // Streak broken
        reward.currentStreak = 1;
        reward.lastStreakDate = today;
        xpEarned = 10;
      }
    }

    // Check for streak badges
    await this.checkStreakBadges(reward);

    await reward.save();

    if (xpEarned > 0) {
      await this.addXP(kidId, xpEarned, 'streak', undefined, `Daily streak: ${reward.currentStreak} days`);
    }

    return { streak: reward.currentStreak, xpEarned };
  }

  private async checkLevelUpBadges(reward: RewardDocument): Promise<void> {
    const badges: BadgeType[] = [];

    // XP badges
    if (reward.totalXP >= 5000 && !reward.badges.includes(await this.getBadgeId(BadgeType.XP_5000))) {
      badges.push(BadgeType.XP_5000);
    } else if (reward.totalXP >= 1000 && !reward.badges.includes(await this.getBadgeId(BadgeType.XP_1000))) {
      badges.push(BadgeType.XP_1000);
    }

    if (badges.length > 0) {
      const badgeIds = await Promise.all(
        badges.map((type) => this.getBadgeId(type)),
      );
      reward.badges.push(...badgeIds.filter((id) => id && !reward.badges.includes(id)));
    }
  }

  private async checkStreakBadges(reward: RewardDocument): Promise<void> {
    const badges: BadgeType[] = [];

    if (reward.currentStreak >= 30 && !reward.badges.includes(await this.getBadgeId(BadgeType.STREAK_30))) {
      badges.push(BadgeType.STREAK_30);
    } else if (reward.currentStreak >= 7 && !reward.badges.includes(await this.getBadgeId(BadgeType.STREAK_7))) {
      badges.push(BadgeType.STREAK_7);
    }

    if (badges.length > 0) {
      const badgeIds = await Promise.all(
        badges.map((type) => this.getBadgeId(type)),
      );
      reward.badges.push(...badgeIds.filter((id) => id && !reward.badges.includes(id)));
    }
  }

  async checkQuizBadges(kidId: string, score: number, totalQuestions: number): Promise<void> {
    const reward = await this.getOrCreateReward(kidId);

    // Perfect score badge
    if (score === totalQuestions) {
      const badgeId = await this.getBadgeId(BadgeType.PERFECT_SCORE);
      if (badgeId && !reward.badges.includes(badgeId)) {
        reward.badges.push(badgeId);
        await reward.save();
      }
    }

    // Quiz master badge (count completed quizzes)
    const completedQuizzes = await this.rewardHistoryModel
      .countDocuments({
        kidId: new Types.ObjectId(kidId),
        source: 'quiz',
      })
      .exec();

    if (completedQuizzes >= 10) {
      const badgeId = await this.getBadgeId(BadgeType.QUIZ_MASTER);
      if (badgeId && !reward.badges.includes(badgeId)) {
        reward.badges.push(badgeId);
        await reward.save();
      }
    }
  }

  private async getBadgeId(type: BadgeType): Promise<Types.ObjectId | null> {
    const badge = await this.badgeModel.findOne({ type }).exec();
    return badge ? badge._id : null;
  }

  async getRewardsByKidId(
    kidId: string,
    requesterKidId?: string,
    requesterParentId?: string,
  ) {
    // Strict IDOR check
    if (requesterKidId) {
      if (kidId !== requesterKidId) {
        throw new ForbiddenException('You can only view your own rewards');
      }
    } else if (requesterParentId) {
      const kid = await this.kidsService.findOneById(kidId);
      if (!kid) {
        throw new NotFoundException('Kid not found');
      }
      if (kid.parentId.toString() !== requesterParentId) {
        throw new ForbiddenException('You can only view rewards for your own kids');
      }
    } else {
      throw new ForbiddenException('Authentication required');
    }

    const reward = await this.getOrCreateReward(kidId);
    const badges = await this.badgeModel
      .find({ _id: { $in: reward.badges } })
      .exec();

    const recentHistory = await this.rewardHistoryModel
      .find({ kidId: new Types.ObjectId(kidId) })
      .sort({ createdAt: -1 })
      .limit(10)
      .exec();

    return {
      kidId: reward.kidId.toString(),
      totalXP: reward.totalXP,
      currentLevel: reward.currentLevel,
      xpForNextLevel: this.XP_PER_LEVEL - (reward.totalXP % this.XP_PER_LEVEL),
      currentStreak: reward.currentStreak,
      lastStreakDate: reward.lastStreakDate,
      badges: badges.map((b) => ({
        id: b._id.toString(),
        type: b.type,
        name: b.name,
        description: b.description,
        icon: b.icon,
      })),
      recentHistory: recentHistory.map((h) => ({
        id: h._id.toString(),
        xpEarned: h.xpEarned,
        source: h.source,
        description: h.description,
        createdAt: h.createdAt,
      })),
    };
  }
}
