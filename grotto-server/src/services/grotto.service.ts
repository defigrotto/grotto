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

    getVoteDetails(voteId: string): Promise<VoteDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getVotingDetails(voteId));
            } catch (error) {
                reject(error);
            }
        });        
    }

    getPoolDetails(poolId: string): Promise<PoolDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getPoolDetails(poolId));
            } catch (error) {
                reject(error);
            }
        });
    }

    getPoolDetailsByOwner(owner: string): Promise<PoolDetails[]> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getPoolDetailsByOwner(owner));
            } catch (error) {
                reject(error);
            }
        });
    }    

    getAllPoolDetails() {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getAllPoolDetails());
            } catch (error) {
                reject(error);
            }
        });        
    }

    getLatestPrice() {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getLatestPrice());
            } catch (error) {
                reject(error);
            }
        });        
    }    
}
