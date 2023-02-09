// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BasisPoint {
    // 10,000 basis points (bps) = 100%
    uint256 public constant WHOLE_BPS = 10_000;

    function calculateBasisPoint(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        // Minimal precision
        require((amount * basisPoints) >= WHOLE_BPS);
        return (amount * basisPoints) / WHOLE_BPS;
    }
}
