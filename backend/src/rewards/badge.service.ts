import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { Badge, BadgeDocument, BadgeType } from "./schemas/badge.schema";

@Injectable()
export class BadgeService {
  constructor(
    @InjectModel(Badge.name) private badgeModel: Model<BadgeDocument>,
  ) {}

  async createOrUpdate(badgeData: {
    type: BadgeType;
    name: string;
    description?: string;
    icon?: string;
  }): Promise<BadgeDocument> {
    return this.badgeModel.findOneAndUpdate(
      { type: badgeData.type },
      badgeData,
      { upsert: true, new: true },
    );
  }

  async findAll(): Promise<BadgeDocument[]> {
    return this.badgeModel.find().exec();
  }
}
