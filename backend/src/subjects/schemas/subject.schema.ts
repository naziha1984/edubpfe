import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SubjectDocument = Subject &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Subject {
  @Prop({ required: true, unique: true, index: true })
  name: string;

  @Prop()
  description?: string;

  @Prop()
  code?: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const SubjectSchema = SchemaFactory.createForClass(Subject);
// Index créé par @Prop({ unique: true, index: true }) sur name
