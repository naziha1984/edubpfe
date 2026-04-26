import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { StudentNote, StudentNoteSchema } from "./schemas/student-note.schema";
import {
  StudentProgressEntry,
  StudentProgressEntrySchema,
} from "./schemas/student-progress-entry.schema";
import { StudentTrackingController } from "./student-tracking.controller";
import { StudentTrackingService } from "./student-tracking.service";
import { Kid, KidSchema } from "../kids/schemas/kid.schema";
import {
  ClassMembership,
  ClassMembershipSchema,
} from "../classes/schemas/class-membership.schema";
import { Class, ClassSchema } from "../classes/schemas/class.schema";
import {
  KidTeacherSelection,
  KidTeacherSelectionSchema,
} from "../kids/schemas/kid-teacher-selection.schema";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StudentNote.name, schema: StudentNoteSchema },
      { name: StudentProgressEntry.name, schema: StudentProgressEntrySchema },
      { name: Kid.name, schema: KidSchema },
      { name: ClassMembership.name, schema: ClassMembershipSchema },
      { name: Class.name, schema: ClassSchema },
      { name: KidTeacherSelection.name, schema: KidTeacherSelectionSchema },
    ]),
  ],
  controllers: [StudentTrackingController],
  providers: [StudentTrackingService],
  exports: [StudentTrackingService],
})
export class StudentTrackingModule {}
