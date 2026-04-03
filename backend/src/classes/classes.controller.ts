import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { ClassesService } from './classes.service';
import { CreateClassDto } from './dto/create-class.dto';
import { AddStudentDto } from './dto/add-student.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { UserRole } from '../users/schemas/user.schema';

@Controller('teacher/classes')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.TEACHER)
export class ClassesController {
  constructor(private readonly classesService: ClassesService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createClass(
    @Body() createClassDto: CreateClassDto,
    @GetUser() user: any,
  ) {
    const newClass = await this.classesService.createClass(
      createClassDto,
      user.id,
    );

    return {
      id: newClass._id.toString(),
      name: newClass.name,
      description: newClass.description,
      classCode: newClass.classCode,
      teacherId: newClass.teacherId.toString(),
      isActive: newClass.isActive,
      createdAt: newClass.createdAt,
      updatedAt: newClass.updatedAt,
    };
  }

  @Get()
  async findAll(@GetUser() user: any) {
    const classes = await this.classesService.findAllByTeacherId(user.id);
    return classes.map((c) => ({
      id: c._id.toString(),
      name: c.name,
      description: c.description,
      classCode: c.classCode,
      teacherId: c.teacherId.toString(),
      isActive: c.isActive,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    }));
  }

  @Get(':classId')
  async findOne(@Param('classId') classId: string, @GetUser() user: any) {
    const classDoc = await this.classesService.findOneById(classId);
    if (!classDoc) {
      throw new NotFoundException('Class not found');
    }

    // Strict ownership check
    const isOwner = await this.classesService.checkOwnership(classId, user.id);
    if (!isOwner) {
      throw new ForbiddenException('You can only view your own classes');
    }

    // Get members
    const members = await this.classesService.getClassMembers(classId, user.id);

    return {
      id: classDoc._id.toString(),
      name: classDoc.name,
      description: classDoc.description,
      classCode: classDoc.classCode,
      teacherId: classDoc.teacherId.toString(),
      isActive: classDoc.isActive,
      members: members.map((m) => ({
        id: m._id.toString(),
        kidId: m.kidId.toString(),
        kid: m.kidId,
        isActive: m.isActive,
        joinedAt: m.createdAt,
      })),
      createdAt: classDoc.createdAt,
      updatedAt: classDoc.updatedAt,
    };
  }

  @Post(':classId/students')
  @HttpCode(HttpStatus.CREATED)
  async addStudent(
    @Param('classId') classId: string,
    @Body() addStudentDto: AddStudentDto,
    @GetUser() user: any,
  ) {
    const membership = await this.classesService.addStudentToClass(
      classId,
      addStudentDto.kidId,
      user.id,
    );

    return {
      id: membership._id.toString(),
      kidId: membership.kidId.toString(),
      classId: membership.classId.toString(),
      isActive: membership.isActive,
      joinedAt: membership.createdAt,
    };
  }

  @Delete(':classId/students/:kidId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeStudent(
    @Param('classId') classId: string,
    @Param('kidId') kidId: string,
    @GetUser() user: any,
  ) {
    await this.classesService.removeStudentFromClass(classId, kidId, user.id);
  }
}
