import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';
import { LiveSessionsService } from './live-sessions.service';
import { KidAuthGuard } from '../kids/guards/kid-auth.guard';
import { GetKid } from '../kids/decorators/get-kid.decorator';

@Controller('kid/live-sessions')
@UseGuards(KidAuthGuard)
export class KidLiveSessionsController {
  constructor(private readonly liveSessionsService: LiveSessionsService) {}

  @Get()
  async getKidLiveSessions(@GetKid() kid: any) {
    const liveSessions = await this.liveSessionsService.getKidLiveSessions(kid.id);

    return liveSessions.map((session) => ({
      id: session._id.toString(),
      classId: session.classId.toString(),
      class: session.classId
        ? {
            id: (session.classId as any)._id?.toString(),
            name: (session.classId as any).name,
          }
        : null,
      teacherId: session.teacherId.toString(),
      title: session.title,
      description: session.description,
      scheduledAt: session.scheduledAt,
      meetingUrl: session.meetingUrl,
      status: session.status,
      isActive: session.isActive,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    }));
  }
}
