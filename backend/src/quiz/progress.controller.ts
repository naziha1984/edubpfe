import {
  Controller,
  Get,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ProgressService } from './progress.service';
import { KidAuthGuard } from '../kids/guards/kid-auth.guard';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { GetKid } from '../kids/decorators/get-kid.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('progress')
export class ProgressController {
  constructor(private readonly progressService: ProgressService) {}

  @Get('kids/:kidId')
  @UseGuards(KidAuthGuard)
  async getProgressByKid(@Param('kidId') kidId: string, @GetKid() kid: any) {
    const progress = await this.progressService.getProgressByKidId(
      kidId,
      kid.kidId,
    );
    return progress.map((p) => ({
      id: p._id.toString(),
      kidId: p.kidId.toString(),
      lessonId: p.lessonId.toString(),
      subjectId: p.subjectId.toString(),
      lesson: p.lessonId,
      subject: p.subjectId,
      bestScore: p.bestScore,
      attempts: p.attempts,
      isCompleted: p.isCompleted,
      lastAttemptAt: p.lastAttemptAt,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  }

  @Get('parent/kids/:kidId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async getProgressByParent(
    @Param('kidId') kidId: string,
    @GetUser() user: any,
  ) {
    const progress = await this.progressService.getProgressByKidId(
      kidId,
      undefined,
      user.id,
    );
    return progress.map((p) => ({
      id: p._id.toString(),
      kidId: p.kidId.toString(),
      lessonId: p.lessonId.toString(),
      subjectId: p.subjectId.toString(),
      lesson: p.lessonId,
      subject: p.subjectId,
      bestScore: p.bestScore,
      attempts: p.attempts,
      isCompleted: p.isCompleted,
      lastAttemptAt: p.lastAttemptAt,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  }
}
