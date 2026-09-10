import { Controller, Get, Post, Put, Body, Param, Request } from '@nestjs/common';
import { JobsService } from './jobs.service';
import { CreateJobDto, UpdateJobDto } from '@app/shared';

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Post()
  create(@Request() req, @Body() createJobDto: CreateJobDto) {
    return this.jobsService.create(req.user.id, createJobDto);
  }

  @Get()
  findAll() {
    return this.jobsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.jobsService.findOne(id);
  }

  @Get('client/:clientId')
  findByClientId(@Param('clientId') clientId: string) {
    return this.jobsService.findByClientId(clientId);
  }

  @Get('handyman/:handymanId')
  findByHandymanId(@Param('handymanId') handymanId: string) {
    return this.jobsService.findByHandymanId(handymanId);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateJobDto: UpdateJobDto) {
    return this.jobsService.update(id, updateJobDto);
  }

  @Put(':id/accept')
  acceptJob(@Param('id') id: string, @Request() req) {
    return this.jobsService.acceptJob(id, req.user.id);
  }

  @Put(':id/cancel')
  cancelJob(@Param('id') id: string, @Request() req) {
    return this.jobsService.cancelJob(id, req.user.id);
  }
}
