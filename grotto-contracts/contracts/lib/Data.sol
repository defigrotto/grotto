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

    struct Vote {
        string voteId;
        bool inProgress;
        address[] voters;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votes;
        uint256 proposedValue;
        address proposedGovernor;
    }        
}