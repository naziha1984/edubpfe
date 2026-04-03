import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ClassesController } from './classes.controller';
import { JoinController } from './join.controller';
import { ClassesService } from './classes.service';
import { Class, ClassSchema } from './schemas/class.schema';
import {
  ClassMembership,
  ClassMembershipSchema,
} from './schemas/class-membership.schema';
import { KidsModule } from '../kids/kids.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Class.name, schema: ClassSchema },
      { name: ClassMembership.name, schema: ClassMembershipSchema },
    ]),
    KidsModule,
  ],
  controllers: [ClassesController, JoinController],
  providers: [ClassesService],
  exports: [ClassesService],
})
export class ClassesModule {}
