// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        // ------------------ @audit-issue Arbitrary External Call ------------------
        //~ unlimited target
        //~ set target = token, call `approval` to leave a backdoor 
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        return true;
    }

    // ------------------------- mitigation: ERC-3156 -------------------------
    //~ The borrower must be a contract that Implements IERC3156FlashBorrower.
/*     
    function flashLoan(IERC3156FlashBorrower receiver, uint256 amount, bytes calldata data) 
    external 
    returns (bool) 
    {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transfer(address(receiver), amount);

        require(
            receiver.onFlashLoan(msg.sender, token, amount, 0, data) == keccak256("ERC3156FlashBorrower.onFlashLoan"),
            "Invalid return value"
        );

        require(token.balanceOf(address(this)) >= balanceBefore, "Repay failed");
        return true;
    }
 */
}
