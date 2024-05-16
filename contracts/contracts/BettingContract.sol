//SPDX-License-Identifier: MIT

/*******************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~ REALTIME Betting Game on L3 OP-MODE_CELESTIA CHAIN ~~~~~~~~~~~~~~~~~
      3 6 9 12 15 18 21 24 27 30 33 36
    0 2 5 8 11 14 17 20 23 26 29 32 35
      1 4 7 10 13 16 19 22 25 28 31 34
--------------------------------------------  
 <Even|Odd> ~~ <Black|Red> ~~ <1st|2nd> ~~ <1st|2nd|3rd> 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*******************************************/

/*** @notice REALTIME ON-Chain Betting on L3 OP-MODE_CELESTIA CHAIN powered by GELLATO VRF
 *** Only supports one bet (single number, black/red, even/odd, 1st/2nd or 1st/2nd/3rd of board) per spin.
 *** User places bet by calling applicable payable function, then calls spinBettingWheel(),
 *** hardcoded minimum bet of .001 ETH , winnings paid from this contract **/
/// @title Betting
/// Betting odds should prevent the House (this contract) and sponsorWallet from bankruptcy, but anyone can refill by sending ETH directly to this address.

pragma solidity >=0.8.4;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainSecurityModule.sol";


contract BettingContract  {
    uint256 public constant MIN_BET = 10000000000000; // .001 ETH
    uint256 spinCount;
    address immutable deployer;
    address payable sponsorWallet;
    bytes32 endpointId;

    uint256 public randomnumber;
 
    IMailbox inbox;
    bytes32 public lastSender;
    string public lastMessage;

    event ReceivedRandomNumber(uint32 origin, bytes32 sender, bytes message);

    IInterchainSecurityModule public interchainSecurityModule;

    function setInterchainSecurityModule(address _module) public {
        interchainSecurityModule = IInterchainSecurityModule(_module);
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external {
        lastSender = _sender;
        lastMessage = string(_message);
        bytes memory messageBytes = _message;
        uint256 randomeNumber;
        require(messageBytes.length == 32, "Message length must be 32 bytes");
            assembly {
                randomeNumber := mload(add(messageBytes, 32))
            }
        randomnumber = randomeNumber;
        emit ReceivedRandomNumber(_origin, _sender, _message);
    }

  // ~~~~~~~ ENUMS ~~~~~~~

  enum BetType {
    Color,
    Number,
    EvenOdd,
    Third,
	 Half
  }

  // ~~~~~~~ MAPPINGS ~~~~~~~

  mapping(address => bool) public userBetAColor;
  mapping(address => bool) public userBetANumber;
  mapping(address => bool) public userBetEvenOdd;
  mapping(address => bool) public userBetThird;
  mapping(address => bool) public userBetHalf;
  mapping(address => bool) public userToColor;
  mapping(address => bool) public userToEven;

  mapping(address => uint256) public userToCurrentBet;
  mapping(address => uint256) public userToSpinCount;
  mapping(address => uint256) public userToNumber;
  mapping(address => uint256) public userToThird;
  mapping(address => uint256) public userToHalf;

  mapping(bytes32 => uint256) public requestIdToSpinCount;
  mapping(bytes32 => uint256) public requestIdToResult;

  mapping(uint256 => bool) blackNumber;
  mapping(uint256 => bool) public blackSpin;
  mapping(uint256 => bool) public spinIsComplete;

  mapping(uint256 => BetType) public spinToBetType;
  mapping(uint256 => address) public spinToUser;
  mapping(uint256 => uint256) public spinResult;
  uint256 public finalNumber;

  // ~~~~~~~ ERRORS ~~~~~~~

  error HouseBalanceTooLow();
  error NoBet();
  error ReturnFailed();
  error SpinNotComplete();
  error TransferToDeployerWalletFailed();
  error TransferToSponsorWalletFailed();

  // ~~~~~~~ EVENTS ~~~~~~~

  event RequestedUint256(bytes32 requestId);
  event ReceivedUint256(bytes32 indexed requestId, uint256 response);
  event SpinComplete(bytes32 indexed requestId, uint256 indexed spinNumber, uint256 vrfResult);
  event WinningNumber(uint256 indexed spinNumber, uint256 winningNumber);

  constructor(address _inbox, address payable _sponsorWallet)  {
    sponsorWallet = _sponsorWallet;
    inbox = IMailbox(_inbox);
    deployer = msg.sender;
    blackNumber[2] = true;
    blackNumber[4] = true;
    blackNumber[6] = true;
    blackNumber[8] = true;
    blackNumber[10] = true;
    blackNumber[11] = true;
    blackNumber[13] = true;
    blackNumber[15] = true;
    blackNumber[17] = true;
    blackNumber[20] = true;
    blackNumber[22] = true;
    blackNumber[24] = true;
    blackNumber[26] = true;
    blackNumber[28] = true;
    blackNumber[29] = true;
    blackNumber[31] = true;
    blackNumber[33] = true;
    blackNumber[35] = true;
  }

  /// @notice for user to spin after bet is placed
  /// @param _spinCount the msg.sender's spin number assigned when bet placed
    function _spinBettingWheel(uint256 _spinCount) internal {
        require(!spinIsComplete[_spinCount], "spin already complete");
        require(_spinCount == userToSpinCount[msg.sender], "!= msg.sender spinCount");

        // No need for external calls, since we already have the random number
        // Directly handle the spin completion
        _spinComplete(_spinCount, randomnumber);
    }

    function _spinComplete(uint256 _spin, uint256 _vrfUint256) internal {
        require(!spinIsComplete[_spin], "spin already complete");

        spinResult[_spin] = _vrfUint256 % 37; // Ensure result is within the range [0, 36]
        spinIsComplete[_spin] = true;
        emit SpinComplete("spincomplete",_spin, spinResult[_spin]);

        // Check if any bet type has won based on the completed spin
        if (spinToBetType[_spin] == BetType.Number) {
            checkIfNumberWon(_spin);
        } else if (spinToBetType[_spin] == BetType.Color) {
            checkIfColorWon(_spin);
        } else if (spinToBetType[_spin] == BetType.EvenOdd) {
            checkIfEvenOddWon(_spin);
        } else if (spinToBetType[_spin] == BetType.Half) {
            checkIfHalfWon(_spin);
        } else if (spinToBetType[_spin] == BetType.Third) {
            checkIfThirdWon(_spin);
        }
    }

  /** @dev a failed fulfill (return 0) assigned 37 to avoid modulo problem
   *** in spinResult calculations in above functions,
   *** otherwise assigns the vrf result to the applicable spin number **/
  function _spinComplete(bytes32 _requestId, uint256 _vrfUint256) internal {
    uint256 _spin = requestIdToSpinCount[_requestId];
    if (_vrfUint256 == 0) {
      spinResult[_spin] = 37;
    } else {
      spinResult[_spin] = _vrfUint256;
    }
    spinIsComplete[_spin] = true;
    if (spinToBetType[_spin] == BetType.Number) {
      checkIfNumberWon(_spin);
    } else if (spinToBetType[_spin] == BetType.Color) {
      checkIfColorWon(_spin);
    } else if (spinToBetType[_spin] == BetType.EvenOdd) {
      checkIfEvenOddWon(_spin);
	 } else if (spinToBetType[_spin] == BetType.Half) {
		checkIfHalfWon(_spin);
    } else if (spinToBetType[_spin] == BetType.Third) {
      checkIfThirdWon(_spin);
    }
    emit SpinComplete(_requestId, _spin, spinResult[_spin]);
  }


  // to refill the "house" (address(this)) if bankrupt
  receive() external payable {}

  /// @notice for user to submit a single-number bet, which pays out 35:1 if correct after spin
  /// @param _numberBet number between 0 and 36
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinBettingWheel()
  function betNumber(uint256 _numberBet) external payable returns (uint256) {
    require(_numberBet < 37, "_numberBet is > 36");
    require(msg.value >= MIN_BET, "msg.value < MIN_BET");
    if (address(this).balance < msg.value * 35) revert HouseBalanceTooLow();
    userToCurrentBet[msg.sender] = msg.value;
    unchecked {
      ++spinCount;
    }
    userToSpinCount[msg.sender] = spinCount;
    spinToUser[spinCount] = msg.sender;
    userToNumber[msg.sender] = _numberBet;
    userBetANumber[msg.sender] = true;
    spinToBetType[spinCount] = BetType.Number;
    _spinBettingWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check number bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfNumberWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetANumber[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    if (spinResult[_spin] == 37) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] }("");
      if (!sent) revert ReturnFailed();
    } else {}
    if (userToNumber[_user] == spinResult[_spin] % 37) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 35 }("");
      if (!sent) revert HouseBalanceTooLow();
    } else {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
      (bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
      if (!sent2) revert TransferToDeployerWalletFailed();
    }
    userToCurrentBet[_user] = 0;
    userBetANumber[_user] = false;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }

  /// @notice submit bet and "1", "2", or "3" for a bet on 1st/2nd/3rd of table, which pays out 3:1 if correct after spin
  /// @param _oneThirdBet uint 1, 2, or 3 to represent first, second or third of table
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinBettingWheel()
  function betOneThird(uint256 _oneThirdBet) external payable returns (uint256) {
    require(_oneThirdBet == 1 || _oneThirdBet == 2 || _oneThirdBet == 3, "_oneThirdBet not 1 or 2 or 3");
    require(msg.value >= MIN_BET, "msg.value < MIN_BET");
    if (address(this).balance < msg.value * 3) revert HouseBalanceTooLow();
    userToCurrentBet[msg.sender] = msg.value;
    unchecked {
      ++spinCount;
    }
    spinToUser[spinCount] = msg.sender;
    userToSpinCount[msg.sender] = spinCount;
    userToThird[msg.sender] = _oneThirdBet;
    userBetThird[msg.sender] = true;
    spinToBetType[spinCount] = BetType.Third;
    _spinBettingWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check third bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfThirdWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetThird[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    uint256 _result = spinResult[_spin] % 37;
    uint256 _thirdResult;
    if (_result > 0 && _result < 13) {
      _thirdResult = 1;
    } else if (_result > 12 && _result < 25) {
      _thirdResult = 2;
    } else if (_result > 24) {
      _thirdResult = 3;
    }
    if (spinResult[_spin] == 37) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] }("");
      if (!sent) revert ReturnFailed();
    } else {}
    if (userToThird[_user] == 1 && _thirdResult == 1) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 3 }("");
      if (!sent) revert HouseBalanceTooLow();
    } else if (userToThird[_user] == 2 && _thirdResult == 2) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 3 }("");
      if (!sent) revert HouseBalanceTooLow();
    } else if (userToThird[_user] == 3 && _thirdResult == 3) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 3 }("");
      if (!sent) revert HouseBalanceTooLow();
    } else {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
      (bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
      if (!sent2) revert TransferToDeployerWalletFailed();
    }
    userToCurrentBet[_user] = 0;
    userBetThird[_user] = false;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }

  // make similar function as above for halves
    /// @notice submit bet and "1" or "2" for a bet on 1st/2nd/3rd of table, which pays out 2:1 if correct after spin
  /// @param _halfBet uint 1 or 2 to represent first or second half of table
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinBettingWheel()
  function betHalf(uint256 _halfBet) external payable returns (uint256) {
	 require(_halfBet == 1 || _halfBet == 2, "_halfBet not 1 or 2");
	 require(msg.value >= MIN_BET, "msg.value < MIN_BET");
	 if (address(this).balance < msg.value * 2) revert HouseBalanceTooLow();
	 userToCurrentBet[msg.sender] = msg.value;
	 unchecked {
		++spinCount;
	 }
	 spinToUser[spinCount] = msg.sender;
	 userToSpinCount[msg.sender] = spinCount;
	 userToHalf[msg.sender] = _halfBet;
	 userBetHalf[msg.sender] = true;
	 spinToBetType[spinCount] = BetType.Half;
	 _spinBettingWheel(spinCount);
	 return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check half bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfHalfWon(uint256 _spin) internal returns (uint256) {
	 address _user = spinToUser[_spin];
	 if (userToCurrentBet[_user] == 0) revert NoBet();
	 if (!userBetHalf[_user]) revert NoBet();
	 if (!spinIsComplete[_spin]) revert SpinNotComplete();
	 uint256 _result = spinResult[_spin] % 37;
	 uint256 _halfResult;
	 if (_result > 0 && _result < 19) {
		_halfResult = 1;
	 } else if (_result > 18) {
		_halfResult = 2;
	 }
	 if (spinResult[_spin] == 37) {
		(bool sent, ) = _user.call{ value: userToCurrentBet[_user] }("");
		if (!sent) revert ReturnFailed();
	 } else {}
	 if (userToHalf[_user] == 1 && _halfResult == 1) {
		(bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 2 }("");
		if (!sent) revert HouseBalanceTooLow();
	 } else if (userToHalf[_user] == 2 && _halfResult == 2) {
		(bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 2 }("");
		if (!sent) revert HouseBalanceTooLow();
	 } else {
		(bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
		if (!sent) revert TransferToSponsorWalletFailed();
		(bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
		if (!sent2) revert TransferToDeployerWalletFailed();
	 }
	 userToCurrentBet[_user] = 0;
	 userBetHalf[_user] = false;
	 emit WinningNumber(_spin, spinResult[_spin] % 37);
	 return (spinResult[_spin] % 37);
  }




  /** @notice for user to submit a boolean even or odd bet, which pays out 2:1 if correct
   *** reminder that a return of 0 is neither even nor odd in Betting **/
  /// @param _isEven boolean bet, true for even
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinBettingWheel()
  function betEvenOdd(bool _isEven) external payable returns (uint256) {
    require(msg.value >= MIN_BET, "msg.value < MIN_BET");
    if (address(this).balance < msg.value * 2) revert HouseBalanceTooLow();
    unchecked {
      ++spinCount;
    }
    spinToUser[spinCount] = msg.sender;
    userToCurrentBet[msg.sender] = msg.value;
    userToSpinCount[msg.sender] = spinCount;
    userBetEvenOdd[msg.sender] = true;
    if (_isEven) {
      userToEven[msg.sender] = true;
    } else {}
    spinToBetType[spinCount] = BetType.EvenOdd;
    _spinBettingWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check even/odd bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfEvenOddWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetEvenOdd[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    uint256 _result = spinResult[_spin] % 37;
    if (spinResult[_spin] == 37) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] }("");
      if (!sent) revert ReturnFailed();
    } else {}
    if (_result == 0) {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
    } else if (userToEven[_user] && (_result % 2 == 0)) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 2 }("");
      if (!sent) revert HouseBalanceTooLow();
    } else if (!userToEven[_user] && _result % 2 != 0) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 2 }("");
      if (!sent) revert HouseBalanceTooLow();
    } else {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
      (bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
      if (!sent2) revert TransferToDeployerWalletFailed();
    }
    userBetEvenOdd[_user] = false;
    userToCurrentBet[_user] = 0;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }

  /** @notice for user to submit a boolean black or red bet, which pays out 2:1 if correct
   *** reminder that 0 is neither red nor black in Betting **/
  /// @param _isBlack boolean bet, true for black, false for red
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinBettingWheel()
  function betColor(bool _isBlack) external payable returns (uint256) {
    require(msg.value >= MIN_BET, "msg.value < MIN_BET");
    if (address(this).balance < msg.value * 2) revert HouseBalanceTooLow();
    unchecked {
      ++spinCount;
    }
    spinToUser[spinCount] = msg.sender;
    userToCurrentBet[msg.sender] = msg.value;
    userToSpinCount[msg.sender] = spinCount;
    userBetAColor[msg.sender] = true;
    if (_isBlack) {
      userToColor[msg.sender] = true;
    } else {}
    spinToBetType[spinCount] = BetType.Color;
    _spinBettingWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check color bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfColorWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetAColor[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    uint256 _result = spinResult[_spin] % 37;
    if (spinResult[_spin] == 37) {
      (bool sent, ) = _user.call{ value: userToCurrentBet[_user] }("");
      if (!sent) revert ReturnFailed();
    } else if (_result == 0) {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
      (bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
      if (!sent2) revert TransferToDeployerWalletFailed();
    } else {
      if (blackNumber[_result]) {
        blackSpin[_spin] = true;
      } else {}
      if (userToColor[_user] && blackSpin[_spin]) {
        (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 2 }("");
        if (!sent) revert HouseBalanceTooLow();
      } else if (!userToColor[_user] && !blackSpin[_spin] && _result != 0) {
        (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * 2 }("");
        if (!sent) revert HouseBalanceTooLow();
      } else {
        (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
        if (!sent) revert TransferToSponsorWalletFailed();
        (bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
        if (!sent2) revert TransferToDeployerWalletFailed();
      }
    }
    userBetAColor[_user] = false;
    userToCurrentBet[_user] = 0;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }
}