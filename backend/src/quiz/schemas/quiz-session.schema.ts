import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

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
