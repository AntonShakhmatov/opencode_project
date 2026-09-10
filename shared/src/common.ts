export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface PaginationDto {
  page?: number;
  limit?: number;
}

export interface GeoLocation {
  latitude: number;
  longitude: number;
}

export interface GeoJsonPoint {
  type: 'Point';
  coordinates: [number, number];
}
