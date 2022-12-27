pragma solidity ^0.8.17;

contract DeployByteCode {
    function deploy(bytes memory _bytecode) external returns (address addr) {
        assembly {
            addr := create(0, add(_bytecode, 0x20), mload(_bytecode))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}
