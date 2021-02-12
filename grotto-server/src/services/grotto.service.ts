import { Injectable } from '@nestjs/common';
import { PoolDetails } from 'src/models/pool.details';
import { VoteDetails } from 'src/models/vote.details';
import { EthereumService } from './ethereum.service';

@Injectable()
export class GrottoService {

    constructor(
        private ethereumService: EthereumService
    ) {

    }    

    getCurrentValue(voteId: string, mode: string): Promise<any> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getCurrentValue(voteId, mode));
            } catch (error) {
                reject(error);
            }
        });                
    }

    getVoteDetails(voteId: string, mode: string): Promise<VoteDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getVotingDetails(voteId, mode));
            } catch (error) {
                reject(error);
            }
        });        
    }

    getPoolDetails(poolId: string, mode: string): Promise<PoolDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getPoolDetails(poolId, mode));
            } catch (error) {
                reject(error);
            }
        });
    }

    getPoolDetailsByOwner(owner: string, mode: string): Promise<PoolDetails[]> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getPoolDetailsByOwner(owner, mode));
            } catch (error) {
                reject(error);
            }
        });
    }    

    getAllPoolDetails(mode: string) {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getAllPoolDetails(mode));
            } catch (error) {
                reject(error);
            }
        });        
    }

    getLatestPrice(mode: string) {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getLatestPrice(mode));
            } catch (error) {
                reject(error);
            }
        });        
    }    
}
