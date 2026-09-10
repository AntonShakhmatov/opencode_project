import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MessagesService } from '../messages/messages.service';
import { LocationService } from '../location/location.service';
import { JobsService } from '../jobs/jobs.service';
import { GeoLocation } from '@app/shared';

@WebSocketGateway({
  cors: {
    origin: ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true,
  },
})
export class ChatGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSockets = new Map<string, string>();
  private jobSockets = new Map<string, Set<string>>();

  constructor(
    private messagesService: MessagesService,
    private locationService: LocationService,
    @Inject(forwardRef(() => JobsService))
    private jobsService: JobsService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  afterInit(server: Server) {
    const secret = this.configService.get<string>(
      'JWT_SECRET',
      'handyman-test-secret-key-2024',
    );
    server.use((socket, next) => {
      const token = socket.handshake.auth?.token as string | undefined;
      if (!token) {
        return next(new Error('unauthorized'));
      }
      try {
        const payload = this.jwtService.verify(token, { secret });
        if (payload.type === 'refresh' || !payload.sub) {
          return next(new Error('unauthorized'));
        }
        socket.data.userId = payload.sub;
        socket.data.role = payload.role;
        next();
      } catch {
        next(new Error('unauthorized'));
      }
    });
  }

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id} (user ${client.data.userId})`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    
    for (const [userId, socketId] of this.userSockets.entries()) {
      if (socketId === client.id) {
        this.userSockets.delete(userId);
        break;
      }
    }
    
    for (const [jobId, sockets] of this.jobSockets.entries()) {
      sockets.delete(client.id);
      if (sockets.size === 0) {
        this.jobSockets.delete(jobId);
      }
    }
  }

  @SubscribeMessage('register')
  handleRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userId: string },
  ) {
    this.userSockets.set(data.userId, client.id);
    return { event: 'registered', data: { userId: data.userId } };
  }

  @SubscribeMessage('joinJob')
  handleJoinJob(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { jobId: string; userId: string },
  ) {
    client.join(`job:${data.jobId}`);
    
    if (!this.jobSockets.has(data.jobId)) {
      this.jobSockets.set(data.jobId, new Set());
    }
    this.jobSockets.get(data.jobId).add(client.id);
    
    return { event: 'joinedJob', data: { jobId: data.jobId } };
  }

  @SubscribeMessage('leaveJob')
  handleLeaveJob(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { jobId: string },
  ) {
    client.leave(`job:${data.jobId}`);
    this.jobSockets.get(data.jobId)?.delete(client.id);
    return { event: 'leftJob', data: { jobId: data.jobId } };
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { jobId: string; senderId: string; content: string },
  ) {
    const message = await this.messagesService.create(data.senderId, {
      jobId: data.jobId,
      content: data.content,
    });

    this.server.to(`job:${data.jobId}`).emit('newMessage', {
      id: message.id,
      jobId: message.jobId,
      senderId: message.senderId,
      content: message.content,
      createdAt: message.createdAt,
    });

    return { event: 'messageSent', data: { messageId: message.id } };
  }

  @SubscribeMessage('updateLocation')
  async handleUpdateLocation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userId: string; location: GeoLocation },
  ) {
    await this.locationService.updateLocation(data.userId, data.location);
    
    this.server.emit('locationUpdated', {
      userId: data.userId,
      location: data.location,
    });

    return { event: 'locationUpdated', data: { userId: data.userId } };
  }

  @SubscribeMessage('updateJobStatus')
  async handleUpdateJobStatus(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { jobId: string; status: string; userId: string },
  ) {
    const job = await this.jobsService.update(data.jobId, {
      status: data.status as any,
    });

    this.server.to(`job:${data.jobId}`).emit('jobStatusUpdated', {
      jobId: job.id,
      status: job.status,
      updatedAt: job.updatedAt,
    });

    return { event: 'statusUpdated', data: { jobId: job.id } };
  }

  @SubscribeMessage('handymanFound')
  handleHandymanFound(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { jobId: string; handymanId: string },
  ) {
    this.server.to(`job:${data.jobId}`).emit('handymanFound', {
      jobId: data.jobId,
      handymanId: data.handymanId,
    });

    return { event: 'handymanNotified', data: { jobId: data.jobId } };
  }

  emitToUser(userId: string, event: string, data: any) {
    const socketId = this.userSockets.get(userId);
    if (socketId) {
      this.server.to(socketId).emit(event, data);
    }
  }

  emitToJob(jobId: string, event: string, data: any) {
    this.server.to(`job:${jobId}`).emit(event, data);
  }
}
