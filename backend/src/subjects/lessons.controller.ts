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
import { LessonsService } from './lessons.service';
import { SubjectsService } from './subjects.service';
import { CreateLessonDto } from './dto/create-lesson.dto';
import { UpdateLessonDto } from './dto/update-lesson.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('lessons')
export class LessonsController {
  constructor(
    private readonly lessonsService: LessonsService,
    private readonly subjectsService: SubjectsService,
  ) {}

  // Admin endpoints
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createLessonDto: CreateLessonDto) {
    // Verify subject exists
    const subject = await this.subjectsService.findOne(
      createLessonDto.subjectId,
    );
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    const lesson = await this.lessonsService.create(createLessonDto);
    return {
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
    };
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async findOne(@Param('id') id: string) {
    const lesson = await this.lessonsService.findOne(id);
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }
    return {
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
    };
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async update(
    @Param('id') id: string,
    @Body() updateLessonDto: UpdateLessonDto,
  ) {
    // If subjectId is being updated, verify it exists
    if (updateLessonDto.subjectId) {
      const subject = await this.subjectsService.findOne(
        updateLessonDto.subjectId,
      );
      if (!subject) {
        throw new NotFoundException('Subject not found');
      }
    }

    const lesson = await this.lessonsService.update(id, updateLessonDto);
    return {
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
    };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string) {
    await this.lessonsService.remove(id);
  }
}
