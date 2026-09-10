export interface Review {
  id: string;
  jobId: string;
  reviewerId: string;
  revieweeId: string;
  rating: number;
  comment?: string;
  createdAt: Date;
}

export interface CreateReviewDto {
  jobId: string;
  revieweeId: string;
  rating: number;
  comment?: string;
}

export interface ReviewWithUser extends Review {
  reviewer?: {
    id: string;
    name: string;
    avatar?: string;
  };
  reviewee?: {
    id: string;
    name: string;
    avatar?: string;
  };
}
