import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Class, ClassDocument } from "./schemas/class.schema";
import {
  ClassMembership,
  ClassMembershipDocument,
} from "./schemas/class-membership.schema";
import { CreateClassDto } from "./dto/create-class.dto";
import { JoinClassDto } from "./dto/join-class.dto";

@Injectable()
export class ClassesService {
  constructor(
    @InjectModel(Class.name) private classModel: Model<ClassDocument>,
    @InjectModel(ClassMembership.name)
    private classMembershipModel: Model<ClassMembershipDocument>,
  ) {}

  generateClassCode(): string {
    // Générer un code alphanumérique de 6 caractères
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let code = "";
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  async createClass(
    createClassDto: CreateClassDto,
    teacherId: string,
  ): Promise<ClassDocument> {
    let classCode: string;
    let isUnique = false;
    let attempts = 0;
    const maxAttempts = 10;

    // Générer un code de classe unique
    while (!isUnique && attempts < maxAttempts) {
      classCode = this.generateClassCode();
      const existing = await this.classModel.findOne({ classCode }).exec();
      if (!existing) {
        isUnique = true;
      }
      attempts++;
    }

    if (!isUnique) {
      throw new ConflictException("Failed to generate unique class code");
    }

    const newClass = new this.classModel({
      ...createClassDto,
      teacherId: new Types.ObjectId(teacherId),
      classCode,
    });

    return newClass.save();
  }

  async findAllByTeacherId(teacherId: string): Promise<ClassDocument[]> {
    return this.classModel
      .find({ teacherId: new Types.ObjectId(teacherId) })
      .sort({ createdAt: -1 })
      .exec();
  }

  async findOneById(classId: string): Promise<ClassDocument | null> {
    return this.classModel.findById(classId).exec();
  }

  async findByClassCode(classCode: string): Promise<ClassDocument | null> {
    return this.classModel.findOne({ classCode, isActive: true }).exec();
  }

  async checkOwnership(classId: string, teacherId: string): Promise<boolean> {
    const classDoc = await this.findOneById(classId);
    if (!classDoc) {
      return false;
    }
    return classDoc.teacherId.toString() === teacherId;
  }

  async joinClass(
    joinClassDto: JoinClassDto,
  ): Promise<ClassMembershipDocument> {
    // Rechercher la classe par son code
    const classDoc = await this.findByClassCode(joinClassDto.classCode);
    if (!classDoc) {
      throw new NotFoundException("Class not found or inactive");
    }

    // Vérifier que l'enfant existe et appartient bien au parent (contrôle de propriété)
    // Cette vérification est effectuée dans le contrôleur via KidsService

    // Vérifier si l'enfant est déjà membre
    const existingMembership = await this.classMembershipModel
      .findOne({
        classId: classDoc._id,
        kidId: new Types.ObjectId(joinClassDto.kidId),
      })
      .exec();

    if (existingMembership) {
      if (existingMembership.isActive) {
        throw new ConflictException("Kid is already a member of this class");
      } else {
        // Réactiver l'adhésion
        existingMembership.isActive = true;
        return existingMembership.save();
      }
    }

    // Créer une nouvelle adhésion
    const membership = new this.classMembershipModel({
      classId: classDoc._id,
      kidId: new Types.ObjectId(joinClassDto.kidId),
      isActive: true,
    });

    return membership.save();
  }

  async getClassMembers(
    classId: string,
    teacherId: string,
  ): Promise<ClassMembershipDocument[]> {
    // Vérifier la propriété
    const isOwner = await this.checkOwnership(classId, teacherId);
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only view members of your own classes",
      );
    }

    return this.classMembershipModel
      .find({ classId: new Types.ObjectId(classId), isActive: true })
      .populate("kidId", "firstName lastName parentId schoolLevel")
      .exec();
  }

  async getKidClasses(kidId: string): Promise<ClassDocument[]> {
    const memberships = await this.classMembershipModel
      .find({ kidId: new Types.ObjectId(kidId), isActive: true })
      .populate("classId")
      .exec();

    return memberships
      .map((m) => m.classId as unknown as ClassDocument)
      .filter((c) => c && c.isActive);
  }

  async addStudentToClass(
    classId: string,
    kidId: string,
    teacherId: string,
  ): Promise<ClassMembershipDocument> {
    // Vérifier la propriété
    const isOwner = await this.checkOwnership(classId, teacherId);
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only manage students in your own classes",
      );
    }

    // Vérifier si l'enfant est déjà membre
    const existingMembership = await this.classMembershipModel
      .findOne({
        classId: new Types.ObjectId(classId),
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    if (existingMembership) {
      if (existingMembership.isActive) {
        throw new ConflictException(
          "Student is already a member of this class",
        );
      } else {
        // Réactiver l'adhésion
        existingMembership.isActive = true;
        return existingMembership.save();
      }
    }

    // Créer une nouvelle adhésion
    const membership = new this.classMembershipModel({
      classId: new Types.ObjectId(classId),
      kidId: new Types.ObjectId(kidId),
      isActive: true,
    });

    return membership.save();
  }

  async removeStudentFromClass(
    classId: string,
    kidId: string,
    teacherId: string,
  ): Promise<void> {
    // Vérifier la propriété
    const isOwner = await this.checkOwnership(classId, teacherId);
    if (!isOwner) {
      throw new ForbiddenException(
        "You can only manage students in your own classes",
      );
    }

    const membership = await this.classMembershipModel
      .findOne({
        classId: new Types.ObjectId(classId),
        kidId: new Types.ObjectId(kidId),
      })
      .exec();

    if (!membership) {
      throw new NotFoundException("Student is not a member of this class");
    }

    // Désactivation logique
    membership.isActive = false;
    await membership.save();
  }
}
