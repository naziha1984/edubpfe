import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Notification,
  NotificationDocument,
  NotificationType,
  NotificationStatus,
} from './schemas/notification.schema';
import { Assignment, AssignmentDocument } from './schemas/assignment.schema';
import {
  ClassMembership,
  ClassMembershipDocument,
} from '../classes/schemas/class-membership.schema';
import { Progress, ProgressDocument } from '../quiz/schemas/progress.schema';
import { Kid, KidDocument } from '../kids/schemas/kid.schema';
import { UserRole } from '../users/schemas/user.schema';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name)
    private notificationModel: Model<NotificationDocument>,
    @InjectModel(Assignment.name)
    private assignmentModel: Model<AssignmentDocument>,
    @InjectModel(ClassMembership.name)
    private classMembershipModel: Model<ClassMembershipDocument>,
    @InjectModel(Progress.name) private progressModel: Model<ProgressDocument>,
    @InjectModel(Kid.name) private kidModel: Model<KidDocument>,
  ) {}

  async getNotifications(
    userId: string,
    _userRole: UserRole,
  ): Promise<NotificationDocument[]> {
    // Pour l’instant la logique ne dépend pas du rôle utilisateur.
    void _userRole;

    return this.notificationModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
  }

  async markAsRead(
    notificationId: string,
    userId: string,
  ): Promise<NotificationDocument> {
    const notification = await this.notificationModel
      .findOne({
        _id: new Types.ObjectId(notificationId),
        userId: new Types.ObjectId(userId),
      })
      .exec();

    if (!notification) {
      throw new Error('Notification not found');
    }

    if (notification.status === NotificationStatus.READ) {
      return notification;
    }

    notification.status = NotificationStatus.READ;
    notification.readAt = new Date();
    return notification.save();
  }

  // Cron job: 检查作业到期前24小时
  async checkAssignmentDueNotifications(): Promise<void> {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // 查找24小时内到期的作业
    const assignments = await this.assignmentModel
      .find({
        dueDate: {
          $gte: now,
          $lte: in24Hours,
        },
        isActive: true,
      })
      .populate('classId')
      .exec();

    for (const assignment of assignments) {
      const classDoc = assignment.classId as any;
      if (!classDoc) continue;

      // 获取班级的所有成员（kids）
      const memberships = await this.classMembershipModel
        .find({
          classId: classDoc._id,
          isActive: true,
        })
        .populate('kidId')
        .exec();

      for (const membership of memberships) {
        const kid = membership.kidId as any;
        if (!kid) continue;

        // 检查是否已经有通知（避免重复）
        const existingNotification = await this.notificationModel
          .findOne({
            userId: kid.parentId,
            type: NotificationType.ASSIGNMENT_DUE_24H,
            relatedId: assignment._id,
            status: NotificationStatus.UNREAD,
          })
          .exec();

        if (!existingNotification) {
          // 创建通知给 parent
          const notification = new this.notificationModel({
            userId: kid.parentId,
            type: NotificationType.ASSIGNMENT_DUE_24H,
            status: NotificationStatus.UNREAD,
            title: 'Assignment Due Soon',
            message: `Assignment "${assignment.title}" is due in less than 24 hours for ${kid.firstName} ${kid.lastName}`,
            kidId: kid._id,
            relatedId: assignment._id,
            relatedType: 'assignment',
          });
          await notification.save();

          // 也创建通知给 teacher（如果作业还没完成）
          const existingTeacherNotification = await this.notificationModel
            .findOne({
              userId: assignment.teacherId,
              type: NotificationType.ASSIGNMENT_DUE_24H,
              relatedId: assignment._id,
              kidId: kid._id,
              status: NotificationStatus.UNREAD,
            })
            .exec();

          if (!existingTeacherNotification) {
            const teacherNotification = new this.notificationModel({
              userId: assignment.teacherId,
              type: NotificationType.ASSIGNMENT_DUE_24H,
              status: NotificationStatus.UNREAD,
              title: 'Assignment Due Soon',
              message: `Assignment "${assignment.title}" is due in less than 24 hours. Student: ${kid.firstName} ${kid.lastName}`,
              kidId: kid._id,
              relatedId: assignment._id,
              relatedType: 'assignment',
            });
            await teacherNotification.save();
          }
        }
      }
    }
  }

  // Cron job: 检查3天不活动
  async checkInactivityNotifications(): Promise<void> {
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    // 查找所有活跃的 kids
    const kids = await this.kidModel.find({ isActive: true }).exec();

    for (const kid of kids) {
      // 查找 kid 的最后活动（Progress 的 lastAttemptAt）
      const lastProgress = await this.progressModel
        .findOne({ kidId: kid._id })
        .sort({ lastAttemptAt: -1 })
        .exec();

      const lastActivity = lastProgress?.lastAttemptAt || kid.createdAt;

      // 如果最后活动超过3天
      if (lastActivity < threeDaysAgo) {
        // 检查是否已经有通知（避免重复）
        const existingNotification = await this.notificationModel
          .findOne({
            userId: kid.parentId,
            type: NotificationType.INACTIVITY_3_DAYS,
            kidId: kid._id,
            status: NotificationStatus.UNREAD,
            createdAt: {
              $gte: threeDaysAgo,
            },
          })
          .exec();

        if (!existingNotification) {
          // 创建通知给 parent
          const notification = new this.notificationModel({
            userId: kid.parentId,
            type: NotificationType.INACTIVITY_3_DAYS,
            status: NotificationStatus.UNREAD,
            title: 'Inactivity Alert',
            message: `${kid.firstName} ${kid.lastName} has been inactive for 3 days`,
            kidId: kid._id,
            relatedType: 'kid',
          });
          await notification.save();
        }
      }
    }
  }

  // 清理旧通知（可选）
  async cleanupOldNotifications(): Promise<void> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    await this.notificationModel
      .deleteMany({
        status: NotificationStatus.READ,
        readAt: { $lt: thirtyDaysAgo },
      })
      .exec();
  }
}
