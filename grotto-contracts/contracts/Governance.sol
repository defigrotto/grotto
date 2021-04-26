/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.9.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/GovernanceInterface.sol";
import "./interface/StorageInterface.sol";
import "./interface/GrottoTokenInterface.sol";
import "./lib/Data.sol";

contract Governance is GovernanceInterface {
    using SafeMath for uint256;

    StorageInterface store;
    
    address private storeAddress = 0xd7Af206e780D21aA9B1AD46DE96b5Dbe0c4a0C99;
    address private tokenAddress = 0x90a81fE6E78c12e090C8FFa48a24e8CFb61B6bD9;

    GrottoTokenInterface grottoToken;

    address[] private voters;

    address payable[] private governors;

    uint256 constant private MAX_GOVERNORS = 21;

    constructor() {
        store = StorageInterface(storeAddress);
        store.addGovernor(0xac706cE8A9BF27Afecf080fB298d0ee13cfb978A); // SMWC 
        store.addGovernor(0x513F4Eae3b71582F653d6468801a2eC129F562ec); // SBWC
        store.addGovernor(0x616B6c01DFeA4AF613326FDF683429f43CEe86FD); // SEGWAL
        store.addGovernor(0x2EC51cDCEf76d943ae564753693d09B4EeB027ca); // AKBWC
        store.addGovernor(0x1bc00278A6321882938bB271b14bb0BCa94a46a5); // SWOBC
        store.addGovernor(0x1bbb2a26bdE9ac59466f1a505E9A15A1fb2D6C2c); // BISH
        store.addGovernor(0xB926bDa6387d7fDF59a49E61A753012eD10678D2); // GAB
        store.addGovernor(0x51ee4EAc95BeE304301e41ec175f7DCad50022F6); // GABRO
        store.addGovernor(0xf04670f01CAa31a0DB19Fb35410C4Bf315A2A720); // BAY
        store.addGovernor(0xB2afD8028f10d6b681A129D7E4cBB12374DB42C1); // ANNDT
        store.addGovernor(0xA7B5ab65D3Ea54A990f7E59763C674b67A50C736); // BAM
        

        grottoToken = GrottoTokenInterface(tokenAddress);         
    }    

    function updateGov(address payable newAddress) public {
        store.setGov(newAddress);
    }    

    function votingDetails(string memory voteId) public  view returns (Data.Vote memory) {
        (uint256 house, uint256 govs, uint256 stakers) = store.getProposedShare(); 
        Data.ProposedShare memory p = Data.ProposedShare({
            house: house,
            govs: govs,
            stakers: stakers
        });

        return
            Data.Vote({
                voteId: voteId,
                inProgress: store.isInProgress(voteId),
                voters: store.getVoters(voteId),
                yesVotes: store.getYesVotes(voteId),
                noVotes: store.getNoVotes(voteId),
                votes: store.getVotes(voteId),
                proposedValue: store.getProposedValue(voteId),
                proposedGovernor: store.getProposedGovernor(voteId),
                proposedShare: p
            });
    }

    function getMinValueForSharesProcessing() public view returns (uint256) {
        return store.getMinValueForSharesProcessing();
    }

    function getGovernors() public view returns (address payable[] memory) {
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

    function getHouseCutShares() view public returns (uint256, uint256, uint256) {
        return store.getHouseCutShares();
    }       

    function proposeNewGovernor(address payable newGovernor) public  {
        address payable governor = msg.sender;
        if (!store.addressIsGovernor(governor)) {
            revert("Only a governor can do that");
        }

        if (store.addressIsGovernor(newGovernor)) {
            revert('Already a governor');
        }

        if(store.getGovernors().length == 21) {
            revert('There can not be more than 21 governors');
        }        

        require(grottoToken.balanceOf(newGovernor) >= store.getMinGrottoGovernor(), 'New Governor does not have enough GROTTO');

        address payable[] memory govs = store.getGovernors();
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

    function proposeRemoveGovernor(address payable oldGovernor) public  {
        address payable governor = msg.sender;
        if (!store.addressIsGovernor(governor)) {
            revert("Only a governor can do that");
        }

        if (!store.addressIsGovernor(oldGovernor)) {
            revert("Not a governor");
        }

        if(store.getGovernors().length <= 11) {
            revert('There must be at least 11 governors');
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

    function proposeNewValue(uint256 value, string calldata voteId) public  {
        address payable governor = msg.sender;
        if (!store.addressIsGovernor(governor)) {
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

    function proposeNewShares(uint256 houseShare, uint256 govsShare, uint256 stakersShare) public  {
        uint256 totalShares = houseShare.add(govsShare);
        totalShares = totalShares.add(stakersShare);

        require(totalShares == 100, 'Shares not properly distributed');
        address payable governor = msg.sender;
        if (!store.addressIsGovernor(governor)) {
            revert("Only a governor can do that");
        }

        string memory voteId = Data.ALTER_HOUSE_CUT_SHARES;
        bool isInProgress = store.isInProgress(voteId);
        if (isInProgress) {
            revert("Already In Progress");
        } else {
            store.setProposedShare(houseShare, govsShare, stakersShare);
            _continueToVote(voteId, governor);
        }
    }

    function vote(string calldata voteId, bool yesVote) public  {
        address payable governor = msg.sender;
        if (!store.addressIsGovernor(governor)) {
            revert("Only a governor can do that");
        }

        if (store.getVoted(voteId, governor)) {
            revert("Already voted");
        }

        _vote(voteId, governor, yesVote);
    }

    function _continueToVote(string memory voteId, address payable governor) private {
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

        address payable[] memory newVoters;
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
        address payable[] memory _voters = store.getVoters(voteId);

        for(uint256 i = 0; i < _voters.length; i++) {
            if(!store.addressIsGovernor(_voters[i])) {
                /*
                This can happen is for instance voter was deleted before vote is completed
                Or if voter didn't maintain balance for duration of election
                */
                return true;
            }
        }

        return false;
    }

    function _vote(string memory voteId, address payable governor,bool yesVote) private {
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
                        address payable toRemove = governors[index];
                        uint256 len = governors.length;

                        if (index == (len - 1)) {
                            governors.pop();
                        } else {
                            governors[index] = governors[len - 1];
                            governors.pop();
                        }

                        store.setGovernors(governors);
                        store.setIsGovernor(toRemove, false);                        

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
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_MIN_VALUE_SHARES))
                    ) {
                        store.setMinValueForSharesProcessing(store.getProposedValue(voteId) * Data.ONE_ETHER);
                        emit MIN_VALUE_FOR_SHARES_CHANGED(store.getProposedValue(voteId));
                    } else if (
                        keccak256(bytes(voteId)) ==
                        keccak256(bytes(Data.ALTER_HOUSE_CUT_SHARES))
                    ) {
                        (uint256 house, uint256 govs, uint256 stakers) = store.getProposedShare();
                        store.setHouseShare(house);
                        store.setStakersShare(stakers);
                        store.setGovernorsShare(govs);
                        emit SHARES_CHANGED(house, govs, stakers);
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
