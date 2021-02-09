import { Component } from '@angular/core';
import { AppService } from './app.service';
import { first } from 'rxjs/operators';
import { PoolDetails } from './models/pool.model';
import { ethers } from 'ethers';
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

  constructor(private appService: AppService) {
    if (window.ethereum === undefined) {
      this.noMetaMask = true;
    } else {
      this.ethereum = window.ethereum;
    }

    this.getAllPools();
    this.connectMetamask();
    this.interval = setInterval(() => {
      this.getAllPools();
    }, 5000);
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
        console.log(pd);
        this.poolDetails = pd.data;
        this.mainPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (!pd.isInMainPool) return false;
          return true;
        });

        this.userPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (pd.isInMainPool) return false;
          return true;
        });

        this.completedPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return true;
          return false;
        });
      });
  }

  joinPool(selectedPool: PoolDetails) {
    let abi = [
      "function enterPool(bytes32)",
      "function enterMainPool()",
    ]

    const iface = new ethers.utils.Interface(abi);
    let data: string;
    if (selectedPool.isInMainPool) {
      data = iface.encodeFunctionData("enterMainPool", []);
    } else {
      data = iface.encodeFunctionData("enterPool", [selectedPool.poolId]);
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
