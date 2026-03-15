import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Subject, SubjectDocument } from './schemas/subject.schema';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';

@Injectable()
export class SubjectsService {
  constructor(
    @InjectModel(Subject.name) private subjectModel: Model<SubjectDocument>,
  ) {}

  async findAll(): Promise<SubjectDocument[]> {
    return this.subjectModel.find({ isActive: true }).sort({ name: 1 }).exec();
  }

  async findOne(id: string): Promise<SubjectDocument | null> {
    return this.subjectModel.findById(id).exec();
  }

  async create(createSubjectDto: CreateSubjectDto): Promise<SubjectDocument> {
    try {
      const subject = new this.subjectModel(createSubjectDto);
      return await subject.save();
    } catch (error: any) {
      if (error.code === 11000) {
        throw new ConflictException('Subject with this name already exists');
      }
      throw error;
    }
  }

  async update(
    id: string,
    updateSubjectDto: UpdateSubjectDto,
  ): Promise<SubjectDocument> {
    const subject = await this.findOne(id);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    try {
      return await this.subjectModel
        .findByIdAndUpdate(id, updateSubjectDto, { new: true })
        .exec();
    } catch (error: any) {
      if (error.code === 11000) {
        throw new ConflictException('Subject with this name already exists');
      }
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const subject = await this.findOne(id);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    await this.subjectModel.findByIdAndDelete(id).exec();
  }
}
