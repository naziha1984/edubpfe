import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Progress, ProgressDocument } from "../quiz/schemas/progress.schema";
import {
  ClassMembership,
  ClassMembershipDocument,
} from "../classes/schemas/class-membership.schema";
import { ClassesService } from "../classes/classes.service";

export interface KidProgressStats {
  kidId: string;
  kidName: string;
  avgScore: number;
  lastActivity: Date | null;
  completionRate: number;
  totalLessons: number;
  completedLessons: number;
}

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectModel(Progress.name) private progressModel: Model<ProgressDocument>,
    @InjectModel(ClassMembership.name)
    private classMembershipModel: Model<ClassMembershipDocument>,
    private classesService: ClassesService,
  ) {}

  async getClassSubjectProgress(
    classId: string,
    subjectId: string,
    teacherId: string,
  ): Promise<{
    classId: string;
    subjectId: string;
    kids: KidProgressStats[];
    overallStats: {
      totalKids: number;
      averageScore: number;
      overallCompletionRate: number;
    };
  }> {
    // Verify class ownership
    const isOwner = await this.classesService.checkOwnership(
      classId,
      teacherId,
    );
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only view analytics for your own classes",
      );
    }

    // Verify class exists
    const classDoc = await this.classesService.findOneById(classId);
    if (!classDoc) {
      throw new NotFoundException("Class not found");
    }

    // Get all active members of the class
    const memberships = await this.classMembershipModel
      .find({
        classId: new Types.ObjectId(classId),
        isActive: true,
      })
      .populate("kidId", "firstName lastName")
      .exec();

    if (memberships.length === 0) {
      return {
        classId,
        subjectId,
        kids: [],
        overallStats: {
          totalKids: 0,
          averageScore: 0,
          overallCompletionRate: 0,
        },
      };
    }

    const kidIds = memberships.map((m) => {
      const kidId = m.kidId._id || m.kidId;
      return kidId instanceof Types.ObjectId
        ? kidId
        : new Types.ObjectId(kidId);
    });

    // Use aggregation to get progress statistics for each kid
    const progressStats = await this.progressModel.aggregate([
      // Match progress records for kids in the class and the specific subject
      {
        $match: {
          kidId: { $in: kidIds },
          subjectId: new Types.ObjectId(subjectId),
        },
      },
      // Group by kidId to calculate statistics
      {
        $group: {
          _id: "$kidId",
          avgScore: { $avg: "$bestScore" },
          maxLastActivity: { $max: "$lastAttemptAt" },
          completedCount: {
            $sum: { $cond: ["$isCompleted", 1, 0] },
          },
          totalLessons: { $sum: 1 },
        },
      },
      // Lookup kid information
      {
        $lookup: {
          from: "kids",
          localField: "_id",
          foreignField: "_id",
          as: "kid",
        },
      },
      {
        $unwind: {
          path: "$kid",
          preserveNullAndEmptyArrays: true,
        },
      },
      // Project final structure
      {
        $project: {
          kidId: { $toString: "$_id" },
          kidName: {
            $concat: [
              { $ifNull: ["$kid.firstName", ""] },
              " ",
              { $ifNull: ["$kid.lastName", ""] },
            ],
          },
          avgScore: { $round: [{ $ifNull: ["$avgScore", 0] }, 2] },
          lastActivity: "$maxLastActivity",
          completedLessons: "$completedCount",
          totalLessons: "$totalLessons",
          completionRate: {
            $cond: [
              { $gt: ["$totalLessons", 0] },
              {
                $round: [
                  {
                    $multiply: [
                      { $divide: ["$completedCount", "$totalLessons"] },
                      100,
                    ],
                  },
                  2,
                ],
              },
              0,
            ],
          },
        },
      },
    ]);

    // Create a map of kidId to stats for quick lookup
    const statsMap = new Map(progressStats.map((stat) => [stat.kidId, stat]));

    // Build result array including all kids (even those without progress)
    const kids: KidProgressStats[] = memberships.map((membership) => {
      const kidId = membership.kidId._id.toString();
      const kid = membership.kidId as any;
      const kidName = `${kid.firstName} ${kid.lastName}`;
      const stats = statsMap.get(kidId);

      if (stats) {
        return {
          kidId,
          kidName,
          avgScore: stats.avgScore,
          lastActivity: stats.lastActivity,
          completionRate: stats.completionRate,
          totalLessons: stats.totalLessons,
          completedLessons: stats.completedLessons,
        };
      } else {
        // Kid has no progress for this subject
        return {
          kidId,
          kidName,
          avgScore: 0,
          lastActivity: null,
          completionRate: 0,
          totalLessons: 0,
          completedLessons: 0,
        };
      }
    });

    // Calculate overall statistics
    const kidsWithProgress = kids.filter((k) => k.totalLessons > 0);
    const totalKids = kids.length;
    const averageScore =
      kidsWithProgress.length > 0
        ? kidsWithProgress.reduce((sum, k) => sum + k.avgScore, 0) /
          kidsWithProgress.length
        : 0;
    const overallCompletionRate =
      kidsWithProgress.length > 0
        ? kidsWithProgress.reduce((sum, k) => sum + k.completionRate, 0) /
          kidsWithProgress.length
        : 0;

    return {
      classId,
      subjectId,
      kids,
      overallStats: {
        totalKids,
        averageScore: Math.round(averageScore * 100) / 100,
        overallCompletionRate: Math.round(overallCompletionRate * 100) / 100,
      },
    };
  }
}
