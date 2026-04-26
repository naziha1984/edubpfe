import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  StudentNote,
  StudentNoteDocument,
} from "./schemas/student-note.schema";
import {
  StudentProgressEntry,
  StudentProgressEntryDocument,
} from "./schemas/student-progress-entry.schema";
import { Kid, KidDocument } from "../kids/schemas/kid.schema";
import {
  ClassMembership,
  ClassMembershipDocument,
} from "../classes/schemas/class-membership.schema";
import { Class, ClassDocument } from "../classes/schemas/class.schema";
import { CreateStudentNoteDto } from "./dto/create-student-note.dto";
import { UpdateStudentNoteDto } from "./dto/update-student-note.dto";
import { CreateStudentProgressEntryDto } from "./dto/create-student-progress-entry.dto";
import {
  KidTeacherSelection,
  KidTeacherSelectionDocument,
} from "../kids/schemas/kid-teacher-selection.schema";
import { UserRole } from "../users/schemas/user.schema";

@Injectable()
export class StudentTrackingService {
  constructor(
    @InjectModel(StudentNote.name)
    private readonly noteModel: Model<StudentNoteDocument>,
    @InjectModel(StudentProgressEntry.name)
    private readonly progressModel: Model<StudentProgressEntryDocument>,
    @InjectModel(Kid.name)
    private readonly kidModel: Model<KidDocument>,
    @InjectModel(ClassMembership.name)
    private readonly membershipModel: Model<ClassMembershipDocument>,
    @InjectModel(Class.name)
    private readonly classModel: Model<ClassDocument>,
    @InjectModel(KidTeacherSelection.name)
    private readonly selectionModel: Model<KidTeacherSelectionDocument>,
  ) {}

  async addNote(kidId: string, teacherId: string, dto: CreateStudentNoteDto) {
    await this.assertTeacherCanWrite(kidId, teacherId);
    const created = await this.noteModel.create({
      kidId: new Types.ObjectId(kidId),
      teacherId: new Types.ObjectId(teacherId),
      ...dto,
    });
    return this.mapNote(created);
  }

  async updateNote(
    noteId: string,
    teacherId: string,
    dto: UpdateStudentNoteDto,
  ) {
    const note = await this.noteModel.findById(noteId).exec();
    if (!note) {
      throw new NotFoundException("Note not found");
    }
    if (note.teacherId.toString() !== teacherId) {
      throw new ForbiddenException("You can only update your own notes");
    }
    await this.assertTeacherCanWrite(note.kidId.toString(), teacherId);
    Object.assign(note, dto);
    await note.save();
    return this.mapNote(note);
  }

  async getNotesByStudent(kidId: string, userId: string, role: UserRole) {
    await this.assertCanRead(kidId, userId, role);
    const notes = await this.noteModel
      .find({ kidId: new Types.ObjectId(kidId) })
      .sort({ createdAt: -1 })
      .exec();
    return notes.map((n) => this.mapNote(n));
  }

  async addProgressEntry(
    kidId: string,
    teacherId: string,
    dto: CreateStudentProgressEntryDto,
  ) {
    await this.assertTeacherCanWrite(kidId, teacherId);
    const created = await this.progressModel.create({
      kidId: new Types.ObjectId(kidId),
      teacherId: new Types.ObjectId(teacherId),
      ...dto,
    });
    return this.mapProgress(created);
  }

  async getProgressHistory(kidId: string, userId: string, role: UserRole) {
    await this.assertCanRead(kidId, userId, role);
    const entries = await this.progressModel
      .find({ kidId: new Types.ObjectId(kidId) })
      .sort({ createdAt: -1 })
      .limit(100)
      .exec();
    return entries.map((e) => this.mapProgress(e));
  }

  async getOverview(kidId: string, userId: string, role: UserRole) {
    await this.assertCanRead(kidId, userId, role);
    const [latestNote, latestEntries, totalNotes, totalProgressEntries] =
      await Promise.all([
        this.noteModel
          .findOne({ kidId: new Types.ObjectId(kidId) })
          .sort({ createdAt: -1 })
          .exec(),
        this.progressModel
          .find({ kidId: new Types.ObjectId(kidId) })
          .sort({ createdAt: -1 })
          .limit(5)
          .exec(),
        this.noteModel.countDocuments({ kidId: new Types.ObjectId(kidId) }),
        this.progressModel.countDocuments({ kidId: new Types.ObjectId(kidId) }),
      ]);

    const latestProgressPercent = latestEntries[0]?.progressPercent ?? 0;
    const averageRecentProgress =
      latestEntries.length > 0
        ? Math.round(
            latestEntries.reduce((sum, e) => sum + e.progressPercent, 0) /
              latestEntries.length,
          )
        : 0;

    return {
      latestProgressPercent,
      averageRecentProgress,
      totalNotes,
      totalProgressEntries,
      latestNote: latestNote ? this.mapNote(latestNote) : null,
    };
  }

  private async assertCanRead(kidId: string, userId: string, role: UserRole) {
    if (role === UserRole.ADMIN) return;
    if (role === UserRole.PARENT) {
      const kid = await this.getKidOrThrow(kidId);
      if (kid.parentId.toString() !== userId) {
        throw new ForbiddenException("You can only access your child data");
      }
      return;
    }
    if (role === UserRole.TEACHER) {
      await this.assertTeacherCanWrite(kidId, userId);
      return;
    }
    throw new ForbiddenException("Access denied");
  }

  private async assertTeacherCanWrite(kidId: string, teacherId: string) {
    await this.getKidOrThrow(kidId);

    const memberships = await this.membershipModel
      .find({ kidId: new Types.ObjectId(kidId), isActive: true })
      .select("classId")
      .exec();

    const classIds = memberships.map((m) => m.classId);
    if (classIds.length > 0) {
      const teachesKidInClass = await this.classModel.exists({
        _id: { $in: classIds },
        teacherId: new Types.ObjectId(teacherId),
        isActive: true,
      });
      if (teachesKidInClass) {
        return;
      }
    }

    const selectedByParent = await this.selectionModel.exists({
      kidId: new Types.ObjectId(kidId),
      teacherId: new Types.ObjectId(teacherId),
    });
    if (selectedByParent) {
      return;
    }

    throw new ForbiddenException(
      "You can only write notes/progress for your assigned students",
    );
  }

  private async getKidOrThrow(kidId: string) {
    const kid = await this.kidModel.findById(kidId).exec();
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }
    return kid;
  }

  private mapNote(note: StudentNoteDocument) {
    return {
      id: note._id.toString(),
      kidId: note.kidId.toString(),
      teacherId: note.teacherId.toString(),
      behavior: note.behavior,
      participation: note.participation,
      homeworkQuality: note.homeworkQuality,
      comprehension: note.comprehension,
      recommendations: note.recommendations,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    };
  }

  private mapProgress(entry: StudentProgressEntryDocument) {
    return {
      id: entry._id.toString(),
      kidId: entry.kidId.toString(),
      teacherId: entry.teacherId.toString(),
      progressPercent: entry.progressPercent,
      comprehensionScore: entry.comprehensionScore,
      homeworkScore: entry.homeworkScore,
      participationScore: entry.participationScore,
      title: entry.title,
      note: entry.note,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    };
  }
}
