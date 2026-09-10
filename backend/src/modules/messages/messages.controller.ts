import { Controller, Get, Post, Body, Param, Query, Request } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { CreateMessageDto } from '@app/shared';

@Controller('messages')
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Post()
  create(@Request() req, @Body() createMessageDto: CreateMessageDto) {
    return this.messagesService.create(req.user.id, createMessageDto);
  }

  @Get('job/:jobId')
  findByJobId(@Param('jobId') jobId: string) {
    return this.messagesService.findByJobId(jobId);
  }
}
