// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainSecurityModule.sol";
import { GelatoVRFConsumerBase } from "./GelatoVRFConsumerBase.sol";

contract Gelatoxhypsender is GelatoVRFConsumerBase{

    IMailbox outbox;
    event SentMessage(uint32 destinationDomain, bytes32 recipient, string message);

    uint256 public _tokenIdCounter;
    uint256 public random;

    IInterchainSecurityModule public interchainSecurityModule;

    function setInterchainSecurityModule(address _module) public {
        interchainSecurityModule = IInterchainSecurityModule(_module);
    }

    constructor(address _outbox, address operator) {
        outbox = IMailbox(_outbox);
        _operatorAddr = operator;
    }

    function addressToBytes32(address _addr) external pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function sendString(
        uint32 _destinationDomain,
        bytes32 _recipient,
        string calldata _message
    ) external {
        uint256 quote = outbox.quoteDispatch(_destinationDomain, _recipient, bytes(_message));
        outbox.dispatch{value: quote}(_destinationDomain, _recipient, bytes(_message));
        emit SentMessage(_destinationDomain, _recipient, _message);
    }

    address public _operatorAddr; //
    bytes32 public latestRandomness;
    uint64 public lastRequestId;

    struct Request {
        uint256 requestTime;
        uint256 requestBlock;
        uint256 fulfilledTime;
        uint256 fulfilledBlock;
        uint256 randomness;
    }

    event RandomnessRequested(uint64 requestId);
    event RandomnessFulfilled(uint256 indexed nonce, Request);

    mapping(uint256 => Request) public requests;
    uint256 public nonce;

    function requestRandomness(bytes memory _data) external {
        // Add your own access control mechanism here
        lastRequestId = uint64(_requestRandomness(_data));
        emit RandomnessRequested(lastRequestId);
    }

    function setoperatoraddr(address op) public {
        _operatorAddr = op;
    }

    function _fulfillRandomness(uint256 _randomness, uint256 _requestId, bytes memory _data) internal override {
        // Ensure that this is the expected request being fulfilled
        require(lastRequestId == _requestId, "Request ID does not match the last request.");

        // Create the request record in storage
        Request storage request = requests[uint64(_requestId)];
        request.requestTime = block.timestamp;
        request.requestBlock = block.number;
        request.fulfilledTime = block.timestamp;
        request.fulfilledBlock = block.number;
        request.randomness = _randomness;

        random = uint256(_randomness) % 36;
        // Update the latest randomness and lastRequestId state variables
        latestRandomness = bytes32(_randomness); // Keep if you need bytes32, otherwise just use _randomness
        lastRequestId = uint64(_requestId);

        // Emit an event to signal that the randomness has been fulfilled
        emit RandomnessFulfilled(uint64(_requestId), request);
    }

    // Implement the _operator() function to return the operator's address
    function _operator() internal view virtual override returns (address) {
        return _operatorAddr;
    }

}
