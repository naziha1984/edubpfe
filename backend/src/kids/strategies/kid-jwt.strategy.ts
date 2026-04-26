import { Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "../../config/config.service";
import { PassportStrategy } from "@nestjs/passport";
import { ExtractJwt, Strategy } from "passport-jwt";
import { KidsService } from "../kids.service";

export interface KidJwtPayload {
  sub: string;
  kidId: string;
  type: "KID_SESSION";
}

@Injectable()
export class KidJwtStrategy extends PassportStrategy(Strategy, "kid-jwt") {
  constructor(
    private configService: ConfigService,
    private kidsService: KidsService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.jwtSecret,
    });
  }

  async validate(payload: KidJwtPayload) {
    if (payload.type !== "KID_SESSION") {
      throw new UnauthorizedException("Invalid token type");
    }

    const kid = await this.kidsService.findOneById(payload.kidId);
    if (!kid || !kid.isActive) {
      throw new UnauthorizedException("Kid not found or inactive");
    }

    return {
      id: kid._id.toString(),
      kidId: kid._id.toString(),
      firstName: kid.firstName,
      lastName: kid.lastName,
      parentId: kid.parentId.toString(),
    };
  }
}
