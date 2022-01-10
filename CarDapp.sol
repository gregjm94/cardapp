pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC721 {
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Required methods
    //function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
}

contract AccessControl {
    //     Developer Access Control for different smart contracts:

    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public devAddress = msg.sender;
    //purely exists so the deploying address takes dev rights


    //  Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// Access modifier for dev-only functionality
    modifier onlyDev() {
        require(msg.sender == devAddress);
        _;
    }

    /// Assigns a new address to act as the dev. Only available to the current dev.
    /// _newDev is The address of the new Dev
    function setDev(address _newDev) external onlyDev {
        require(_newDev != address(0));
        devAddress = _newDev;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// Called by developer to pause the contract.
    function pause() external onlyDev whenNotPaused {
        paused = true;
    }

    /// Unpauses the smart contract.
    function unpause() public onlyDev whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

// Declaring carData as AccessControl allows all functions in
// AccessControl to be inherited from AccessControl and cascade
// if another contract is declared as "is" carData.

contract carData is AccessControl {

    // Everytime a transfer occurs this event is triggered as part
    // of ERC721 Token standards.
    event Transfer(address from, address to, uint256 tokenId);

    // data structure of the car
    // unique id
    // creation time of the car
    // readyTime is for when the car is next ready for a race
    // winCount keeps track of the cars win
    // lossCount keeps track of the cars losses
    // level stores cars level - insignificant for now but could potentially be used
    // in further development for the car racing game.
    struct Car {
        uint256 id;
        //uint64 creationTime;
        //uint32 readyTime;
        uint16 winCount;
        uint16 lossCount;
        uint8 level;
        string rarity;
    }

    // 2 minutes between races is reasonable enough for now
    // In a final implementation of a game this could be

    uint32 cooldownTime = 2 minutes;

    // public array of all cars that exist on the chain
    // all created cars are stored in this publicly accessible array starting from the very first
    // to the very last.
    Car[] public cars;

    mapping (uint => address) public carToOwner; //maps a carId to an owner's address
    mapping (address => uint) ownerCarCount; //maps an owner address to cars owned

}

contract CarOwnership is carData, ERC721 {

    using SafeMath for uint256;

    mapping (uint => address) carApprovals;

    modifier onlyOwnerOf(uint _carId) {
        require(msg.sender == carToOwner[_carId]);
        _;
    }

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerCarCount[_owner];
    }

    // asks what address owns the token specified
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return carToOwner[_tokenId];
    }

    // SafeMath here stops overlow and underflow. Rather than using ++ and --
    // safemath.add(1) and safemath.sub(1) means that someone can't transfer
    // any cars if they have 0 cars as the contract will throw an error and
    // automatically revert.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownerCarCount[_to] = ownerCarCount[_to].add(1);
        ownerCarCount[msg.sender] = ownerCarCount[msg.sender].sub(1);
        carToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        carApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(carApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }

    // List all cars currently owned by the specified address
    function getCarsByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerCarCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < cars.length; i++) {
            if (carToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}

contract CarMinting is Ownable, CarOwnership {

    using SafeMath for uint256;

    uint256 public constant price = 10 finney;
    uint256 public constant auction_duration = 1 days;

    uint public creation_counter = 0;

    // create a pseudo-random number using previous blocks hash
    // @note - not the best way to generate a random number
    // as you can see the previous blockhash on the chain
    // and if you can access the creation_counter you
    // can predict roughly what the next car will be
    function randomGen(uint seed) public view returns (uint) {
        uint randNo = (uint(keccak256(blockhash(block.number-1), seed ))%100);
        return randNo;
    }

    event NewCar(uint carId, string rarity);

    function _chooseRarityCar() external {

        uint randNo = randomGen(creation_counter);
        string memory rarity;

        if (randNo <= 10) {
            rarity = "Platinum";
        } else if (randNo >= 11 && randNo <= 25){
            rarity = "Gold";
        } else if (randNo >= 26 && randNo <= 50){
            rarity = "Silver";
        } else {
            rarity = "Bronze";
        }
        creation_counter++;
        _createCar(rarity);
    }

    // At the moment any address can call this function
    // adding onlyDev modifier recommended so that only
    // the deploying address can "create" cars. This could
    // further improved upon by using time-based events
    // that trigger the creation of a new car.
    function _createCar(string _rarity) private {
        uint id = cars.push(Car(creation_counter, 0, 0, 1, _rarity)) - 1;
        carToOwner[id] = msg.sender;
        ownerCarCount[msg.sender]++;
        emit NewCar(id, _rarity);
    }

    //function createDevAuction() external onlyDev {

    //}

}

contract CarRace is CarMinting {
    uint randNonce = 0;
    uint raceVictoryProbability = 65; //65% chance of winning if challenging

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
    }

    function challenge(uint _carId, uint _targetId) external onlyOwnerOf(_carId) {
        Car storage myCar = cars[_carId];
        Car storage opponentCar = cars[_targetId];
        uint rand = randMod(100);
        if (rand <= raceVictoryProbability) {
            myCar.winCount++;
            opponentCar.lossCount++;
            //_triggerCooldown(myCar);
        } else {
            myCar.lossCount++;
            opponentCar.winCount++;
            //_triggerCooldown(myCar);
        }
    }
}

