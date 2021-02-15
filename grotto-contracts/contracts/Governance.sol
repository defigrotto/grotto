/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/GovernanceInterface.sol";
import "./interface/StorageInterface.sol";
import "./interface/GrottoTokenInterface.sol";
import "./lib/Data.sol";

contract Governance is GovernanceInterface {
    using SafeMath for uint256;

    StorageInterface store;
    address private storeAddress = 0x32b0319f75490b1326380D74cDb4224bb293f9f0;

    address private tokenAddress = 0x9F9B1A890eF0275DabFF37C051D52F427A8a4501;
    GrottoTokenInterface grottoToken;

    address[] private voters;

    address[] private governors;

    uint256 constant private MAX_GOVERNORS = 21;

    constructor() {
        store = StorageInterface(storeAddress);
        store.addGovernor(0xC04915f6b3ff85b50A863eB1FcBF368171539413);            
        store.addGovernor(0xb58c226a300fF6dc1eF762d62c536c7aED5CeA74);        
        store.addGovernor(0xB6D80F6d661927afEf42f39e52d630E250696bc4);
        store.addGovernor(0x6B33d96c8353D03433034171433b0Bd9bdaFaC8b);
        store.addGovernor(0x0A0C8E469fef425eF7C6E9754dC563f9BBa588f0); 

        grottoToken = GrottoTokenInterface(tokenAddress);         
    }

    function updateGov(address newAddress) public {
        store.setGov(newAddress);
        grottoToken.setGrotto(newAddress);
    }    

    function votingDetails(string memory voteId) public override view returns (Data.Vote memory) {
        return
            Data.Vote({
                voteId: voteId,
                inProgress: store.isInProgress(voteId),
                voters: store.getVoters(voteId),
                yesVotes: store.getYesVotes(voteId),
                noVotes: store.getNoVotes(voteId),
                votes: store.getVotes(voteId),
                proposedValue: store.getProposedValue(voteId),
                proposedGovernor: store.getProposedGovernor(voteId)
            });
    }

    function getGovernors() public view returns (address[] memory) {
        return store.getGovernors();
    }

    function getMainPoolPrice() public view returns (uint256) {
        return store.getMainPoolPrice();
    }    

    function getMainPoolSize() public view returns (uint256) {
        return store.getMainPoolSize();
    }

    function getHouseCut() public view returns (uint256) {
        return store.getHouseCut();
    }            

    function getHouseCutNewTokens() view public returns (uint256) {
        return store.getHouseCutNewTokens();
    }

    function getMinimumPoolPrice() view public returns (uint256) {
        return store.getMinimumPoolPrice();
    }

    function getMinimumPoolSize() view public returns (uint256) {
        return store.getMinimumPoolSize();
    }    

    function getMinGrottoGovernor() view public returns (uint256) {
        return store.getMinGrottoGovernor();
    }

    function getMaximumPoolSize() view public returns (uint256) {
        return store.getMaximumPoolSize();
    }          

    function isGovernor(address governor) public override view returns (bool) {
        address[] memory govs = store.getGovernors();
        for (uint256 i = 0; i < govs.length; i++) {
            if (govs[i] == governor) {
                if(grottoToken.balanceOf(governor) >= store.getMinGrottoGovernor()) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        return false;
    }

    function proposeNewGovernor(address newGovernor) public override {
        address governor = msg.sender;
        if (!isGovernor(governor)) {
            revert("Only a governor can do that");
        }

        if (isGovernor(newGovernor)) {
            revert('Already a governor');
        }

        require(grottoToken.balanceOf(newGovernor) >= store.getMinGrottoGovernor(), 'New Governor does not have enough GROTTO');

        address[] memory govs = store.getGovernors();
        require(govs.length <= MAX_GOVERNORS, 'You can not add more governors. Remove a governor first');

        string memory voteId = Data.ADD_GOVERNOR_VOTE_ID;
        bool isInProgress = store.isInProgress(voteId);
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            store.addProposedGovernor(voteId, newGovernor);
            _continueToVote(voteId, governor);
        }
    }

    function proposeRemoveGovernor(address oldGovernor) public override {
        address governor = msg.sender;
        if (!isGovernor(governor)) {
            revert("Only a governor can do that");
        }

        if (!isGovernor(oldGovernor)) {
            revert("Not a governor");
        }

        string memory voteId = Data.REMOVE_GOVERNOR_VOTE_ID;
        bool isInProgress = store.isInProgress(voteId);
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            store.addProposedGovernor(voteId, oldGovernor);
            _continueToVote(voteId, governor);
        }
    }

    function proposeNewValue(uint256 value, string calldata voteId) public override {
        address governor = msg.sender;
        if (!isGovernor(governor)) {
            revert("Only a governor can do that");
        }
        bool isInProgress = store.isInProgress(voteId);
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            store.addProposedValue(voteId, value);
            _continueToVote(voteId, governor);
        }
    }

    function vote(string calldata voteId, bool yesVote) public override {
        address governor = msg.sender;
        if (!isGovernor(governor)) {
            revert("Only a governor can do that");
        }

        if (store.getVoted(voteId, governor)) {
            revert("Already voted");
        }

        _vote(voteId, governor, yesVote);
    }

    function _continueToVote(string memory voteId, address governor) private {
        store.setProgress(voteId, true);
        _vote(voteId, governor, true);
        emit NEW_PROPOSAL(voteId);
    }

    function _resetVotes(string memory voteId) private {
        store.setVotes(voteId, 0);
        voters = store.getVoters(voteId);
        
        uint256 len = voters.length;

        for (uint256 i = 0; i < len; i++) {
            address gov = voters[i];
            store.setVoted(voteId, gov, false);
        }

        address[] memory newVoters;
        store.setVoters(voteId, newVoters);

        store.setYesVotes(voteId, 0);
        store.setNoVotes(voteId, 0);
        store.setProgress(voteId, false);
        
        if (
            keccak256(bytes(voteId)) == keccak256(bytes(Data.ADD_GOVERNOR_VOTE_ID)) ||
            (keccak256(bytes(voteId)) == keccak256(bytes(Data.REMOVE_GOVERNOR_VOTE_ID)))
        ) {
            store.addProposedGovernor(voteId, address(0));
        } else {
            store.addProposedValue(voteId, 0);
        }
    }

    function _annulElection(string memory voteId) private view returns (bool) {
        address[] memory _voters = store.getVoters(voteId);

        for(uint256 i = 0; i < _voters.length; i++) {
            if(!isGovernor(_voters[i])) {
                /*
                This can happen is for instance voter was deleted before vote is completed
                Or if voter didn't maintain balance for duration of election
                */
                return true;
            }
        }

        return false;
    }

    function _vote(string memory voteId, address governor,bool yesVote) private {
        bool isInProgress = store.isInProgress(voteId);
        if (isInProgress) {
            if (yesVote) {
                store.setYesVotes(voteId, store.getYesVotes(voteId).add(1));                
            } else {
                store.setNoVotes(voteId, store.getNoVotes(voteId).add(1));
            }
            
            store.addVoter(voteId, governor);
            store.setVotes(voteId, store.getVotes(voteId).add(1));                
            
            store.setVoted(voteId, governor, true);

            emit VOTE_CASTED(governor, voteId);

            // count votes
            uint256 numGovs = store.getGovernors().length;
            uint256 allYes = store.getYesVotes(voteId);
            uint256 allNo = store.getNoVotes(voteId);
            uint256 allVotes = store.getVotes(voteId);

            bool countVotes = allVotes == numGovs;
            if(!countVotes) {
                countVotes = (allYes > allNo && (allNo + (numGovs - allYes) < allYes)) ||
                            (allNo > allYes && (allYes + (numGovs - allNo) < allNo));
            }

            
            if (countVotes) {
                // all governors have voted
                // check if all voting governors still have GROTTO tokens

                if(_annulElection(voteId)) {
                    emit NO_CONSENSUS(voteId);
                } else if (allYes > allNo) {
                    if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ADD_GOVERNOR_VOTE_ID))
                    ) {
                        // add new governor
                        store.addGovernor(store.getProposedGovernor(voteId));
                        emit NEW_GOVERNOR_ADDED(store.getProposedGovernor(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.REMOVE_GOVERNOR_VOTE_ID))
                    ) {
                        int256 intIndex = -1;
                        governors = store.getGovernors();
                        for (uint256 i = 0; i < governors.length; i++) {
                            if (governors[i] == store.getProposedGovernor(voteId)) {
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

                        store.setGovernors(governors); 

                        emit GOVERNOR_REMOVED(store.getProposedGovernor(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MAIN_POOL_PRICE))
                    ) {
                        store.setMainPoolPrice(store.getProposedValue(voteId) * Data.ONE_ETHER);
                        emit MAIN_POOL_PRICE_CHANGED(store.getProposedValue(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MAIN_POOL_SIZE))
                    ) {
                        store.setMainPoolSize(store.getProposedValue(voteId));
                        emit MAIN_POOL_SIZE_CHANGED(store.getProposedValue(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_HOUSE_CUT))
                    ) {
                        store.setHouseCut(store.getProposedValue(voteId));
                        emit HOUSE_CUT_CHANGED(store.getProposedValue(voteId));

                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_HOUSE_CUT_TOKENS))
                    ) {
                        store.setHouseCutNewTokens(store.getProposedValue(voteId));
                        emit HOUSE_CUT_NEW_TOKENS_CHANGED(store.getProposedValue(voteId));

                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MIN_PRICE))
                    ) {
                        store.setMinimumPoolPrice(store.getProposedValue(voteId)  * Data.ONE_ETHER);
                        emit MINIMUM_POOL_PRICE_CHANGED(store.getProposedValue(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MIN_SIZE))
                    ) {
                        store.setMinimumPoolSize(store.getProposedValue(voteId));
                        emit MINIMUM_POOL_SIZE_CHANGED(store.getProposedValue(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MAX_SIZE))
                    ) {
                        store.setMaximumPoolSize(store.getProposedValue(voteId));
                        emit MAXIMUM_POOL_SIZE_CHANGED(store.getProposedValue(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MIN_GOV_GROTTO))
                    ) {
                        store.setMinGrottoGovernor(store.getProposedValue(voteId) * Data.ONE_ETHER);
                        emit MIN_GROTTO_GOV_CHANGED(store.getProposedValue(voteId));
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
