import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
  NotFoundException,
} from '@nestjs/common';
import { SubjectsService } from './subjects.service';
import { LessonsService } from './lessons.service';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('subjects')
export class SubjectsController {
  constructor(
    private readonly subjectsService: SubjectsService,
    private readonly lessonsService: LessonsService,
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
  @Get(':id/lessons')
  async findLessonsBySubject(@Param('id') id: string) {
    const subject = await this.subjectsService.findOne(id);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    const lessons = await this.lessonsService.findAllBySubjectId(id);
    return lessons.map((lesson) => ({
      id: lesson._id.toString(),
      subjectId: lesson.subjectId.toString(),
      title: lesson.title,
      description: lesson.description,
      content: lesson.content,
      order: lesson.order,
      level: lesson.level,
      language: lesson.language,
      isActive: lesson.isActive,
      createdAt: lesson.createdAt,
      updatedAt: lesson.updatedAt,
    }));
  }

  // Admin endpoints
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
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

  @Get('admin/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async findOne(@Param('id') id: string) {
    const subject = await this.subjectsService.findOne(id);
    if (!subject) {
      throw new NotFoundException('Subject not found');
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

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async update(
    @Param('id') id: string,
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

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string) {
    await this.subjectsService.remove(id);
  }
}
