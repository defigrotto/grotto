/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GovernanceInterface.sol";

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

contract Governance is
    GovernanceInterface,
    ERC20("Governance Contract", "DOTGOV")
{
    using SafeMath for uint256;

    string internal constant ADD_GOVERNOR_VOTE_ID = "add_new_governor";
    string internal constant REMOVE_GOVERNOR_VOTE_ID = "remove_governor";
    string internal constant ALTER_MAIN_POOL_PRICE = "alter_main_pool_price";
    string internal constant ALTER_MAIN_POOL_SIZE = "alter_main_pool_size";
    string internal constant ALTER_HOUSE_CUT = "alter_house_cut";
    string internal constant ALTER_HOUSE_CUT_TOKENS = "alter_house_cut_tokens";
    string internal constant ALTER_MIN_PRICE = "alter_min_price";
    string internal constant ALTER_MIN_SIZE = "alter_min_size";
    string internal constant ALTER_MAX_SIZE = "alter_max_size";

    mapping(string => uint256) votes;
    mapping(address => mapping(string => bool)) voted;
    mapping(string => address[]) voters;
    mapping(string => uint256) yesVotes;
    mapping(string => uint256) noVotes;
    mapping(string => bool) inProgress;

    mapping(string => address) proposedGovernor;
    mapping(string => uint256) proposedValue;

    address[] governors;
    // amount of gas needed for transfer
    uint256 private TRANSFER_GAS = 2300;

    uint256 private constant ONE_ETHER = 1 ether;

    // TODO: stake price for the main pool. $100
    //uint256 private MAIN_POOL_PRICE = 100 * ONE_ETHER;
    // for testing make it $1
    uint256 private MAIN_POOL_PRICE = 100 * ONE_ETHER;

    // TODO: number of accounts before winner is calculated.
    // change to 10 for tests to pass
    // change to 5 for sokol tests to pass
    // change to 100 for prod
    uint256 private MAIN_POOL_SIZE = 100;

    // percentage of winning that goes to house. 10%
    uint256 private HOUSE_CUT = 10;

    // how many % of new tokens go to house. 10%
    uint256 private HOUSE_CUT_NEW_TOKEN = 10;

    // TODO: Minimum price for user defined pools
    //uint256 private MINIMUM_POOL_PRICE = 10 * ONE_ETHER;
    // for testing make it $1
    uint256 private MINIMUM_POOL_PRICE = 10 * ONE_ETHER;

    // TODO: Minimum size for user defined pools
    // change to 3 for sokol
    // change to 10 for prod
    uint256 private MINIMUM_POOL_SIZE = 10;

    // Maximum size for user defined pools
    uint256 private MAXIMUM_POOL_SIZE = 100;

    constructor() {
        governors.push(0xC04915f6b3ff85b50A863eB1FcBF368171539413);
        governors.push(0xb58c226a300fF6dc1eF762d62c536c7aED5CeA74);
        governors.push(0xB6D80F6d661927afEf42f39e52d630E250696bc4);
        governors.push(0x6B33d96c8353D03433034171433b0Bd9bdaFaC8b);
        governors.push(0x0A0C8E469fef425eF7C6E9754dC563f9BBa588f0);
    }

    function votingDetails(string memory voteId)
        public
        view
        returns (Vote memory)
    {
        return
            Vote({
                voteId: voteId,
                inProgress: inProgress[voteId],
                voters: voters[voteId],
                yesVotes: yesVotes[voteId],
                noVotes: noVotes[voteId],
                votes: votes[voteId],
                proposedValue: proposedValue[voteId],
                proposedGovernor: proposedGovernor[voteId]
            });
    }

    function getGovernors() public view override returns (address[] memory) {
        return governors;
    }

    function getTransferGas() public view override returns (uint256) {
        return TRANSFER_GAS;
    }

    function getMainPoolPrice() public view override returns (uint256) {
        return MAIN_POOL_PRICE;
    }

    function getMainPoolSize() public view override returns (uint256) {
        return MAIN_POOL_SIZE;
    }

    function getHouseCut() public view override returns (uint256) {
        return HOUSE_CUT;
    }

    function getHouseCutNewTokens() public view override returns (uint256) {
        return HOUSE_CUT_NEW_TOKEN;
    }

    function getMinimumPoolPrice() public view override returns (uint256) {
        return MINIMUM_POOL_PRICE;
    }

    function getMinimumPoolSize() public view override returns (uint256) {
        return MINIMUM_POOL_SIZE;
    }

    function getMaximumPoolSize() public view override returns (uint256) {
        return MAXIMUM_POOL_SIZE;
    }

    function _is_governor(address governor) private view returns (bool) {
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == governor) {
                return true;
            }
        }

        //TODO: set to false in prod
        return false;
    }

    function proposeNewGovernor(address newGovernor) public {
        address governor = msg.sender;
        if (!_is_governor(governor)) {
            revert("Only a governor can do that");
        }

        if (_is_governor(newGovernor)) {
            //TODO: uncomment in prod
            revert('Already a governor');
        }

        string memory voteId = ADD_GOVERNOR_VOTE_ID;
        bool isInProgress = inProgress[voteId];
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            proposedGovernor[voteId] = newGovernor;
            _continueToVote(voteId, governor);
        }
    }

    function proposeRemoveGovernor(address oldGovernor) public {
        address governor = msg.sender;
        if (!_is_governor(governor)) {
            revert("Only a governor can do that");
        }

        if (!_is_governor(oldGovernor)) {
            revert("Not a governor");
        }

        string memory voteId = REMOVE_GOVERNOR_VOTE_ID;
        bool isInProgress = inProgress[voteId];
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            proposedGovernor[voteId] = oldGovernor;
            _continueToVote(voteId, governor);
        }
    }

    function proposeNewValue(uint256 value, string calldata voteId) public {
        address governor = msg.sender;
        uint256 newPrice = value;
        if (!_is_governor(governor)) {
            revert("Only a governor can do that");
        }
        bool isInProgress = inProgress[voteId];
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            proposedValue[voteId] = newPrice;
            _continueToVote(voteId, governor);
        }
    }

    function vote(string calldata voteId, bool yesVote) public {
        address governor = msg.sender;
        if (!_is_governor(governor)) {
            revert("Only a governor can do that");
        }

        if (voted[governor][voteId] == true) {
            revert("Already voted");
        }

        _vote(voteId, governor, yesVote);
    }

    function _continueToVote(string memory voteId, address governor) private {
        inProgress[voteId] = true;
        _vote(voteId, governor, true);
        emit NEW_PROPOSAL(voteId);
    }

    function _resetVotes(string memory voteId) private {
        votes[voteId] = 0;
        for (uint256 i = 0; i < voters[voteId].length; i++) {
            voters[voteId].pop();
            voted[governors[i]][voteId] = false;
        }
        yesVotes[voteId] = 0;
        noVotes[voteId] = 0;
        inProgress[voteId] = false;
        if (
            keccak256(bytes(voteId)) ==
            keccak256(bytes(ADD_GOVERNOR_VOTE_ID)) ||
            (keccak256(bytes(voteId)) ==
                keccak256(bytes(REMOVE_GOVERNOR_VOTE_ID)))
        ) {
            proposedGovernor[voteId] = address(0);
        } else {
            proposedValue[voteId] = 0;
        }
    }

    function _vote(
        string memory voteId,
        address governor,
        bool yesVote
    ) private {
        bool isInProgress = inProgress[voteId];
        if (isInProgress) {
            if (yesVote) {
                yesVotes[voteId] = yesVotes[voteId].add(1);
            } else {
                noVotes[voteId] = noVotes[voteId].add(1);
            }

            voters[voteId].push(governor);
            votes[voteId] = votes[voteId].add(1);
            voted[governor][voteId] = true;

            emit VOTE_CASTED(governor, voteId);

            // count votes
            if (votes[voteId] == governors.length) {
                // all governors have voted
                uint256 allYes = yesVotes[voteId];
                uint256 allNo = noVotes[voteId];

                if (allYes > allNo) {
                    if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ADD_GOVERNOR_VOTE_ID))
                    ) {
                        // add new governor
                        governors.push(proposedGovernor[voteId]);
                        emit NEW_GOVERNOR_ADDED(proposedGovernor[voteId]);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(REMOVE_GOVERNOR_VOTE_ID))
                    ) {
                        int256 intIndex = -1;
                        for (uint256 i = 0; i < governors.length; i++) {
                            if (governors[i] == proposedGovernor[voteId]) {
                                intIndex = int256(i);
                                break;
                            }
                        }

                        if (intIndex == -1) {
                            revert("governor not found.");
                        }

                        uint256 index = uint256(intIndex);
                        uint256 len = governors.length;

                        if (index == (len - 1)) {
                            governors.pop();
                        } else {
                            governors[index] = governors[len - 1];
                            governors.pop();
                        }

                        emit GOVERNOR_REMOVED(proposedGovernor[voteId]);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_MAIN_POOL_PRICE))
                    ) {
                        MAIN_POOL_PRICE = proposedValue[voteId] * ONE_ETHER;
                        emit MAIN_POOL_PRICE_CHANGED(MAIN_POOL_PRICE);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_MAIN_POOL_SIZE))
                    ) {
                        MAIN_POOL_SIZE = proposedValue[voteId];
                        emit MAIN_POOL_SIZE_CHANGED(MAIN_POOL_SIZE);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_HOUSE_CUT))
                    ) {
                        HOUSE_CUT = proposedValue[voteId];
                        emit HOUSE_CUT_CHANGED(HOUSE_CUT);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_HOUSE_CUT_TOKENS))
                    ) {
                        HOUSE_CUT_NEW_TOKEN = proposedValue[voteId];
                        emit HOUSE_CUT_NEW_TOKENS_CHANGED(HOUSE_CUT_NEW_TOKEN);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_MIN_PRICE))
                    ) {
                        MINIMUM_POOL_PRICE = proposedValue[voteId] * ONE_ETHER;
                        emit MINIMUM_POOL_PRICE_CHANGED(MINIMUM_POOL_PRICE);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_MIN_SIZE))
                    ) {
                        MINIMUM_POOL_SIZE = proposedValue[voteId];
                        emit MINIMUM_POOL_SIZE_CHANGED(MINIMUM_POOL_SIZE);
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(ALTER_MAX_SIZE))
                    ) {
                        MAXIMUM_POOL_SIZE = proposedValue[voteId];
                        emit MAXIMUM_POOL_SIZE_CHANGED(MAXIMUM_POOL_SIZE);
                    }
                } else {
                    emit NO_CONSENSUS(voteId);
                }

                _resetVotes(voteId);
            }
        } else {
            revert("Not in progress");
        }
    }
}
