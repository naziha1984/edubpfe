import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type NotificationDocument = Notification &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum NotificationType {
  ASSIGNMENT_DUE_24H = 'ASSIGNMENT_DUE_24H',
  INACTIVITY_3_DAYS = 'INACTIVITY_3_DAYS',
  /** New work assigned to the class */
  ASSIGNMENT_CREATED = 'ASSIGNMENT_CREATED',
  /** Live session scheduled */
  LIVE_SESSION_SCHEDULED = 'LIVE_SESSION_SCHEDULED',
  /** Live session is in progress */
  LIVE_SESSION_STARTED = 'LIVE_SESSION_STARTED',
  /** Quiz / lesson progress */
  CHILD_PROGRESS = 'CHILD_PROGRESS',
  /** XP, badges, streaks */
  REWARD_EARNED = 'REWARD_EARNED',
  /** Kid turned in homework */
  ASSIGNMENT_SUBMITTED = 'ASSIGNMENT_SUBMITTED',
}

export enum NotificationStatus {
  UNREAD = 'UNREAD',
  READ = 'READ',
}

@Schema({ timestamps: true })
export class Notification {
  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true, enum: NotificationType })
  type: NotificationType;

  @Prop({
    required: true,
    enum: NotificationStatus,
    default: NotificationStatus.UNREAD,
  })
  status: NotificationStatus;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  message: string;

  @Prop({ type: Types.ObjectId, ref: 'Kid' })
  kidId?: Types.ObjectId; // 关联的 kid（如果是关于 kid 的通知）

  @Prop({ type: Types.ObjectId })
  relatedId?: Types.ObjectId; // 关联的实体 ID（assignment, class, etc.）

  @Prop()
  relatedType?: string; // 关联的实体类型（'assignment', 'class', etc.）

  @Prop()
  readAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// 索引用于查询
NotificationSchema.index({ userId: 1, status: 1, createdAt: -1 });
NotificationSchema.index({ userId: 1, type: 1 });
