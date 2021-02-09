import { Component } from '@angular/core';
import { AppService } from './app.service';
import { first } from 'rxjs/operators';
import { PoolDetails } from './models/pool.model';
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
  selectedPool!: PoolDetails;
  noMetaMask = false;

  constructor(private appService: AppService) {
    if (window.ethereum === undefined) {
      this.noMetaMask = true;
    } else {
      this.ethereum = window.ethereum;
    }

    this.connectMetamask();
    this.appService.getAllPools()
      .pipe(first())
      .subscribe(pd => {
        console.log(pd);
        this.poolDetails = pd.data;
        this.mainPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (pd.isInMainPool) return true;
          return true;
        });

        this.userPool = this.poolDetails.filter((pd) => {
          if (pd.isPoolConcluded) return false;
          if (pd.isInMainPool) return false;
          return true;
        });
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
