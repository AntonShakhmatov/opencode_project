import { GeoJsonPoint } from './common';

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  role: UserRole;
  avatar?: string;
  rating?: number;
  reviewCount?: number;
  skills?: string[];
  location?: GeoJsonPoint;
  isAvailable?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type UserRole = 'client' | 'handyman' | 'admin';

export interface CreateUserDto {
  email: string;
  name: string;
  password: string;
  phone?: string;
  role: UserRole;
  skills?: string[];
}

export interface UpdateUserDto {
  email?: string;
  name?: string;
  phone?: string;
  avatar?: string;
  rating?: number;
  reviewCount?: number;
  skills?: string[];
  location?: GeoJsonPoint;
  isAvailable?: boolean;
}

export interface UserProfile {
  id: string;
  email: string;
  name: string;
  phone?: string;
  avatar?: string;
  role: UserRole;
  rating?: number;
  reviewCount?: number;
  skills?: string[];
  isAvailable?: boolean;
}
