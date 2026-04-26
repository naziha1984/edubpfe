import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import { AssignmentsService } from "./assignments.service";
import { KidAuthGuard } from "../kids/guards/kid-auth.guard";
import { GetKid } from "../kids/decorators/get-kid.decorator";

@Controller("kids/assignments")
@UseGuards(KidAuthGuard)
export class KidAssignmentsController {
  constructor(private readonly assignmentsService: AssignmentsService) {}

  @Get()
  async getKidAssignments(@GetKid() kid: any) {
    const assignments = await this.assignmentsService.getKidAssignments(kid.id);
    return assignments;
  }

  @Post(":assignmentId/start")
  @HttpCode(HttpStatus.OK)
  async startAssignment(
    @Param("assignmentId") assignmentId: string,
    @GetKid() kid: any,
  ) {
    const submission = await this.assignmentsService.startAssignment(
      assignmentId,
      kid.id,
    );

    return {
      id: submission._id.toString(),
      assignmentId: submission.assignmentId.toString(),
      kidId: submission.kidId.toString(),
      status: submission.status,
      startedAt: submission.startedAt,
      createdAt: submission.createdAt,
      updatedAt: submission.updatedAt,
    };
  }

  @Post(":assignmentId/submit")
  @HttpCode(HttpStatus.OK)
  async submitAssignment(
    @Param("assignmentId") assignmentId: string,
    @Body() body: { quizSessionId?: string; score?: number },
    @GetKid() kid: any,
  ) {
    const submission = await this.assignmentsService.submitAssignment(
      assignmentId,
      kid.id,
      body.quizSessionId,
      body.score,
    );

    return {
      id: submission._id.toString(),
      assignmentId: submission.assignmentId.toString(),
      kidId: submission.kidId.toString(),
      status: submission.status,
      quizSessionId: submission.quizSessionId?.toString(),
      score: submission.score,
      submittedAt: submission.submittedAt,
      startedAt: submission.startedAt,
      createdAt: submission.createdAt,
      updatedAt: submission.updatedAt,
    };
  }
}
