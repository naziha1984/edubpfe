import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type ConversationDocument = Conversation &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Conversation {
  @Prop({ required: true, type: [Types.ObjectId], ref: "User" })
  participantIds: Types.ObjectId[];

  @Prop()
  lastMessage?: string;

  @Prop()
  lastMessageAt?: Date;
}

export const ConversationSchema = SchemaFactory.createForClass(Conversation);

ConversationSchema.index({ participantIds: 1 });
ConversationSchema.index({ lastMessageAt: -1 });
