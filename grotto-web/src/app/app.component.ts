import { Component, ElementRef, ViewChild } from '@angular/core';
import { AppService } from './app.service';
import { first } from 'rxjs/operators';
import { PoolDetails } from './models/pool.model';
import { ethers, logger } from 'ethers';
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
    "function enterPool(bytes32)",
    "function enterMainPool()",
    "function startNewPool(string, uint256)",
  ];
  govAbi = [
    "function vote(string,bool)",
    "function proposeNewValue(uint256,string)",
    "function proposeRemoveGovernor(address)",
    "function proposeNewGovernor(address)",
  ];

  govContractAddress = "";

  iFace = new ethers.utils.Interface(this.abi);
  govFace = new ethers.utils.Interface(this.govAbi);

  form: FormGroup;
  searchForm: FormGroup;
  contractAddress!: string;

  page = "home";
  selectedVote!: VoteDetails;

  voteType = "add_new_governor";
  voteLabel = "";

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
  chainId = 77;
  explorer = "https://blockscout.com/poa/sokol/address";
  currency = 'ETH';

  constructor(private appService: AppService, private formBuilder: FormBuilder) {
    if (window.ethereum === undefined) {
      this.noMetaMask = true;
    } else {
      this.ethereum = window.ethereum;
    }

    this.form = this.formBuilder.group({
      newPoolName: ['', Validators.required],
      newPoolPrice: ['', Validators.required],
      newPoolSize: ['', Validators.required],
    });

    this.searchForm = this.formBuilder.group({
      poolCreator: ['', Validators.required],
    });

    this.getAllPools();
    this.selectVote(this.voteType, "New Governor");
    this.getNewPoolValues();
    this.connectMetamask();
    this.interval = setInterval(() => {
      this.getAllPools();
    }, 30000);
  }

  reload() {
    this.getAllPools();
    this.selectVote(this.voteType, "New Governor");
    this.getNewPoolValues();
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
                });                
              });
            });
          });
        });
      });
    });
  }

  selectVote(voteId: string, label: string) {
    if (this.interval) {
      clearInterval(this.interval);
    }

    this.voteType = voteId;
    this.voteLabel = label;
    this.appService.getVoteDetails(voteId, this.mode)
      .pipe(first())
      .subscribe(vd => {
        this.selectedVote = vd.data;
        this.govContractAddress = vd.data.contractAddress;
      });
  }

  proposeNewGovernor() {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("proposeNewGovernor", [this.proposedGov]);
    this.sendProposal(data);
  }

  removeGovernor() {
    this.votingSuccess = false;
    this.votingFailure = false;

    const data: string = this.govFace.encodeFunctionData("proposeRemoveGovernor", [this.proposedGov]);
    this.sendProposal(data);
  }

  sendProposal(data: string) {
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
      this.getAllPools();
    }, (error: any) => {
      this.votingFailure = true;
    });
  }

  vote(yes: boolean) {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("vote", [this.selectedVote.voteId, yes]);

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
      this.getAllPools();
    }, (error: any) => {
      this.votingFailure = true;
    });
  }

  proposeNewValue() {
    this.votingSuccess = false;
    this.votingFailure = false;
    const data: string = this.govFace.encodeFunctionData("proposeNewValue", [this.proposedValue, this.voteType]);

    this.sendProposal(data);
  }

  gotoPage(page: string) {
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
        const data: string = this.iFace.encodeFunctionData("startNewPool", [this.form.value.newPoolName, this.form.value.newPoolSize]);

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
          this.getAllPools();
        }, (error: any) => {
          this.startPoolFailure = true;
        });
      }, (error: any) => {
        this.startPoolFailure = true;
      });
  }

  joinPool(selectedPool: PoolDetails) {
    this.joinPoolSuccess = false;
    this.joinPoolFailure = false;
    let data: string;
    if (selectedPool.isInMainPool) {
      data = this.iFace.encodeFunctionData("enterMainPool", []);
    } else {
      data = this.iFace.encodeFunctionData("enterPool", [selectedPool.poolId]);
    }

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
      this.getAllPools();
    }, (error: any) => {
      this.joinPoolFailure = true;
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
      this.explorer = newMode === 'prod' ? 'https://bscscan.com/address' : 'https://blockscout.com/poa/sokol/address'
      this.reload();
    }
  }

  connectMetamask() {
    if (!this.noMetaMask) {
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
  }
}
