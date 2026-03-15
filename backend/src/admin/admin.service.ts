import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument, UserRole } from '../users/schemas/user.schema';
import { Subject, SubjectDocument } from '../subjects/schemas/subject.schema';
import { Lesson, LessonDocument } from '../subjects/schemas/lesson.schema';
import { Kid, KidDocument } from '../kids/schemas/kid.schema';

@Injectable()
export class AdminService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Subject.name) private subjectModel: Model<SubjectDocument>,
    @InjectModel(Lesson.name) private lessonModel: Model<LessonDocument>,
    @InjectModel(Kid.name) private kidModel: Model<KidDocument>,
  ) {}

  async getUsers(role?: string, search?: string) {
    const query: any = {};

    // Filtrer par rôle
    if (role && Object.values(UserRole).includes(role as UserRole)) {
      query.role = role;
    }

    // Recherche par email, firstName, lastName
    if (search && search.trim()) {
      const searchRegex = new RegExp(search.trim(), 'i');
      query.$or = [
        { email: searchRegex },
        { firstName: searchRegex },
        { lastName: searchRegex },
      ];
    }

    const users = await this.userModel.find(query).select('-password').exec();

    return users.map((user) => ({
      id: user._id.toString(),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    }));
  }

  async getKids() {
    const kids = await this.kidModel
      .find()
      .populate('parentId', 'email firstName lastName')
      .sort({ createdAt: -1 })
      .exec();

    return kids.map((kid) => {
      const parent = kid.parentId as any;
      return {
        id: kid._id.toString(),
        firstName: kid.firstName,
        lastName: kid.lastName,
        dateOfBirth: kid.dateOfBirth,
        grade: kid.grade,
        school: kid.school,
        isActive: kid.isActive,
        parentId: kid.parentId?.toString(),
        parentEmail: parent?.email,
        parentFirstName: parent?.firstName,
        parentLastName: parent?.lastName,
        createdAt: kid.createdAt,
        updatedAt: kid.updatedAt,
      };
    });
  }

  async getStats() {
    const [totalUsers, totalSubjects, totalLessons] = await Promise.all([
      this.userModel.countDocuments().exec(),
      this.subjectModel.countDocuments().exec(),
      this.lessonModel.countDocuments().exec(),
    ]);

    return {
      totalUsers,
      totalSubjects,
      totalLessons,
    };
  }
}
