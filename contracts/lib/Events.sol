// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library Events {
    event CarRegistered(uint256 indexed carId, address indexed seller);
    event CarSold(
        uint256 indexed carId,
        address indexed newOwner,
        uint256 price
    );
    event CarListed(uint256 indexed carId, uint256 price);
    event CarPriceUpdated(uint256 indexed carId, uint256 newPrice);
}
