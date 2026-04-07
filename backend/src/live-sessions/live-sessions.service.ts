import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  LiveSession,
  LiveSessionDocument,
  LiveSessionStatus,
} from './schemas/live-session.schema';
import { CreateLiveSessionDto } from './dto/create-live-session.dto';
import { ClassesService } from '../classes/classes.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/schemas/notification.schema';

@Injectable()
export class LiveSessionsService {
  constructor(
    @InjectModel(LiveSession.name)
    private liveSessionModel: Model<LiveSessionDocument>,
    private classesService: ClassesService,
    private notificationsService: NotificationsService,
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

    const saved = await liveSession.save();

    await this.notificationsService.notifyParentsInClass(
      createLiveSessionDto.classId,
      NotificationType.LIVE_SESSION_SCHEDULED,
      'Live lesson scheduled',
      `"${saved.title}" is scheduled. Open the app for details.`,
      {
        relatedId: saved._id.toString(),
        relatedType: 'live_session',
      },
    );

    return saved;
  }

  async markSessionLive(
    classId: string,
    sessionId: string,
    teacherId: string,
  ): Promise<LiveSessionDocument> {
    const session = await this.liveSessionModel.findById(sessionId).exec();
    if (!session || session.classId.toString() !== classId) {
      throw new NotFoundException('Live session not found');
    }
    const isOwner = await this.classesService.checkOwnership(
      classId,
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        'You can only start live sessions for your own classes',
      );
    }
    session.status = LiveSessionStatus.LIVE;
    await session.save();

    await this.notificationsService.notifyParentsInClass(
      classId,
      NotificationType.LIVE_SESSION_STARTED,
      'Live class now',
      `"${session.title}" is live — your child can join.`,
      {
        relatedId: session._id.toString(),
        relatedType: 'live_session',
      },
    );

    return session;
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
