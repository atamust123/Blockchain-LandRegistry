pragma solidity ^0.4.25;

import {ecdsa} from  'ecdsa.sol';

//using ecdsa for bytes32;

contract land{
    
    struct Land{
        uint area;
        string location;
        string addr;
        uint id;
        uint price;
        uint percentage;
        mapping(address=>uint) shareOwned;
        bool verificationStatus;
    }
    
    struct Manager{
        address managerAddress;
        uint id;
        string name;
        uint salary;
    }
    
    struct User{
        address userAddress;
        uint balance;
        string homeAddress;
        string telefonNumber;
        string nameSurname;
        string dateOfbirth;
        string ssn;
        Land[] ownedLand;
    }
    
    modifier onlyManager(){
        require(manager.managerAddress == msg.sender);
        _;
    }
    
    modifier onlyUser(){
        require(users[msg.sender].userAddress != address(0));
        _;
    }
    
    uint fee;
    uint purchasingTime;
    uint offerTime;
    uint contractBalance;
   
    Manager manager;
    mapping(address=>User) users;
    Land[] lands;
    bytes32 private sellerHashMessage;
    bytes32 private buyerHashMessage;
    
    constructor(string _name, uint _id){
        fee = 10 ether;
        purchasingTime = 10 minutes;
        manager.managerAddress = msg.sender;
        manager.name = _name;
        manager.id = _id;
        
    }
    
    function join(string _home,string _telephone,string _name,string _birth, string _ssn,Land[] _myLand) public payable{
        users[msg.sender] = User(msg.sender, msg.value, _home, _telephone, _name, _birth, _ssn, _myLand);
        contractBalance += fee;
        users[msg.sender].balance -= fee;
    }
    
    function selling(uint _id,uint _percentage,uint _price,uint _index) onlyUser public{
        offerTime = now;
        lands.push(Land(_id, _percentage, _price, users[msg.sender].ownedLand[_index]));
        const messageHash = web3.sha3("approved by seller");
        const signature = await web3.eth.personal.sign(messageHash, web3.eth.defaultAccount);
        sellerHashMessage = signature;
    }
    
    function buying(uint _id,uint _price) onlyUser public payable{
        require(users[msg.sender].balance >= _price);
        for (int i = 0; i < lands.size(); i++){
            if ( lands[i].id == _id){
                const messageHash = web3.sha3("approved by buyer");
                const signature = await web3.eth.personal.sign(messageHash, web3.eth.defaultAccount);
                buyerHashMessage = signature;
            }
        }
    }
    
    function verification (address _addressOfSeller,address _addressOfBuyer,uint _index,uint _price, uint _percentage, bytes _signatureOfSeller, 
    bytes _signatureOfBuyer) onlyManager public payable{
        require(offerTime <= purchasingTime);
        bytes32 hashSeller = keccak256(abi.encodePacked(uint256(_addressOfSeller)));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        bytes32 hashBuyer = keccak256(abi.encodePacked(uint256(_addressOfBuyer)));
        
        address signerSeller = messageHash.recover(_signatureOfSeller);
        address signerBuyer = messageHash.recover(_signatureOfBuyer);
        require(signerSeller == _addressOfSeller);
        require(signerBuyer == _signatureOfBuyer);
        
        users[_addressOfSeller].ownedLand[_index].shareOwned[_addressOfSeller] -= _percentage;
        users[_addressOfBuyer].ownedLand.push(users[_addressOfSeller].ownedLand[_index]);
        users[_addressOfBuyer].ownedLand[_index].shareOwned[_addressOfBuyer] += _percentage;
        
        users[_addressOfSeller].balance += _price;
        users[_addressOfBuyer].balance -= _price;
        
    }
    
    function() external{
        revert();
    }
}