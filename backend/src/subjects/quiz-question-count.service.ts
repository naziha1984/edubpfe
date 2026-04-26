import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  QuizQuestion,
  QuizQuestionDocument,
} from "../quiz/schemas/quiz-question.schema";

@Injectable()
export class QuizQuestionCountService {
  constructor(
    @InjectModel(QuizQuestion.name)
    private readonly quizQuestionModel: Model<QuizQuestionDocument>,
  ) {}

  /** Compte les questions actives par leçon (pour l’API matières / leçons). */
  async countByLessonIds(lessonIds: string[]): Promise<Map<string, number>> {
    const map = new Map<string, number>();
    if (lessonIds.length === 0) return map;
    const oids = lessonIds.map((id) => new Types.ObjectId(id));
    const agg = await this.quizQuestionModel
      .aggregate<{
        _id: Types.ObjectId;
        count: number;
      }>([{ $match: { lessonId: { $in: oids }, isActive: true } }, { $group: { _id: "$lessonId", count: { $sum: 1 } } }])
      .exec();
    for (const row of agg) {
      map.set(row._id.toString(), row.count);
    }
    return map;
  }
}
