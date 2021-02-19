/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

library Data {
    string public constant ADD_GOVERNOR_VOTE_ID = "add_new_governor";
    string public constant REMOVE_GOVERNOR_VOTE_ID = "remove_governor";
    string public constant ALTER_MAIN_POOL_PRICE = "alter_main_pool_price";
    string public constant ALTER_MAIN_POOL_SIZE = "alter_main_pool_size";
    string public constant ALTER_HOUSE_CUT = "alter_house_cut";
    string public constant ALTER_HOUSE_CUT_TOKENS = "alter_house_cut_tokens";
    string public constant ALTER_MIN_PRICE = "alter_min_price";
    string public constant ALTER_MIN_SIZE = "alter_min_size";
    string public constant ALTER_MAX_SIZE = "alter_max_size";
    string public constant ALTER_MIN_GOV_GROTTO = "alter_min_gov_grotto";
    string public constant ALTER_HOUSE_CUT_SHARES = "alter_house_cut_shares";
    
    uint256 public constant ONE_ETHER = 1 ether;

    struct Pool {
        address winner;
        uint256 currentPoolSize;
        bool isInMainPool;
        uint256 poolSize;
        uint256 poolPrice;
        address poolCreator;
        bool isPoolConcluded;
        uint256 poolPriceInEther;
        bytes32 poolId;
        uint256 totalStaked;
    }

    struct ProposedShare {
        uint256 house;        
        uint256 govs;
        uint256 stakers;
    }

    struct Vote {
        string voteId;
        bool inProgress;
        address payable[] voters;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votes;
        uint256 proposedValue;
        address proposedGovernor;
        ProposedShare proposedShare;
    }        
}