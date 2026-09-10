import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './message.entity';
import { CreateMessageDto } from '@app/shared';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message)
    private messagesRepository: Repository<Message>,
  ) {}

  async create(senderId: string, createMessageDto: CreateMessageDto): Promise<Message> {
    const message = this.messagesRepository.create({
      ...createMessageDto,
      senderId,
    });
    return this.messagesRepository.save(message);
  }

  async findByJobId(jobId: string): Promise<Message[]> {
    return this.messagesRepository.find({
      where: { jobId },
      relations: ['sender'],
      order: { createdAt: 'ASC' },
    });
  }
}
