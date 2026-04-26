import {
  BadRequestException,
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  NotFoundException,
  UploadedFiles,
  UseInterceptors,
} from "@nestjs/common";
import { FilesInterceptor } from "@nestjs/platform-express";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";
import { LessonsService } from "./lessons.service";
import { SubjectsService } from "./subjects.service";
import { CreateLessonDto } from "./dto/create-lesson.dto";
import { UpdateLessonDto } from "./dto/update-lesson.dto";
import { UpsertLessonReviewDto } from "./dto/upsert-lesson-review.dto";
import { LessonReviewsQueryDto } from "./dto/lesson-reviews-query.dto";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { lessonFilesMulterOptions } from "./lesson-upload.config";
import { mapLessonToJson } from "./lesson-response.util";
import { GetUser } from "../auth/decorators/get-user.decorator";

@Controller("lessons")
export class LessonsController {
  constructor(
    private readonly lessonsService: LessonsService,
    private readonly subjectsService: SubjectsService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FilesInterceptor("files", 20, lessonFilesMulterOptions))
  async create(
    @UploadedFiles() files: Express.Multer.File[],
    @Body() body: Record<string, string>,
    @GetUser() user: { id: string },
  ) {
    const dto = plainToInstance(CreateLessonDto, {
      subjectId: body.subjectId,
      classId: body.classId,
      title: body.title,
      description: body.description,
      content: body.content,
      order:
        body.order == null || body.order === ""
          ? undefined
          : Number(body.order),
      level: body.level,
      language: body.language,
      isActive:
        body.isActive == null || body.isActive === ""
          ? undefined
          : body.isActive === "true",
    });
    const errors = await validate(dto);
    if (errors.length > 0) {
      throw new BadRequestException(
        errors.map((e) => Object.values(e.constraints ?? {})).flat(),
      );
    }

    // Verify subject exists
    const subject = await this.subjectsService.findOne(dto.subjectId);
    if (!subject) {
      throw new NotFoundException("Subject not found");
    }

    const lesson = await this.lessonsService.create(dto, files ?? [], user.id);
    return mapLessonToJson(lesson);
  }

  @Put(":id/review")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async addOrUpdateReview(
    @Param("id") lessonId: string,
    @Body() dto: UpsertLessonReviewDto,
    @GetUser() user: { id: string },
  ) {
    return this.lessonsService.upsertLessonReview(lessonId, user.id, dto);
  }

  @Get(":id/reviews")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT, UserRole.TEACHER, UserRole.ADMIN)
  async getLessonReviews(
    @Param("id") lessonId: string,
    @Query() query: LessonReviewsQueryDto,
  ) {
    return this.lessonsService.getLessonReviews(
      lessonId,
      query.page ?? 1,
      query.limit ?? 20,
    );
  }

  @Get("teacher/ratings-summary")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.TEACHER)
  async getTeacherRatingsSummary(@GetUser() user: { id: string }) {
    return this.lessonsService.getTeacherLessonRatingsSummary(user.id);
  }

  @Get(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  async findOne(@Param("id") id: string) {
    const lesson = await this.lessonsService.findOne(id);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }
    return mapLessonToJson(lesson);
  }

  @Put(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @UseInterceptors(FilesInterceptor("files", 20, lessonFilesMulterOptions))
  async update(
    @Param("id") id: string,
    @UploadedFiles() files: Express.Multer.File[],
    @Body() body: Record<string, string>,
  ) {
    const dto = plainToInstance(UpdateLessonDto, {
      subjectId: body.subjectId,
      classId: body.classId,
      title: body.title,
      description: body.description,
      content: body.content,
      order:
        body.order == null || body.order === ""
          ? undefined
          : Number(body.order),
      level: body.level,
      language: body.language,
      isActive:
        body.isActive == null || body.isActive === ""
          ? undefined
          : body.isActive === "true",
    });
    const errors = await validate(dto);
    if (errors.length > 0) {
      throw new BadRequestException(
        errors.map((e) => Object.values(e.constraints ?? {})).flat(),
      );
    }

    // If subjectId is being updated, verify it exists
    if (dto.subjectId) {
      const subject = await this.subjectsService.findOne(dto.subjectId);
      if (!subject) {
        throw new NotFoundException("Subject not found");
      }
    }

    const lesson = await this.lessonsService.update(id, dto, files ?? []);
    return mapLessonToJson(lesson);
  }

  @Delete(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param("id") id: string) {
    await this.lessonsService.remove(id);
  }
}
