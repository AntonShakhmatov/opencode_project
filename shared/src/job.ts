import { GeoJsonPoint, GeoLocation } from './common';

export interface Job {
  id: string;
  clientId: string;
  handymanId?: string;
  serviceType: string;
  description: string;
  status: JobStatus;
  location: GeoJsonPoint;
  address?: string;
  estimatedPrice?: number;
  finalPrice?: number;
  scheduledAt?: Date;
  startedAt?: Date;
  completedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export type JobStatus =
  | 'pending'
  | 'searching'
  | 'matched'
  | 'accepted'
  | 'en_route'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export interface CreateJobDto {
  serviceType: string;
  description: string;
  location: GeoLocation;
  address?: string;
  scheduledAt?: Date;
}

export interface UpdateJobDto {
  status?: JobStatus;
  handymanId?: string;
  estimatedPrice?: number;
  finalPrice?: number;
}

export interface JobWithUser extends Job {
  client?: {
    id: string;
    name: string;
    avatar?: string;
    rating?: number;
  };
  handyman?: {
    id: string;
    name: string;
    avatar?: string;
    rating?: number;
  };
}

export interface NearbyHandyman {
  userId: string;
  name: string;
  avatar?: string;
  rating?: number;
  skills?: string[];
  location: GeoJsonPoint;
  distanceInMeters: number;
}
