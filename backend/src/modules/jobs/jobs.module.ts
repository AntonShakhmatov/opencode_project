import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JobsController } from './jobs.controller';
import { JobsService } from './jobs.service';
import { JobMatchingService } from './job-matching.service';
import { Job } from './job.entity';
import { UsersModule } from '../users/users.module';
import { ChatModule } from '../chat/chat.module';
import { LocationModule } from '../location/location.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Job]),
    UsersModule,
    LocationModule,
    forwardRef(() => ChatModule),
  ],
  controllers: [JobsController],
  providers: [JobsService, JobMatchingService],
  exports: [JobsService, JobMatchingService],
})
export class JobsModule {}