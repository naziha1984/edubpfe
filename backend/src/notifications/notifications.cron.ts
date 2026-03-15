import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationsService } from './notifications.service';
import { Logger } from '@nestjs/common';

@Injectable()
export class NotificationsCron {
  private readonly logger = new Logger(NotificationsCron.name);

  constructor(private readonly notificationsService: NotificationsService) {}

  // 每6小时检查一次作业到期通知
  @Cron('0 */6 * * *', {
    name: 'checkAssignmentDue',
    timeZone: 'UTC',
  })
  async handleAssignmentDue() {
    this.logger.log('Checking assignment due notifications...');
    try {
      await this.notificationsService.checkAssignmentDueNotifications();
      this.logger.log('Assignment due notifications checked successfully');
    } catch (error) {
      this.logger.error('Error checking assignment due notifications:', error);
    }
  }

  // 每天凌晨2点检查不活动通知
  @Cron('0 2 * * *', {
    name: 'checkInactivity',
    timeZone: 'UTC',
  })
  async handleInactivity() {
    this.logger.log('Checking inactivity notifications...');
    try {
      await this.notificationsService.checkInactivityNotifications();
      this.logger.log('Inactivity notifications checked successfully');
    } catch (error) {
      this.logger.error('Error checking inactivity notifications:', error);
    }
  }

  // 每天凌晨3点清理旧通知
  @Cron('0 3 * * *', {
    name: 'cleanupOldNotifications',
    timeZone: 'UTC',
  })
  async handleCleanup() {
    this.logger.log('Cleaning up old notifications...');
    try {
      await this.notificationsService.cleanupOldNotifications();
      this.logger.log('Old notifications cleaned up successfully');
    } catch (error) {
      this.logger.error('Error cleaning up old notifications:', error);
    }
  }
}
