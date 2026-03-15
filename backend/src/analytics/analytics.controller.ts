import {
  Controller,
  Get,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('teacher')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.TEACHER)
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('classes/:classId/subjects/:subjectId/progress')
  async getClassSubjectProgress(
    @Param('classId') classId: string,
    @Param('subjectId') subjectId: string,
    @GetUser() user: any,
  ) {
    return this.analyticsService.getClassSubjectProgress(
      classId,
      subjectId,
      user.id,
    );
  }
}
