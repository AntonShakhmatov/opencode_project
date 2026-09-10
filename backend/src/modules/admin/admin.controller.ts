import { Controller, Get, Query } from '@nestjs/common';
import { AdminService } from './admin.service';
import { Roles } from '../../decorators/roles.decorator';

@Controller('admin')
@Roles('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  getStats() {
    return this.adminService.getDashboardStats();
  }

  @Get('jobs/recent')
  getRecentJobs(@Query('limit') limit: number) {
    return this.adminService.getRecentJobs(limit || 10);
  }
}
