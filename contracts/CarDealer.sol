// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract CarDealer is ERC721, Ownable {
    struct Car {
        uint256 id;
        string model;
        string color;
        uint256 price;
        address owner;
        address payable seller;
        bool forSale;
        address[] previousOwners;
    }

    uint256 private nextCarID;
    mapping(uint256 => Car) public cars;
    mapping(uint256 => address[]) public carHistory;
    mapping(address => uint256[]) private userCars;
    uint256[] private listedCars;
    string private baseURI;

    constructor(
        string memory _baseURI
    ) ERC721("CarNFT", "GLK") Ownable(msg.sender) {
        baseURI = _baseURI;
    }

    function registerCar(
        string memory _model,
        string memory _color,
        uint256 _price
    ) external {
        uint256 carId = nextCarID++;
        cars[carId] = Car({
            id: carId,
            model: _model,
            color: _color,
            price: _price,
            owner: msg.sender,
            seller: payable(msg.sender),
            forSale: true,
            previousOwners: new address[](0)
        });

        userCars[msg.sender].push(carId);
        listedCars.push(carId);

        _mint(msg.sender, carId);
        emit Events.CarRegistered(carId, msg.sender);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        return bytes(baseURI).length > 0 ? string.concat(baseURI) : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        try this.ownerOf(tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    function forSale(uint256 _carId, uint256 _price) external {
        if (msg.sender != cars[_carId].owner) {
            revert Errors.NotCarOwner();
        }
        if (cars[_carId].forSale) {
            revert Errors.CarAlreadyListed();
        }

        cars[_carId].forSale = true;
        cars[_carId].price = _price;

        listedCars.push(_carId);

        emit Events.CarListed(_carId, _price);
    }

    function buyCar(uint256 _carId) external payable {
        Car storage car = cars[_carId];
        if (!car.forSale) {
            revert Errors.CarNotForSale();
        }
        if (msg.value < car.price) {
            revert Errors.InsufficientFunds();
        }

        car.seller.transfer(msg.value);

        _transfer(car.owner, msg.sender, _carId);

        car.previousOwners.push(car.owner);
        carHistory[_carId].push(car.owner);

        car.owner = msg.sender;
        car.seller = payable(msg.sender);

        car.forSale = false;

        for (uint256 i = 0; i < listedCars.length; i++) {
            if (listedCars[i] == _carId) {
                listedCars[i] = listedCars[listedCars.length - 1];
                listedCars.pop();
                break;
            }
        }

        userCars[msg.sender].push(_carId);
        emit Events.CarSold(_carId, msg.sender, msg.value);
    }

    function getCarsForSale() external view returns (Car[] memory) {
        Car[] memory saleCars = new Car[](listedCars.length);
        for (uint256 i = 0; i < listedCars.length; i++) {
            saleCars[i] = cars[listedCars[i]];
        }
        return saleCars;
    }

    function getMyCars() external view returns (Car[] memory) {
        uint256[] memory myCarIds = userCars[msg.sender];
        Car[] memory myCars = new Car[](myCarIds.length);
        for (uint256 i = 0; i < myCarIds.length; i++) {
            myCars[i] = cars[myCarIds[i]];
        }
        return myCars;
    }

    function getCarHistory(
        uint256 _carId
    ) external view returns (address[] memory) {
        return carHistory[_carId];
    }
}
