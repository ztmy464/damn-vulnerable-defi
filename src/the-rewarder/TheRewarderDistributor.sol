// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

struct Distribution {
    uint256 remaining;
    uint256 nextBatchNumber;
    mapping(uint256 batchNumber => bytes32 root) roots;
    mapping(address claimer => mapping(uint256 word => uint256 bits)) claims;
}

struct Claim {
    uint256 batchNumber;
    uint256 amount;
    uint256 tokenIndex;
    bytes32[] proof;
}

/**
 * An efficient token distributor contract based on Merkle proofs and bitmaps
 */
contract TheRewarderDistributor {
    using BitMaps for BitMaps.BitMap;

    address public immutable owner = msg.sender;

    mapping(IERC20 token => Distribution) public distributions;

    error StillDistributing();
    error InvalidRoot();
    error AlreadyClaimed();
    error InvalidProof();
    error NotEnoughTokensToDistribute();

    event NewDistribution(IERC20 token, uint256 batchNumber, bytes32 newMerkleRoot, uint256 totalAmount);

    function getRemaining(address token) external view returns (uint256) {
        return distributions[IERC20(token)].remaining;
    }

    function getNextBatchNumber(address token) external view returns (uint256) {
        return distributions[IERC20(token)].nextBatchNumber;
    }

    function getRoot(address token, uint256 batchNumber) external view returns (bytes32) {
        return distributions[IERC20(token)].roots[batchNumber];
    }

    function createDistribution(IERC20 token, bytes32 newRoot, uint256 amount) external {
        if (amount == 0) revert NotEnoughTokensToDistribute();
        if (newRoot == bytes32(0)) revert InvalidRoot();
        if (distributions[token].remaining != 0) revert StillDistributing();

        distributions[token].remaining = amount;

        uint256 batchNumber = distributions[token].nextBatchNumber;
        distributions[token].roots[batchNumber] = newRoot;
        distributions[token].nextBatchNumber++;

        SafeTransferLib.safeTransferFrom(address(token), msg.sender, address(this), amount);

        emit NewDistribution(token, batchNumber, newRoot, amount);
    }

    function clean(IERC20[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            //~ remaining?
            if (distributions[token].remaining == 0) {
                token.transfer(owner, token.balanceOf(address(this)));
            }
        }
    }

    // Allow claiming rewards of multiple tokens in a single transaction
    function claimRewards(Claim[] memory inputClaims, IERC20[] memory inputTokens) external {
        Claim memory inputClaim;
        IERC20 token;
        uint256 bitsSet; // accumulator
        uint256 amount;
        /* 
        struct Claim {
            uint256 batchNumber;
            uint256 amount;
            uint256 tokenIndex;
            bytes32[] proof;
        }
         */
        for (uint256 i = 0; i < inputClaims.length; i++) {
            inputClaim = inputClaims[i];
            // ------------------------ use bitmap 标记 msg.sender 的批次领取状态 ---------------------------
            //~ q 什么是 batchNumber
                //~ 唯一标识这笔奖励属于哪个批次

            //~ q 什么是 wordPosition 和 bitPosition 
                //~ 把批次编号映射到 bitmap

                /* eg:
                    batchNumber = 777
                    wordPosition = 777 / 256 = 3
                    → 落在 第 3 组（表示批次 768–1023）

                    bitPosition = 777 % 256 = 9
                    → 在第 3 组里的第 9 个 bit 位

                ~   distributions[token].claims[msg.sender][3] = bitPosition(第 9 个 bit = 1)
                    distributions[token].claims[msg.sender][wordPosition] = bitPosition
                */
            uint256 wordPosition = inputClaim.batchNumber / 256;
            uint256 bitPosition = inputClaim.batchNumber % 256;

            //~ @audit multiple claims with the same token (duplication in array)
            //~ will skip this if statements and _setClaimed
            if (token != inputTokens[inputClaim.tokenIndex]) {
                if (address(token) != address(0)) {
                    if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
                }

                token = inputTokens[inputClaim.tokenIndex];
                bitsSet = 1 << bitPosition; //~ 把第 bitPosition 位设为 1
                amount = inputClaim.amount;
            } else {
                //~ 把之前已经设置过的位，和这次要设置的位合并
                bitsSet = bitsSet | (1 << bitPosition);
                amount += inputClaim.amount;
            }

            // for the last claim
            if (i == inputClaims.length - 1) {
                if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
            }

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, inputClaim.amount));
            bytes32 root = distributions[token].roots[inputClaim.batchNumber];

            if (!MerkleProof.verify(inputClaim.proof, root, leaf)) revert InvalidProof();

            inputTokens[inputClaim.tokenIndex].transfer(msg.sender, inputClaim.amount);
        }
    }
    function _setClaimed(IERC20 token, uint256 amount, uint256 wordPosition, uint256 newBits) private returns (bool) {
        uint256 currentWord = distributions[token].claims[msg.sender][wordPosition];
        //~ 说明新领取的批次和之前的批次有交集 → 已经领过
        if ((currentWord & newBits) != 0) return false;

        //~ 如何记录用户的token领取进度？如果他只领取了一半，他被标记已经领过了怎么办
        //~ 必须领取指定的amount才能通过 proof 校验 

        // update state
        distributions[token].claims[msg.sender][wordPosition] = currentWord | newBits; //~ 把之前已经设置过的位，和这次要设置的位合并
        distributions[token].remaining -= amount;

        return true;
    }
}
