import { Controller, Get, Post, Body, Param, Request } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from '@app/shared';

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  create(@Request() req, @Body() createReviewDto: CreateReviewDto) {
    return this.reviewsService.create(req.user.id, createReviewDto);
  }

  @Get()
  findAll() {
    return this.reviewsService.findAll();
  }

  @Get('job/:jobId')
  findByJobId(@Param('jobId') jobId: string) {
    return this.reviewsService.findByJobId(jobId);
  }

  @Get('user/:userId')
  findByUserId(@Param('userId') userId: string) {
    return this.reviewsService.findByRevieweeId(userId);
  }
}
