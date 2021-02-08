import { Injectable, Logger } from '@nestjs/common';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const path = require('path')
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require('fs')
import { ethers } from 'ethers';
import { PoolDetails } from 'src/models/pool.details';
import { abi } from '../abis/grotto.abi';

@Injectable()
export class EthereumService {
    provider: ethers.providers.JsonRpcProvider;
    grottoAbi = abi.abi;
    grottoAddress: string;
    grottoContract: ethers.Contract;

    private readonly logger = new Logger(EthereumService.name);

    constructor() {
        this.provider = new ethers.providers.JsonRpcProvider(process.env.WEB3_PROVIDER);
        this.grottoAddress = process.env.GROTTO_ADDRESS;
        this.logger.debug(this.grottoAddress);
        this.grottoContract = new ethers.Contract(this.grottoAddress, this.grottoAbi, this.provider);
    }

    getPoolDetails(poolId: string): Promise<PoolDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                const pd = await this.grottoContract.getPoolDetails(poolId);
                const poolDetails: PoolDetails = {
                    winner: pd[0],
                    currentPoolSize: pd[1],
                    isInMainPool: pd[2],
                    poolSize: pd[3],
                    poolPrice: pd[4],
                    poolCreator: pd[5],
                    isPoolConcluded: pd[6]
                }

                resolve(poolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getAllPoolDetails(): Promise<PoolDetails[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const allPoolDetails: PoolDetails[] = [];

                const pools = await this.grottoContract.getAllPools();
                for (let i = 0; i < 10; i++) {
                    allPoolDetails.push(await this.getPoolDetails(pools[i]));
                }

                resolve(allPoolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getPoolDetailsByOwner(owner: string): Promise<PoolDetails[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const allPoolDetails: PoolDetails[] = [];

                const pools = await this.grottoContract.getPoolsByOwner(owner);
                for (let i = 0; i < pools.length; i++) {
                    allPoolDetails.push(await this.getPoolDetails(pools[i]));
                }

                resolve(allPoolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }    
}