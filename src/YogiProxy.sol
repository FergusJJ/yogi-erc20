// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract YogiERC20Proxy {
    address public implementation;
    address public admin;

    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }


    fallback() external {
        address _impl = implementation;
        assembly {
            // Copy call data into memory and call the implementation contract
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            // Copy the returned data into memory
            returndatacopy(0, 0, returndatasize())
            // Check if the call was successful and return the result
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    function upgradeImplementation(address _newImplementation) external onlyAdmin {
        implementation = _newImplementation;
    }

    function transferAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }
}
