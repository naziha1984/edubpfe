import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import { RewardsService } from "./rewards.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { KidAuthGuard } from "../kids/guards/kid-auth.guard";
import { GetUser } from "../auth/decorators/get-user.decorator";
import { GetKid } from "../kids/decorators/get-kid.decorator";
import { UserRole } from "../users/schemas/user.schema";

@Controller()
export class RewardsController {
  constructor(private readonly rewardsService: RewardsService) {}

  @Get("kids/:kidId/rewards")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async getRewardsByParent(
    @Param("kidId") kidId: string,
    @GetUser() user: any,
  ) {
    return this.rewardsService.getRewardsByKidId(kidId, undefined, user.id);
  }

  @Get("kid/rewards")
  @UseGuards(KidAuthGuard)
  async getRewardsByKid(@GetKid() kid: any) {
    return this.rewardsService.getRewardsByKidId(kid.kidId, kid.kidId);
  }

  @Post("kid/streak")
  @UseGuards(KidAuthGuard)
  @HttpCode(HttpStatus.OK)
  async updateStreak(@GetKid() kid: any) {
    const result = await this.rewardsService.updateStreak(kid.kidId);
    return {
      streak: result.streak,
      xpEarned: result.xpEarned,
      message:
        result.xpEarned > 0
          ? `Streak updated! Current streak: ${result.streak} days. Earned ${result.xpEarned} XP.`
          : "Already checked in today.",
    };
  }
}
