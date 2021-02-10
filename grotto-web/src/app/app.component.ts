import { Component } from '@angular/core';
import { AppService } from './app.service';
import { first } from 'rxjs/operators';
import { PoolDetails } from './models/pool.model';
import { ethers } from 'ethers';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
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
  chainId = "";

  poolDetails!: PoolDetails[];
  mainPool!: PoolDetails[];
  userPool!: PoolDetails[];
  completedPool!: PoolDetails[];
  selectedPool!: PoolDetails;
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
  iFace = new ethers.utils.Interface(this.abi);

  form: FormGroup;
  contractAddress!: string;

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

    this.getAllPools();
    this.connectMetamask();
    this.interval = setInterval(() => {
      this.getAllPools();
    }, 30000);
  }

  ngOnDestroy() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  getAllPools() {
    this.appService.getAllPools()
      .pipe(first())
      .subscribe(pd => {
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
      });
  }

  startNewPool() {
    this.startPoolSuccess = false;
    this.startPoolFailure = false;
    if (!this.form.valid) {
      this.startPoolFailure = true;
      return;
    }
    this.appService.getLatestPrice()
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

  setSelectedPool(pool: PoolDetails) {
    this.selectedPool = pool;
  }

  registerEvents() {
    this.ethereum.on('accountsChanged', (accounts: string[]) => {
      console.log(this.ethereum.selectedAddress);
      this.account = this.ethereum.selectedAddress;
    });

    this.ethereum.on('connect', (connectInfo: any) => {
      console.log(connectInfo);
      this.chainId = connectInfo.chainId;
    });

    this.ethereum.on('chainChanged', (chainId: string) => {
      console.log(chainId);
      this.chainId = chainId;
    });

  }

  connectMetamask() {
    this.registerEvents();
    this.ethereum.request({ method: 'eth_requestAccounts' }).then((accounts: string[]) => {
      this.ethereum.request({ method: 'eth_chainId' }).then((chainId: string) => {
        console.log(chainId);
        this.chainId = chainId;
        if (+this.chainId === 0x4d || +this.chainId === 77) {
          this.account = accounts[0];
          this.noMetaMask = false;
        } else {
          this.account = "Connect Metamask";
          this.noMetaMask = true;
        }
      }, (error: any) => {
        this.noMetaMask = true;
        this.account = "Connect Metamask";
        console.log(error);
      });
    }, (error: any) => {
      this.noMetaMask = true;
      this.account = "Connect Metamask";
      console.log(error);
    });
  }
}
