import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { AssignmentsController } from "./assignments.controller";
import { KidAssignmentsController } from "./kid-assignments.controller";
import { AssignmentsService } from "./assignments.service";
import {
  Assignment,
  AssignmentSchema,
} from "../notifications/schemas/assignment.schema";
import {
  AssignmentSubmission,
  AssignmentSubmissionSchema,
} from "./schemas/assignment-submission.schema";
import { ClassesModule } from "../classes/classes.module";
import { NotificationsModule } from "../notifications/notifications.module";
import { Kid, KidSchema } from "../kids/schemas/kid.schema";
import { RewardsModule } from "../rewards/rewards.module";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Assignment.name, schema: AssignmentSchema },
      { name: AssignmentSubmission.name, schema: AssignmentSubmissionSchema },
      { name: Kid.name, schema: KidSchema },
    ]),
    ClassesModule,
    NotificationsModule,
    RewardsModule,
  ],
  controllers: [AssignmentsController, KidAssignmentsController],
  providers: [AssignmentsService],
  exports: [AssignmentsService],
})
export class AssignmentsModule {}
