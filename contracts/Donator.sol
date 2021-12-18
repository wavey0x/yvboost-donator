pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IVault {
    function withdraw(uint256, address) external view returns (uint256);
}

contract Donator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Donated(uint256 amountBunred, uint256 amountDonated);

    address public governance;
    address public pendingGovernance;
    uint256 public lastDonateTime;
    uint256 public donateInterval;
    uint256 public maxBurnAmount;
    uint256 public yvBoost;

    constructor() public {
        governance = address(0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7);
        donateInterval = 60 * 60 * 24 * 2;
        maxBurnAmount = 50_000e18;
    }

    function canDonate() public view returns (bool) {
        return block.timestamp > lastDonateTime.add(donateInterval);
    }

    function donate() public {
        require(canDonate(), "Too soon");
        require(IERC20(yvBoost).balanceOf(address(this)) > 0, "Nothing to donate");
        uint256 amountDonated = IVault(yvBoost).withdraw(maxBurnAmount, address(yvBoost));
        emit Donated(maxBurnAmount, amountDonated);
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
        require(msg.sender == governance,"!authorized");
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }
}