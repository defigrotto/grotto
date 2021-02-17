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

    @Get('get-vote-details/:voteId/:mode')
    async getVoteDetails(@Param("voteId") voteId: string, @Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getVoteDetails(voteId, mode));
    }
    
    @Get('get-grotto-token-address/:mode')
    async getGrottoTokenAddress(@Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getGrottoTokenAddress(mode));
    }
    
    @Get('get-grotto-token-balance/:address/:mode')
    async getGrottoTokenBalance(@Param("address") address: string, @Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getGrottoTokenBalance(address, mode));
    }
    
    @Get('get-stake/:address/:mode')
    async getStake(@Param("address") address: string, @Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getStake(address, mode));
    }    

    @Get('get-stakers/:mode')
    async getStakers(@Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getStakers(mode));
    }    
    
    @Get('get-total-staked/:mode')
    async getTotalStaked(@Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getTotalStaked(mode));
    }        

    @Get('get-current-value/:voteId/:mode')
    async getCurrentValue(@Param("voteId") voteId: string, @Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getCurrentValue(voteId, mode));
    }    

    @Get('get-pool-details/:poolId/:mode')
    async getPoolDetails(@Param("poolId") poolId: string, @Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getPoolDetails(poolId, mode));
    }

    @Get('all-pools/:mode')
    async getAllPoolDetails(@Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getAllPoolDetails(mode));
    }

    @Get('get-latest-price/:mode')
    async getLatestPrice(@Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getLatestPrice(mode));
    }    

    @Get('pools-by-owner/:owner/:mode')
    async getPoolsByOwner(@Param("owner") owner: string, @Param("mode") mode: string): Promise<Response> {
        return ResponseUtils.getSuccessResponse(await this.grottoService.getPoolDetailsByOwner(owner, mode));
    }    
}
