import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { JwtModule } from "@nestjs/jwt";
import { PassportModule } from "@nestjs/passport";
import { ConfigService } from "../config/config.service";
import { KidsController } from "./kids.controller";
import { KidDemoController } from "./kid-demo.controller";
import { KidsService } from "./kids.service";
import { Kid, KidSchema } from "./schemas/kid.schema";
import {
  KidTeacherSelection,
  KidTeacherSelectionSchema,
} from "./schemas/kid-teacher-selection.schema";
import { KidJwtStrategy } from "./strategies/kid-jwt.strategy";
import { User, UserSchema } from "../users/schemas/user.schema";
import { Lesson, LessonSchema } from "../subjects/schemas/lesson.schema";
import { Subject, SubjectSchema } from "../subjects/schemas/subject.schema";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [
    NotificationsModule,
    MongooseModule.forFeature([
      { name: Kid.name, schema: KidSchema },
      { name: KidTeacherSelection.name, schema: KidTeacherSelectionSchema },
      { name: User.name, schema: UserSchema },
      { name: Lesson.name, schema: LessonSchema },
      { name: Subject.name, schema: SubjectSchema },
    ]),
    PassportModule,
    JwtModule.registerAsync({
      useFactory: (configService: ConfigService) => ({
        secret: configService.jwtSecret,
        signOptions: { expiresIn: "30m" },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [KidsController, KidDemoController],
  providers: [KidsService, KidJwtStrategy],
  exports: [KidsService],
})
export class KidsModule {}
