import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Lesson, LessonDocument } from './schemas/lesson.schema';
import { CreateLessonDto } from './dto/create-lesson.dto';
import { UpdateLessonDto } from './dto/update-lesson.dto';

@Injectable()
export class LessonsService {
  constructor(
    @InjectModel(Lesson.name) private lessonModel: Model<LessonDocument>,
  ) {}

  async findAllBySubjectId(subjectId: string): Promise<LessonDocument[]> {
    return this.lessonModel
      .find({ subjectId: new Types.ObjectId(subjectId), isActive: true })
      .sort({ order: 1, createdAt: 1 })
      .exec();
  }

  async findOne(id: string): Promise<LessonDocument | null> {
    return this.lessonModel.findById(id).exec();
  }

  async create(createLessonDto: CreateLessonDto): Promise<LessonDocument> {
    try {
      const lessonData = {
        ...createLessonDto,
        subjectId: new Types.ObjectId(createLessonDto.subjectId),
      };
      const lesson = new this.lessonModel(lessonData);
      return await lesson.save();
    } catch (error: any) {
      if (error.code === 11000) {
        throw new ConflictException(
          'Lesson with this title already exists in this subject',
        );
      }
      throw error;
    }
  }

  async update(
    id: string,
    updateLessonDto: UpdateLessonDto,
  ): Promise<LessonDocument> {
    const lesson = await this.findOne(id);
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    try {
      const updateData: any = { ...updateLessonDto };
      if (updateLessonDto.subjectId) {
        updateData.subjectId = new Types.ObjectId(updateLessonDto.subjectId);
      }

      return await this.lessonModel
        .findByIdAndUpdate(id, updateData, { new: true })
        .exec();
    } catch (error: any) {
      if (error.code === 11000) {
        throw new ConflictException(
          'Lesson with this title already exists in this subject',
        );
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const lesson = await this.findOne(id);
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    await this.lessonModel.findByIdAndDelete(id).exec();
  }
}
