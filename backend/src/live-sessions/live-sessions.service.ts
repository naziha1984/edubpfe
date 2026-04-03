import { Injectable, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  LiveSession,
  LiveSessionDocument,
  LiveSessionStatus,
} from './schemas/live-session.schema';
import { CreateLiveSessionDto } from './dto/create-live-session.dto';
import { ClassesService } from '../classes/classes.service';

@Injectable()
export class LiveSessionsService {
  constructor(
    @InjectModel(LiveSession.name)
    private liveSessionModel: Model<LiveSessionDocument>,
    private classesService: ClassesService,
  ) {}

  async createLiveSession(
    createLiveSessionDto: CreateLiveSessionDto,
    teacherId: string,
  ): Promise<LiveSessionDocument> {
    // Verify class ownership
    const isOwner = await this.classesService.checkOwnership(
      createLiveSessionDto.classId,
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        'You can only create live sessions for your own classes',
      );
    }

    const liveSession = new this.liveSessionModel({
      ...createLiveSessionDto,
      classId: new Types.ObjectId(createLiveSessionDto.classId),
      teacherId: new Types.ObjectId(teacherId),
      scheduledAt: new Date(createLiveSessionDto.scheduledAt),
      status: LiveSessionStatus.SCHEDULED,
    });

    return liveSession.save();
  }

  async getLiveSessionsByClass(
    classId: string,
    teacherId: string,
  ): Promise<LiveSessionDocument[]> {
    const isOwner = await this.classesService.checkOwnership(
      classId,
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        'You can only view live sessions for your own classes',
      );
    }

    return this.liveSessionModel
      .find({ classId: new Types.ObjectId(classId) })
      .sort({ scheduledAt: 1 })
      .exec();
  }

  async getKidLiveSessions(kidId: string): Promise<LiveSessionDocument[]> {
    // Get all classes the kid belongs to
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id);

    if (classIds.length === 0) {
      return [];
    }

    // Get all live sessions for these classes
    return this.liveSessionModel
      .find({
        classId: { $in: classIds },
        isActive: true,
        status: { $in: [LiveSessionStatus.SCHEDULED, LiveSessionStatus.LIVE] },
      })
      .populate('classId', 'name')
      .sort({ scheduledAt: 1 })
      .exec();
  }
}
