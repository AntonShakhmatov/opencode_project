import { Controller, Put, Body, Param, Get, Query } from '@nestjs/common';
import { LocationService } from './location.service';
import { GeoLocation } from '@app/shared';

@Controller('location')
export class LocationController {
  constructor(private readonly locationService: LocationService) {}

  @Put(':userId')
  updateLocation(@Param('userId') userId: string, @Body() location: GeoLocation) {
    return this.locationService.updateLocation(userId, location);
  }

  @Get('nearby')
  findNearby(
    @Query('lat') lat: number,
    @Query('lng') lng: number,
    @Query('radius') radius: number,
    @Query('serviceType') serviceType?: string,
  ) {
    return this.locationService.findNearbyHandymen(
      { latitude: lat, longitude: lng },
      radius || 5000,
      serviceType,
    );
  }

  @Get(':userId')
  getLocation(@Param('userId') userId: string) {
    return this.locationService.getHandymanLocation(userId);
  }
}
