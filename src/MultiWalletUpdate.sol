//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {myLibrary} from "./MyLibrary2.sol";

error SavingsWallet__IDAlreadyExists();
error SavingsWallet__NotEnoughEth();
error SavingsWallet__Failed();
error SavingsWallet__NotAuthorized();

contract SavingsWallet {
  using myLibrary for uint256;
  AggregatorV3Interface public priceFeed;

  mapping (uint256 => address) public iDtoAddress;
  mapping (uint256 => bool) private markId;
  mapping (uint256 => uint256) public iDtoBalance;
  mapping (address => uint256) public addressToId;
  uint256 private constant USD_FOR_DEPOSIT = 5;
  uint256 private constant USD_FOR_WITHDRAWAL = 100;

  constructor(address _priceFeed) {
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  function fund(uint256 _iD) public payable {
    if (msg.value.getConversionRate(priceFeed) < USD_FOR_DEPOSIT) {
      revert SavingsWallet__NotEnoughEth();
    }

    if(markId[_iD] && msg.sender != iDtoAddress[_iD]) {
      revert SavingsWallet__IDAlreadyExists();
    } else {
      markId[_iD] = true;
      iDtoAddress[_iD] = msg.sender;
    }

    addressToId[msg.sender] = _iD;
    iDtoBalance[_iD] += msg.value;
  }

  function getWalletBalance(uint256 _iD) public view returns(uint256) {
    uint256 getBalance = iDtoBalance[_iD];
    return getBalance.getConversionRate(priceFeed);
  }

  function withdraw(uint256 _iD, uint256 _amount) public payable {
    uint256 walletBalance = iDtoBalance[_iD];

    if(msg.sender != iDtoAddress[_iD]) {
      revert SavingsWallet__NotAuthorized();
    }

    if(walletBalance.getConversionRate(priceFeed) < USD_FOR_WITHDRAWAL) {
      revert("Save up to $100 before withdrawing");
    }

    if(_amount > walletBalance) {
      revert SavingsWallet__NotEnoughEth();
    }

    iDtoBalance[_iD] -= _amount;
    (bool success, ) = payable(msg.sender).call{value: _amount}("");
    if (!success) {
     revert SavingsWallet__Failed(); 
    }
  }

  /* Extra Functions*/

  function getRate(uint256 _amount) public view returns(uint256) {
    return _amount.getConversionRate(priceFeed);
  }

  function getVersion() public view returns(uint256) {
    return myLibrary.getVersion(priceFeed);
  }
  
} //0x694AA1769357215DE4FAC081bf1f309aDC325306

/*So, i started building NumiSwap while i was learning HTML, CSS and JS, a month ago.. you know, the best way to learn is by building, so since i was an aspiring full stack blockachain software dev, i decided to learn by building a DAPP, so i started cloning UniSwap frontPage, it was easy to learn tho, cus i had already learnt JAVA.. then all of a sudden while i was getting confortable, built a mini wallet that deposits and withdraws (just numbers tho 😂) then some other chat gpt task.. an idea hit me.. what if i start up my own DEX, build something unique, not in UI but in function and smart contracts that would be the fastest and efficient way of making it in this industry, so i began working, started my looking for a name. it wasnt hard, i was a seminrian, so i have a diploma in latin, so i token the latin word for "Coin" which is "Numi".. so it all came out .."Coin Swap" ❌too common, "NumiSwap" ✅ new.. 

so i change the Uniswap name to NumiSwap... used gemini to draft a logo and get the svgs, made major mods like making the logo "S" turn 180 degrees to "N" symbolizing "Numi", and then back to "S" meaning "Swap"- (happen every 3 secs after refreshing the page).. 

i then changed the header display, scales down a little when you scroll to the downside, scales up to up when you scroll back to the up side.. 

every other thing like the swap area and the TRADE EXPLORE POOL, i haven't touvhed it yet cus i haven't learnt the full integration, so i don't know how to arrange thos, thats why i dropped it and entered solidity immediately.. so once i learn integration, i'll bring it back up and continue 😎😎😎 

As for the a Unique differences, this Savings Contract is actually my first idea outside regular Swap contract and LP contract.. the more i grow and learn, the more i come up with more unique ideas
*/