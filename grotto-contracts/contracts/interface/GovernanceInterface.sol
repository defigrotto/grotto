// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3 <0.8.0;
pragma experimental ABIEncoderV2;

import "../lib/Data.sol";

interface GovernanceInterface {
    event NEW_GOVERNOR_ADDED(address);
    event GOVERNOR_REMOVED(address);
    event MAIN_POOL_PRICE_CHANGED(uint256);
    event MAIN_POOL_SIZE_CHANGED(uint256);
    event HOUSE_CUT_CHANGED(uint256);
    event HOUSE_CUT_NEW_TOKENS_CHANGED(uint256);
    event MINIMUM_POOL_PRICE_CHANGED(uint256);
    event MINIMUM_POOL_SIZE_CHANGED(uint256);
    event MAXIMUM_POOL_SIZE_CHANGED(uint256);
    event MIN_GROTTO_GOV_CHANGED(uint256);
    event SHARES_CHANGED(uint256, uint256, uint256);
    event NO_CONSENSUS(string);
    event VOTE_CASTED(address, string);
    event NEW_PROPOSAL(string);

    function votingDetails(string memory) external view returns (Data.Vote memory);
    function isGovernor(address) external view returns (bool);
    function proposeNewGovernor(address) external;
    function proposeRemoveGovernor(address) external;
    function proposeNewValue(uint256, string calldata) external;
    function proposeNewShares(uint256, uint256, uint256) external;
    function vote(string calldata voteId, bool yesVote) external;
}