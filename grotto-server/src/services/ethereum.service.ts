import { Injectable, Logger } from '@nestjs/common';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const path = require('path')
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require('fs')
import { ethers } from 'ethers';
import { PoolDetails } from 'src/models/pool.details';

@Injectable()
export class EthereumService {
    provider: ethers.providers.JsonRpcProvider;
    grottoAbi;
    grottoAddress: string;
    grottoContract: ethers.Contract;

    private readonly logger = new Logger(EthereumService.name);

    constructor() {
        this.provider = new ethers.providers.JsonRpcProvider(process.env.WEB3_PROVIDER);
        this.grottoAddress = process.env.GROTTO_ADDRESS;
        this.grottoAbi = JSON.parse(fs.readFileSync(path.resolve('src/abis/grotto.abi.json'), 'utf8')).abi;
        this.logger.debug(this.grottoAddress);
        this.grottoContract = new ethers.Contract(this.grottoAddress, this.grottoAbi, this.provider);
    }

    getPoolDetails(poolId: string): Promise<PoolDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                const pd = await this.grottoContract.getPoolDetails(poolId);     
                console.log(pd);
                const poolDetails: PoolDetails = {
                    winner: pd[0],
                    currentPoolSize: pd[1].toNumber(),
                    isInMainPool: pd[2],
                    poolSize: pd[3].toNumber(),
                    poolPrice: +ethers.utils.formatEther(pd[4]),
                    poolCreator: pd[5],
                    isPoolConcluded: pd[6],
                    poolPriceInEther: +ethers.utils.formatEther(pd[7]),
                    poolId: poolId,
                    contractAddress: this.grottoAddress
                }

                this.logger.debug(poolDetails);
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

                const pools: string[] = await this.grottoContract.getAllPools();
                const size = pools.length;
                for (let i = 0; i < size; i++) {
                    allPoolDetails.push(await this.getPoolDetails(pools[i]));
                }

                resolve(allPoolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getLatestPrice(): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const price = await this.grottoContract.getLatestPrice();
                resolve(price.toNumber());
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