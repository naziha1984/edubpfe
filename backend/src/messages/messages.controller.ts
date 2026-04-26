import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { GetUser } from "../auth/decorators/get-user.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { MessagesService } from "./messages.service";
import { SendDirectMessageDto } from "./dto/send-direct-message.dto";

@Controller("messages")
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.PARENT, UserRole.TEACHER)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get("conversations")
  async listConversations(@GetUser() user: { id: string; role: string }) {
    return this.messagesService.listConversations(user.id, user.role);
  }

  @Get("conversations/:conversationId/messages")
  async getConversationMessages(
    @Param("conversationId") conversationId: string,
    @GetUser() user: { id: string; role: string },
  ) {
    return this.messagesService.getConversationMessages(
      conversationId,
      user.id,
      user.role,
    );
  }

  @Post("direct/:receiverId")
  async sendDirectMessage(
    @Param("receiverId") receiverId: string,
    @Body() dto: SendDirectMessageDto,
    @GetUser() user: { id: string; role: string },
  ) {
    return this.messagesService.sendDirectMessage(
      user.id,
      user.role,
      receiverId,
      dto.message,
    );
  }

  @Patch("conversations/:conversationId/read")
  async markConversationAsRead(
    @Param("conversationId") conversationId: string,
    @GetUser() user: { id: string; role: string },
  ) {
    return this.messagesService.markConversationAsRead(
      conversationId,
      user.id,
      user.role,
    );
  }
}
