import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type UserDocument = User &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum UserRole {
  PARENT = "PARENT",
  TEACHER = "TEACHER",
  ADMIN = "ADMIN",
}

export enum TeacherApprovalStatus {
  PENDING = "PENDING",
  ACCEPTED = "ACCEPTED",
  REJECTED = "REJECTED",
}

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ required: true })
  password: string;

  @Prop({ required: true })
  firstName: string;

  @Prop({ required: true })
  lastName: string;

  @Prop({ enum: UserRole, default: UserRole.PARENT })
  role: UserRole;

  @Prop({ default: true })
  isActive: boolean;

  @Prop()
  specialty?: string;

  @Prop()
  bio?: string;

  @Prop()
  profilePhotoUrl?: string;

  @Prop({ default: 0 })
  ratingAvg?: number;

  @Prop({ default: 0 })
  ratingCount?: number;

  @Prop()
  cvUrl?: string;

  @Prop({
    enum: TeacherApprovalStatus,
    default: TeacherApprovalStatus.ACCEPTED,
  })
  approvalStatus: TeacherApprovalStatus;

  @Prop()
  rejectionReason?: string;

  @Prop()
  submittedAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
