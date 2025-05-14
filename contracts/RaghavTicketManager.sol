// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for Loyalty Token Minting
interface ILoyaltyToken {
    /// @notice Mints loyalty tokens to a user
    /// @param to Recipient address
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external;
}

/// @title Interface for Ticket NFT Minting
interface ITicketNFT {
    /// @notice Mints a Ticket NFT with event metadata
    /// @param to Recipient address
    /// @param eventId ID of the event
    /// @param eventName Name of the event
    /// @param eventStartDate Start timestamp of the event
    /// @param eventEndDate End timestamp of the event
    /// @param seat Seat identifier
    /// @return tokenId Newly minted NFT ID
    function mint(
        address to,
        uint256 eventId,
        string memory eventName,
        uint256 eventStartDate,
        uint256 eventEndDate,
        string memory seat
    ) external returns (uint256);
}

/// @title Raghav Ticket Manager
/// @notice Handles event creation, ticket purchases, and issues loyalty rewards
contract RaghavTicketManager {
    /// @notice Address with admin privileges
    address public admin;

    /// @notice Loyalty token used for rewards
    ILoyaltyToken public loyaltyToken;

    /// @notice Ticket NFT contract
    ITicketNFT public ticketNFT;

    /// @notice Next event ID to be assigned
    uint256 public nextEventId = 1;

    /// @notice Event data structure
    struct Event {
        string eventName;
        uint256 eventStartDate;
        uint256 eventEndDate;
        uint256 ticketPrice;
        uint256 rewardAmount;
        uint256 totalTickets;
        uint256 ticketsSold;
    }

    /// @notice Mapping from event ID to Event details
    mapping(uint256 => Event) public eventId;

    /// @notice Emitted when a new event is created
    event EventCreated(
        uint256 indexed eventId,
        string name,
        uint256 startDate,
        uint256 endDate,
        uint256 price,
        uint256 reward,
        uint256 totalTickets
    );

    /// @notice Emitted when tickets are purchased
    event TicketPurchased(
        address indexed buyer,
        uint256 indexed eventId,
        uint256 count,
        uint256 amountPaid
    );

    /// @notice Emitted when ticket price of an event is updated
    event TicketPriceUpdated(uint256 indexed eventId, uint256 newPrice);

    /// @notice Emitted when reward amount of an event is updated
    event RewardAmountUpdated(uint256 indexed eventId, uint256 newReward);

    /// @notice Ensures only admin can call
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /// @notice Initializes the manager with loyalty token and ticket NFT contracts
    /// @param _loyaltyToken Address of the loyalty token contract
    /// @param _ticketNFT Address of the ticket NFT contract
    constructor(address _loyaltyToken, address _ticketNFT) {
        admin = msg.sender;
        loyaltyToken = ILoyaltyToken(_loyaltyToken);
        ticketNFT = ITicketNFT(_ticketNFT);
    }

    /// @notice Creates a new event
    /// @param name Name of the event
    /// @param startDate Unix timestamp for when event starts
    /// @param endDate Unix timestamp for when event ends
    /// @param price Price per ticket (in wei)
    /// @param reward Loyalty tokens rewarded per ticket
    /// @param totalTickets Total number of tickets available
    /// @return eid ID assigned to the newly created event
    function createEvent(
        string memory name,
        uint256 startDate,
        uint256 endDate,
        uint256 price,
        uint256 reward,
        uint256 totalTickets
    ) external onlyAdmin returns (uint256 eid) {
        require(totalTickets > 0, "Total tickets must be > 0");
        require(startDate < endDate, "Start must be before end");
        require(
            startDate > block.timestamp,
            "Start date must be in the future"
        );

        eid = nextEventId++;
        eventId[eid] = Event(
            name,
            startDate,
            endDate,
            price,
            reward,
            totalTickets,
            0
        );
        emit EventCreated(
            eid,
            name,
            startDate,
            endDate,
            price,
            reward,
            totalTickets
        );
    }

    /// @notice Updates the price of an existing event
    /// @param eid ID of the event to update
    /// @param newPrice New price per ticket (in wei)
    function updatePrice(uint256 eid, uint256 newPrice) external onlyAdmin {
        require(eventId[eid].eventStartDate != 0, "Event does not exist");
        eventId[eid].ticketPrice = newPrice;
        emit TicketPriceUpdated(eid, newPrice);
    }

    /// @notice Updates the loyalty reward amount for an event
    /// @param eid ID of the event to update
    /// @param newReward New loyalty tokens rewarded per ticket
    function updateReward(uint256 eid, uint256 newReward) external onlyAdmin {
        require(eventId[eid].eventStartDate != 0, "Event does not exist");
        eventId[eid].rewardAmount = newReward;
        emit RewardAmountUpdated(eid, newReward);
    }

    /// @notice Purchases `ticketCount` tickets for event `eid`
    /// @param eid ID of the event
    /// @param ticketCount Number of tickets to purchase (1–10)
    /// @param paymentAmount Amount of wei sent by the buyer (must equal price * count)
    function purchaseTicket(
        uint256 eid,
        uint256 ticketCount,
        uint256 paymentAmount
    ) external {
        require(
            ticketCount > 0 && ticketCount <= 10,
            "You can book 1-10 tickets"
        );

        Event storage evt = eventId[eid];
        require(evt.eventStartDate != 0, "Event not found");
        require(block.timestamp < evt.eventEndDate, "Event is over");
        require(
            evt.ticketsSold + ticketCount <= evt.totalTickets,
            "Not enough tickets"
        );

        uint256 totalCost = ticketCount * evt.ticketPrice;
        require(paymentAmount == totalCost, "Incorrect payment");

        for (uint256 i = 1; i <= ticketCount; i++) {
            evt.ticketsSold++;
            string memory seat = string(
                abi.encodePacked("Seat-", _uintToStr(evt.ticketsSold))
            );
            ticketNFT.mint(
                msg.sender,
                eid,
                evt.eventName,
                evt.eventStartDate,
                evt.eventEndDate,
                seat
            );
        }

        loyaltyToken.mint(msg.sender, ticketCount * evt.rewardAmount);
        emit TicketPurchased(msg.sender, eid, ticketCount, totalCost);
    }

    /// @dev Converts a uint256 to its ASCII string decimal representation
    /// @param v Value to convert
    /// @return str String representation
    function _uintToStr(uint256 v) internal pure returns (string memory str) {
        if (v == 0) return "0";
        uint256 j = v;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = v;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }
}
