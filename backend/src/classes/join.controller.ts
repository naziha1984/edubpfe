import {
  Controller,
  Post,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import { ClassesService } from "./classes.service";
import { KidsService } from "../kids/kids.service";
import { JoinClassDto } from "./dto/join-class.dto";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { GetUser } from "../auth/decorators/get-user.decorator";
import { UserRole } from "../users/schemas/user.schema";

@Controller("classes")
export class JoinController {
  constructor(
    private readonly classesService: ClassesService,
    private readonly kidsService: KidsService,
  ) {}

  @Post("join")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  @HttpCode(HttpStatus.CREATED)
  async joinClass(@Body() joinClassDto: JoinClassDto, @GetUser() user: any) {
    // Strict ownership check: verify parent owns the kid
    const kid = await this.kidsService.findOneById(joinClassDto.kidId);
    if (!kid) {
      throw new NotFoundException("Kid not found");
    }

    if (kid.parentId.toString() !== user.id) {
      throw new ForbiddenException(
        "You can only join classes for your own kids",
      );
    }

    const membership = await this.classesService.joinClass(joinClassDto);

    return {
      id: membership._id.toString(),
      classId: membership.classId.toString(),
      kidId: membership.kidId.toString(),
      isActive: membership.isActive,
      joinedAt: membership.createdAt,
    };
  }
}
