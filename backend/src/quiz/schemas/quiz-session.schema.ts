import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { QuizDifficulty } from './quiz-question.schema';

export type QuizSessionDocument = QuizSession &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class QuizSession {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Kid' })
  kidId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Lesson' })
  lessonId: Types.ObjectId;

  /** Filtre appliqué à la création (doit correspondre au chargement des questions). */
  @Prop({ enum: QuizDifficulty })
  difficultyFilter?: QuizDifficulty;

  @Prop({ default: 'in_progress' })
  status: 'in_progress' | 'completed';

  @Prop()
  score?: number;

  @Prop()
  totalQuestions?: number;

  @Prop()
  completedAt?: Date;
}

export const QuizSessionSchema = SchemaFactory.createForClass(QuizSession);
