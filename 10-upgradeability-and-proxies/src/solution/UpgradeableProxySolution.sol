// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UUPSProxy
 * @notice Minimal UUPS proxy implementation
 */
contract UUPSProxy {
    // EIP-1967 slot for implementation address
    bytes32 private constant IMPLEMENTATION_SLOT = 
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    
    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    
    constructor(address _implementation) {
        _setImplementation(_implementation);
        _setAdmin(msg.sender);
    }
    
    function _setImplementation(address newImplementation) private {
        require(newImplementation.code.length > 0, "Not a contract");
        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }
    }
    
    function _setAdmin(address newAdmin) private {
        assembly {
            sstore(ADMIN_SLOT, newAdmin)
        }
    }
    
    function implementation() public view returns (address impl) {
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
    }
    
    function admin() public view returns (address adm) {
        assembly {
            adm := sload(ADMIN_SLOT)
        }
    }
    
    fallback() external payable {
        address impl = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}

contract ImplementationV1 {
    uint256 public value;
    
    function setValue(uint256 _value) public {
        value = _value;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}

contract ImplementationV2 {
    uint256 public value;
    
    function setValue(uint256 _value) public {
        value = _value * 2;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
    
    function newFunction() public pure returns (string memory) {
        return "This is V2";
    }
}
