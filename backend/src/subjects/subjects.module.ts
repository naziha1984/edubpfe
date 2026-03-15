import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SubjectsController } from './subjects.controller';
import { LessonsController } from './lessons.controller';
import { SubjectsService } from './subjects.service';
import { LessonsService } from './lessons.service';
import { Subject, SubjectSchema } from './schemas/subject.schema';
import { Lesson, LessonSchema } from './schemas/lesson.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Subject.name, schema: SubjectSchema },
      { name: Lesson.name, schema: LessonSchema },
    ]),
  ],
  controllers: [SubjectsController, LessonsController],
  providers: [SubjectsService, LessonsService],
  exports: [SubjectsService, LessonsService],
})
export class SubjectsModule {}
