import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import {
  TeacherApprovalStatus,
  User,
  UserDocument,
  UserRole,
} from "./schemas/user.schema";
import * as bcrypt from "bcrypt";

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private escapeRegex(value: string): string {
    return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  async create(
    email: string,
    password: string,
    firstName: string,
    lastName: string,
    role: UserRole = UserRole.PARENT,
    options?: {
      cvUrl?: string;
      approvalStatus?: TeacherApprovalStatus;
      rejectionReason?: string;
      submittedAt?: Date;
    },
  ): Promise<UserDocument> {
    const hashedPassword = await bcrypt.hash(password, 10);
    const normalizedEmail = this.normalizeEmail(email);
    const user = new this.userModel({
      email: normalizedEmail,
      password: hashedPassword,
      firstName,
      lastName,
      role,
      cvUrl: options?.cvUrl,
      approvalStatus: options?.approvalStatus,
      rejectionReason: options?.rejectionReason,
      submittedAt: options?.submittedAt,
    });
    return user.save();
  }

  async upsertByEmail(
    email: string,
    password: string,
    firstName: string,
    lastName: string,
    role: UserRole,
  ): Promise<UserDocument | null> {
    const normalizedEmail = this.normalizeEmail(email);
    const hashedPassword = await bcrypt.hash(password, 10);
    return this.userModel
      .findOneAndUpdate(
        { email: normalizedEmail },
        {
          email: normalizedEmail,
          password: hashedPassword,
          firstName,
          lastName,
          role,
          isActive: true,
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .exec();
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    const normalizedEmail = this.normalizeEmail(email);
    const escaped = this.escapeRegex(normalizedEmail);
    return this.userModel
      .findOne({ email: new RegExp(`^${escaped}$`, "i") })
      .exec();
  }

  async findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).exec();
  }

  /** Détecte un hash bcrypt (les anciens comptes peuvent avoir un mot de passe en clair). */
  isBcryptHash(stored: string | undefined): boolean {
    if (typeof stored !== "string" || stored.length < 7) return false;
    // Ex. $2b$10$... ou $2a$12$...
    return /^\$2[aby]\$\d{2}\$/.test(stored);
  }

  async validatePassword(plain: string, stored: string): Promise<boolean> {
    if (this.isBcryptHash(stored)) {
      return bcrypt.compare(plain, stored);
    }
    // Ancien format : mot de passe stocké en clair (données de dev / import)
    return plain === stored;
  }

  async upgradePasswordToBcrypt(
    userId: string,
    plainPassword: string,
  ): Promise<void> {
    const hashed = await bcrypt.hash(plainPassword, 10);
    await this.userModel.findByIdAndUpdate(userId, { password: hashed }).exec();
  }
}
