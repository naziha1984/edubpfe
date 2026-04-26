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
} from "@nestjs/common";
import { SubjectsService } from "./subjects.service";
import { LessonsService } from "./lessons.service";
import { CreateSubjectDto } from "./dto/create-subject.dto";
import { UpdateSubjectDto } from "./dto/update-subject.dto";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { mapLessonToJson } from "./lesson-response.util";
import { QuizQuestionCountService } from "./quiz-question-count.service";

@Controller("subjects")
export class SubjectsController {
  constructor(
    private readonly subjectsService: SubjectsService,
    private readonly lessonsService: LessonsService,
    private readonly quizQuestionCountService: QuizQuestionCountService,
  ) {}

  // Public endpoint
  @Get()
  async findAll() {
    const subjects = await this.subjectsService.findAll();
    return subjects.map((subject) => ({
      id: subject._id.toString(),
      name: subject.name,
      description: subject.description,
      code: subject.code,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: subject.updatedAt,
    }));
  }

  // Public endpoint
  @Get(":id/lessons")
  async findLessonsBySubject(
    @Param("id") id: string,
    @Query("schoolLevel") schoolLevel?: string,
  ) {
    const subject = await this.subjectsService.findOne(id);
    if (!subject) {
      throw new NotFoundException("Subject not found");
    }

    let parsedSchoolLevel: number | undefined;
    if (schoolLevel != null && schoolLevel.trim() != "") {
      const n = Number(schoolLevel);
      if (!Number.isInteger(n) || n < 1 || n > 6) {
        throw new BadRequestException("Invalid schoolLevel, expected 1..6");
      }
      parsedSchoolLevel = n;
    }

    const lessons = await this.lessonsService.findAllBySubjectId(
      id,
      parsedSchoolLevel,
    );
    const lessonIds = lessons.map((l) => l._id.toString());
    const counts =
      await this.quizQuestionCountService.countByLessonIds(lessonIds);
    return lessons.map((lesson) =>
      mapLessonToJson(lesson, {
        quizQuestionCount: counts.get(lesson._id.toString()) ?? 0,
      }),
    );
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createSubjectDto: CreateSubjectDto) {
    const subject = await this.subjectsService.create(createSubjectDto);
    return {
      id: subject._id.toString(),
      name: subject.name,
      description: subject.description,
      code: subject.code,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: subject.updatedAt,
    };
  }

  @Get("admin/:id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async findOne(@Param("id") id: string) {
    const subject = await this.subjectsService.findOne(id);
    if (!subject) {
      throw new NotFoundException("Subject not found");
    }
    return {
      id: subject._id.toString(),
      name: subject.name,
      description: subject.description,
      code: subject.code,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: subject.updatedAt,
    };
  }

  @Put(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async update(
    @Param("id") id: string,
    @Body() updateSubjectDto: UpdateSubjectDto,
  ) {
    const subject = await this.subjectsService.update(id, updateSubjectDto);
    return {
      id: subject._id.toString(),
      name: subject.name,
      description: subject.description,
      code: subject.code,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: subject.updatedAt,
    };
  }

  @Delete(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param("id") id: string) {
    await this.subjectsService.remove(id);
  }
}
