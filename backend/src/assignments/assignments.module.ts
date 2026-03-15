import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AssignmentsController } from './assignments.controller';
import { KidAssignmentsController } from './kid-assignments.controller';
import { AssignmentsService } from './assignments.service';
import { Assignment, AssignmentSchema } from '../notifications/schemas/assignment.schema';
import { AssignmentSubmission, AssignmentSubmissionSchema } from './schemas/assignment-submission.schema';
import { ClassesModule } from '../classes/classes.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Assignment.name, schema: AssignmentSchema },
      { name: AssignmentSubmission.name, schema: AssignmentSubmissionSchema },
    ]),
    ClassesModule,
  ],
  controllers: [AssignmentsController, KidAssignmentsController],
  providers: [AssignmentsService],
  exports: [AssignmentsService],
})
export class AssignmentsModule {}
