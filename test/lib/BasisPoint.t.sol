// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import "../../src/lib/BasisPoint.sol";

contract BasisPointTest is Test {
    function test_calculateBasisPoint() public {
        // given
        uint256 amount = 10000;
        uint256 bps = 37 * 100; // 37%

        // then
        uint256 actual = BasisPoint.calculateBasisPoint(amount, bps);
        assertEq(actual, 3700);
    }
}
