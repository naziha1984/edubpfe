import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  TeacherApprovalStatus,
  User,
  UserDocument,
  UserRole,
} from "../users/schemas/user.schema";
import { Subject, SubjectDocument } from "../subjects/schemas/subject.schema";
import {
  Lesson,
  LessonDocument,
  LessonModerationStatus,
} from "../subjects/schemas/lesson.schema";
import { Kid, KidDocument } from "../kids/schemas/kid.schema";
import { NotificationsService } from "../notifications/notifications.service";
import {
  Notification,
  NotificationDocument,
  NotificationStatus,
  NotificationType,
} from "../notifications/schemas/notification.schema";
import { QueryAdminTeachersDto } from "./dto/query-admin-teachers.dto";
import { QueryAdminLessonsDto } from "./dto/query-admin-lessons.dto";

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Subject.name) private subjectModel: Model<SubjectDocument>,
    @InjectModel(Lesson.name) private lessonModel: Model<LessonDocument>,
    @InjectModel(Kid.name) private kidModel: Model<KidDocument>,
    @InjectModel(Notification.name)
    private notificationModel: Model<NotificationDocument>,
    private readonly notificationsService: NotificationsService,
  ) {}

  private mapUser(user: UserDocument) {
    return {
      id: user._id.toString(),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isActive: user.isActive,
      cvUrl: user.cvUrl,
      approvalStatus: user.approvalStatus,
      rejectionReason: user.rejectionReason,
      submittedAt: user.submittedAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  async getUsers(role?: string, search?: string) {
    const query: any = {};

    // Filtrer par rôle
    if (role && Object.values(UserRole).includes(role as UserRole)) {
      query.role = role;
    }

    // Recherche par email, firstName, lastName
    if (search && search.trim()) {
      const searchRegex = new RegExp(search.trim(), "i");
      query.$or = [
        { email: searchRegex },
        { firstName: searchRegex },
        { lastName: searchRegex },
      ];
    }

    const users = await this.userModel.find(query).select("-password").exec();

    return users.map((user) => this.mapUser(user));
  }

  async getKids() {
    const kids = await this.kidModel
      .find()
      .populate("parentId", "email firstName lastName")
      .sort({ createdAt: -1 })
      .exec();

    return kids.map((kid) => {
      const parent = kid.parentId as any;
      return {
        id: kid._id.toString(),
        firstName: kid.firstName,
        lastName: kid.lastName,
        dateOfBirth: kid.dateOfBirth,
        grade: kid.grade,
        schoolLevel: kid.schoolLevel,
        school: kid.school,
        isActive: kid.isActive,
        parentId: kid.parentId?.toString(),
        parentEmail: parent?.email,
        parentFirstName: parent?.firstName,
        parentLastName: parent?.lastName,
        createdAt: kid.createdAt,
        updatedAt: kid.updatedAt,
      };
    });
  }

  async getStats() {
    const [totalUsers, totalSubjects, totalLessons] = await Promise.all([
      this.userModel.countDocuments().exec(),
      this.subjectModel.countDocuments().exec(),
      this.lessonModel.countDocuments().exec(),
    ]);

    return {
      totalUsers,
      totalSubjects,
      totalLessons,
    };
  }

  async getDashboardOverview() {
    const [
      totalUsers,
      totalSubjects,
      totalLessons,
      pendingTeachers,
      flaggedLessons,
      hiddenLessons,
      unreadNotifications,
      recentTeachers,
      recentLessons,
      recentNotifications,
    ] = await Promise.all([
      this.userModel.countDocuments().exec(),
      this.subjectModel.countDocuments().exec(),
      this.lessonModel.countDocuments().exec(),
      this.userModel.countDocuments({
        role: UserRole.TEACHER,
        approvalStatus: TeacherApprovalStatus.PENDING,
      }),
      this.lessonModel.countDocuments({
        moderationStatus: LessonModerationStatus.FLAGGED,
      }),
      this.lessonModel.countDocuments({
        moderationStatus: LessonModerationStatus.HIDDEN,
      }),
      this.notificationModel.countDocuments({
        status: NotificationStatus.UNREAD,
      }),
      this.userModel
        .find({ role: UserRole.TEACHER })
        .select("-password")
        .sort({ submittedAt: -1, createdAt: -1 })
        .limit(5)
        .exec(),
      this.lessonModel
        .find()
        .populate("teacherId", "firstName lastName email")
        .populate("subjectId", "name")
        .sort({ createdAt: -1 })
        .limit(6)
        .exec(),
      this.notificationModel.find().sort({ createdAt: -1 }).limit(6).exec(),
    ]);

    return {
      totalUsers,
      totalSubjects,
      totalLessons,
      pendingTeachers,
      flaggedLessons,
      hiddenLessons,
      unreadNotifications,
      recentTeachers: recentTeachers.map((teacher) => this.mapUser(teacher)),
      recentLessons: recentLessons.map((lesson) => {
        const teacher = lesson.teacherId as unknown as
          | { firstName?: string; lastName?: string; email?: string }
          | undefined;
        const subject = lesson.subjectId as unknown as
          | { name?: string }
          | undefined;
        return {
          id: lesson._id.toString(),
          title: lesson.title,
          subjectName: subject?.name ?? "Subject",
          teacherName:
            `${teacher?.firstName ?? ""} ${teacher?.lastName ?? ""}`.trim() ||
            teacher?.email ||
            "Teacher",
          moderationStatus:
            lesson.moderationStatus ?? LessonModerationStatus.APPROVED,
          createdAt: lesson.createdAt,
          updatedAt: lesson.updatedAt,
        };
      }),
      recentNotifications: recentNotifications.map((notification) => ({
        id: notification._id.toString(),
        title: notification.title,
        message: notification.message,
        type: notification.type,
        status: notification.status,
        createdAt: notification.createdAt,
      })),
    };
  }

  async getNotificationsOverview() {
    const [unreadCount, recentNotifications] = await Promise.all([
      this.notificationModel.countDocuments({
        status: NotificationStatus.UNREAD,
      }),
      this.notificationModel.find().sort({ createdAt: -1 }).limit(20).exec(),
    ]);

    return {
      unreadCount,
      items: recentNotifications.map((notification) => ({
        id: notification._id.toString(),
        title: notification.title,
        message: notification.message,
        type: notification.type,
        status: notification.status,
        relatedType: notification.relatedType,
        createdAt: notification.createdAt,
      })),
    };
  }

  async getTeachers(query: QueryAdminTeachersDto) {
    const filters: Record<string, unknown> = {
      role: UserRole.TEACHER,
    };

    if (query.status) {
      filters.approvalStatus = query.status;
    }

    if (query.search?.trim()) {
      const regex = new RegExp(query.search.trim(), "i");
      filters.$or = [
        { email: regex },
        { firstName: regex },
        { lastName: regex },
      ];
    }

    const teachers = await this.userModel
      .find(filters)
      .select("-password")
      .sort({ submittedAt: -1, createdAt: -1 })
      .exec();

    return teachers.map((teacher) => this.mapUser(teacher));
  }

  async getPendingTeachers() {
    const teachers = await this.userModel
      .find({
        role: UserRole.TEACHER,
        approvalStatus: TeacherApprovalStatus.PENDING,
      })
      .select("-password")
      .sort({ submittedAt: -1, createdAt: -1 })
      .exec();
    return teachers.map((t) => this.mapUser(t));
  }

  async getAdminLessons(query: QueryAdminLessonsDto) {
    const filters: Record<string, unknown> = {};

    if (query.search?.trim()) {
      const regex = new RegExp(query.search.trim(), "i");
      filters.$or = [
        { title: regex },
        { description: regex },
        { level: regex },
      ];
    }

    if (query.teacherId?.trim()) {
      filters.teacherId = new Types.ObjectId(query.teacherId.trim());
    }

    if (query.status) {
      filters.moderationStatus = query.status;
    }

    if (query.dateFrom || query.dateTo) {
      filters.createdAt = {};
      if (query.dateFrom) {
        (filters.createdAt as Record<string, Date>).$gte = new Date(
          query.dateFrom,
        );
      }
      if (query.dateTo) {
        (filters.createdAt as Record<string, Date>).$lte = new Date(
          query.dateTo,
        );
      }
    }

    const lessons = await this.lessonModel
      .find(filters)
      .populate("teacherId", "firstName lastName email")
      .populate("subjectId", "name")
      .sort({ createdAt: -1 })
      .limit(100)
      .exec();

    return lessons.map((lesson) => {
      const teacher = lesson.teacherId as unknown as
        | {
            _id?: Types.ObjectId;
            firstName?: string;
            lastName?: string;
            email?: string;
          }
        | undefined;
      const subject = lesson.subjectId as unknown as
        | { name?: string }
        | undefined;
      return {
        id: lesson._id.toString(),
        title: lesson.title,
        description: lesson.description,
        level: lesson.level,
        isActive: lesson.isActive,
        subjectName: subject?.name ?? "Subject",
        teacherId: teacher?._id?.toString(),
        teacherName:
          `${teacher?.firstName ?? ""} ${teacher?.lastName ?? ""}`.trim() ||
          teacher?.email ||
          "Teacher",
        moderationStatus:
          lesson.moderationStatus ?? LessonModerationStatus.APPROVED,
        moderationNote: lesson.moderationNote,
        createdAt: lesson.createdAt,
        updatedAt: lesson.updatedAt,
      };
    });
  }

  async moderateLesson(
    lessonId: string,
    status: string,
    moderationNote?: string,
  ) {
    const lesson = await this.lessonModel.findById(lessonId).exec();
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }

    lesson.moderationStatus = status as LessonModerationStatus;
    lesson.moderationNote = moderationNote?.trim() || undefined;
    lesson.moderatedAt = new Date();
    await lesson.save();

    if (
      lesson.teacherId &&
      (status === LessonModerationStatus.FLAGGED ||
        status === LessonModerationStatus.HIDDEN)
    ) {
      const readable =
        status === LessonModerationStatus.FLAGGED ? "flagged" : "hidden";
      await this.notificationsService.createForUser(
        lesson.teacherId.toString(),
        NotificationType.ADMIN_LESSON_MODERATED,
        "Lesson moderation update",
        moderationNote?.trim()
          ? `Your lesson "${lesson.title}" was ${readable} by admin. Note: ${moderationNote.trim()}`
          : `Your lesson "${lesson.title}" was ${readable} by admin.`,
        {
          relatedId: lesson._id.toString(),
          relatedType: "lesson-moderation",
        },
      );
    }

    return {
      message: "Lesson moderation updated successfully",
      lessonId: lesson._id.toString(),
      moderationStatus: lesson.moderationStatus,
      moderationNote: lesson.moderationNote,
      moderatedAt: lesson.moderatedAt,
    };
  }

  async getTeacherDetails(teacherId: string) {
    const teacher = await this.userModel
      .findOne({
        _id: teacherId,
        role: UserRole.TEACHER,
      })
      .select("-password")
      .exec();
    if (!teacher) {
      throw new NotFoundException("Teacher not found");
    }
    return this.mapUser(teacher);
  }

  async acceptTeacher(teacherId: string) {
    const teacher = await this.userModel
      .findOne({
        _id: teacherId,
        role: UserRole.TEACHER,
      })
      .exec();
    if (!teacher) {
      throw new NotFoundException("Teacher not found");
    }

    teacher.approvalStatus = TeacherApprovalStatus.ACCEPTED;
    teacher.rejectionReason = undefined;
    await teacher.save();

    await this.notificationsService.createForUser(
      teacher._id.toString(),
      NotificationType.TEACHER_REVIEWED,
      "Teacher profile accepted",
      "Your teacher account has been accepted by the admin.",
      { relatedType: "teacher-approval" },
    );

    return {
      message: "Teacher accepted successfully",
      teacher: this.mapUser(teacher),
    };
  }

  async rejectTeacher(teacherId: string, rejectionReason?: string) {
    const teacher = await this.userModel
      .findOne({
        _id: teacherId,
        role: UserRole.TEACHER,
      })
      .exec();
    if (!teacher) {
      throw new NotFoundException("Teacher not found");
    }

    teacher.approvalStatus = TeacherApprovalStatus.REJECTED;
    teacher.rejectionReason = rejectionReason?.trim() || undefined;
    await teacher.save();

    await this.notificationsService.createForUser(
      teacher._id.toString(),
      NotificationType.TEACHER_REVIEWED,
      "Teacher profile rejected",
      teacher.rejectionReason
        ? `Your teacher account was rejected. Reason: ${teacher.rejectionReason}`
        : "Your teacher account was rejected by the admin.",
      { relatedType: "teacher-approval" },
    );

    return {
      message: "Teacher rejected successfully",
      teacher: this.mapUser(teacher),
    };
  }
}
