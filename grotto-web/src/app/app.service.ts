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

    getAllPools() {
        return this.http.get<any>(`${environment.apiUrl}/all-pools`);
    }
  
}
