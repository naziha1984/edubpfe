import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type NotificationDocument = Notification &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum NotificationType {
  NEW_LESSON_PUBLISHED = "NEW_LESSON_PUBLISHED",
  ASSIGNMENT_DUE_24H = "ASSIGNMENT_DUE_24H",
  INACTIVITY_3_DAYS = "INACTIVITY_3_DAYS",
  /** Nouveau travail assigné à la classe */
  ASSIGNMENT_CREATED = "ASSIGNMENT_CREATED",
  /** Session live planifiée */
  LIVE_SESSION_SCHEDULED = "LIVE_SESSION_SCHEDULED",
  /** Session live en cours */
  LIVE_SESSION_STARTED = "LIVE_SESSION_STARTED",
  /** Progression dans un quiz / une leçon */
  CHILD_PROGRESS = "CHILD_PROGRESS",
  /** XP, badges, séries */
  REWARD_EARNED = "REWARD_EARNED",
  /** Devoir rendu par l'enfant */
  ASSIGNMENT_SUBMITTED = "ASSIGNMENT_SUBMITTED",
  /** Inscription enseignant relue par l'admin */
  TEACHER_REVIEWED = "TEACHER_REVIEWED",
  /** Enseignant sélectionné par le parent pour l'enfant */
  TEACHER_SELECTED = "TEACHER_SELECTED",
  /** Avis parent ajouté ou mis à jour sur une leçon */
  LESSON_REVIEWED = "LESSON_REVIEWED",
  /** Nouveau message direct reçu */
  DIRECT_MESSAGE = "DIRECT_MESSAGE",
  /** Leçon signalée ou masquée par l'admin */
  ADMIN_LESSON_MODERATED = "ADMIN_LESSON_MODERATED",
}

export enum NotificationStatus {
  UNREAD = "UNREAD",
  READ = "READ",
}

@Schema({ timestamps: true })
export class Notification {
  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  userId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "Kid" })
  kidRecipientId?: Types.ObjectId;

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

  @Prop({ type: Types.ObjectId, ref: "Kid" })
  kidId?: Types.ObjectId; // Enfant concerné (si la notification porte sur un enfant)

  @Prop({ type: Types.ObjectId })
  relatedId?: Types.ObjectId; // ID de l'entité liée (assignment, class, etc.)

  @Prop()
  relatedType?: string; // Type de l'entité liée ('assignment', 'class', etc.)

  @Prop()
  readAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// Index de support pour les requêtes
NotificationSchema.index({ userId: 1, status: 1, createdAt: -1 });
NotificationSchema.index({ userId: 1, type: 1 });
NotificationSchema.index({ kidRecipientId: 1, status: 1, createdAt: -1 });
