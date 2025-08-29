
### 1	Unstoppable

---
### 2	Naive receiver

functionality:  LenderPool that offer a flashloan supports meta-transactions

prep：          flash loan, EIP712, multi-call

**audit**:      access control , message data

mitigation:     

TODO: 看懂了，之后把code写上

---
### 3	Truster

functionality:  LenderPool that offer a flashloan

prep：          functionCall

**audit**:      Arbitrary External Call

mitigation:     follow ERC-3156

#### The method of invoking a function of a contract：  

 - interface invoke
 - call  ——> functionCall (OpenZeppelin)
    - abi.encodeWithSelector / abi.encodeWithSignature (create calldata, not call)
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", msg.sender, 100);
        (bool success,) = target.call(data);
 - staticcall（read only）
 - delegatecall

|           | `call`     | `delegatecall`     |
| ------------ | ---------- | ------------------ |
| context  | The called contract     | caller's contract          |
| `msg.sender` | caller's address    | Original caller's address (EOA)           |

#### Dynamic types：  
```solidity
//~ Dynamic types (bytes, string, dynamic arrays) must be 
//~ explicitly specified for data locations within the function.(storage/memory/calldata)
// Prepare the calldata to approve this contract to spend the pool's tokens
bytes memory data = abi.encodeWithSignature();
```
---
### 4	Side Entrance

functionality:  Pool allow deposit and withdraw then offer a flashloan

prep：          

**audit**:      use balance to check repay

mitigation:     

---
### 5	The Rewarder 

functionality:  Distributor token to Rewarder

prep：          Merkle,  bitmap

**audit**:      pass malicious data to function (duplication in array)

mitigation:

1. use bitmap 标记 msg.sender 的批次领取状态

```solidity
//~ q 什么是 batchNumber
    //~ 唯一标识这笔奖励属于哪个批次

//~ q 什么是 wordPosition 和 bitPosition 
    //~ 把批次编号映射到 bitmap
    
/* eg:*/
    batchNumber = 777
    wordPosition = 777 / 256 = 3
    → 落在 第 3 组（表示批次 768–1023）

    bitPosition = 777 % 256 = 9
    → 在第 3 组里的第 9 个 bit 位

    distributions[token].claims[msg.sender][3] = bitPosition(第 9 个 bit = 1)
    distributions[token].claims[msg.sender][wordPosition] = bitPosition
    
```


---
### 6	Selfie

functionality:  A pool with voting/governance tokens that offers a flashloan.

prep：          ERC-3156, ERC20Votes

**audit**:      The token that is offered to loan has some functionality.(voting/governance token)

mitigation:     

#### ERC20Votes：
Extension of ERC-20 to support Compound-like voting and delegation.
see OpenZeppelin `ERC20Votes.sol` and `Votes.sol` 

#### different ways to do flashloan：  

```solidity

 1. target.functionCall(data);

 2. ERC-3156
    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata /*_data*/
    ) external returns (bytes32)
```
---
### 7	Compromised

functionality:  A exchange selling “DVNFT” fetched price from an oracle

prep：          oracle, ERC721

**audit**:      leak private key

mitigation:     

#### safeMint：

 - `ERC721.safeMint(to, tokenId)` not only mint the NFT, but also checks whether the recipient can safely receive the NFT.
 - If the recipient is an EOA, it will succeed directly;
 - If the recipient is a contract, it must correctly implement the IERC721Receiver interface and return the standard magic value;
```solidity
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
```

---
### 8	Puppet


---
### 9	Puppet V2


---
### 10	Free Rider


---
### 11	Backdoor


---
### 12	Climber


---
### 13	Wallet Mining


---
### 14	Puppet V3


---
### 15	ABI Smuggling


---
### 16	Shards


---
### 17	Curvy Puppet


---
### 18	Withdrawal



