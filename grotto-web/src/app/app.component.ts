import { Component, Output } from '@angular/core';
declare const window: any

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {
  title = 'grotto-web';
  ethereum: any;

  account = "";

  constructor() {
    if (window.ethereum === undefined) {
      alert('Non-Ethereum browser detected. Install MetaMask');
    } else {
      this.ethereum = window.ethereum;
    }
  }

  registerEvents() {
    this.ethereum.on('accountsChanged', (accounts: string[]) => {
      console.log(this.ethereum.selectedAddress);
      this.account = this.ethereum.selectedAddress;
    });
  }

  connectMetamask() {
    this.registerEvents();
    this.ethereum.request({ method: 'eth_requestAccounts' }).then((accounts: string[]) => {
      this.account = accounts[0];
    });
  }
}
