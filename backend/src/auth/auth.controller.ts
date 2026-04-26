import {
  BadRequestException,
  Controller,
  Post,
  Patch,
  Get,
  Body,
  UploadedFile,
  UseInterceptors,
  UseGuards,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { AuthService } from "./auth.service";
import { RegisterDto } from "./dto/register.dto";
import { LoginDto } from "./dto/login.dto";
import { JwtAuthGuard } from "./guards/jwt-auth.guard";
import { GetUser } from "./decorators/get-user.decorator";
import { RolesGuard } from "./guards/roles.guard";
import { Roles } from "./decorators/roles.decorator";
import { UserRole } from "../users/schemas/user.schema";
import { teacherCvMulterOptions } from "./teacher-cv-upload.config";

@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post("register")
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor("cv", teacherCvMulterOptions))
  async register(
    @UploadedFile() cvFile: Express.Multer.File | undefined,
    @Body() registerDto: RegisterDto,
  ) {
    if (registerDto.role?.toUpperCase() === UserRole.TEACHER && !cvFile) {
      throw new BadRequestException(
        "CV file is required for teacher registration",
      );
    }
    return this.authService.register(registerDto, cvFile);
  }

  @Post("login")
  @HttpCode(HttpStatus.OK)
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Get("me")
  @UseGuards(JwtAuthGuard)
  async getMe(@GetUser() user: any) {
    return this.authService.getProfile(user.id);
  }

  @Patch("teacher/cv")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.TEACHER)
  @UseInterceptors(FileInterceptor("cv", teacherCvMulterOptions))
  async updateTeacherCv(
    @GetUser() user: { id: string },
    @UploadedFile() cvFile: Express.Multer.File | undefined,
  ) {
    if (!cvFile) {
      throw new BadRequestException("CV file is required");
    }
    return this.authService.updateTeacherCv(user.id, cvFile);
  }
}
