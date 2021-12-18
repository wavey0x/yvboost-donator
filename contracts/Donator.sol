pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IVault {
    function withdraw(uint256, address, uint256) external returns (uint256);
}

import "@openzeppelin/contracts/math/Math.sol";

contract Donator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Donated(uint256 amountBurned, uint256 amountDonated);

    address public governance;
    address public pendingGovernance;
    uint256 public donateInterval;
    uint256 public maxBurnAmount;
    uint256 public lastDonateTime;
    address internal constant yvBoost = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;

    constructor() public {
        governance = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;
        donateInterval = 60 * 60 * 24 * 2;
        maxBurnAmount = 50_000e18;
    }

    function canDonate() public view returns (bool) {
        return block.timestamp > lastDonateTime.add(donateInterval);
    }

    function donate() external {
        require(canDonate(), "Too soon");
        uint256 balance = IERC20(yvBoost).balanceOf(address(this));
        require(balance > 0, "Nothing to donate");
        uint256 toBurn = Math.min(balance, maxBurnAmount);
        uint256 amountDonated = IVault(yvBoost).withdraw(toBurn, yvBoost, 0);
        lastDonateTime = block.timestamp;
        emit Donated(toBurn, amountDonated);
    }

    function setMaxBurnAmount(uint256 _maxBurnAmount) public {
        require(msg.sender == governance,"!authorized");
        maxBurnAmount = _maxBurnAmount;
    }

    function setDonateInterval(uint256 _donateInterval) public {
        require(msg.sender == governance, "!authorized");
        donateInterval = _donateInterval;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!authorized");
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!authorized");
        governance = pendingGovernance;
    }

    function sweep(address _token) external {
        require(msg.sender == governance, "!authorized");
        IERC20(_token).safeTransfer(address(governance), IERC20(_token).balanceOf(address(this)));
    }
}
