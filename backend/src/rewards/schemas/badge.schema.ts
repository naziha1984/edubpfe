import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type BadgeDocument = Badge & Document;

export enum BadgeType {
  QUIZ_MASTER = "QUIZ_MASTER", // Complete 10 quizzes
  PERFECT_SCORE = "PERFECT_SCORE", // Get 100% on a quiz
  STREAK_7 = "STREAK_7", // 7 day streak
  STREAK_30 = "STREAK_30", // 30 day streak
  XP_1000 = "XP_1000", // Reach 1000 XP
  XP_5000 = "XP_5000", // Reach 5000 XP
}

@Schema({ timestamps: true })
export class Badge {
  @Prop({ required: true, unique: true, enum: BadgeType })
  type: BadgeType;

  @Prop({ required: true })
  name: string;

  @Prop()
  description?: string;

  @Prop()
  icon?: string;
}

export const BadgeSchema = SchemaFactory.createForClass(Badge);
// Index unique sur type créé par @Prop({ unique: true }) sur type
