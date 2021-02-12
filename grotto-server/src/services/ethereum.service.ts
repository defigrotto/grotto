import { Injectable, Logger } from '@nestjs/common';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const path = require('path')
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require('fs')
import { ethers } from 'ethers';
import { PoolDetails } from 'src/models/pool.details';
import { VoteDetails } from 'src/models/vote.details';

@Injectable()
export class EthereumService {
    provider: ethers.providers.JsonRpcProvider;
    grottoAbi;
    grottoAddress: string;
    grottoContract: ethers.Contract;

    governanceAddress: string;
    governanceContract: ethers.Contract;
    governanceAbi;

    private readonly logger = new Logger(EthereumService.name);

    constructor() {
        this.provider = new ethers.providers.JsonRpcProvider(process.env.WEB3_PROVIDER);
        this.grottoAddress = process.env.GROTTO_ADDRESS;
        this.grottoAbi = JSON.parse(fs.readFileSync(path.resolve('src/abis/grotto.abi.json'), 'utf8')).abi;
        this.logger.debug(this.grottoAddress);
        this.grottoContract = new ethers.Contract(this.grottoAddress, this.grottoAbi, this.provider);

        this.governanceAddress = process.env.GOVERNANCE_ADDRESS;
        this.governanceAbi = JSON.parse(fs.readFileSync(path.resolve('src/abis/governance.abi.json'), 'utf8')).abi;
        this.governanceContract = new ethers.Contract(this.governanceAddress, this.governanceAbi, this.provider);
    }

    getVotingDetails(voteId: string): Promise<VoteDetails> {
        return new Promise(async (resolve, reject) => {
            try {
                const vd = await this.governanceContract.votingDetails(voteId);
                console.log(vd);

                const voteDetails: VoteDetails = {
                    voteId: vd[0],
                    isInProgress: vd[1],
                    voters: vd[2],
                    yesVotes: vd[3].toNumber(),
                    noVotes: vd[4].toNumber(),
                    votes: vd[5].toNumber(),
                    contractAddress: this.governanceAddress,
                    proposedValue: vd[6].toNumber(),
                    proposedGovernor: vd[7],
                    currentValue: await this.getCurrentValue(voteId)
                };

                resolve(voteDetails);
            } catch (error) {
                reject(error);
            }
        });
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

                const pools: any[] = await this.grottoContract.getAllPools();
                const size = pools.length;
                for (let i = 0; i < size; i++) {
                    const pd = pools[i];
                    const poolDetails: PoolDetails = {
                        winner: pd[0],
                        currentPoolSize: pd[1].toNumber(),
                        isInMainPool: pd[2],
                        poolSize: pd[3].toNumber(),
                        poolPrice: +ethers.utils.formatEther(pd[4]),
                        poolCreator: pd[5],
                        isPoolConcluded: pd[6],
                        poolPriceInEther: +ethers.utils.formatEther(pd[7]),
                        poolId: pd[8],
                        contractAddress: this.grottoAddress
                    }
                    allPoolDetails.push(poolDetails);
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

    getCurrentValue(voteId: string): Promise<any> {
        return new Promise(async (resolve, reject) => {
            let retVal;
            
            try {
                switch (voteId) {
                    case 'add_new_governor':
                    case 'remove_governor':
                        retVal = await this.governanceContract.getGovernors();
                        resolve(retVal);
                        break;
                    case 'alter_main_pool_price':
                        retVal = await this.governanceContract.getMainPoolPrice();
                        resolve(ethers.utils.formatEther(retVal));
                        break;
                    case 'alter_main_pool_size':
                        retVal = await this.governanceContract.getMainPoolSize();
                        resolve(retVal.toNumber());
                        break;
                    case 'alter_house_cut':
                        retVal = await this.governanceContract.getHouseCut();
                        resolve(retVal.toNumber());
                        break;
                    case 'alter_house_cut_tokens':
                        retVal = await this.governanceContract.getHouseCutNewTokens();
                        resolve(retVal.toNumber());
                        break;
                    case 'alter_min_price':
                        retVal = await this.governanceContract.getMinimumPoolPrice();
                        resolve(ethers.utils.formatEther(retVal));
                        break;
                    case 'alter_min_size':
                        retVal = await this.governanceContract.getMinimumPoolSize();
                        resolve(retVal.toNumber());
                        break;
                    case 'alter_max_size':
                        retVal = await this.governanceContract.getMaximumPoolSize();
                        resolve(retVal.toNumber());
                        break;
                }
            } catch (error) {
                reject(error);
            }
        });
    }
}