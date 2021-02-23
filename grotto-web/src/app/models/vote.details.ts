export class VoteDetails {
    voteId!: string;
    title: string;
    index: number;
    isInProgress!: boolean;
    voters!: string[];
    yesVotes!: number;
    noVotes!: number;
    votes!: number;
    contractAddress!: string;
    proposedValue!: number;
    proposedGovernor!: string;    
    proposedShares!: any;    
    currentValue!: any;
}