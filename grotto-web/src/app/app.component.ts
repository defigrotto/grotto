import { Component } from '@angular/core';
import { AppService } from './app.service';
import { first } from 'rxjs/operators';
import { PoolDetails } from './models/pool.model';
import { ethers } from 'ethers';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { VoteDetails } from './models/vote.details';
declare const window: any

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  title = 'grotto-web';
  ethereum: any;

  account = "Connect Metamask";

  poolDetails: PoolDetails[] = [];
  mainPool: PoolDetails[] = [];
  userPool: PoolDetails[] = [];
  completedPool: PoolDetails[] = [];
  myPool: PoolDetails[] = [];

  selectedPool!: PoolDetails;
  selectedIndex = -1;

  noMetaMask = false;
  joinPoolSuccess = false;
  joinPoolFailure = false;
  interval: any;
  startPoolSuccess = false;
  startPoolFailure = false;
  abi = [
    "function processShares()",
    "function enterPool(bytes32)",
    "function startNewPool(uint256,bytes32)",
    "function updateGrotto(address)",
    "function updateGovernor(address)",
    "function stake(uint256)",
    "function withdrawStake()",
    "function withdrawStakeRewards(uint256)",
  ];
  govAbi = [
    "function vote(string,bool)",
    "function proposeNewValue(uint256,string)",
    "function proposeRemoveGovernor(address)",
    "function proposeNewGovernor(address)",
    "function proposeNewShares(uint256,uint256,uint256)",
    "function updateGov(address)",
  ];

  govContractAddress = "";

  iFace = new ethers.utils.Interface(this.abi);
  govFace = new ethers.utils.Interface(this.govAbi);

  form: FormGroup;
  searchForm: FormGroup;
  stakingForm: FormGroup;

  contractAddress!: string;

  page = "home";
  //selectedVote!: VoteDetails;

  proposedGov = "";
  proposedValue = 0;

  votingSuccess = false;
  votingFailure = false;

  poolPrice!: number;
  poolMinSize!: number;
  mainPoolPrice!: number;
  mainPoolSize!: number;
  poolMaxSize!: number;
  houseCut!: number;
  houseCutNewTokens!: number;
  mode = "demo";
  chainId = 97;
  explorer = "https://testnet.bscscan.com";
  currency = 'BNB';

  grottoTokenAddress = "";

  isAdmin = false;

  bodyColor = "white";
  failColor = "#f8d7da";
  successsColor = "#d4edda";

  grottoTokenBalance = 0;
  stake = 0;
  stakers: string[] = [];
  totalStaked = 0;

  stakingSuccess = false;
  stakingFailure = false;

  withdrawSuccess = false;
  withdrawFailure = false;

  houseCutShares: any;
  houseShare = 0;
  govsShare = 0;
  stakersShare = 0;

  minStakeQ = 1000;

  completedStakes: any = [];
  message: string;

  vts: any[] = [
    { id: 'add_new_governor', title: 'Add New Governor', index: 0, showInList: false },
    { id: 'remove_governor', title: 'Remove Governor', index: 0, showInList: false },
    { id: 'alter_house_cut_shares', title: 'House Cut Shares', index: 0, showInList: false },
    // below place holder so that page is nicely displayed without holes
    { id: 'alter_house_cut_shares', title: 'House Cut Shares', index: 0, showInList: false },
    { id: 'alter_main_pool_price', title: 'Main Pool Price', index: 0 },
    { id: 'alter_main_pool_size', title: 'Main Pool Size', index: 0 },
    { id: 'alter_house_cut', title: 'House Percentage Per Pool (BNB)', index: 0 },
    { id: 'alter_house_cut_tokens', title: 'House Percentage Per Pool (GROTTO)', index: 0 },
    { id: 'alter_min_price', title: 'Minimum Pool Price', index: 0 },
    { id: 'alter_min_size', title: 'Minimum Pool Size', index: 0 },
    { id: 'alter_max_size', title: 'Maximum Pool Size', index: 0 },
    { id: 'alter_min_value_shares', title: 'Minimum Cummulative House Cuts Before Sharing', index: 0 },
    { id: 'alter_min_gov_grotto', title: 'Minimum GROTTO per Governor', index: 0 },
  ];

  addNewGovVote: VoteDetails;
  removeGovVote: VoteDetails;
  sharingFormulaVote: VoteDetails;

  selectedVotes: VoteDetails[] = [];

  constructor(private appService: AppService, private formBuilder: FormBuilder) {
    if (window.ethereum === undefined) {
      this.noMetaMask = true;
    } else {
      this.ethereum = window.ethereum;
    }

    this.form = this.formBuilder.group({
      newPoolPrice: ['', Validators.required],
      newPoolSize: ['', Validators.required],
    });

    this.stakingForm = this.formBuilder.group({
      amountToStake: ['', Validators.required],
      amountToWithdraw: ['', Validators.required],
    });

    this.searchForm = this.formBuilder.group({
      poolCreator: ['', Validators.required],
    });

    this.getAllPools();
    this.getNewPoolValues();
    this.connectMetamask(false);
    this.interval = setInterval(() => {
      this.getAllPools();
    }, 30000);

    // every hour
    setInterval(() => {
      //this.processShares();
    }, 3600000);
    //}, 60000);


    for (let index = 0; index < this.vts.length; index++) {
      this.getVoteDetails(index);
    }
  }

  flash(color: string) {
    this.bodyColor = color;
    setTimeout(() => {
      this.bodyColor = "white";
      window.scroll(0, 0);
    }, 2000);
  }

  reload() {
    this.votingSuccess = false;
    this.votingFailure = false;
    this.startPoolSuccess = false;
    this.startPoolFailure = false;
    this.joinPoolSuccess = false;
    this.joinPoolFailure = false;
    this.getAllPools();
    this.getNewPoolValues();
  }

  getVoteDetails(index: number) {
    this.appService.getVoteDetails(this.vts[index].id, this.mode)
      .pipe(first())
      .subscribe(vd => {
        if (index === 0) {
          this.addNewGovVote = vd.data;
          this.addNewGovVote.index = 0;
        } else if (index === 1) {
          this.removeGovVote = vd.data;
          this.removeGovVote.index = 1;
        } else if (index === 2) {
          this.sharingFormulaVote = vd.data;
          this.sharingFormulaVote.index = 2;
        } else {
          vd.data.title = this.vts[index].title;
          vd.data.index = index;
          this.vts[index].index = index;    
          this.vts[index].currentValue = vd.data.currentValue;      
          this.vts[index].voters = vd.data.voters;
          this.vts[index].yesVotes = vd.data.yesVotes;
          this.vts[index].noVotes = vd.data.noVotes;
          this.vts[index].votes = vd.data.votes;
          this.vts[index].proposedValue = vd.data.proposedValue;
          this.vts[index].isInProgress = vd.data.isInProgress;
          this.vts[index].currentValue = vd.data.currentValue;
          this.vts[index].voteId = vd.data.voteId;
          this.selectedVotes.push(vd.data);
        }
        this.govContractAddress = vd.data.contractAddress;
      });
  }

  proposeNewShares() {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("proposeNewShares", [this.houseShare, this.govsShare, this.stakersShare]);
    this.sendProposal(data, 2);
  }

  proposeNewGovernor() {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("proposeNewGovernor", [this.proposedGov]);
    this.sendProposal(data, 0);
  }

  removeGovernor() {
    this.votingSuccess = false;
    this.votingFailure = false;

    const data: string = this.govFace.encodeFunctionData("proposeRemoveGovernor", [this.proposedGov]);
    this.sendProposal(data, 1);
  }

  sendProposal(data: string, index: number) {
    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: this.govContractAddress, // Required except during contract publications.
      from: this.ethereum.selectedAddress, // must match user's active address.
      value: "0x0", // Only required to send ether to the recipient from the initiating external account.
      data: data,
      chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
      this.votingSuccess = true;
    }, (error: any) => {
      this.votingFailure = true;
    });
  }

  vote(yes: boolean, selectedVote: VoteDetails) {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("vote", [selectedVote.voteId, yes]);

    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: this.govContractAddress, // Required except during contract publications.
      from: this.ethereum.selectedAddress, // must match user's active address.
      value: "0x0", // Only required to send ether to the recipient from the initiating external account.
      data: data,
      chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
      this.votingSuccess = true;
    }, (error: any) => {
      this.votingFailure = true;
    });
  }

  proposeNewValue(voteType: string, index: number) {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("proposeNewValue", [this.proposedValue, voteType]);

    this.sendProposal(data, index);
  }

  getStakingValues() {
    //this.processShares();
    this.completedStakes = [];
    this.stakingSuccess = false;
    this.stakingFailure = false;
    this.appService.getGrottoTokenBalance(this.ethereum.selectedAddress, this.mode).pipe(first()).subscribe(vd => {
      this.grottoTokenBalance = vd.data;
      this.appService.getStake(this.ethereum.selectedAddress, this.mode).pipe(first()).subscribe(vd => {
        this.stake = vd.data;
        this.appService.getStakers(this.mode).pipe(first()).subscribe(vd => {
          for(let  i = 0; i < vd.data.length; i++) {
            if(vd.data[i] !== "0x0000000000000000000000000000000000000000") {
              this.stakers.push(vd.data[i] + "");
            }
          }          
          console.log(this.stakers);
          this.appService.getTotalStaked(this.mode).pipe(first()).subscribe(vd => {
            this.totalStaked = vd.data;

            if (this.stake > 0) {
              this.appService.getCompletedStakes(this.mode).pipe(first()).subscribe(vd => {
                // take only the last 5....ideally, if you't withdraw your winning after 5 iterations, you can as well consider it lost
                const cs = vd.data.reverse().splice(0, 10);
                let found = false;
                for (let x of cs) {
                  if (found) {
                    break;
                  }
                  this.appService.getStakeAndRewards(this.ethereum.selectedAddress, x, this.mode).pipe(first()).subscribe(vd => {
                    if (+vd.data.stakeInPool > 0) {
                      const pool = vd.data;
                      pool.stakeIndex = x;
                      this.completedStakes.push(pool);
                      found = true;
                    }
                  });
                };
              });
            }
          });
        });
      });
    });
  }

  withdrawStakeRewards(stakePoolIndex: number) {
    console.log(stakePoolIndex);
    this.stakingSuccess = false;
    this.stakingFailure = false;
    this.message = "";
    const data: string = this.iFace.encodeFunctionData("withdrawStakeRewards", [stakePoolIndex]);

    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: this.contractAddress, // Required except during contract publications.
      from: this.ethereum.selectedAddress, // must match user's active address.
      value: "0x0", // Only required to send ether to the recipient from the initiating external account.
      data: data,
      chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
      this.stakingSuccess = true;
      this.getStakingValues();
    }, (error: any) => {
      this.stakingFailure = true;
    });
  }

  stakeGrotto() {
    this.stakingSuccess = false;
    this.stakingFailure = false;
    this.message = "";
    const amount = this.stakingForm.value.amountToStake;
    if (amount < this.minStakeQ) {
      this.stakingFailure = true;
      this.message = "Minimum Staking Quantity is " + this.minStakeQ;
      return;
    }

    console.log(amount);
    console.log(ethers.utils.parseEther(amount + ""))
    const data: string = this.iFace.encodeFunctionData("stake", [ethers.utils.parseEther(amount + "").toHexString()]);

    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: this.contractAddress, // Required except during contract publications.
      from: this.ethereum.selectedAddress, // must match user's active address.
      value: "0x0", // Only required to send ether to the recipient from the initiating external account.
      data: data,
      chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
      this.stakingSuccess = true;
      this.getStakingValues();
    }, (error: any) => {
      this.stakingFailure = true;
    });
  }

  withdrawStake() {
    const amount = this.stakingForm.value.amountToWithdraw;
    const data: string = this.iFace.encodeFunctionData("withdrawStake", []);

    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: this.contractAddress, // Required except during contract publications.
      from: this.ethereum.selectedAddress, // must match user's active address.
      value: "0x0", // Only required to send ether to the recipient from the initiating external account.
      data: data,
      chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      this.withdrawSuccess = true;
      this.getStakingValues();
    }, (error: any) => {
      this.withdrawFailure = true;
    });
  }

  gotoPage(page: string) {
    if (page === 'staking') {
      this.getStakingValues();
    } else if (page === 'governance') {
      this.selectedVotes = [];
      for (let index = 0; index < this.vts.length; index++) {
        this.getVoteDetails(index);
      }
    }
    this.page = page;
  }

  filterPool() {
    const poolCreator = this.searchForm.value.poolCreator;

    if (poolCreator === '' || poolCreator === undefined) {
      return;
    }

    console.log("filtering pools");

    this.mainPool = [];
    this.userPool = [];
    this.completedPool = [];
    this.myPool = [];
    if (this.interval) {
      clearInterval(this.interval);
    }

    this.appService.getAllPools(this.mode)
      .pipe(first())
      .subscribe(pd => {
        console.log(pd.data);
        this.poolDetails = pd.data.reverse();
        this.contractAddress = this.poolDetails[0].contractAddress;

        this.mainPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (!pd.isInMainPool) return false;
          return true;
        }).slice(0, 10);

        this.userPool = this.poolDetails.filter((pd) => {
          if (pd.poolCreator.toLocaleLowerCase() === poolCreator.toLocaleLowerCase()) return true;
          return false;
        }).slice(0, 10);
      });
  }

  getAllPools() {
    this.appService.getGrottoTokenAddress(this.mode)
      .pipe(first())
      .subscribe(pd => {
        console.log(pd.data);
        this.grottoTokenAddress = pd.data;
      });
    this.appService.getAllPools(this.mode)
      .pipe(first())
      .subscribe(pd => {
        console.log(pd.data);
        this.poolDetails = pd.data.reverse();
        this.contractAddress = this.poolDetails[0].contractAddress;
        this.mainPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (!pd.isInMainPool) return false;
          return true;
        }).slice(0, 10);

        this.userPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (pd.isInMainPool) return false;
          if (pd.poolId === "") return false;
          return true;
        }).slice(0, 10);

        this.completedPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return true;
          return false;
        }).slice(0, 10);

        this.myPool = this.poolDetails.filter((pd) => {
          if (pd.poolCreator.toLocaleLowerCase() === this.account.toLocaleLowerCase()) return true;
          return false;
        }).slice(0, 10);

        console.log(this.account);
        console.log(this.myPool);
      });
  }

  startNewPool() {
    this.startPoolSuccess = false;
    this.startPoolFailure = false;
    if (!this.form.valid) {
      this.startPoolFailure = true;
      return;
    }
    this.appService.getLatestPrice(this.mode)
      .pipe(first())
      .subscribe(pd => {
        console.log(pd.data);
        const usdPrice: number = +pd.data;
        const ethValue: number = this.form.value.newPoolPrice / usdPrice;
        const poolId: string = ethers.utils.keccak256(ethers.utils.id(this.ethereum.selectedAddress + Math.random()));
        const data: string = this.iFace.encodeFunctionData("startNewPool", [this.form.value.newPoolSize, poolId]);

        const transactionParameters = {
          nonce: '0x00', // ignored by MetaMask
          //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
          //gas: '0x12C07', // customizable by user during MetaMask confirmation.
          to: this.contractAddress, // Required except during contract publications.
          from: this.ethereum.selectedAddress, // must match user's active address.
          value: ethers.utils.parseEther(ethValue + "").toHexString(), // Only required to send ether to the recipient from the initiating external account.
          data: data,
          chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
        };

        // txHash is a hex string
        // As with any RPC call, it may throw an error
        console.log(transactionParameters);
        this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
          console.log(txHash);
          this.startPoolSuccess = true;
          this.flash(this.successsColor);
          this.getAllPools();
        }, (_error: any) => {
          this.flash(this.failColor);
          this.startPoolFailure = true;
        });
      }, (error: any) => {
        this.flash(this.failColor);
        this.startPoolFailure = true;
      });
  }

  updateGov() {
    this.appService.updateGov(this.ethereum, this.govContractAddress, this.contractAddress, this.chainId);
  }

  updateGrotto() {
    this.appService.updateGrotto(this.ethereum, this.contractAddress, this.chainId);
  }

  joinPool(selectedPool: PoolDetails) {
    this.joinPoolSuccess = false;
    this.joinPoolFailure = false;
    let data: string;
    console.log(selectedPool.poolId);
    data = this.iFace.encodeFunctionData("enterPool", [selectedPool.poolId]);

    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: selectedPool.contractAddress, // Required except during contract publications.
      from: this.ethereum.selectedAddress, // must match user's active address.
      value: ethers.utils.parseEther(selectedPool.poolPriceInEther + "").toHexString(), // Only required to send ether to the recipient from the initiating external account.
      data: data,
      chainId: this.chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    this.ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
      this.joinPoolSuccess = true;
      this.flash(this.successsColor);
      this.getAllPools();
    }, (error: any) => {
      this.joinPoolFailure = true;
      this.flash(this.failColor);
    });
  }

  setSelectedPool(pool: PoolDetails, index: number) {
    this.selectedPool = pool;
    this.selectedIndex = index;
  }

  registerEvents() {
    this.ethereum.on('accountsChanged', (accounts: string[]) => {
      console.log(this.ethereum.selectedAddress);
      this.account = this.ethereum.selectedAddress;
    });

    this.ethereum.on('connect', (connectInfo: any) => {
      console.log(connectInfo);
    });

    this.ethereum.on('chainChanged', (chainId: string) => {
      console.log(chainId);
    });

  }

  selectMode(newMode: string) {
    if (newMode !== this.mode) {
      this.mode = newMode;
      this.currency = newMode === 'prod' ? 'BNB' : 'ETH';
      this.chainId = newMode === 'prod' ? 56 : 77;
      this.explorer = newMode === 'prod' ? 'https://bscscan.com/address' : 'https://testnet.bscscan.com'
      this.reload();
    }
  }

  connectMetamask(fromButton: boolean) {
    if (fromButton) {
      this.tryConnect();
    }

    if (!this.noMetaMask) {
      this.tryConnect();
    }
  }

  tryConnect() {
    this.registerEvents();
    this.ethereum.request({ method: 'eth_requestAccounts' }).then((accounts: string[]) => {
      this.ethereum.request({ method: 'eth_chainId' }).then((chainId: string) => {
        console.log(`Metamask Chain ID: ${+chainId}`);
        console.log(`Chain ID We want: ${+this.chainId}`);
        if (+this.chainId === +chainId) {
          this.account = accounts[0];
          this.noMetaMask = false;
        } else {
          this.account = "Connect Metamask";
          this.noMetaMask = true;
        }
        this.reload();
      }, (error: any) => {
        this.noMetaMask = true;
        this.account = "Connect Metamask";
        console.log(error);
        this.reload();
      });
    }, (error: any) => {
      this.noMetaMask = true;
      this.account = "Connect Metamask";
      console.log(error);
      this.reload();
    });
  }

  getNewPoolValues() {
    this.appService.getCurrentValue('alter_min_price', this.mode).pipe(first()).subscribe(vd => {
      this.poolPrice = vd.data;
      this.appService.getCurrentValue('alter_min_size', this.mode).pipe(first()).subscribe(vd => {
        this.poolMinSize = vd.data;
        this.appService.getCurrentValue('alter_max_size', this.mode).pipe(first()).subscribe(vd => {
          this.poolMaxSize = vd.data;
          this.appService.getCurrentValue('alter_house_cut', this.mode).pipe(first()).subscribe(vd => {
            this.houseCut = vd.data;
            this.appService.getCurrentValue('alter_house_cut_tokens', this.mode).pipe(first()).subscribe(vd => {
              this.houseCutNewTokens = vd.data;
              this.appService.getCurrentValue('alter_main_pool_price', this.mode).pipe(first()).subscribe(vd => {
                this.mainPoolPrice = vd.data;
                this.appService.getCurrentValue('alter_main_pool_size', this.mode).pipe(first()).subscribe(vd => {
                  this.mainPoolSize = vd.data;
                  this.appService.getCurrentValue('alter_house_cut_shares', this.mode).pipe(first()).subscribe(vd => {
                    this.houseCutShares = vd.data;
                  });
                });
              });
            });
          });
        });
      });
    });
  }

}
