// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Raghav Ticket NFT
/// @notice ERC-721-style NFT representing a ticket, carrying event metadata
contract RaghavTicketNFT {
    /// @notice Name of the NFT collection
    string public name;

    /// @notice Symbol of the NFT collection
    string public symbol;

    /// @notice Address with admin privileges
    address public admin;

    /// @notice Address permitted to mint new ticket NFTs
    address public NFTminter;

    /// @notice Data stored for each ticket NFT
    struct TicketData {
        uint256 eventId;
        string eventName;
        uint256 eventStartDate;
        uint256 eventEndDate;
        string seat;
    }

    /// @notice Next token ID to be minted
    uint256 public nextId = 1;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public ownerOf;

    /// @notice Mapping from owner address to token count
    mapping(address => uint256) public balanceOf;

    /// @notice Mapping from token ID to its TicketData
    mapping(uint256 => TicketData) public ticketInfo;

    /// @notice Mapping from token ID to approved address
    mapping(uint256 => address) public approved;

    /// @notice Emitted when a token is transferred, including zero value transfers
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @notice Emitted when the approved address for a token is changed
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @notice Initializes the NFT collection with a `name` and `symbol`
    /// @param _name Name of the NFT collection
    /// @param _symbol Symbol of the NFT collection
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        admin = msg.sender;
    }

    /// @notice Restricts access to admin or the designated NFTminter
    modifier onlyAdminOrMinter() {
        require(msg.sender == admin || msg.sender == NFTminter, "Unauthorized");
        _;
    }

    /// @notice Updates the address permitted to mint new ticket NFTs
    /// @param _manager New NFT minter address
    function updateTicketManager(address _manager) external {
        require(msg.sender == admin, "Only admin can set");
        NFTminter = _manager;
    }

    /// @notice Mints a new ticket NFT carrying event metadata
    /// @dev Only callable by admin or NFTminter
    /// @param to Recipient of the NFT
    /// @param eventId ID of the associated event
    /// @param eventName Name of the event
    /// @param eventStartDate Unix timestamp when the event starts
    /// @param eventEndDate Unix timestamp when the event ends
    /// @param seat Seat identifier string
    /// @return tokenId The newly minted token ID
    function mint(
        address to,
        uint256 eventId,
        string memory eventName,
        uint256 eventStartDate,
        uint256 eventEndDate,
        string memory seat
    ) external onlyAdminOrMinter returns (uint256 tokenId) {
        require(to != address(0), "Cannot mint to zero address");

        tokenId = nextId++;
        ownerOf[tokenId] = to;
        balanceOf[to]++;
        ticketInfo[tokenId] = TicketData(
            eventId,
            eventName,
            eventStartDate,
            eventEndDate,
            seat
        );
        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Transfers `tokenId` from caller to `to`
    /// @param to Recipient address
    /// @param tokenId ID of the token to transfer
    function transfer(address to, uint256 tokenId) external {
        transferFrom(msg.sender, to, tokenId);
    }

    /// @notice Transfers `tokenId` from `from` to `to`, if approved or owner
    /// @param from Current owner of the token
    /// @param to Recipient address
    /// @param tokenId ID of the token
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == from, "Not owner");
        require(
            msg.sender == from || approved[tokenId] == msg.sender,
            "Not authorized"
        );
        ownerOf[tokenId] = to;
        balanceOf[from]--;
        balanceOf[to]++;
        approved[tokenId] = address(0);
        emit Transfer(from, to, tokenId);
    }

    /// @notice Approves `to` to transfer `tokenId`
    /// @param to Address to be approved
    /// @param tokenId ID of the token
    function approve(address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == msg.sender, "Not owner");
        approved[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    /// @notice Returns the list of token IDs owned by `wallet`
    /// @param wallet Address to query
    /// @return result Array of token IDs owned by `wallet`
    function getOwnedTokenIds(
        address wallet
    ) external view returns (uint256[] memory result) {
        uint256 ownedCount = balanceOf[wallet];
        result = new uint256[](ownedCount);
        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId < nextId; tokenId++) {
            if (ownerOf[tokenId] == wallet) {
                result[index++] = tokenId;
                if (index == ownedCount) break;
            }
        }
    }
}
