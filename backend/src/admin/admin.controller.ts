import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from "@nestjs/common";
import { AdminService } from "./admin.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { ReviewTeacherDto } from "./dto/review-teacher.dto";
import { QueryAdminTeachersDto } from "./dto/query-admin-teachers.dto";
import { QueryAdminLessonsDto } from "./dto/query-admin-lessons.dto";
import { ModerateLessonDto } from "./dto/moderate-lesson.dto";

@Controller("admin")
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get("users")
  async getUsers(
    @Query("role") role?: string,
    @Query("search") search?: string,
  ) {
    return this.adminService.getUsers(role, search);
  }

  @Get("kids")
  async getKids() {
    return this.adminService.getKids();
  }

  @Get("stats")
  async getStats() {
    return this.adminService.getStats();
  }

  @Get("dashboard/overview")
  async getDashboardOverview() {
    return this.adminService.getDashboardOverview();
  }

  @Get("notifications/overview")
  async getNotificationsOverview() {
    return this.adminService.getNotificationsOverview();
  }

  @Get("teachers")
  async getTeachers(@Query() query: QueryAdminTeachersDto) {
    return this.adminService.getTeachers(query);
  }

  @Get("teachers/pending")
  async getPendingTeachers() {
    return this.adminService.getPendingTeachers();
  }

  @Get("teachers/:teacherId")
  async getTeacherDetails(@Param("teacherId") teacherId: string) {
    return this.adminService.getTeacherDetails(teacherId);
  }

  @Patch("teachers/:teacherId/accept")
  async acceptTeacher(@Param("teacherId") teacherId: string) {
    return this.adminService.acceptTeacher(teacherId);
  }

  @Patch("teachers/:teacherId/reject")
  async rejectTeacher(
    @Param("teacherId") teacherId: string,
    @Body() body: ReviewTeacherDto,
  ) {
    return this.adminService.rejectTeacher(teacherId, body.rejectionReason);
  }

  @Get("lessons")
  async getAdminLessons(@Query() query: QueryAdminLessonsDto) {
    return this.adminService.getAdminLessons(query);
  }

  @Patch("lessons/:lessonId/moderation")
  async moderateLesson(
    @Param("lessonId") lessonId: string,
    @Body() body: ModerateLessonDto,
  ) {
    return this.adminService.moderateLesson(
      lessonId,
      body.status,
      body.moderationNote,
    );
  }
}
