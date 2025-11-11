// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC777Recipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC777Sender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

/**
 * @title ERC777AdvancedTokenSolution
 * @notice Complete ERC-777 implementation with hooks and operators
 */
contract ERC777AdvancedTokenSolution {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public granularity = 1;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => bool)) public isOperatorFor;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address[] private _defaultOperators;
    mapping(address => bool) private _isDefaultOperator;
    
    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address[] memory defaultOperators_
    ) {
        name = _name;
        symbol = _symbol;
        
        _defaultOperators = defaultOperators_;
        for (uint i = 0; i < defaultOperators_.length; i++) {
            _isDefaultOperator[defaultOperators_[i]] = true;
        }
        
        _mint(msg.sender, _initialSupply, "", "");
    }
    
    function send(address to, uint256 amount, bytes calldata data) external {
        _send(msg.sender, msg.sender, to, amount, data, "");
    }
    
    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        require(isOperatorFor[msg.sender][from] || _isDefaultOperator[msg.sender], "Not an operator");
        _send(msg.sender, from, to, amount, data, operatorData);
    }
    
    function burn(uint256 amount, bytes calldata data) external {
        _burn(msg.sender, msg.sender, amount, data, "");
    }
    
    function operatorBurn(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
        require(isOperatorFor[msg.sender][from] || _isDefaultOperator[msg.sender], "Not an operator");
        _burn(msg.sender, from, amount, data, operatorData);
    }
    
    function authorizeOperator(address operator) external {
        require(msg.sender != operator, "Cannot authorize self");
        isOperatorFor[operator][msg.sender] = true;
        emit AuthorizedOperator(operator, msg.sender);
    }
    
    function revokeOperator(address operator) external {
        require(msg.sender != operator, "Cannot revoke self");
        isOperatorFor[operator][msg.sender] = false;
        emit RevokedOperator(operator, msg.sender);
    }
    
    function defaultOperators() public view returns (address[] memory) {
        return _defaultOperators;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _send(msg.sender, msg.sender, to, amount, "", "");
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        allowance[from][msg.sender] -= amount;
        _send(msg.sender, from, to, amount, "", "");
        return true;
    }
    
    function _send(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(balanceOf[from] >= amount, "Insufficient balance");
        
        _callTokensToSend(operator, from, to, amount, data, operatorData);
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        emit Sent(operator, from, to, amount, data, operatorData);
        emit Transfer(from, to, amount);
        
        _callTokensReceived(operator, from, to, amount, data, operatorData);
    }
    
    function _mint(address to, uint256 amount, bytes memory data, bytes memory operatorData) internal {
        require(to != address(0), "Invalid recipient");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        emit Minted(msg.sender, to, amount, data, operatorData);
        emit Transfer(address(0), to, amount);
        
        _callTokensReceived(msg.sender, address(0), to, amount, data, operatorData);
    }
    
    function _burn(address operator, address from, uint256 amount, bytes memory data, bytes memory operatorData) internal {
        require(from != address(0), "Invalid sender");
        require(balanceOf[from] >= amount, "Insufficient balance");
        
        _callTokensToSend(operator, from, address(0), amount, data, operatorData);
        
        balanceOf[from] -= amount;
        totalSupply -= amount;
        
        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }
    
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) private {
        if (from.code.length > 0) {
            try IERC777Sender(from).tokensToSend(operator, from, to, amount, data, operatorData) {}
            catch {}
        }
    }
    
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) private {
        if (to.code.length > 0) {
            try IERC777Recipient(to).tokensReceived(operator, from, to, amount, data, operatorData) {}
            catch {}
        }
    }
}
