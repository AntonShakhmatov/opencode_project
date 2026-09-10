export interface Message {
  id: string;
  jobId: string;
  senderId: string;
  content: string;
  createdAt: Date;
}

export interface CreateMessageDto {
  jobId: string;
  content: string;
}

export interface MessageWithUser extends Message {
  sender?: {
    id: string;
    name: string;
    avatar?: string;
  };
}
