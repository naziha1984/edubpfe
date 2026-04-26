import {
  Controller,
  Get,
  Patch,
  Param,
  UseGuards,
  Query,
} from "@nestjs/common";
import { NotificationsService } from "./notifications.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { GetUser } from "../auth/decorators/get-user.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { KidAuthGuard } from "../kids/guards/kid-auth.guard";
import { GetKid } from "../kids/decorators/get-kid.decorator";

@Controller("notifications")
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT, UserRole.TEACHER)
  async getNotifications(
    @GetUser() user: any,
    @Query("status") status?: string,
  ) {
    const notifications = await this.notificationsService.getNotifications(
      user.id,
      user.role,
    );

    // 如果指定了 status 过滤
    let filtered = notifications;
    if (status === "unread") {
      filtered = notifications.filter((n) => n.status === "UNREAD");
    } else if (status === "read") {
      filtered = notifications.filter((n) => n.status === "READ");
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

  @Get("unread-count")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT, UserRole.TEACHER)
  async getUnreadCount(@GetUser() user: any) {
    const unreadCount = await this.notificationsService.getUnreadCount(user.id);
    return { unreadCount };
  }

  @Patch(":id/read")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT, UserRole.TEACHER)
  async markAsRead(@Param("id") id: string, @GetUser() user: any) {
    const notification = await this.notificationsService.markAsRead(
      id,
      user.id,
    );
    return {
      id: notification._id.toString(),
      status: notification.status,
      readAt: notification.readAt,
    };
  }

  @Get("kid")
  @UseGuards(KidAuthGuard)
  async getKidNotifications(@GetKid() kid: any) {
    const notifications = await this.notificationsService.getKidNotifications(
      kid.kidId,
    );
    return notifications.map((notification) => ({
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

  @Get("kid/unread-count")
  @UseGuards(KidAuthGuard)
  async getKidUnreadCount(@GetKid() kid: any) {
    const unreadCount = await this.notificationsService.getKidUnreadCount(
      kid.kidId,
    );
    return { unreadCount };
  }

  @Patch("kid/:id/read")
  @UseGuards(KidAuthGuard)
  async markKidAsRead(@Param("id") id: string, @GetKid() kid: any) {
    const notification =
      await this.notificationsService.markKidNotificationAsRead(id, kid.kidId);
    return {
      id: notification._id.toString(),
      status: notification.status,
      readAt: notification.readAt,
    };
  }
}
