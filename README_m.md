
### 1	Unstoppable

---
### 2	Naive receiver
pre： flash loan, EIP712, multi-call

audit：access control , message data

TODO: 看懂了，之后把code写上

---
### 3	Truster
pre： functionCall 

audit: Arbitrary External Call

mitigation: follow ERC-3156

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


---
### 5	The Rewarder 


---
### 6	Selfie


---
### 7	Compromised


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



