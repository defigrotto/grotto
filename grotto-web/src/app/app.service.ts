import { Injectable } from "@angular/core";
import { Router } from "@angular/router";
import { BehaviorSubject, Observable } from "rxjs";
import { PoolDetails } from "./models/pool.model";
import { HttpClient } from '@angular/common/http';
import { environment } from '../environments/environment';
import { ethers } from 'ethers';

@Injectable({
  providedIn: 'root'
})
export class AppService {
  private poolDetailsSubject: BehaviorSubject<PoolDetails>;
  public poolDetails: Observable<PoolDetails>;

  constructor(private router: Router, private http: HttpClient) {
    this.poolDetailsSubject = new BehaviorSubject<PoolDetails>(JSON.parse(localStorage.getItem('poolsDetails')!));
    this.poolDetails = this.poolDetailsSubject.asObservable();
  }

  public get poolDetailsValue(): PoolDetails {
    return this.poolDetailsSubject.value;
  }

  getAllPools(mode: string) {
    console.log(mode);
    return this.http.get<any>(`${environment.apiUrl}/all-pools/${mode}`);
  }

  getLatestPrice(mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-latest-price/${mode}`);
  }

  getGrottoTokenAddress(mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-grotto-token-address/${mode}`);
  }  

  getGrottoTokenBalance(address: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-grotto-token-balance/${address}/${mode}`);
  }    

  getStake(address: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-stake/${address}/${mode}`);
  }      

  getCompletedStakes(mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-completed-stakes/${mode}`);
  }        

  getStakeAndRewards(address: string, poolIndex: number, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-stake-rewards/${address}/${poolIndex}/${mode}`);
  }        

  getStakers(mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-stakers/${mode}`);
  }      
  
  getTotalStaked(mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-total-staked/${mode}`);
  }        

  getPoolDetails(poolId: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-pool-details/${poolId}/${mode}`);
  }

  getVoteDetails(voteId: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-vote-details/${voteId}/${mode}`);
  }  

  getCurrentValue(voteId: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-current-value/${voteId}/${mode}`);
  }    

  abi = [
    "function updateGrotto(address)",
    "function updateGovernor(address)",
  ];
  govAbi = [
    "function updateGov(address)",
  ];

  iFace = new ethers.utils.Interface(this.abi);
  govFace = new ethers.utils.Interface(this.govAbi);

  updateGrotto(ethereum: any, contractAddress: string, chainId: number) {
    const data = this.iFace.encodeFunctionData("updateGrotto", ["0x22ABA0A13282cC8E79570dD26f1AB88ae9E4fe9f"]);
    const transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: contractAddress, // Required except during contract publications.
      from: ethereum.selectedAddress, // must match user's active address.
      value: "0x0",
      data: data,
      chainId: chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
    }, (error: any) => {
      console.log(error);
    });    
  }

  updateGov(ethereum: any, govContractAddress: string, contractAddress: string, chainId: number) {
    let data = this.govFace.encodeFunctionData("updateGov", ["0x5C029fc829b88474c756119d793E14c4068bf9dF"]);
    let transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: govContractAddress, // Required except during contract publications.
      from: ethereum.selectedAddress, // must match user's active address.
      value: "0x0",
      data: data,
      chainId: chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
    }, (error: any) => {
      console.log(error);
    });    

    data = this.iFace.encodeFunctionData("updateGovernor", ["0x5C029fc829b88474c756119d793E14c4068bf9dF"]);
    transactionParameters = {
      nonce: '0x00', // ignored by MetaMask
      //gasPrice: '0x37E11D600', // customizable by user during MetaMask confirmation.
      //gas: '0x12C07', // customizable by user during MetaMask confirmation.
      to: contractAddress, // Required except during contract publications.
      from: ethereum.selectedAddress, // must match user's active address.
      value: "0x0",
      data: data,
      chainId: chainId, // Used to prevent transaction reuse across blockchains. Auto-filled by MetaMask.
    };

    // txHash is a hex string
    // As with any RPC call, it may throw an error
    console.log(transactionParameters);
    ethereum.request({ method: 'eth_sendTransaction', params: [transactionParameters], }).then((txHash: string) => {
      console.log(txHash);
    }, (error: any) => {
      console.log(error);
    });        
  }  


}
