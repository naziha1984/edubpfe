import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Progress, ProgressDocument } from './schemas/progress.schema';
import { KidsService } from '../kids/kids.service';
import { ClassesService } from '../classes/classes.service';

@Injectable()
export class ProgressService {
  constructor(
    @InjectModel(Progress.name) private progressModel: Model<ProgressDocument>,
    private kidsService: KidsService,
    private classesService: ClassesService,
  ) {}

  async getProgressByKidId(
    kidId: string,
    requesterKidId?: string,
    requesterParentId?: string,
  ): Promise<ProgressDocument[]> {
    // Strict IDOR check
    if (requesterKidId) {
      // Kid accessing their own progress
      if (kidId !== requesterKidId) {
        throw new ForbiddenException('You can only view your own progress');
      }
    } else if (requesterParentId) {
      // Parent accessing their kid's progress
      const kid = await this.kidsService.findOneById(kidId);
      if (!kid) {
        throw new NotFoundException('Kid not found');
      }
      if (kid.parentId.toString() !== requesterParentId) {
        throw new ForbiddenException(
          'You can only view progress for your own kids',
        );
      }
    } else {
      throw new ForbiddenException('Authentication required');
    }

    return this.progressModel
      .find({ kidId: new Types.ObjectId(kidId) })
      .populate('lessonId', 'title description')
      .populate('subjectId', 'name code')
      .sort({ updatedAt: -1 })
      .exec();
  }

  async getKidProgressSummaryForParent(
    kidId: string,
    parentUserId: string,
  ): Promise<{
    lessonsTracked: number;
    lessonsCompleted: number;
    averageBestScore: number;
    totalQuizAttempts: number;
    lastActivityAt: Date | null;
  }> {
    const kid = await this.kidsService.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException('Kid not found');
    }
    if (kid.parentId.toString() !== parentUserId) {
      throw new ForbiddenException(
        'You can only view summary for your own kids',
      );
    }
    return this.buildProgressSummary(kidId);
  }

  async getKidProgressSummaryForTeacher(
    classId: string,
    kidId: string,
    teacherUserId: string,
  ) {
    const isOwner = await this.classesService.checkOwnership(
      classId,
      teacherUserId,
    );
    if (!isOwner) {
      throw new ForbiddenException('You do not teach this class');
    }
    const members = await this.classesService.getClassMembers(
      classId,
      teacherUserId,
    );
    const allowed = members.some(
      (m) => m.kidId.toString() === kidId,
    );
    if (!allowed) {
      throw new ForbiddenException('This student is not in the class');
    }
    return this.buildProgressSummary(kidId);
  }

  private async buildProgressSummary(kidId: string) {
    const list = await this.progressModel
      .find({ kidId: new Types.ObjectId(kidId) })
      .exec();

    const lessonsCompleted = list.filter((p) => p.isCompleted).length;
    const withScore = list.filter(
      (p) => typeof p.bestScore === 'number' && p.bestScore > 0,
    );
    const avg =
      withScore.length > 0
        ? Math.round(
            (withScore.reduce((s, p) => s + p.bestScore, 0) /
              withScore.length) *
              10,
          ) / 10
        : 0;
    const totalQuizAttempts = list.reduce((s, p) => s + (p.attempts || 0), 0);
    const lastActivityAt =
      list.length === 0
        ? null
        : list.reduce<Date | null>((max, p) => {
            const t = p.lastAttemptAt;
            if (!t) return max;
            if (!max || t > max) return t;
            return max;
          }, null);

    return {
      lessonsTracked: list.length,
      lessonsCompleted,
      averageBestScore: avg,
      totalQuizAttempts,
      lastActivityAt,
    };
  }
}
