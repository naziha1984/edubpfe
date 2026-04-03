import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFiles,
  BadRequestException,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AssignmentsService } from './assignments.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { UserRole } from '../users/schemas/user.schema';
import { assignmentFilesMulterOptions } from './assignment-upload.config';
import { mapAssignmentToJson } from './assignment-response.util';

@Controller('teacher/assignments')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.TEACHER)
export class AssignmentsController {
  constructor(private readonly assignmentsService: AssignmentsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FilesInterceptor('files', 30, assignmentFilesMulterOptions))
  async createAssignment(
    @UploadedFiles() files: Express.Multer.File[],
    @Body() body: Record<string, string>,
    @GetUser() user: any,
  ) {
    const dto = plainToInstance(CreateAssignmentDto, {
      classId: body.classId,
      title: body.title,
      description: body.description?.trim() || undefined,
      lessonId: body.lessonId?.trim() || undefined,
      dueDate: body.dueDate,
    });

    const errors = await validate(dto);
    if (errors.length > 0) {
      const msg = errors
        .map((e) => Object.values(e.constraints || {}).join(', '))
        .join('; ');
      throw new BadRequestException(msg || 'Données invalides');
    }

    const assignment = await this.assignmentsService.createAssignment(
      dto,
      user.id,
      files ?? [],
    );

    return mapAssignmentToJson(assignment);
  }

  @Get('class/:classId')
  async getAssignmentsByClass(
    @Param('classId') classId: string,
    @GetUser() user: any,
  ) {
    const assignments = await this.assignmentsService.getAssignmentsByClass(
      classId,
      user.id,
    );

    return assignments.map((a) => mapAssignmentToJson(a));
  }

  @Get(':assignmentId/submissions')
  async getAssignmentSubmissions(
    @Param('assignmentId') assignmentId: string,
    @GetUser() user: any,
  ) {
    const submissions = await this.assignmentsService.getAssignmentSubmissions(
      assignmentId,
      user.id,
    );

    return submissions.map((submission) => ({
      id: submission._id.toString(),
      assignmentId: submission.assignmentId.toString(),
      kidId: submission.kidId.toString(),
      kid: submission.kidId
        ? {
            id: (submission.kidId as any)._id?.toString(),
            firstName: (submission.kidId as any).firstName,
            lastName: (submission.kidId as any).lastName,
          }
        : null,
      status: submission.status,
      quizSessionId: submission.quizSessionId?.toString(),
      score: submission.score,
      submittedAt: submission.submittedAt,
      startedAt: submission.startedAt,
      createdAt: submission.createdAt,
      updatedAt: submission.updatedAt,
    }));
  }
}
