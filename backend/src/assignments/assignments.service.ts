import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  Assignment,
  AssignmentDocument,
} from "../notifications/schemas/assignment.schema";
import {
  AssignmentSubmission,
  AssignmentSubmissionDocument,
  SubmissionStatus,
} from "./schemas/assignment-submission.schema";
import { CreateAssignmentDto } from "./dto/create-assignment.dto";
import { ClassesService } from "../classes/classes.service";
import { ASSIGNMENTS_UPLOAD_SUBDIR } from "./assignment-upload.config";
import { mapAssignmentAttachment } from "./assignment-response.util";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/schemas/notification.schema";
import { Kid, KidDocument } from "../kids/schemas/kid.schema";
import { RewardsService } from "../rewards/rewards.service";

@Injectable()
export class AssignmentsService {
  constructor(
    @InjectModel(Assignment.name)
    private assignmentModel: Model<AssignmentDocument>,
    @InjectModel(AssignmentSubmission.name)
    private submissionModel: Model<AssignmentSubmissionDocument>,
    private classesService: ClassesService,
    private notificationsService: NotificationsService,
    @InjectModel(Kid.name) private readonly kidModel: Model<KidDocument>,
    private readonly rewardsService: RewardsService,
  ) {}

  async createAssignment(
    createAssignmentDto: CreateAssignmentDto,
    teacherId: string,
    uploadedFiles: Express.Multer.File[] = [],
  ): Promise<AssignmentDocument> {
    // Vérifier que la classe appartient bien à l'enseignant
    const isOwner = await this.classesService.checkOwnership(
      createAssignmentDto.classId,
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only create assignments for your own classes",
      );
    }

    const attachments = uploadedFiles.map((f) => ({
      originalName: f.originalname,
      storedName: f.filename,
      mimeType: f.mimetype,
      size: f.size,
      urlPath: `${ASSIGNMENTS_UPLOAD_SUBDIR}/${f.filename}`,
    }));

    const assignment = new this.assignmentModel({
      ...createAssignmentDto,
      classId: new Types.ObjectId(createAssignmentDto.classId),
      teacherId: new Types.ObjectId(teacherId),
      lessonId: createAssignmentDto.lessonId
        ? new Types.ObjectId(createAssignmentDto.lessonId)
        : undefined,
      dueDate: new Date(createAssignmentDto.dueDate),
      attachments,
    });

    const savedAssignment = await assignment.save();

    // Créer une remise pour chaque membre de la classe
    const members = await this.classesService.getClassMembers(
      createAssignmentDto.classId,
      teacherId,
    );
    for (const member of members) {
      await this.submissionModel.create({
        assignmentId: savedAssignment._id,
        kidId: member.kidId,
        status: SubmissionStatus.ASSIGNED,
      });
    }

    await this.notificationsService.notifyParentsInClass(
      createAssignmentDto.classId,
      NotificationType.ASSIGNMENT_CREATED,
      "New assignment",
      `A new assignment "${savedAssignment.title}" was posted for your child’s class.`,
      {
        relatedId: savedAssignment._id.toString(),
        relatedType: "assignment",
      },
    );

    return savedAssignment;
  }

  async getAssignmentsByClass(
    classId: string,
    teacherId: string,
  ): Promise<AssignmentDocument[]> {
    const isOwner = await this.classesService.checkOwnership(
      classId,
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only view assignments for your own classes",
      );
    }

    return this.assignmentModel
      .find({ classId: new Types.ObjectId(classId) })
      .populate("lessonId", "title")
      .sort({ dueDate: 1 })
      .exec();
  }

  async getAssignmentSubmissions(assignmentId: string, teacherId: string) {
    const assignment = await this.assignmentModel.findById(assignmentId).exec();
    if (!assignment) {
      throw new NotFoundException("Assignment not found");
    }

    const isOwner = await this.classesService.checkOwnership(
      assignment.classId.toString(),
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only view submissions for your own assignments",
      );
    }

    return this.submissionModel
      .find({ assignmentId: new Types.ObjectId(assignmentId) })
      .populate("kidId", "firstName lastName")
      .populate("quizSessionId")
      .exec();
  }

  async getKidAssignments(kidId: string): Promise<any[]> {
    // Récupérer toutes les classes auxquelles l'enfant appartient
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id);

    if (classIds.length === 0) {
      return [];
    }

    // Récupérer tous les devoirs de ces classes
    const assignments = await this.assignmentModel
      .find({ classId: { $in: classIds }, isActive: true })
      .populate("lessonId", "title")
      .sort({ dueDate: 1 })
      .exec();

    // Récupérer les remises pour cet enfant
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

    // Fusionner les devoirs avec leurs remises
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
        attachments: (assignment.attachments || []).map(
          mapAssignmentAttachment,
        ),
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

  async startAssignment(
    assignmentId: string,
    kidId: string,
  ): Promise<AssignmentSubmissionDocument> {
    const assignment = await this.assignmentModel.findById(assignmentId).exec();
    if (!assignment) {
      throw new NotFoundException("Assignment not found");
    }

    // Vérifier que l'enfant appartient à la classe
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id.toString());
    if (!classIds.includes(assignment.classId.toString())) {
      throw new ForbiddenException(
        "You can only start assignments for your classes",
      );
    }

    // Rechercher ou créer la remise
    let submission = await this.submissionModel
      .findOne({
        assignmentId: new Types.ObjectId(assignmentId),
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    if (!submission) {
      // Créer la remise si elle n'existe pas
      submission = await this.submissionModel.create({
        assignmentId: new Types.ObjectId(assignmentId),
        kidId: new Types.ObjectId(kidId),
        status: SubmissionStatus.IN_PROGRESS,
        startedAt: new Date(),
      });
    } else {
      // Mettre à jour la remise existante
      if (submission.status === SubmissionStatus.COMPLETED) {
        throw new ConflictException("Assignment already completed");
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
      throw new NotFoundException("Assignment not found");
    }

    // Vérifier que l'enfant appartient à la classe
    const classes = await this.classesService.getKidClasses(kidId);
    const classIds = classes.map((c) => c._id.toString());
    if (!classIds.includes(assignment.classId.toString())) {
      throw new ForbiddenException(
        "You can only submit assignments for your classes",
      );
    }

    // Rechercher la remise
    const submission = await this.submissionModel
      .findOne({
        assignmentId: new Types.ObjectId(assignmentId),
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    if (!submission) {
      throw new NotFoundException(
        "Assignment submission not found. Please start the assignment first.",
      );
    }

    if (submission.status === SubmissionStatus.COMPLETED) {
      throw new ConflictException("Assignment already completed");
    }

    // Mettre à jour la remise
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

    // Bonus : devoir remis à temps -> +10 points
    // Idempotence : sourceId = submissionId, donc un retry ne duplique pas les points.
    const onTime =
      submission.submittedAt != null &&
      assignment.dueDate != null &&
      submission.submittedAt.getTime() <= assignment.dueDate.getTime();

    const kid = await this.kidModel
      .findById(kidId)
      .select("firstName lastName")
      .exec();
    const studentName = kid
      ? `${kid.firstName ?? ""} ${kid.lastName ?? ""}`.trim()
      : "Student";

    const submittedAtIso = submission.submittedAt?.toISOString();

    await this.notificationsService.createForUser(
      assignment.teacherId.toString(),
      NotificationType.ASSIGNMENT_SUBMITTED,
      "Homework submitted",
      `${studentName} submitted "${assignment.title}"${
        submittedAtIso ? ` at ${submittedAtIso}` : ""
      }.`,
      {
        kidId,
        relatedId: assignment._id.toString(),
        relatedType: "assignment",
      },
    );

    if (onTime) {
      await this.rewardsService.addXP(
        kidId,
        10,
        "homework_on_time",
        submission._id.toString(),
        `Homework on time: ${assignment.title}`,
      );
      await this.rewardsService.updateStreak(kidId);
    }

    return submission;
  }
}
