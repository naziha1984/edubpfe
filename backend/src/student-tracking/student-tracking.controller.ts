import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { StudentTrackingService } from "./student-tracking.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { GetUser } from "../auth/decorators/get-user.decorator";
import { CreateStudentNoteDto } from "./dto/create-student-note.dto";
import { UpdateStudentNoteDto } from "./dto/update-student-note.dto";
import { CreateStudentProgressEntryDto } from "./dto/create-student-progress-entry.dto";

@Controller("student-tracking")
@UseGuards(JwtAuthGuard, RolesGuard)
export class StudentTrackingController {
  constructor(
    private readonly studentTrackingService: StudentTrackingService,
  ) {}

  @Post("students/:kidId/notes")
  @Roles(UserRole.TEACHER)
  async addNote(
    @Param("kidId") kidId: string,
    @Body() dto: CreateStudentNoteDto,
    @GetUser() user: any,
  ) {
    return this.studentTrackingService.addNote(kidId, user.id, dto);
  }

  @Patch("notes/:noteId")
  @Roles(UserRole.TEACHER)
  async updateNote(
    @Param("noteId") noteId: string,
    @Body() dto: UpdateStudentNoteDto,
    @GetUser() user: any,
  ) {
    return this.studentTrackingService.updateNote(noteId, user.id, dto);
  }

  @Get("students/:kidId/notes")
  @Roles(UserRole.TEACHER, UserRole.PARENT, UserRole.ADMIN)
  async getNotesByStudent(@Param("kidId") kidId: string, @GetUser() user: any) {
    return this.studentTrackingService.getNotesByStudent(
      kidId,
      user.id,
      user.role,
    );
  }

  @Post("students/:kidId/progress")
  @Roles(UserRole.TEACHER)
  async addProgressEntry(
    @Param("kidId") kidId: string,
    @Body() dto: CreateStudentProgressEntryDto,
    @GetUser() user: any,
  ) {
    return this.studentTrackingService.addProgressEntry(kidId, user.id, dto);
  }

  @Get("students/:kidId/progress")
  @Roles(UserRole.TEACHER, UserRole.PARENT, UserRole.ADMIN)
  async getProgressHistory(
    @Param("kidId") kidId: string,
    @GetUser() user: any,
  ) {
    return this.studentTrackingService.getProgressHistory(
      kidId,
      user.id,
      user.role,
    );
  }

  @Get("students/:kidId/overview")
  @Roles(UserRole.TEACHER, UserRole.PARENT, UserRole.ADMIN)
  async getOverview(@Param("kidId") kidId: string, @GetUser() user: any) {
    return this.studentTrackingService.getOverview(kidId, user.id, user.role);
  }
}
