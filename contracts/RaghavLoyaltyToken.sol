// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Raghav Loyalty Token
/// @notice ERC20-style loyalty token used to reward users for purchases
/// @dev Simplified implementation for minting, transfers, and allowances
contract RaghavLoyaltyToken {
    /// @notice Name of the token
    string public name;

    /// @notice Symbol of the token
    string public symbol;

    /// @notice Number of decimals the token uses
    uint8 public decimals;

    /// @notice Total supply of tokens in existence
    uint256 public totalSupply;

    /// @notice Address with the highest privileges (can set minter)
    address public admin;

    /// @notice Address that is permitted to mint new tokens
    address public minter;

    /// @notice Mapping from account addresses to current balance
    mapping(address => uint256) public balanceOf;

    /// @notice Mapping from owner to spender approvals
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`)
    /// @param from Sender address
    /// @param to Recipient address
    /// @param value Amount of tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}
    /// @param owner Token owner address
    /// @param spender Spender address
    /// @param value Amount of tokens approved
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice Initializes the token with a `name`, `symbol`, and number of `decimals`
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    /// @param _decimals Number of decimal places
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        admin = msg.sender;
    }

    /// @notice Restricts access to admin or the designated minter
    modifier onlyAdminOrMinter() {
        require(msg.sender == admin || msg.sender == minter, "Unauthorized");
        _;
    }

    /// @notice Updates the address allowed to mint new tokens
    /// @param _manager Address to grant minting rights
    function updateTicketManager(address _manager) external {
        require(msg.sender == admin, "Only admin can set");
        minter = _manager;
    }

    /// @notice Creates `amount` new tokens and assigns them to `to`, increasing the total supply
    /// @dev Only callable by admin or minter
    /// @param to Receiver of the newly minted tokens
    /// @param amount Number of tokens to mint (in smallest units, considering `decimals`)
    function mint(address to, uint256 amount) external onlyAdminOrMinter {
        require(to != address(0), "Invalid address");
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @notice Transfers `amount` tokens from caller to `to`
    /// @param to Recipient address
    /// @param amount Amount of tokens to transfer
    /// @return success True if the transfer succeeded
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller’s tokens
    /// @param spender Address authorized to spend
    /// @param amount Maximum amount they can spend
    /// @return success True if approval succeeded
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens on behalf of `from` to `to`, deducting from the caller’s allowance
    /// @param from Address to send tokens from
    /// @param to Address to send tokens to
    /// @param amount Amount of tokens to transfer
    /// @return success True if the operation succeeded
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Not approved");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
