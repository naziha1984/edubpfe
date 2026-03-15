import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { LiveSessionsService } from './live-sessions.service';
import { CreateLiveSessionDto } from './dto/create-live-session.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('teacher/classes')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.TEACHER)
export class LiveSessionsController {
  constructor(private readonly liveSessionsService: LiveSessionsService) {}

  @Post(':classId/live-sessions')
  @HttpCode(HttpStatus.CREATED)
  async createLiveSession(
    @Param('classId') classId: string,
    @Body() createLiveSessionDto: CreateLiveSessionDto,
    @GetUser() user: any,
  ) {
    // Override classId from param
    const dto = { ...createLiveSessionDto, classId };
    
    const liveSession = await this.liveSessionsService.createLiveSession(
      dto,
      user.id,
    );

    return {
      id: liveSession._id.toString(),
      classId: liveSession.classId.toString(),
      teacherId: liveSession.teacherId.toString(),
      title: liveSession.title,
      description: liveSession.description,
      scheduledAt: liveSession.scheduledAt,
      meetingUrl: liveSession.meetingUrl,
      status: liveSession.status,
      isActive: liveSession.isActive,
      createdAt: liveSession.createdAt,
      updatedAt: liveSession.updatedAt,
    };
  }

  @Get(':classId/live-sessions')
  async getLiveSessionsByClass(
    @Param('classId') classId: string,
    @GetUser() user: any,
  ) {
    const liveSessions = await this.liveSessionsService.getLiveSessionsByClass(
      classId,
      user.id,
    );

    return liveSessions.map((session) => ({
      id: session._id.toString(),
      classId: session.classId.toString(),
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
