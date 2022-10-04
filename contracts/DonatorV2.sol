pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

interface IStrategy {
    function vault() external returns (address);
}

contract Donator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Donated(address strategy, uint256 amount);

    address internal constant YCRV = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b;
    address public governance;
    address public management;
    address public strategy;
    address public pendingGovernance;
    uint256 public donateAmount;
    uint256 public donateInterval;
    uint256 public lastDonateTime;
    bool public donationsPaused;

    constructor() public {
        governance = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
        management = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;
        strategy = 0xE7863292dd8eE5d215eC6D75ac00911D06E59B2d;
        donateInterval = 60 * 60 * 24 * 2;
    }
    
    /// @notice check if enough time has elapsed since our last donation
    function canDonate() public view returns (bool) {
        return (
            !donationsPaused &&
            block.timestamp > lastDonateTime.add(donateInterval)
        );
    }
    
    function donate() external {
        address _strategy = strategy;
        requires(msg.sender == _strategy, "!Strategy");
        require(canDonate(), "Can't Donate");
        uint256 balance = IERC20(YCRV).balanceOf(address(this));
        if (balance == 0) return;
        uint256 amountDonated = IERC20(YCRV).transfer(_strategy, Math.min(balance, donateAmount));
        lastDonateTime = block.timestamp;
        emit Donated(_strategy, amountDonated);
    }
    
    function setDonateAmount(uint256 _donateAmount) public {
        require(msg.sender == governance, "!authorized");
        donateAmount = _donateAmount;
    }

    function setPaused(bool _paused) public {
        require(msg.sender == governance || msg.sender == management, "!authorized");
        donationsPaused = _paused;
    }
    
    function setDonateInterval(uint256 _donateInterval) public {
        require(msg.sender == governance, "!authorized");
        donateInterval = _donateInterval;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!authorized");
        pendingGovernance = _governance;
    }

    function setManagement(address _management) external {
        require(msg.sender == governance, "!authorized");
        management = _management;
    }

    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!authorized");
        require(IStrategy(_strategy).vault() != address(0), "invalidStrategy");
        strategy = _strategy;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!authorized");
        governance = pendingGovernance;
    }
    
    /// @notice sweep function in case anyone sends random tokens here or we need to rescue yvBOOST
    function sweep(address _token) external {
        require(msg.sender == governance, "!authorized");
        uint bal = IERC20(_token).balanceOf(address(this));
        SafeERC20(_token).safeTransfer(address(governance), bal);
    }
}
