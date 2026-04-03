import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Kid, KidDocument } from './schemas/kid.schema';
import { CreateKidDto } from './dto/create-kid.dto';
import { UpdateKidDto } from './dto/update-kid.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class KidsService {
  constructor(@InjectModel(Kid.name) private kidModel: Model<KidDocument>) {}

  async findAllByParentId(parentId: string): Promise<KidDocument[]> {
    return this.kidModel
      .find({ parentId: new Types.ObjectId(parentId) })
      .exec();
  }

  async findOneById(kidId: string): Promise<KidDocument | null> {
    return this.kidModel.findById(kidId).exec();
  }

  async checkOwnership(kidId: string, parentId: string): Promise<boolean> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      return false;
    }
    return kid.parentId.toString() === parentId;
  }

  async create(
    createKidDto: CreateKidDto,
    parentId: string,
  ): Promise<KidDocument> {
    const kidData = {
      ...createKidDto,
      parentId: new Types.ObjectId(parentId),
      dateOfBirth: createKidDto.dateOfBirth
        ? new Date(createKidDto.dateOfBirth)
        : undefined,
    };

    const kid = new this.kidModel(kidData);
    return kid.save();
  }

  async update(
    kidId: string,
    updateKidDto: UpdateKidDto,
    parentId: string,
  ): Promise<KidDocument> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException('Kid not found');
    }

    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        'You do not have permission to update this kid',
      );
    }

    const updateData: any = { ...updateKidDto };
    if (updateKidDto.dateOfBirth) {
      updateData.dateOfBirth = new Date(updateKidDto.dateOfBirth);
    }

    return this.kidModel
      .findByIdAndUpdate(kidId, updateData, { new: true })
      .exec();
  }

  async remove(kidId: string, parentId: string): Promise<void> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException('Kid not found');
    }

    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        'You do not have permission to delete this kid',
      );
    }

    await this.kidModel.findByIdAndDelete(kidId).exec();
  }

  async setPin(kidId: string, pin: string, parentId: string): Promise<void> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException('Kid not found');
    }

    if (kid.parentId.toString() !== parentId) {
      throw new ForbiddenException(
        'You do not have permission to set PIN for this kid',
      );
    }

    const hashedPin = await bcrypt.hash(pin, 10);
    await this.kidModel
      .findByIdAndUpdate(kidId, {
        hashedPin,
        failedPinAttempts: 0,
        pinLockedUntil: null,
      })
      .exec();
  }

  async verifyPin(kidId: string, pin: string): Promise<boolean> {
    const kid = await this.findOneById(kidId);
    if (!kid) {
      throw new NotFoundException('Kid not found');
    }

    if (!kid.hashedPin) {
      throw new BadRequestException('PIN not set for this kid');
    }

    // Check if PIN is locked
    if (kid.pinLockedUntil && new Date() < kid.pinLockedUntil) {
      const minutesRemaining = Math.ceil(
        (kid.pinLockedUntil.getTime() - new Date().getTime()) / 60000,
      );
      throw new BadRequestException(
        `PIN is locked. Try again in ${minutesRemaining} minute(s)`,
      );
    }

    // Verify PIN
    const isPinValid = await bcrypt.compare(pin, kid.hashedPin);

    if (isPinValid) {
      // Reset failed attempts on successful verification
      await this.kidModel
        .findByIdAndUpdate(kidId, {
          failedPinAttempts: 0,
          pinLockedUntil: null,
        })
        .exec();
      return true;
    } else {
      // Increment failed attempts
      const newFailedAttempts = (kid.failedPinAttempts || 0) + 1;
      const updateData: any = {
        failedPinAttempts: newFailedAttempts,
      };

      // Lock after 5 failed attempts for 10 minutes
      if (newFailedAttempts >= 5) {
        const lockUntil = new Date();
        lockUntil.setMinutes(lockUntil.getMinutes() + 10);
        updateData.pinLockedUntil = lockUntil;
      }

      await this.kidModel.findByIdAndUpdate(kidId, updateData).exec();
      return false;
    }
  }

  async generateKidToken(kidId: string): Promise<string> {
    // This method will be used by the controller to generate kidToken
    // The actual JWT signing will be done in the controller using JwtService
    return kidId;
  }
}
