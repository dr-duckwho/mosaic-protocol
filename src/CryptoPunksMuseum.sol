// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import "./ICryptoPunksGroupRegistry.sol";
import "./ICryptoPunksMosaicRegistry.sol";
import "./external/ICryptoPunksMarket.sol";

// TODO: Adopt Eternal Storage in the next phase
contract CryptoPunksMuseum is AccessControl {
    ICryptoPunksMarket public immutable cryptoPunksMarket;
    ICryptoPunksGroupRegistry public groupRegistry;
    ICryptoPunksMosaicRegistry public mosaicRegistry;
    // @dev true if and only if the Museum's configuration is done and all the registries are ready
    bool public isActive;

    constructor(address cryptoPunksMarketAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        cryptoPunksMarket = ICryptoPunksMarket(cryptoPunksMarketAddress);
    }

    function setGroupRegistry(
        address addr
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        groupRegistry = ICryptoPunksGroupRegistry(addr);
    }

    function setMosaicRegistry(
        address addr
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mosaicRegistry = ICryptoPunksMosaicRegistry(addr);
    }

    function activate() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(groupRegistry) != address(0x0) &&
                address(mosaicRegistry) != address(0x0)
        );
        mosaicRegistry.grantMintAuthority(address(groupRegistry));
        isActive = true;
    }

    function deactivate() public onlyRole(DEFAULT_ADMIN_ROLE) {
        isActive = false;
    }
}
