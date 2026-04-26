import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
  ConflictException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { UsersService } from "../users/users.service";
import { RegisterDto } from "./dto/register.dto";
import { LoginDto } from "./dto/login.dto";
import {
  TeacherApprovalStatus,
  UserDocument,
  UserRole,
} from "../users/schemas/user.schema";
import { unlink } from "fs/promises";
import { existsSync } from "fs";
import { join } from "path";
import { TEACHER_CV_UPLOAD_SUBDIR } from "./teacher-cv-upload.config";

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private toUserPayload(user: UserDocument) {
    return {
      id: user._id.toString(),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isActive: user.isActive,
      cvUrl: user.cvUrl,
      approvalStatus: user.approvalStatus,
      rejectionReason: user.rejectionReason,
      submittedAt: user.submittedAt,
    };
  }

  private isTeacherPending(user: UserDocument): boolean {
    return (
      user.role === UserRole.TEACHER &&
      user.approvalStatus === TeacherApprovalStatus.PENDING
    );
  }

  private cvUrlFromFile(file: Express.Multer.File): string {
    return `/api/uploads/${TEACHER_CV_UPLOAD_SUBDIR}/${file.filename}`;
  }

  private async removeUploadedCvIfExists(cvUrl?: string): Promise<void> {
    if (!cvUrl) return;
    const filename = cvUrl.split("/").pop();
    if (!filename) return;
    const fullPath = join(
      process.cwd(),
      "uploads",
      TEACHER_CV_UPLOAD_SUBDIR,
      filename,
    );
    if (existsSync(fullPath)) {
      await unlink(fullPath);
    }
  }

  async register(registerDto: RegisterDto, cvFile?: Express.Multer.File) {
    const normalizedEmail = this.normalizeEmail(registerDto.email);
    const existingUser = await this.usersService.findByEmail(normalizedEmail);
    if (existingUser) {
      throw new ConflictException("Email already exists");
    }

    const role =
      registerDto.role?.toUpperCase() === "TEACHER"
        ? UserRole.TEACHER
        : UserRole.PARENT;

    if (role === UserRole.TEACHER && !cvFile) {
      throw new BadRequestException(
        "CV file is required for teacher registration",
      );
    }

    const user = await this.usersService.create(
      normalizedEmail,
      registerDto.password,
      registerDto.firstName,
      registerDto.lastName,
      role,
      {
        cvUrl: cvFile ? this.cvUrlFromFile(cvFile) : undefined,
        approvalStatus:
          role === UserRole.TEACHER
            ? TeacherApprovalStatus.PENDING
            : TeacherApprovalStatus.ACCEPTED,
        submittedAt: role === UserRole.TEACHER ? new Date() : undefined,
      },
    );

    const payload = {
      sub: user._id.toString(),
      email: user.email,
      role: user.role,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: this.toUserPayload(user),
      registrationMeta:
        role === UserRole.TEACHER
          ? {
              message:
                "Teacher registration submitted successfully. Your profile is pending admin approval.",
              cvUploaded: true,
            }
          : {
              message: "Registration successful.",
              cvUploaded: false,
            },
    };
  }

  async login(loginDto: LoginDto) {
    const normalizedEmail = this.normalizeEmail(loginDto.email);
    const user = await this.usersService.findByEmail(normalizedEmail);
    if (!user) {
      throw new UnauthorizedException("Invalid credentials");
    }

    const isPasswordValid = await this.usersService.validatePassword(
      loginDto.password,
      user.password,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException("Invalid credentials");
    }

    if (!user.isActive) {
      throw new UnauthorizedException("Account is inactive");
    }

    if (this.isTeacherPending(user)) {
      throw new ForbiddenException("Teacher account is pending admin approval");
    }

    if (
      user.role === UserRole.TEACHER &&
      user.approvalStatus === TeacherApprovalStatus.REJECTED
    ) {
      throw new ForbiddenException(
        user.rejectionReason || "Teacher account was rejected by admin",
      );
    }

    // Migrer les anciens mots de passe en clair vers bcrypt au prochain login réussi
    if (!this.usersService.isBcryptHash(user.password)) {
      await this.usersService.upgradePasswordToBcrypt(
        user._id.toString(),
        loginDto.password,
      );
    }

    const payload = {
      sub: user._id.toString(),
      email: user.email,
      role: user.role,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: this.toUserPayload(user),
    };
  }

  async getProfile(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException("User not found");
    }

    return this.toUserPayload(user);
  }

  async updateTeacherCv(userId: string, cvFile: Express.Multer.File) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException("User not found");
    }
    if (user.role !== UserRole.TEACHER) {
      throw new ForbiddenException("Only teachers can update CV");
    }

    const previousCvUrl = user.cvUrl;
    user.cvUrl = this.cvUrlFromFile(cvFile);
    user.submittedAt = new Date();
    user.approvalStatus = TeacherApprovalStatus.PENDING;
    user.rejectionReason = undefined;
    await user.save();

    await this.removeUploadedCvIfExists(previousCvUrl);

    return {
      message: "CV updated successfully. Awaiting admin approval.",
      user: this.toUserPayload(user),
    };
  }
}
