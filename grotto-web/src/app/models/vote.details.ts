export class VoteDetails {
    voteId!: string;
    isInProgress!: boolean;
    voters!: string[];
    yesVotes!: number;
    noVotes!: number;
    votes!: number;
    contractAddress!: string;
    proposedValue!: number;
    proposedGovernor!: string;    
}