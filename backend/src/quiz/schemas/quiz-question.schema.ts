import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type QuizQuestionDocument = QuizQuestion & Document;

@Schema({ timestamps: true })
export class QuizQuestion {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Lesson' })
  lessonId: Types.ObjectId;

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
