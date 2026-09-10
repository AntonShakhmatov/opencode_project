import { Module, forwardRef } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { MessagesModule } from '../messages/messages.module';
import { LocationModule } from '../location/location.module';
import { JobsModule } from '../jobs/jobs.module';

@Module({
  imports: [MessagesModule, LocationModule, forwardRef(() => JobsModule)],
  providers: [ChatGateway],
  exports: [ChatGateway],
})
export class ChatModule {}