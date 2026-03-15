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
import { AssignmentsService } from './assignments.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('teacher/assignments')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.TEACHER)
export class AssignmentsController {
  constructor(private readonly assignmentsService: AssignmentsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createAssignment(
    @Body() createAssignmentDto: CreateAssignmentDto,
    @GetUser() user: any,
  ) {
    const assignment = await this.assignmentsService.createAssignment(
      createAssignmentDto,
      user.id,
    );

    return {
      id: assignment._id.toString(),
      classId: assignment.classId.toString(),
      teacherId: assignment.teacherId.toString(),
      lessonId: assignment.lessonId?.toString(),
      title: assignment.title,
      description: assignment.description,
      dueDate: assignment.dueDate,
      isActive: assignment.isActive,
      createdAt: assignment.createdAt,
      updatedAt: assignment.updatedAt,
    };
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

    return assignments.map((assignment) => ({
      id: assignment._id.toString(),
      classId: assignment.classId.toString(),
      teacherId: assignment.teacherId.toString(),
      lessonId: assignment.lessonId?.toString(),
      lesson: assignment.lessonId
        ? {
            id: (assignment.lessonId as any)._id?.toString(),
            title: (assignment.lessonId as any).title,
          }
        : null,
      title: assignment.title,
      description: assignment.description,
      dueDate: assignment.dueDate,
      isActive: assignment.isActive,
      createdAt: assignment.createdAt,
      updatedAt: assignment.updatedAt,
    }));
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
