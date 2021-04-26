import { Injectable, Logger } from '@nestjs/common';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const path = require('path')
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require('fs')
import { ethers } from 'ethers';
import { Mode } from 'src/models/mode';
import { PoolDetails } from 'src/models/pool.details';
import { VoteDetails } from 'src/models/vote.details';

@Injectable()
export class EthereumService {
    provider: ethers.providers.JsonRpcProvider;
    grottoAbi;
    grottoAddress: Mode = {
        test: "",
        prod: ""
    };

    grottoContract: ethers.Contract;

    governanceAddress: Mode = {
        test: "",
        prod: ""
    };
    governanceContract: ethers.Contract;
    governanceAbi;

    webProvider: Mode = {
        test: "",
        prod: ""
    };

    private readonly logger = new Logger(EthereumService.name);

    constructor() {
        this.webProvider.prod = process.env.WEB3_PROVIDER;
        this.webProvider.test = process.env.WEB3_PROVIDER_TEST;

        this.grottoAddress.prod = process.env.GROTTO_ADDRESS;
        this.grottoAddress.test = process.env.GROTTO_ADDRESS_TEST;

        this.governanceAddress.prod = process.env.GOVERNANCE_ADDRESS;
        this.governanceAddress.test = process.env.GOVERNANCE_ADDRESS_TEST;

        this.grottoAbi = JSON.parse(fs.readFileSync(path.resolve('src/abis/grotto.abi.json'), 'utf8')).abi;
        this.governanceAbi = JSON.parse(fs.readFileSync(path.resolve('src/abis/governance.abi.json'), 'utf8')).abi;
        this.init('test');

        // every house
        setInterval(() => {
            this.processShares();
        }, 3600000);
    }

    init(mode: string) {
        if (mode === 'prod') {
            this.provider = new ethers.providers.JsonRpcProvider(this.webProvider.prod);
            this.grottoContract = new ethers.Contract(this.grottoAddress.prod, this.grottoAbi, this.provider);
            this.governanceContract = new ethers.Contract(this.governanceAddress.prod, this.governanceAbi, this.provider);
        } else {
            this.provider = new ethers.providers.JsonRpcProvider(this.webProvider.test);
            this.grottoContract = new ethers.Contract(this.grottoAddress.test, this.grottoAbi, this.provider);
            this.governanceContract = new ethers.Contract(this.governanceAddress.test, this.governanceAbi, this.provider);
        }
    }


    async processShares() {
        // TODO: Change to prod
        this.init('demo');
        let privateKey = process.env.HOUSE_PRIVATE_KEY;
        let wallet = new ethers.Wallet(privateKey, this.provider);
        let contractWithSigner = this.grottoContract.connect(wallet);
        let tx = await contractWithSigner.processShares();
        console.log(`Processing Shares: ${tx.hash}`);
        await tx.wait();
        return;
    }

    getTotalStaked(mode: string): Promise<number> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                const balance = await this.grottoContract.getStakingMasterBalance();
                resolve(+ethers.utils.formatEther(balance));
            } catch (error) {
                reject(error);
            }
        });
    }

    getCompletedStakes(mode: string): Promise<number[]> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                let cs = await this.grottoContract.getCompletedStakePools();
                cs = cs.map((x) => {
                    return x.toNumber();
                })

                resolve(cs);
            } catch (error) {
                reject(error);
            }
        });
    }

    getStakeRewards(address: string, poolIndex: number, mode: string): Promise<any> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                let stakeInPool = await this.grottoContract.getStakeInPool(address, poolIndex);
                stakeInPool = +ethers.utils.formatEther(stakeInPool);
                let stakeReward = await this.grottoContract.getRewardPerGrotto(poolIndex);
                console.log(stakeReward);
                stakeReward = +ethers.utils.formatEther(stakeReward);
                resolve ({"stakeInPool": stakeInPool, "stakeReward": stakeReward});
            } catch (error) {
                reject(error);
            }
        });
    }    

    getStakers(mode: string): Promise<any> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                const stakers = await this.grottoContract.getStakers();
                resolve(stakers);
            } catch (error) {
                reject(error);
            }
        });
    }

    getPendingGrottoMintingPayments(): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const balance = await this.grottoContract.getPendingGrottoMintingPayments();
                resolve(balance.toString());
            } catch (error) {
                reject(error);
            }
        });
    }

    getGrottoTokenBalance(address: string, mode: string): Promise<number> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                const balance = await this.grottoContract.getGrottoTokenBalance(address);
                resolve(+ethers.utils.formatEther(balance));
            } catch (error) {
                reject(error);
            }
        });
    }

    getGrottoTokenAddress(mode: string): string {
        return mode === 'prod' ? process.env.GROTTO_TOKEN_ADDRESS : process.env.GROTTO_TOKEN_ADDRESS_TEST;
    }

    getStake(address: string, mode: string): Promise<number> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                const stake = await this.grottoContract.getStake(address);
                resolve(+ethers.utils.formatEther(stake));
            } catch (error) {
                reject(error);
            }
        });
    }

    getVotingDetails(voteId: string, mode: string): Promise<VoteDetails> {
        this.init(mode);
        const contractAddress = mode === 'prod' ? this.governanceAddress.prod : this.governanceAddress.test;
        return new Promise(async (resolve, reject) => {
            try {
                const vd = await this.governanceContract.votingDetails(voteId);
                const proposedShares = {
                    house: vd[8][0].toNumber(),
                    govs: vd[8][1].toNumber(),
                    stakers: vd[8][2].toNumber(),
                }

                const voteDetails: VoteDetails = {
                    voteId: vd[0],
                    isInProgress: vd[1],
                    voters: vd[2],
                    yesVotes: vd[3].toNumber(),
                    noVotes: vd[4].toNumber(),
                    votes: vd[5].toNumber(),
                    contractAddress: contractAddress,
                    proposedValue: vd[6].toNumber(),
                    proposedGovernor: vd[7],
                    proposedShares: proposedShares,
                    currentValue: await this.getCurrentValue(voteId, mode)
                };
                resolve(voteDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getPoolDetails(poolId: string, mode: string): Promise<PoolDetails> {
        this.init(mode);
        const contractAddress = mode === 'prod' ? this.grottoAddress.prod : this.grottoAddress.test;

        return new Promise(async (resolve, reject) => {
            try {
                const pd = await this.grottoContract.getPoolDetails(poolId);
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
                    contractAddress: contractAddress
                }

                this.logger.debug(poolDetails);
                resolve(poolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getAllPoolDetails(mode: string): Promise<PoolDetails[]> {
        this.init(mode);
        const contractAddress = mode === 'prod' ? this.grottoAddress.prod : this.grottoAddress.test;

        return new Promise(async (resolve, reject) => {
            try {
                const allPoolDetails: PoolDetails[] = [];

                const pools: any[] = await this.grottoContract.getAllPools();
                const size = pools.length;
                if (size <= 0) {
                    const poolDetails: PoolDetails = {
                        winner: "",
                        currentPoolSize: 0,
                        isInMainPool: false,
                        poolSize: 0,
                        poolPrice: 0,
                        poolCreator: "",
                        isPoolConcluded: false,
                        poolPriceInEther: 0,
                        poolId: "",
                        contractAddress: contractAddress
                    }
                    allPoolDetails.push(poolDetails);
                } else {
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
                            contractAddress: contractAddress
                        }
                        allPoolDetails.push(poolDetails);
                    }
                }

                resolve(allPoolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getLatestPrice(mode: string): Promise<number> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                const price = await this.grottoContract.getLatestPrice();
                resolve(price.toNumber());
            } catch (error) {
                reject(error);
            }
        });
    }

    getPoolDetailsByOwner(owner: string, mode: string): Promise<PoolDetails[]> {
        this.init(mode);
        return new Promise(async (resolve, reject) => {
            try {
                const allPoolDetails: PoolDetails[] = [];

                const pools = await this.grottoContract.getPoolsByOwner(owner);
                for (let i = 0; i < pools.length; i++) {
                    allPoolDetails.push(await this.getPoolDetails(pools[i], mode));
                }

                resolve(allPoolDetails);
            } catch (error) {
                reject(error);
            }
        });
    }

    getCurrentValue(voteId: string, mode: string): Promise<any> {
        this.init(mode);
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
                    case 'alter_min_gov_grotto':
                        retVal = await this.governanceContract.getMinGrottoGovernor();
                        resolve(ethers.utils.formatEther(retVal));
                        break;
                    case 'alter_min_value_shares':
                        retVal = await this.governanceContract.getMinValueForSharesProcessing();
                        resolve(ethers.utils.formatEther(retVal));
                        break;
                    case 'alter_house_cut_shares':
                        retVal = await this.governanceContract.getHouseCutShares();
                        const result = {
                            house: retVal[0].toNumber(),
                            govs: retVal[1].toNumber(),
                            stakers: retVal[2].toNumber(),
                        }
                        resolve(result);
                        break;
                }
            } catch (error) {
                reject(error);
            }
        });
    }
}