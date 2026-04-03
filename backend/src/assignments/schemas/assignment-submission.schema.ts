import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type AssignmentSubmissionDocument = AssignmentSubmission &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum SubmissionStatus {
  ASSIGNED = 'ASSIGNED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
}

@Schema({ timestamps: true })
export class AssignmentSubmission {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Assignment' })
  assignmentId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Kid' })
  kidId: Types.ObjectId;

  @Prop({ default: SubmissionStatus.ASSIGNED, enum: SubmissionStatus })
  status: SubmissionStatus;

  @Prop({ type: Types.ObjectId, ref: 'QuizSession' })
  quizSessionId?: Types.ObjectId;

  @Prop()
  score?: number;

  @Prop()
  submittedAt?: Date;

  @Prop()
  startedAt?: Date;
}

export const AssignmentSubmissionSchema =
  SchemaFactory.createForClass(AssignmentSubmission);

// 确保每个 kid 对每个 assignment 只有一个 soumission
AssignmentSubmissionSchema.index(
  { assignmentId: 1, kidId: 1 },
  { unique: true },
);
