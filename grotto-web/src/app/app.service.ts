import { Injectable } from "@angular/core";
import { Router } from "@angular/router";
import { BehaviorSubject, Observable } from "rxjs";
import { PoolDetails } from "./models/pool.model";
import { HttpClient } from '@angular/common/http';
import { environment } from '../environments/environment';

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

  getPoolDetails(poolId: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-pool-details/${poolId}/${mode}`);
  }

  getVoteDetails(voteId: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-vote-details/${voteId}/${mode}`);
  }  

  getCurrentValue(voteId: string, mode: string) {
    return this.http.get<any>(`${environment.apiUrl}/get-current-value/${voteId}/${mode}`);
  }    

}
