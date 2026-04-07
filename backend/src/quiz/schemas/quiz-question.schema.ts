import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type QuizQuestionDocument = QuizQuestion &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum QuizDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard',
}

@Schema({ timestamps: true })
export class QuizQuestion {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Lesson' })
  lessonId: Types.ObjectId;

  /** Dénormalisé depuis la leçon : filtrage / cohérence avec la matière. */
  @Prop({ type: Types.ObjectId, ref: 'Subject', index: true })
  subjectId?: Types.ObjectId;

  @Prop({
    enum: QuizDifficulty,
    default: QuizDifficulty.MEDIUM,
  })
  difficulty: QuizDifficulty;

  @Prop({ required: true })
  question: string;

  @Prop({ type: [String], required: true })
  options: string[];

  @Prop({ required: true })
  correctAnswer: number; // Index of correct answer in options array

  @Prop()
  explanation?: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const QuizQuestionSchema = SchemaFactory.createForClass(QuizQuestion);
