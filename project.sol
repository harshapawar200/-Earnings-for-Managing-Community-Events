// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommunityEventEarnings {

    address public owner;
    uint256 public rewardPerEvent;
    uint256 public eventIdCounter;

    struct Event {
        uint256 eventId;
        address manager;
        string eventName;
        uint256 participantCount;
        bool isCompleted;
    }

    mapping(uint256 => Event) public events;
    mapping(address => uint256) public balances;

    event EventCreated(uint256 eventId, address indexed manager, string eventName);
    event EventCompleted(uint256 eventId, address indexed manager, uint256 reward);
    event ParticipantJoined(uint256 eventId, address indexed participant);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this.");
        _;
    }

    modifier onlyManager(uint256 eventId) {
        require(events[eventId].manager == msg.sender, "Only the event manager can execute this.");
        _;
    }

    modifier eventExists(uint256 eventId) {
        require(events[eventId].manager != address(0), "Event does not exist.");
        _;
    }

    constructor(uint256 _rewardPerEvent) {
        owner = msg.sender;
        rewardPerEvent = _rewardPerEvent;
        eventIdCounter = 1;  // Starting event ID from 1
    }

    // Create a new community event
    function createEvent(string memory _eventName) public {
        uint256 newEventId = eventIdCounter;
        events[newEventId] = Event({
            eventId: newEventId,
            manager: msg.sender,
            eventName: _eventName,
            participantCount: 0,
            isCompleted: false
        });
        eventIdCounter++;

        emit EventCreated(newEventId, msg.sender, _eventName);
    }

    // Add a participant to the event
    function joinEvent(uint256 eventId) public eventExists(eventId) {
        require(!events[eventId].isCompleted, "Event already completed.");
        
        events[eventId].participantCount++;
        emit ParticipantJoined(eventId, msg.sender);
    }

    // Mark event as completed and reward the manager
    function completeEvent(uint256 eventId) public onlyManager(eventId) eventExists(eventId) {
        require(!events[eventId].isCompleted, "Event already completed.");
        
        events[eventId].isCompleted = true;
        uint256 reward = rewardPerEvent;
        balances[msg.sender] += reward;

        emit EventCompleted(eventId, msg.sender, reward);
    }

    // Withdraw earnings for managing events
    function withdrawEarnings() public {
        uint256 earnings = balances[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(earnings);
    }

    // Deposit funds into the contract to reward managers
    function depositFunds() public payable onlyOwner {
        require(msg.value > 0, "Must deposit some Ether.");
    }

    // View balance of the manager (or any address)
    function viewBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
