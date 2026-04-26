import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Lesson, LessonDocument } from "./schemas/lesson.schema";
import {
  LessonReview,
  LessonReviewDocument,
} from "./schemas/lesson-review.schema";
import { CreateLessonDto } from "./dto/create-lesson.dto";
import { UpdateLessonDto } from "./dto/update-lesson.dto";
import { LESSONS_UPLOAD_SUBDIR } from "./lesson-upload.config";
import { UpsertLessonReviewDto } from "./dto/upsert-lesson-review.dto";
import { Kid, KidDocument } from "../kids/schemas/kid.schema";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/schemas/notification.schema";
import { User, UserDocument } from "../users/schemas/user.schema";
import {
  ClassMembership,
  ClassMembershipDocument,
} from "../classes/schemas/class-membership.schema";
import {
  KidTeacherSelection,
  KidTeacherSelectionDocument,
} from "../kids/schemas/kid-teacher-selection.schema";
import { RewardsService } from "../rewards/rewards.service";

@Injectable()
export class LessonsService {
  constructor(
    @InjectModel(Lesson.name) private lessonModel: Model<LessonDocument>,
    @InjectModel(LessonReview.name)
    private lessonReviewModel: Model<LessonReviewDocument>,
    @InjectModel(Kid.name) private kidModel: Model<KidDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(ClassMembership.name)
    private classMembershipModel: Model<ClassMembershipDocument>,
    @InjectModel(KidTeacherSelection.name)
    private kidTeacherSelectionModel: Model<KidTeacherSelectionDocument>,
    private readonly notificationsService: NotificationsService,
    private readonly rewardsService: RewardsService,
  ) {}

  async findAllBySubjectId(
    subjectId: string,
    schoolLevel?: number,
  ): Promise<LessonDocument[]> {
    const query: Record<string, unknown> = {
      subjectId: new Types.ObjectId(subjectId),
      isActive: true,
    };
    if (schoolLevel != null) {
      query.level = {
        $in: [
          schoolLevel.toString(),
          `Year ${schoolLevel}`,
          `YEAR_${schoolLevel}`,
          `Niveau ${schoolLevel}`,
        ],
      };
    }
    return this.lessonModel.find(query).sort({ order: 1, createdAt: 1 }).exec();
  }

  async findOne(id: string): Promise<LessonDocument | null> {
    return this.lessonModel.findById(id).exec();
  }

  async create(
    createLessonDto: CreateLessonDto,
    uploadedFiles: Express.Multer.File[] = [],
    teacherId?: string,
  ): Promise<LessonDocument> {
    try {
      const attachments = uploadedFiles.map((f) => ({
        originalName: f.originalname,
        storedName: f.filename,
        mimeType: f.mimetype,
        size: f.size,
        urlPath: `${LESSONS_UPLOAD_SUBDIR}/${f.filename}`,
      }));
      const lessonData: Record<string, unknown> = {
        ...createLessonDto,
        subjectId: new Types.ObjectId(createLessonDto.subjectId),
        attachments,
      };
      delete lessonData.classId;
      if (createLessonDto.classId) {
        lessonData.classId = new Types.ObjectId(createLessonDto.classId);
      }
      if (teacherId) {
        lessonData.teacherId = new Types.ObjectId(teacherId);
      }
      const lesson = new this.lessonModel(lessonData);
      const savedLesson = await lesson.save();
      await this.notifyLessonPublished(savedLesson);
      return savedLesson;
    } catch (error: any) {
      if (error.code === 11000) {
        throw new ConflictException(
          "Lesson with this title already exists in this subject",
        );
      }
      throw error;
    }
  }

  private async notifyLessonPublished(lesson: LessonDocument): Promise<void> {
    if (!lesson.teacherId) {
      return;
    }

    const teacher = await this.userModel
      .findById(lesson.teacherId)
      .select("firstName lastName")
      .exec();
    const teacherName = teacher
      ? `${teacher.firstName ?? ""} ${teacher.lastName ?? ""}`.trim()
      : "Your teacher";

    const levelNumber = this.extractSchoolLevel(lesson.level);
    const recipientKids = new Map<string, KidDocument>();

    if (lesson.classId) {
      const memberships = await this.classMembershipModel
        .find({
          classId: lesson.classId,
          isActive: true,
        })
        .populate("kidId")
        .exec();

      for (const membership of memberships) {
        const kid = membership.kidId as unknown as KidDocument | null;
        if (!kid || !kid.isActive) continue;
        if (levelNumber != null && kid.schoolLevel !== levelNumber) continue;
        recipientKids.set(kid._id.toString(), kid);
      }
    }

    const selectedKids = await this.kidTeacherSelectionModel
      .find({
        teacherId: lesson.teacherId,
      })
      .populate("kidId")
      .exec();

    for (const selection of selectedKids) {
      const kid = selection.kidId as unknown as KidDocument | null;
      if (!kid || !kid.isActive) continue;
      if (levelNumber != null && kid.schoolLevel !== levelNumber) continue;
      recipientKids.set(kid._id.toString(), kid);
    }

    if (recipientKids.size === 0) {
      return;
    }

    const parentIds = new Set<string>();
    const parentMessage = `${teacherName} published a new lesson: "${lesson.title}".`;
    const kidMessage = `${teacherName} added a new lesson for you: "${lesson.title}".`;

    for (const [kidId, kid] of recipientKids.entries()) {
      parentIds.add(kid.parentId.toString());
      await this.notificationsService.createForKid(
        kidId,
        NotificationType.NEW_LESSON_PUBLISHED,
        "New lesson available",
        kidMessage,
        {
          relatedId: lesson._id.toString(),
          relatedType: "lesson",
        },
      );
    }

    for (const parentId of parentIds) {
      await this.notificationsService.createForUser(
        parentId,
        NotificationType.NEW_LESSON_PUBLISHED,
        "New lesson available",
        parentMessage,
        {
          relatedId: lesson._id.toString(),
          relatedType: "lesson",
        },
      );
    }
  }

  private extractSchoolLevel(level?: string): number | null {
    if (!level) return null;
    const match = level.match(/(\d+)/);
    if (!match) return null;
    const parsed = Number(match[1]);
    if (Number.isNaN(parsed) || parsed < 1 || parsed > 6) {
      return null;
    }
    return parsed;
  }

  async update(
    id: string,
    updateLessonDto: UpdateLessonDto,
    uploadedFiles: Express.Multer.File[] = [],
  ): Promise<LessonDocument> {
    const lesson = await this.findOne(id);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }

    try {
      const updateData: any = { ...updateLessonDto };
      if (updateLessonDto.subjectId) {
        updateData.subjectId = new Types.ObjectId(updateLessonDto.subjectId);
      }
      if (updateLessonDto.classId !== undefined) {
        updateData.classId = updateLessonDto.classId
          ? new Types.ObjectId(updateLessonDto.classId)
          : null;
      }
      if (uploadedFiles.length > 0) {
        const newAttachments = uploadedFiles.map((f) => ({
          originalName: f.originalname,
          storedName: f.filename,
          mimeType: f.mimetype,
          size: f.size,
          urlPath: `${LESSONS_UPLOAD_SUBDIR}/${f.filename}`,
        }));
        updateData.$push = { attachments: { $each: newAttachments } };
      }

      return await this.lessonModel
        .findByIdAndUpdate(id, updateData, { new: true })
        .exec();
    } catch (error: any) {
      if (error.code === 11000) {
        throw new ConflictException(
          "Lesson with this title already exists in this subject",
        );
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const lesson = await this.findOne(id);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }

    await this.lessonModel.findByIdAndDelete(id).exec();
  }

  async upsertLessonReview(
    lessonId: string,
    parentId: string,
    dto: UpsertLessonReviewDto,
  ) {
    const lesson = await this.findOne(lessonId);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }
    if (!lesson.teacherId) {
      throw new ConflictException("Lesson has no assigned teacher");
    }

    let kidObjectId: Types.ObjectId | undefined;
    if (dto.kidId) {
      const kid = await this.kidModel.findById(dto.kidId).exec();
      if (!kid) {
        throw new NotFoundException("Kid not found");
      }
      if (kid.parentId.toString() !== parentId) {
        throw new ForbiddenException(
          "You can only attach review to your own kid",
        );
      }
      kidObjectId = kid._id as Types.ObjectId;
    }

    const existing = await this.lessonReviewModel
      .findOne({
        lessonId: new Types.ObjectId(lessonId),
        parentId: new Types.ObjectId(parentId),
      })
      .exec();
    const wasUpdate = Boolean(existing);

    const saved = await this.lessonReviewModel
      .findOneAndUpdate(
        {
          lessonId: new Types.ObjectId(lessonId),
          parentId: new Types.ObjectId(parentId),
        },
        {
          lessonId: new Types.ObjectId(lessonId),
          teacherId: lesson.teacherId,
          parentId: new Types.ObjectId(parentId),
          kidId: kidObjectId,
          stars: dto.stars,
          comment: (dto.comment ?? "").trim(),
        },
        {
          upsert: true,
          new: true,
          setDefaultsOnInsert: true,
        },
      )
      .exec();

    await this.notificationsService.createForUser(
      lesson.teacherId.toString(),
      NotificationType.LESSON_REVIEWED,
      wasUpdate ? "Lesson review updated" : "New lesson review",
      wasUpdate
        ? `A parent updated review for lesson "${lesson.title}" (${dto.stars}/5).`
        : `A parent added review for lesson "${lesson.title}" (${dto.stars}/5).`,
      {
        relatedId: lessonId,
        relatedType: "lesson-review",
      },
    );

    // Excellent rating bonus: 5 stars on first review
    if (dto.stars === 5 && !wasUpdate && saved.kidId) {
      const kidId = saved.kidId.toString();
      await this.rewardsService.addXP(
        kidId,
        5,
        "excellent_rating",
        saved._id.toString(),
        `Excellent progress: ${lesson.title}`,
      );
      await this.rewardsService.updateStreak(kidId);
    }

    return {
      id: saved._id.toString(),
      lessonId: saved.lessonId.toString(),
      teacherId: saved.teacherId.toString(),
      parentId: saved.parentId.toString(),
      kidId: saved.kidId?.toString(),
      stars: saved.stars,
      comment: saved.comment ?? "",
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
      action: wasUpdate ? "updated" : "created",
    };
  }

  async getLessonReviews(lessonId: string, page = 1, limit = 20) {
    const lesson = await this.findOne(lessonId);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }
    const skip = (page - 1) * limit;
    const [reviews, total, agg] = await Promise.all([
      this.lessonReviewModel
        .find({ lessonId: new Types.ObjectId(lessonId) })
        .populate("parentId", "firstName lastName")
        .populate("kidId", "firstName lastName")
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.lessonReviewModel
        .countDocuments({ lessonId: new Types.ObjectId(lessonId) })
        .exec(),
      this.lessonReviewModel.aggregate([
        { $match: { lessonId: new Types.ObjectId(lessonId) } },
        {
          $group: {
            _id: "$lessonId",
            averageStars: { $avg: "$stars" },
            totalReviews: { $sum: 1 },
          },
        },
      ]),
    ]);
    const summary = agg[0] ?? { averageStars: 0, totalReviews: 0 };

    return {
      lessonId,
      averageStars: Number(summary.averageStars ?? 0),
      totalReviews: Number(summary.totalReviews ?? 0),
      page,
      limit,
      total,
      items: reviews.map((r) => {
        const parent = r.parentId as unknown as {
          firstName?: string;
          lastName?: string;
        };
        const kid = r.kidId as unknown as {
          firstName?: string;
          lastName?: string;
        };
        return {
          id: r._id.toString(),
          lessonId: r.lessonId.toString(),
          teacherId: r.teacherId.toString(),
          parentId: r.parentId.toString(),
          parentName:
            `${parent?.firstName ?? ""} ${parent?.lastName ?? ""}`.trim(),
          kidId: r.kidId?.toString(),
          kidName: kid
            ? `${kid.firstName ?? ""} ${kid.lastName ?? ""}`.trim()
            : undefined,
          stars: r.stars,
          comment: r.comment ?? "",
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        };
      }),
    };
  }

  async getTeacherLessonRatingsSummary(teacherId: string) {
    const lessons = await this.lessonModel
      .find({
        teacherId: new Types.ObjectId(teacherId),
      })
      .select("title")
      .exec();
    const lessonIds = lessons.map((l) => l._id);
    const perLesson = await this.lessonReviewModel.aggregate([
      {
        $match: {
          teacherId: new Types.ObjectId(teacherId),
          lessonId: { $in: lessonIds as Types.ObjectId[] },
        },
      },
      {
        $group: {
          _id: "$lessonId",
          averageStars: { $avg: "$stars" },
          totalReviews: { $sum: 1 },
        },
      },
    ]);
    const summaryByLesson = new Map(
      perLesson.map((s) => [s._id.toString(), s]),
    );

    return lessons.map((l) => {
      const s = summaryByLesson.get(l._id.toString());
      return {
        lessonId: l._id.toString(),
        lessonTitle: l.title,
        averageStars: Number(s?.averageStars ?? 0),
        totalReviews: Number(s?.totalReviews ?? 0),
      };
    });
  }
}
