// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Bylaws.sol";
import "./Payment.sol";
import "./PermissionManagment.sol";
import "./Executor.sol";
import "./Tithe.sol";

contract DAC is
    ERC20,
    Bylaws,
    Payment,
    PermissionManagment,
    ReentrancyGuard,
    Executor,
    Tithe
{
    using Math for uint256;

    address public currentCEO;
    uint256 public electionThreshold;
    uint256 public votingPeriod;
    uint256 public minParticipationRate;
    bool public electionInProgress;

    struct Election {
        uint256 startTime;
        uint256 endTime;
        mapping(address => uint256) votes;
        mapping(address => bool) hasVoted;
        address[] candidates;
        uint256 totalVotes;
        bool concluded;
        mapping(address => uint256) voterSnapshots;
    }

    Election private currentElection;

    event ElectionCalled(uint256 startTime, uint256 endTime);
    event VoteCast(
        address indexed voter,
        address indexed candidate,
        uint256 votes
    );
    event ElectionConcluded(address newCEO);
    event ElectionCancelled(string reason);
    event CandidateNominated(address candidate);

    uint256 private constant POINT_MULTIPLIER = 1e18;
    uint256 private totalDividendPoints;
    uint256 private totalDividendsDistributed;
    uint256 private unclaimedDividends;
    mapping(address => uint256) private lastDividendPoints;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        string memory initialBylawsUrl,
        uint256 _electionThreshold,
        uint256 _votingPeriod,
        uint256 _minParticipationRate,
        address _titheBeneficiary,
        uint256 _tithePercentage,
        address _initialCEO
    )
        ERC20(name, symbol)
        Bylaws(initialBylawsUrl)
        Tithe(_titheBeneficiary, _tithePercentage)
    {
        require(
            _electionThreshold > 0 && _electionThreshold <= 100,
            "Invalid election threshold"
        );
        require(_votingPeriod > 0, "Invalid voting period");
        require(
            _minParticipationRate > 0 && _minParticipationRate <= 100,
            "Invalid participation rate"
        );

        _mint(msg.sender, initialSupply);
        currentCEO = _initialCEO;

        _grantPermission(currentCEO, PermissionType.TREASURY);
        _grantPermission(currentCEO, PermissionType.CONTENT);

        electionThreshold = _electionThreshold;
        votingPeriod = _votingPeriod;
        minParticipationRate = _minParticipationRate;
    }

    function callForElection() public virtual {
        require(!electionInProgress, "Election already in progress");
        require(
            balanceOf(msg.sender) >= (totalSupply() * electionThreshold) / 100,
            "Insufficient tokens to call election"
        );

        electionInProgress = true;
        currentElection.startTime = block.timestamp;
        currentElection.endTime = block.timestamp + votingPeriod;
        currentElection.concluded = false;
        currentElection.totalVotes = 0;

        emit ElectionCalled(currentElection.startTime, currentElection.endTime);
    }

    function isCandidate(address candidate) public view virtual returns (bool) {
        for (uint256 i = 0; i < currentElection.candidates.length; i++) {
            if (currentElection.candidates[i] == candidate) {
                return true;
            }
        }
        return false;
    }

    function nominate(address candidate) public virtual {
        require(electionInProgress, "No election in progress");
        require(
            block.timestamp < currentElection.endTime,
            "Nomination period has ended"
        );
        require(candidate != address(0), "Invalid candidate address");
        require(!isCandidate(candidate), "Candidate already nominated");

        currentElection.candidates.push(candidate);

        emit CandidateNominated(candidate);
    }

    function vote(address candidate) public virtual nonReentrant {
        require(electionInProgress, "No election in progress");
        require(
            block.timestamp >= currentElection.startTime &&
                block.timestamp <= currentElection.endTime,
            "Not within voting period"
        );
        require(isCandidate(candidate), "Invalid candidate");
        require(!currentElection.hasVoted[msg.sender], "Already voted");

        uint256 voterBalance = balanceOf(msg.sender);
        require(voterBalance > 0, "No voting power");

        // Snapshot the voter's balance
        currentElection.voterSnapshots[msg.sender] = voterBalance;

        currentElection.votes[candidate] =
            currentElection.votes[candidate] +
            voterBalance;

        currentElection.totalVotes = currentElection.totalVotes + voterBalance;

        currentElection.hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, candidate, voterBalance);

        // Automatically conclude the election if the voting period has ended
        if (block.timestamp > currentElection.endTime) {
            concludeElection();
        }
    }

    function concludeElection() public virtual {
        require(electionInProgress, "No election in progress");
        require(
            block.timestamp > currentElection.endTime,
            "Voting period not ended"
        );
        require(!currentElection.concluded, "Election already concluded");

        uint256 participationRate = (currentElection.totalVotes * (100)) /
            totalSupply();

        if (participationRate < minParticipationRate) {
            cancelElection("Minimum participation threshold not met");
            return;
        }

        address winningCandidate = getWinningCandidate();
        require(winningCandidate != address(0), "No valid winner");

        currentElection.concluded = true;
        electionInProgress = false;
        currentCEO = winningCandidate;

        emit ElectionConcluded(currentCEO);
    }

    function cancelElection(string memory reason) internal virtual {
        electionInProgress = false;
        currentElection.concluded = true;
        emit ElectionCancelled(reason);
    }

    function getWinningCandidate() public view virtual returns (address) {
        require(electionInProgress, "No election in progress");

        address winningCandidate;
        uint256 winningVotes = 0;

        for (uint256 i = 0; i < currentElection.candidates.length; i++) {
            address candidate = currentElection.candidates[i];
            uint256 votes = currentElection.votes[candidate];
            if (votes > winningVotes) {
                winningCandidate = candidate;
                winningVotes = votes;
            }
        }

        return winningCandidate;
    }

    function canVote(address account) public view virtual returns (bool) {
        return
            electionInProgress &&
            !currentElection.hasVoted[account] &&
            balanceOf(account) > 0 &&
            block.timestamp <= currentElection.endTime;
    }

    function setTithe(
        address _beneficiary,
        uint256 _percentage
    ) public override onlyWithPermission(PermissionType.TREASURY) {
        super.setTithe(_beneficiary, _percentage);
    }

    modifier onlyCEO() {
        require(msg.sender == currentCEO, "Caller is not the CEO");
        _;
    }

    function setBylaws(string memory _arweaveUrl) public override onlyCEO {
        super.setBylaws(_arweaveUrl);
    }

    function sendPayment(
        address recipient,
        uint256 amount,
        string memory memo
    ) public override onlyWithPermission(PermissionType.TREASURY) {
        super.sendPayment(recipient, amount, memo);
    }

    function receivePayment(
        string calldata description
    ) public payable override {
        emit PaymentReceived(msg.sender, msg.value, description);

        if (msg.value > 0) {
            uint256 titheAmount = (msg.value * tithePercentage) / 100;
            if (titheAmount > 0) {
                (bool success, ) = payable(beneficiary).call{
                    value: titheAmount
                }("");
                require(success, "Failed to transfer tithe");
                emit TithePaid(beneficiary, titheAmount);
            }
        }
    }

    function grantPermission(
        address user,
        string memory permission
    ) public onlyCEO {
        PermissionType permType = stringToPermission(permission);
        _grantPermission(user, permType);
    }

    function revokePermission(
        address user,
        string memory permission
    ) public onlyCEO {
        PermissionType permType = stringToPermission(permission);
        _revokePermission(user, permType);
    }

    function revokeAllPermissions(address user) public onlyCEO {
        _revokeAllPermissions(user);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        bool isDelegateCall,
        uint256 txGas,
        string memory memo
    )
        public
        payable
        override
        onlyWithPermission(PermissionType.TREASURY)
        returns (bool)
    {
        return super.execute(to, value, data, isDelegateCall, txGas, memo);
    }

    function dividendsOwing(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDividendPoints -
            lastDividendPoints[account];
        return (balanceOf(account) * newDividendPoints) / POINT_MULTIPLIER;
    }

    function disburse(
        uint256 amount
    ) public onlyWithPermission(PermissionType.TREASURY) {
        require(totalSupply() > 0, "Cannot disburse with zero total supply");
        require(amount > 0, "Must disburse a positive amount");
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );

        totalDividendPoints += (amount * POINT_MULTIPLIER) / totalSupply();
        totalDividendsDistributed += amount;
    }

    function withdrawDividends() public nonReentrant {
        uint256 owing = dividendsOwing(msg.sender);
        require(owing > 0, "No dividends to withdraw");

        lastDividendPoints[msg.sender] = totalDividendPoints;

        (bool success, ) = payable(msg.sender).call{value: owing}("");
        require(success, "ETH transfer failed");

        totalDividendsDistributed -= owing;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function accumulatedDividends(
        address account
    ) public view returns (uint256) {
        return dividendsOwing(account);
    }

    function totalUnclaimedDividends() public view returns (uint256) {
        return unclaimedDividends;
    }

    receive() external payable {}
}
