import { NestFactory } from '@nestjs/core';
import { AppModule } from '../../app.module';
import { BadgeService } from '../badge.service';
import { BadgeType } from '../schemas/badge.schema';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const logger = new Logger('SeedBadges');
  const badgeService = app.get(BadgeService);

  try {
    const badges = [
      {
        type: BadgeType.QUIZ_MASTER,
        name: 'Quiz Master',
        description: 'Complete 10 quizzes',
        icon: '🎯',
      },
      {
        type: BadgeType.PERFECT_SCORE,
        name: 'Perfect Score',
        description: 'Get 100% on a quiz',
        icon: '⭐',
      },
      {
        type: BadgeType.STREAK_7,
        name: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: '🔥',
      },
      {
        type: BadgeType.STREAK_30,
        name: 'Monthly Champion',
        description: 'Maintain a 30-day streak',
        icon: '👑',
      },
      {
        type: BadgeType.XP_1000,
        name: 'XP Explorer',
        description: 'Reach 1000 XP',
        icon: '🌟',
      },
      {
        type: BadgeType.XP_5000,
        name: 'XP Master',
        description: 'Reach 5000 XP',
        icon: '💎',
      },
    ];

    for (const badgeData of badges) {
      await badgeService.createOrUpdate(badgeData);
      logger.log(`✅ Badge created/updated: ${badgeData.name}`);
    }

    logger.log('🎉 Badge seed completed successfully!');
  } catch (error) {
    logger.error('❌ Badge seed failed:', error);
  } finally {
    await app.close();
  }
}

bootstrap();
