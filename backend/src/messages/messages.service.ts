import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  Conversation,
  ConversationDocument,
} from "./schemas/conversation.schema";
import {
  DirectMessage,
  DirectMessageDocument,
} from "./schemas/direct-message.schema";
import { User, UserDocument, UserRole } from "../users/schemas/user.schema";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/schemas/notification.schema";

@Injectable()
export class MessagesService {
  constructor(
    @InjectModel(Conversation.name)
    private conversationModel: Model<ConversationDocument>,
    @InjectModel(DirectMessage.name)
    private messageModel: Model<DirectMessageDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private readonly notificationsService: NotificationsService,
  ) {}

  private ensureMessagingRole(role: string) {
    const normalized = role?.toUpperCase();
    if (normalized !== UserRole.PARENT && normalized !== UserRole.TEACHER) {
      throw new ForbiddenException(
        "Only parent and teacher can use direct messaging",
      );
    }
  }

  private async ensureAllowedPair(
    sender: UserDocument,
    receiver: UserDocument,
  ) {
    const s = sender.role?.toUpperCase();
    const r = receiver.role?.toUpperCase();
    const valid =
      (s === UserRole.PARENT && r === UserRole.TEACHER) ||
      (s === UserRole.TEACHER && r === UserRole.PARENT);
    if (!valid) {
      throw new ForbiddenException(
        "Direct messaging allowed only between parent and teacher",
      );
    }
  }

  private async getOrCreateConversation(userAId: string, userBId: string) {
    const ids = [new Types.ObjectId(userAId), new Types.ObjectId(userBId)];
    let conv = await this.conversationModel
      .findOne({
        participantIds: {
          $all: ids,
          $size: 2,
        },
      })
      .exec();
    if (!conv) {
      conv = await this.conversationModel.create({
        participantIds: ids,
        lastMessageAt: new Date(),
      });
    }
    return conv;
  }

  async listConversations(userId: string, role: string) {
    this.ensureMessagingRole(role);
    const userObjectId = new Types.ObjectId(userId);
    const conversations = await this.conversationModel
      .find({ participantIds: userObjectId })
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .exec();

    const convIds = conversations.map((c) => c._id as Types.ObjectId);
    const unreadAgg = await this.messageModel.aggregate([
      {
        $match: {
          conversationId: { $in: convIds },
          receiverId: userObjectId,
          isRead: false,
        },
      },
      { $group: { _id: "$conversationId", unreadCount: { $sum: 1 } } },
    ]);
    const unreadByConv = new Map(
      unreadAgg.map((u) => [u._id.toString(), Number(u.unreadCount ?? 0)]),
    );

    const otherIds = conversations.map((c) =>
      c.participantIds.find((pid) => pid.toString() !== userId)?.toString(),
    );
    const uniqOtherIds = Array.from(new Set(otherIds.filter(Boolean)));
    const users = await this.userModel
      .find({ _id: { $in: uniqOtherIds } })
      .select("firstName lastName email role")
      .exec();
    const userMap = new Map(users.map((u) => [u._id.toString(), u]));

    return conversations.map((c) => {
      const otherId = c.participantIds
        .find((pid) => pid.toString() !== userId)
        ?.toString();
      const other = otherId ? userMap.get(otherId) : undefined;
      return {
        id: c._id.toString(),
        participantIds: c.participantIds.map((p) => p.toString()),
        otherUser: other
          ? {
              id: other._id.toString(),
              fullName: `${other.firstName} ${other.lastName}`.trim(),
              firstName: other.firstName,
              lastName: other.lastName,
              email: other.email,
              role: other.role,
            }
          : null,
        lastMessage: c.lastMessage ?? "",
        lastMessageAt: c.lastMessageAt ?? c.updatedAt ?? c.createdAt,
        unreadCount: unreadByConv.get(c._id.toString()) ?? 0,
      };
    });
  }

  async getConversationMessages(
    conversationId: string,
    userId: string,
    role: string,
  ) {
    this.ensureMessagingRole(role);
    const conversation = await this.conversationModel
      .findById(conversationId)
      .exec();
    if (!conversation) {
      throw new NotFoundException("Conversation not found");
    }
    const isParticipant = conversation.participantIds.some(
      (id) => id.toString() === userId,
    );
    if (!isParticipant) {
      throw new ForbiddenException("Not allowed to access this conversation");
    }

    const items = await this.messageModel
      .find({ conversationId: new Types.ObjectId(conversationId) })
      .sort({ createdAt: 1 })
      .exec();
    return items.map((m) => ({
      id: m._id.toString(),
      conversationId: m.conversationId.toString(),
      senderId: m.senderId.toString(),
      receiverId: m.receiverId.toString(),
      message: m.message,
      isRead: m.isRead,
      readAt: m.readAt,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
    }));
  }

  async sendDirectMessage(
    senderId: string,
    senderRole: string,
    receiverId: string,
    message: string,
  ) {
    this.ensureMessagingRole(senderRole);
    const [sender, receiver] = await Promise.all([
      this.userModel.findById(senderId).exec(),
      this.userModel.findById(receiverId).exec(),
    ]);
    if (!sender || !receiver) {
      throw new NotFoundException("Sender or receiver not found");
    }
    await this.ensureAllowedPair(sender, receiver);

    const conversation = await this.getOrCreateConversation(
      senderId,
      receiverId,
    );
    const msg = await this.messageModel.create({
      conversationId: conversation._id,
      senderId: new Types.ObjectId(senderId),
      receiverId: new Types.ObjectId(receiverId),
      message: message.trim(),
      isRead: false,
    });
    conversation.lastMessage = msg.message;
    conversation.lastMessageAt = msg.createdAt;
    await conversation.save();

    await this.notificationsService.createForUser(
      receiverId,
      NotificationType.DIRECT_MESSAGE,
      "New direct message",
      `You received a new message from ${sender.firstName} ${sender.lastName}.`,
      {
        relatedId: conversation._id.toString(),
        relatedType: "conversation",
      },
    );

    return {
      conversationId: conversation._id.toString(),
      id: msg._id.toString(),
      senderId,
      receiverId,
      message: msg.message,
      isRead: msg.isRead,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
    };
  }

  async markConversationAsRead(
    conversationId: string,
    userId: string,
    role: string,
  ) {
    this.ensureMessagingRole(role);
    const conversation = await this.conversationModel
      .findById(conversationId)
      .exec();
    if (!conversation) {
      throw new NotFoundException("Conversation not found");
    }
    const isParticipant = conversation.participantIds.some(
      (id) => id.toString() === userId,
    );
    if (!isParticipant) {
      throw new ForbiddenException("Not allowed to access this conversation");
    }
    await this.messageModel.updateMany(
      {
        conversationId: new Types.ObjectId(conversationId),
        receiverId: new Types.ObjectId(userId),
        isRead: false,
      },
      {
        $set: {
          isRead: true,
          readAt: new Date(),
        },
      },
    );
    return { message: "Conversation marked as read" };
  }
}
