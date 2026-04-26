import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  Notification,
  NotificationDocument,
  NotificationType,
  NotificationStatus,
} from "./schemas/notification.schema";
import { Assignment, AssignmentDocument } from "./schemas/assignment.schema";
import {
  ClassMembership,
  ClassMembershipDocument,
} from "../classes/schemas/class-membership.schema";
import { Progress, ProgressDocument } from "../quiz/schemas/progress.schema";
import { Kid, KidDocument } from "../kids/schemas/kid.schema";
import { UserRole } from "../users/schemas/user.schema";
import { NotificationsGateway } from "./notifications.gateway";

@Injectable()
export class NotificationsService {
  private gateway: NotificationsGateway | null = null;

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

  attachGateway(gateway: NotificationsGateway) {
    this.gateway = gateway;
  }

  /**
   * Persiste la notification et pousse éventuellement via Socket.IO
   * (parents / enseignants uniquement).
   */
  async createForUser(
    userId: string,
    type: NotificationType,
    title: string,
    message: string,
    opts?: {
      kidId?: string;
      relatedId?: string;
      relatedType?: string;
    },
  ): Promise<NotificationDocument> {
    const doc = new this.notificationModel({
      userId: new Types.ObjectId(userId),
      type,
      status: NotificationStatus.UNREAD,
      title,
      message,
      kidId: opts?.kidId ? new Types.ObjectId(opts.kidId) : undefined,
      relatedId: opts?.relatedId
        ? new Types.ObjectId(opts.relatedId)
        : undefined,
      relatedType: opts?.relatedType,
    });
    await doc.save();
    this.gateway?.emitToUser(userId, {
      id: doc._id.toString(),
      type: doc.type,
      title: doc.title,
      message: doc.message,
      kidId: doc.kidId?.toString(),
      relatedId: doc.relatedId?.toString(),
      relatedType: doc.relatedType,
      createdAt: doc.createdAt,
    });
    return doc;
  }

  async createForKid(
    kidId: string,
    type: NotificationType,
    title: string,
    message: string,
    opts?: {
      relatedId?: string;
      relatedType?: string;
    },
  ): Promise<NotificationDocument> {
    const doc = new this.notificationModel({
      kidRecipientId: new Types.ObjectId(kidId),
      type,
      status: NotificationStatus.UNREAD,
      title,
      message,
      kidId: new Types.ObjectId(kidId),
      relatedId: opts?.relatedId
        ? new Types.ObjectId(opts.relatedId)
        : undefined,
      relatedType: opts?.relatedType,
    });
    await doc.save();
    return doc;
  }

  /** Tous les parents distincts des enfants inscrits dans la classe. */
  async notifyParentsInClass(
    classId: string,
    type: NotificationType,
    title: string,
    message: string,
    opts?: { relatedId?: string; relatedType?: string },
  ): Promise<void> {
    const memberships = await this.classMembershipModel
      .find({
        classId: new Types.ObjectId(classId),
        isActive: true,
      })
      .populate("kidId")
      .exec();

    const parentIds = new Set<string>();
    for (const m of memberships) {
      const kid = m.kidId as unknown as KidDocument;
      if (kid?.parentId) {
        parentIds.add(kid.parentId.toString());
      }
    }

    for (const pid of parentIds) {
      await this.createForUser(pid, type, title, message, {
        relatedId: opts?.relatedId ?? classId,
        relatedType: opts?.relatedType ?? "class",
      });
    }
  }

  async notifyParentOfKid(
    kidId: string,
    type: NotificationType,
    title: string,
    message: string,
    opts?: {
      relatedId?: string;
      relatedType?: string;
    },
  ): Promise<void> {
    const kid = await this.kidModel.findById(kidId).exec();
    if (!kid) {
      return;
    }
    await this.createForUser(kid.parentId.toString(), type, title, message, {
      kidId,
      relatedId: opts?.relatedId,
      relatedType: opts?.relatedType,
    });
  }

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

  async getKidNotifications(kidId: string): Promise<NotificationDocument[]> {
    return this.notificationModel
      .find({ kidRecipientId: new Types.ObjectId(kidId) })
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.notificationModel.countDocuments({
      userId: new Types.ObjectId(userId),
      status: NotificationStatus.UNREAD,
    });
  }

  async getKidUnreadCount(kidId: string): Promise<number> {
    return this.notificationModel.countDocuments({
      kidRecipientId: new Types.ObjectId(kidId),
      status: NotificationStatus.UNREAD,
    });
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
      throw new NotFoundException("Notification not found");
    }

    if (notification.status === NotificationStatus.READ) {
      return notification;
    }

    notification.status = NotificationStatus.READ;
    notification.readAt = new Date();
    return notification.save();
  }

  async markKidNotificationAsRead(
    notificationId: string,
    kidId: string,
  ): Promise<NotificationDocument> {
    const notification = await this.notificationModel
      .findOne({
        _id: new Types.ObjectId(notificationId),
        kidRecipientId: new Types.ObjectId(kidId),
      })
      .exec();

    if (!notification) {
      throw new NotFoundException("Notification not found");
    }

    if (notification.status === NotificationStatus.READ) {
      return notification;
    }

    notification.status = NotificationStatus.READ;
    notification.readAt = new Date();
    return notification.save();
  }

  // Tâche planifiée : vérifier les devoirs qui expirent dans les 24 heures
  async checkAssignmentDueNotifications(): Promise<void> {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Rechercher les devoirs qui arrivent à échéance dans les 24 heures
    const assignments = await this.assignmentModel
      .find({
        dueDate: {
          $gte: now,
          $lte: in24Hours,
        },
        isActive: true,
      })
      .populate("classId")
      .exec();

    for (const assignment of assignments) {
      const classDoc = assignment.classId as any;
      if (!classDoc) continue;

      // Récupérer tous les membres de la classe (enfants)
      const memberships = await this.classMembershipModel
        .find({
          classId: classDoc._id,
          isActive: true,
        })
        .populate("kidId")
        .exec();

      for (const membership of memberships) {
        const kid = membership.kidId as any;
        if (!kid) continue;

        // Vérifier si une notification existe déjà pour éviter les doublons
        const existingNotification = await this.notificationModel
          .findOne({
            userId: kid.parentId,
            type: NotificationType.ASSIGNMENT_DUE_24H,
            relatedId: assignment._id,
            status: NotificationStatus.UNREAD,
          })
          .exec();

        if (!existingNotification) {
          // Créer une notification pour le parent
          const notification = new this.notificationModel({
            userId: kid.parentId,
            type: NotificationType.ASSIGNMENT_DUE_24H,
            status: NotificationStatus.UNREAD,
            title: "Assignment Due Soon",
            message: `Assignment "${assignment.title}" is due in less than 24 hours for ${kid.firstName} ${kid.lastName}`,
            kidId: kid._id,
            relatedId: assignment._id,
            relatedType: "assignment",
          });
          await notification.save();

          // Créer aussi une notification pour l'enseignant si le devoir n'est pas encore terminé
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
              title: "Assignment Due Soon",
              message: `Assignment "${assignment.title}" is due in less than 24 hours. Student: ${kid.firstName} ${kid.lastName}`,
              kidId: kid._id,
              relatedId: assignment._id,
              relatedType: "assignment",
            });
            await teacherNotification.save();
          }
        }
      }
    }
  }

  // Tâche planifiée : vérifier l'inactivité sur 3 jours
  async checkInactivityNotifications(): Promise<void> {
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    // Rechercher tous les enfants actifs
    const kids = await this.kidModel.find({ isActive: true }).exec();

    for (const kid of kids) {
      // Rechercher la dernière activité de l'enfant (Progress.lastAttemptAt)
      const lastProgress = await this.progressModel
        .findOne({ kidId: kid._id })
        .sort({ lastAttemptAt: -1 })
        .exec();

      const lastActivity = lastProgress?.lastAttemptAt || kid.createdAt;

      // Si la dernière activité remonte à plus de 3 jours
      if (lastActivity < threeDaysAgo) {
        // Vérifier si une notification existe déjà pour éviter les doublons
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
          // Créer une notification pour le parent
          const notification = new this.notificationModel({
            userId: kid.parentId,
            type: NotificationType.INACTIVITY_3_DAYS,
            status: NotificationStatus.UNREAD,
            title: "Inactivity Alert",
            message: `${kid.firstName} ${kid.lastName} has been inactive for 3 days`,
            kidId: kid._id,
            relatedType: "kid",
          });
          await notification.save();
        }
      }
    }
  }

  // Nettoyer les anciennes notifications (optionnel)
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
