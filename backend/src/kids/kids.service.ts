import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Kid, KidDocument } from "./schemas/kid.schema";
import { CreateKidDto } from "./dto/create-kid.dto";
import { UpdateKidDto } from "./dto/update-kid.dto";
import * as bcrypt from "bcrypt";
import {
  KidTeacherSelection,
  KidTeacherSelectionDocument,
} from "./schemas/kid-teacher-selection.schema";
import {
  TeacherApprovalStatus,
  User,
  UserDocument,
  UserRole,
} from "../users/schemas/user.schema";
import { Lesson, LessonDocument } from "../subjects/schemas/lesson.schema";
import { Subject, SubjectDocument } from "../subjects/schemas/subject.schema";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/schemas/notification.schema";

@Injectable()
export class KidsService {
  constructor(
    @InjectModel(Kid.name) private kidModel: Model<KidDocument>,
    @InjectModel(KidTeacherSelection.name)
    private selectionModel: Model<KidTeacherSelectionDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Lesson.name) private lessonModel: Model<LessonDocument>,
    @InjectModel(Subject.name) private subjectModel: Model<SubjectDocument>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async findAllByParentId(parentId: string): Promise<KidDocument[]> {
    return this.kidModel
      .find({ parentId: new Types.ObjectId(parentId) })
      .exec();
  }

  async findOneById(kidId: string): Promise<KidDocument | null> {
    return this.kidModel.findById(kidId).exec();
  }

  async checkOwnership(kidId: string, parentId: string): Promise<boolean> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      return false;
    }
    return kid.parentId.toString() === parentId;
  }

  async create(
    createKidDto: CreateKidDto,
    parentId: string,
  ): Promise<KidDocument> {
    const kidData = {
      ...createKidDto,
      parentId: new Types.ObjectId(parentId),
      dateOfBirth: createKidDto.dateOfBirth
        ? new Date(createKidDto.dateOfBirth)
        : undefined,
    };

    const kid = new this.kidModel(kidData);
    return kid.save();
  }

  async update(
    kidId: string,
    updateKidDto: UpdateKidDto,
    parentId: string,
  ): Promise<KidDocument> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }

    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        "You do not have permission to update this kid",
      );
    }

    const updateData: any = { ...updateKidDto };
    if (updateKidDto.dateOfBirth) {
      updateData.dateOfBirth = new Date(updateKidDto.dateOfBirth);
    }

    return this.kidModel
      .findByIdAndUpdate(kidId, updateData, { new: true })
      .exec();
  }

  async remove(kidId: string, parentId: string): Promise<void> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }

    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        "You do not have permission to delete this kid",
      );
    }

    await this.kidModel.findByIdAndDelete(kidId).exec();
  }

  async setPin(kidId: string, pin: string, parentId: string): Promise<void> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }

    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        "You do not have permission to set PIN for this kid",
      );
    }

    const hashedPin = await bcrypt.hash(pin, 10);
    await this.kidModel
      .findByIdAndUpdate(kidId, {
        hashedPin,
        failedPinAttempts: 0,
        pinLockedUntil: null,
      })
      .exec();
  }

  async verifyPin(kidId: string, pin: string): Promise<boolean> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }

    if (!kid.hashedPin) {
      throw new BadRequestException("PIN not set for this kid");
    }

    // Check if PIN is locked
    if (kid.pinLockedUntil && new Date() < kid.pinLockedUntil) {
      const minutesRemaining = Math.ceil(
        (kid.pinLockedUntil.getTime() - new Date().getTime()) / 60000,
      );
      throw new BadRequestException(
        `PIN is locked. Try again in ${minutesRemaining} minute(s)`,
      );
    }

    // Verify PIN
    const isPinValid = await bcrypt.compare(pin, kid.hashedPin);

    if (isPinValid) {
      // Reset failed attempts on successful verification
      await this.kidModel
        .findByIdAndUpdate(kidId, {
          failedPinAttempts: 0,
          pinLockedUntil: null,
        })
        .exec();
      return true;
    } else {
      // Increment failed attempts
      const newFailedAttempts = (kid.failedPinAttempts || 0) + 1;
      const updateData: any = {
        failedPinAttempts: newFailedAttempts,
      };

      // Lock after 5 failed attempts for 10 minutes
      if (newFailedAttempts >= 5) {
        const lockUntil = new Date();
        lockUntil.setMinutes(lockUntil.getMinutes() + 10);
        updateData.pinLockedUntil = lockUntil;
      }

      await this.kidModel.findByIdAndUpdate(kidId, updateData).exec();
      return false;
    }
  }

  async generateKidToken(kidId: string): Promise<string> {
    // This method will be used by the controller to generate kidToken
    // The actual JWT signing will be done in the controller using JwtService
    return kidId;
  }

  async getAcceptedTeachers() {
    const teachers = await this.userModel
      .find({
        role: UserRole.TEACHER,
        approvalStatus: TeacherApprovalStatus.ACCEPTED,
        isActive: true,
      })
      .select("-password")
      .sort({ firstName: 1, lastName: 1 })
      .exec();

    const teacherIds = teachers.map((t) => t._id);
    const lessons = await this.lessonModel
      .find({
        teacherId: { $in: teacherIds },
        isActive: true,
      })
      .select("teacherId subjectId")
      .exec();

    const subjectIds = Array.from(
      new Set(lessons.map((l) => l.subjectId?.toString()).filter(Boolean)),
    );
    const subjects = await this.subjectModel
      .find({ _id: { $in: subjectIds } })
      .select("name")
      .exec();
    const subjectNameById = new Map(
      subjects.map((s) => [s._id.toString(), s.name]),
    );

    return teachers.map((t) => {
      const specialties = lessons
        .filter((l) => l.teacherId?.toString() === t._id.toString())
        .map((l) => subjectNameById.get(l.subjectId?.toString() ?? ""))
        .filter((v): v is string => Boolean(v));
      const uniqueSpecialties = Array.from(new Set(specialties));
      return {
        id: t._id.toString(),
        fullName: `${t.firstName} ${t.lastName}`.trim(),
        firstName: t.firstName,
        lastName: t.lastName,
        specialty: t.specialty ?? uniqueSpecialties.join(", "),
        profilePhotoUrl: t.profilePhotoUrl,
        bio: t.bio,
        rating: t.ratingAvg ?? 0,
        ratingCount: t.ratingCount ?? 0,
      };
    });
  }

  async getTeacherPublicDetails(teacherId: string) {
    const teacher = await this.userModel
      .findOne({
        _id: new Types.ObjectId(teacherId),
        role: UserRole.TEACHER,
        approvalStatus: TeacherApprovalStatus.ACCEPTED,
        isActive: true,
      })
      .select("-password")
      .exec();
    if (!teacher) {
      throw new NotFoundException("Teacher not found");
    }
    const lessons = await this.lessonModel
      .find({
        teacherId: new Types.ObjectId(teacherId),
        isActive: true,
      })
      .select("subjectId")
      .exec();
    const subjectIds = Array.from(
      new Set(lessons.map((l) => l.subjectId?.toString()).filter(Boolean)),
    );
    const subjects = await this.subjectModel
      .find({ _id: { $in: subjectIds } })
      .select("name")
      .exec();
    const subjectNames = subjects.map((s) => s.name);

    return {
      id: teacher._id.toString(),
      fullName: `${teacher.firstName} ${teacher.lastName}`.trim(),
      firstName: teacher.firstName,
      lastName: teacher.lastName,
      specialty: teacher.specialty ?? subjectNames.join(", "),
      profilePhotoUrl: teacher.profilePhotoUrl,
      bio: teacher.bio,
      rating: teacher.ratingAvg ?? 0,
      ratingCount: teacher.ratingCount ?? 0,
      subjects: subjectNames,
    };
  }

  async selectTeacherForKid(
    kidId: string,
    teacherId: string,
    parentId: string,
  ) {
    const kid = await this.kidModel.findById(kidId).exec();
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }
    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        "You do not have permission to select teacher for this kid",
      );
    }

    const teacher = await this.userModel
      .findOne({
        _id: new Types.ObjectId(teacherId),
        role: UserRole.TEACHER,
        approvalStatus: TeacherApprovalStatus.ACCEPTED,
        isActive: true,
      })
      .exec();
    if (!teacher) {
      throw new NotFoundException("Teacher not found");
    }

    await this.selectionModel
      .findOneAndUpdate(
        { kidId: new Types.ObjectId(kidId) },
        {
          parentId: new Types.ObjectId(parentId),
          kidId: new Types.ObjectId(kidId),
          teacherId: new Types.ObjectId(teacherId),
          assignedAt: new Date(),
        },
        {
          upsert: true,
          new: true,
          setDefaultsOnInsert: true,
        },
      )
      .exec();

    await this.notificationsService.createForUser(
      teacherId,
      NotificationType.TEACHER_SELECTED,
      "New parent selection",
      `A parent selected you for child ${kid.firstName} ${kid.lastName}.`,
      {
        kidId,
        relatedId: kidId,
        relatedType: "kid-teacher-selection",
      },
    );

    return {
      message: "Teacher selected successfully",
      kidId,
      teacherId,
      assignedAt: new Date(),
    };
  }
}
