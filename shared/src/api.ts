export interface LoginDto {
  email: string;
  password: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
}

export interface RefreshTokenDto {
  refreshToken: string;
}

export interface RegisterDto {
  email: string;
  name: string;
  password: string;
  phone?: string;
  role: 'client' | 'handyman';
}
