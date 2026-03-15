import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Assignment, AssignmentDocument } from '../notifications/schemas/assignment.schema';
import { AssignmentSubmission, AssignmentSubmissionDocument, SubmissionStatus } from './schemas/assignment-submission.schema';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { ClassesService } from '../classes/classes.service';

@Injectable()
export class AssignmentsService {
  constructor(
    @InjectModel(Assignment.name) private assignmentModel: Model<AssignmentDocument>,
    @InjectModel(AssignmentSubmission.name) private submissionModel: Model<AssignmentSubmissionDocument>,
    private classesService: ClassesService,
  ) {}

  async createAssignment(createAssignmentDto: CreateAssignmentDto, teacherId: string): Promise<AssignmentDocument> {
    // Verify class ownership
    const isOwner = await this.classesService.checkOwnership(createAssignmentDto.classId, teacherId);
    if (!isOwner) {
      throw new ForbiddenException('You can only create assignments for your own classes');
    }

    const assignment = new this.assignmentModel({
      ...createAssignmentDto,
      classId: new Types.ObjectId(createAssignmentDto.classId),
      teacherId: new Types.ObjectId(teacherId),
      lessonId: createAssignmentDto.lessonId ? new Types.ObjectId(createAssignmentDto.lessonId) : undefined,
      dueDate: new Date(createAssignmentDto.dueDate),
    });

    const savedAssignment = await assignment.save();

    // Create submissions for all class members
    const members = await this.classesService.getClassMembers(createAssignmentDto.classId, teacherId);
    for (const member of members) {
      await this.submissionModel.create({
        assignmentId: savedAssignment._id,
        kidId: member.kidId,
        status: SubmissionStatus.ASSIGNED,
      });
    }

    return savedAssignment;
  }

  async getAssignmentsByClass(classId: string, teacherId: string): Promise<AssignmentDocument[]> {
    const isOwner = await this.classesService.checkOwnership(classId, teacherId);
    if (!isOwner) {
      throw new ForbiddenException('You can only view assignments for your own classes');
    }

    return this.assignmentModel
      .find({ classId: new Types.ObjectId(classId) })
      .populate('lessonId', 'title')
      .sort({ dueDate: 1 })
      .exec();
  }

  async getAssignmentSubmissions(assignmentId: string, teacherId: string) {
    const assignment = await this.assignmentModel.findById(assignmentId).exec();
    if (!assignment) {
      throw new NotFoundException('Assignment not found');
    }

    const isOwner = await this.classesService.checkOwnership(assignment.classId.toString(), teacherId);
    if (!isOwner) {
      throw new ForbiddenException('You can only view submissions for your own assignments');
    }

    return this.submissionModel
      .find({ assignmentId: new Types.ObjectId(assignmentId) })
      .populate('kidId', 'firstName lastName')
      .populate('quizSessionId')
      .exec();
  }

  async getKidAssignments(kidId: string): Promise<any[]> {
    // Get all classes the kid belongs to
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id);

    if (classIds.length === 0) {
      return [];
    }

    // Get all assignments for these classes
    const assignments = await this.assignmentModel
      .find({ classId: { $in: classIds }, isActive: true })
      .populate('lessonId', 'title')
      .sort({ dueDate: 1 })
      .exec();

    // Get submissions for this kid
    const assignmentIds = assignments.map((a) => a._id);
    const submissions = await this.submissionModel
      .find({
        assignmentId: { $in: assignmentIds },
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    const submissionMap = new Map(
      submissions.map((s) => [s.assignmentId.toString(), s]),
    );

    // Combine assignments with their submissions
    return assignments.map((assignment) => {
      const submission = submissionMap.get(assignment._id.toString());
      return {
        id: assignment._id.toString(),
        classId: assignment.classId.toString(),
        teacherId: assignment.teacherId.toString(),
        lessonId: assignment.lessonId?.toString(),
        lesson: assignment.lessonId
          ? {
              id: (assignment.lessonId as any)._id?.toString(),
              title: (assignment.lessonId as any).title,
            }
          : null,
        title: assignment.title,
        description: assignment.description,
        dueDate: assignment.dueDate,
        isActive: assignment.isActive,
        submission: submission
          ? {
              id: submission._id.toString(),
              status: submission.status,
              quizSessionId: submission.quizSessionId?.toString(),
              score: submission.score,
              submittedAt: submission.submittedAt,
              startedAt: submission.startedAt,
            }
          : null,
        createdAt: assignment.createdAt,
        updatedAt: assignment.updatedAt,
      };
    });
  }

  async startAssignment(assignmentId: string, kidId: string): Promise<AssignmentSubmissionDocument> {
    const assignment = await this.assignmentModel.findById(assignmentId).exec();
    if (!assignment) {
      throw new NotFoundException('Assignment not found');
    }

    // Verify kid belongs to the class
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id.toString());
    if (!classIds.includes(assignment.classId.toString())) {
      throw new ForbiddenException('You can only start assignments for your classes');
    }

    // Find or create submission
    let submission = await this.submissionModel
      .findOne({
        assignmentId: new Types.ObjectId(assignmentId),
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    if (!submission) {
      // Create submission if it doesn't exist
      submission = await this.submissionModel.create({
        assignmentId: new Types.ObjectId(assignmentId),
        kidId: new Types.ObjectId(kidId),
        status: SubmissionStatus.IN_PROGRESS,
        startedAt: new Date(),
      });
    } else {
      // Update existing submission
      if (submission.status === SubmissionStatus.COMPLETED) {
        throw new ConflictException('Assignment already completed');
      }
      submission.status = SubmissionStatus.IN_PROGRESS;
      if (!submission.startedAt) {
        submission.startedAt = new Date();
      }
      await submission.save();
    }

    return submission;
  }

  async submitAssignment(
    assignmentId: string,
    kidId: string,
    quizSessionId?: string,
    score?: number,
  ): Promise<AssignmentSubmissionDocument> {
    const assignment = await this.assignmentModel.findById(assignmentId).exec();
    if (!assignment) {
      throw new NotFoundException('Assignment not found');
    }

    // Verify kid belongs to the class
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id.toString());
    if (!classIds.includes(assignment.classId.toString())) {
      throw new ForbiddenException('You can only submit assignments for your classes');
    }

    // Find submission
    const submission = await this.submissionModel
      .findOne({
        assignmentId: new Types.ObjectId(assignmentId),
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    if (!submission) {
      throw new NotFoundException('Assignment submission not found. Please start the assignment first.');
    }

    if (submission.status === SubmissionStatus.COMPLETED) {
      throw new ConflictException('Assignment already completed');
    }

    // Update submission
    submission.status = SubmissionStatus.COMPLETED;
    submission.submittedAt = new Date();
    if (quizSessionId) {
      submission.quizSessionId = new Types.ObjectId(quizSessionId);
    }
    if (score !== undefined) {
      submission.score = score;
    }
    if (!submission.startedAt) {
      submission.startedAt = new Date();
    }

    await submission.save();
    return submission;
  }
}
