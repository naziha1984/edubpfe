import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Progress, ProgressDocument } from './schemas/progress.schema';
import { KidsService } from '../kids/kids.service';

@Injectable()
export class ProgressService {
  constructor(
    @InjectModel(Progress.name) private progressModel: Model<ProgressDocument>,
    private kidsService: KidsService,
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
}
