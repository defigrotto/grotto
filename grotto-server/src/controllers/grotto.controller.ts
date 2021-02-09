import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GrottoService } from 'src/services/grotto.service';
import { Response, ResponseUtils } from 'src/utils/response.utils';

@ApiTags('grotto-controller')
@Controller('grotto')
export class GrottoController {

    constructor(
        private grottoService: GrottoService
    ) {

    }

    @Get('get-pool-details/:poolId')
    async getPoolDetails(@Param("poolId") poolId: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getPoolDetails(poolId));
    }

    @Get('all-pools')
    async getAllPoolDetails(): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getAllPoolDetails());
    }

    @Get('pools-by-owner/:owner')
    async getPoolsByOwner(@Param("owner") owner: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getPoolDetailsByOwner(owner));
    }    
}
