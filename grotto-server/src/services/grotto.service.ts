import { Injectable } from '@nestjs/common';
import { resolve } from 'path';
import { PoolDetails } from 'src/models/pool.details';
import { VoteDetails } from 'src/models/vote.details';
import { EthereumService } from './ethereum.service';

@Injectable()
export class GrottoService {
    constructor(
        private ethereumService: EthereumService
    ) {

    }    

    getTotalStaked(mode: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const balance = await this.ethereumService.getTotalStaked(mode);
                resolve(balance);
            } catch (error) {
                reject(error);
            }
        });                        
    }

    getGrottoTokenBalance(address: string, mode: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getGrottoTokenBalance(address, mode));
            } catch (error) {
                reject(error);
            }
        });                        
    }

    getStakers(mode: string): Promise<any> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getStakers(mode));
            } catch (error) {
                reject(error);
            }
        });                        
    }    

    getStake(address: string, mode: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await this.ethereumService.getStake(address, mode));
            } catch (error) {
                reject(error);
            }
        });                        
    }    

    getGrottoTokenAddress(mode: string): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const tokenAddress = (mode === 'prod') ? process.env.GROTTO_TOKEN_ADDRESS: process.env.GROTTO_TOKEN_ADDRESS_TEST;
                resolve(tokenAddress);
            } catch (error) {
                reject(error);
            }
        });                        
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
