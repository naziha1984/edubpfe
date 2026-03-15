import {
  Controller,
  Get,
  Patch,
  Param,
  UseGuards,
  Query,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('notifications')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.PARENT, UserRole.TEACHER)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async getNotifications(
    @GetUser() user: any,
    @Query('status') status?: string,
  ) {
    const notifications = await this.notificationsService.getNotifications(
      user.id,
      user.role,
    );

    // 如果指定了 status 过滤
    let filtered = notifications;
    if (status === 'unread') {
      filtered = notifications.filter((n) => n.status === 'UNREAD');
    } else if (status === 'read') {
      filtered = notifications.filter((n) => n.status === 'READ');
    }

    return filtered.map((notification) => ({
      id: notification._id.toString(),
      type: notification.type,
      status: notification.status,
      title: notification.title,
      message: notification.message,
      kidId: notification.kidId?.toString(),
      relatedId: notification.relatedId?.toString(),
      relatedType: notification.relatedType,
      readAt: notification.readAt,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
    }));
  }

  @Patch(':id/read')
  async markAsRead(
    @Param('id') id: string,
    @GetUser() user: any,
  ) {
    const notification = await this.notificationsService.markAsRead(id, user.id);
    return {
      id: notification._id.toString(),
      status: notification.status,
      readAt: notification.readAt,
    };
  }
}
