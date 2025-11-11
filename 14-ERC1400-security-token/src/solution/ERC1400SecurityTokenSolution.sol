// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC1400SecurityTokenSolution
 * @notice Complete implementation of ERC-1400 Security Token Standard for RWAs
 *
 * COMPLIANCE FEATURES:
 * - Partition-based token management (different classes)
 * - Transfer restrictions (KYC, whitelist, lockup)
 * - Document management (prospectus, term sheets)
 * - Controller functions (forced transfers for compliance)
 * - Investor verification system
 */
contract ERC1400SecurityTokenSolution {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    
    // Partition management
    bytes32[] public partitions;
    mapping(address => bytes32[]) public partitionsOf;
    mapping(bytes32 => mapping(address => uint256)) public balanceOfByPartition;
    mapping(bytes32 => uint256) public totalSupplyByPartition;
    
    // Compliance
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isAccredited;
    mapping(address => uint256) public transferLockup;
    mapping(address => string) public jurisdiction;
    
    // Document management
    struct Document {
        string uri;
        bytes32 documentHash;
        uint256 timestamp;
    }
    mapping(bytes32 => Document) public documents;
    bytes32[] public documentNames;
    
    // Controllers (regulatory compliance operators)
    mapping(address => bool) public isController;
    
    address public owner;
    
    event TransferByPartition(
        bytes32 indexed partition,
        address operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );
    
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed from, uint256 value, bytes data);
    event DocumentUpdated(bytes32 indexed name, string uri, bytes32 documentHash);
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event InvestorWhitelisted(address indexed investor);
    event InvestorRemoved(address indexed investor);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyController() {
        require(isController[msg.sender] || msg.sender == owner, "Not controller");
        _;
    }
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        isController[msg.sender] = true;
    }
    
    // ═════════════════════════════════════════════════════════════════
    // PARTITION FUNCTIONS
    // ═════════════════════════════════════════════════════════════════
    
    function balanceOf(address account) public view returns (uint256) {
        uint256 total = 0;
        bytes32[] memory accountPartitions = partitionsOf[account];
        for (uint i = 0; i < accountPartitions.length; i++) {
            total += balanceOfByPartition[accountPartitions[i]][account];
        }
        return total;
    }
    
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32) {
        return _transferByPartition(partition, msg.sender, msg.sender, to, amount, data, "");
    }
    
    function operatorTransferByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external returns (bytes32) {
        require(isController[msg.sender], "Not authorized");
        return _transferByPartition(partition, msg.sender, from, to, amount, data, operatorData);
    }
    
    function _transferByPartition(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal returns (bytes32) {
        require(to != address(0), "Invalid recipient");
        require(balanceOfByPartition[partition][from] >= amount, "Insufficient balance");
        
        // COMPLIANCE CHECKS
        (bool canTransfer, bytes32 reason) = _canTransfer(from, to, amount);
        require(canTransfer, string(abi.encodePacked(reason)));
        
        // Transfer
        balanceOfByPartition[partition][from] -= amount;
        balanceOfByPartition[partition][to] += amount;
        
        // Update partitions
        if (balanceOfByPartition[partition][to] > 0 && !_hasPartition(to, partition)) {
            partitionsOf[to].push(partition);
        }
        
        emit TransferByPartition(partition, operator, from, to, amount, data, operatorData);
        
        return partition;
    }
    
    function issueByPartition(
        bytes32 partition,
        address to,
        uint256 amount,
        bytes calldata data
    ) external onlyController {
        require(to != address(0), "Invalid recipient");
        require(isWhitelisted[to], "Recipient not whitelisted");
        
        balanceOfByPartition[partition][to] += amount;
        totalSupplyByPartition[partition] += amount;
        totalSupply += amount;
        
        if (!_hasPartition(to, partition)) {
            partitionsOf[to].push(partition);
        }
        
        if (!_partitionExists(partition)) {
            partitions.push(partition);
        }
        
        emit IssuedByPartition(partition, to, amount, data);
    }
    
    function redeemByPartition(
        bytes32 partition,
        uint256 amount,
        bytes calldata data
    ) external {
        _redeemByPartition(partition, msg.sender, amount, data);
    }
    
    function operatorRedeemByPartition(
        bytes32 partition,
        address from,
        uint256 amount,
        bytes calldata data
    ) external onlyController {
        _redeemByPartition(partition, from, amount, data);
    }
    
    function _redeemByPartition(
        bytes32 partition,
        address from,
        uint256 amount,
        bytes memory data
    ) internal {
        require(balanceOfByPartition[partition][from] >= amount, "Insufficient balance");
        
        balanceOfByPartition[partition][from] -= amount;
        totalSupplyByPartition[partition] -= amount;
        totalSupply -= amount;
        
        emit RedeemedByPartition(partition, from, amount, data);
    }
    
    // ═════════════════════════════════════════════════════════════════
    // COMPLIANCE FUNCTIONS
    // ═════════════════════════════════════════════════════════════════
    
    function addToWhitelist(address investor, string calldata _jurisdiction) external onlyController {
        isWhitelisted[investor] = true;
        jurisdiction[investor] = _jurisdiction;
        emit InvestorWhitelisted(investor);
    }
    
    function removeFromWhitelist(address investor) external onlyController {
        isWhitelisted[investor] = false;
        emit InvestorRemoved(investor);
    }
    
    function setAccredited(address investor, bool accredited) external onlyController {
        isAccredited[investor] = accredited;
    }
    
    function setTransferLockup(address investor, uint256 lockupEnd) external onlyController {
        transferLockup[investor] = lockupEnd;
    }
    
    function canTransfer(address from, address to, uint256 amount, bytes calldata data) 
        external 
        view 
        returns (bool, bytes32) 
    {
        return _canTransfer(from, to, amount);
    }
    
    function _canTransfer(address from, address to, uint256 amount) 
        internal 
        view 
        returns (bool, bytes32) 
    {
        if (!isWhitelisted[to]) {
            return (false, bytes32("Recipient not whitelisted"));
        }
        
        if (transferLockup[from] > block.timestamp) {
            return (false, bytes32("Tokens locked"));
        }
        
        if (amount == 0) {
            return (false, bytes32("Amount is zero"));
        }
        
        return (true, bytes32(0));
    }
    
    // ═════════════════════════════════════════════════════════════════
    // DOCUMENT MANAGEMENT
    // ═════════════════════════════════════════════════════════════════
    
    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external onlyController {
        Document storage doc = documents[name];
        
        if (doc.timestamp == 0) {
            documentNames.push(name);
        }
        
        doc.uri = uri;
        doc.documentHash = documentHash;
        doc.timestamp = block.timestamp;
        
        emit DocumentUpdated(name, uri, documentHash);
    }
    
    function getDocument(bytes32 name) external view returns (string memory, bytes32, uint256) {
        Document memory doc = documents[name];
        return (doc.uri, doc.documentHash, doc.timestamp);
    }
    
    // ═════════════════════════════════════════════════════════════════
    // CONTROLLER MANAGEMENT
    // ═════════════════════════════════════════════════════════════════
    
    function addController(address controller) external onlyOwner {
        isController[controller] = true;
        emit ControllerAdded(controller);
    }
    
    function removeController(address controller) external onlyOwner {
        isController[controller] = false;
        emit ControllerRemoved(controller);
    }
    
    // ═════════════════════════════════════════════════════════════════
    // INTERNAL HELPERS
    // ═════════════════════════════════════════════════════════════════
    
    function _hasPartition(address account, bytes32 partition) internal view returns (bool) {
        bytes32[] memory accountPartitions = partitionsOf[account];
        for (uint i = 0; i < accountPartitions.length; i++) {
            if (accountPartitions[i] == partition) {
                return true;
            }
        }
        return false;
    }
    
    function _partitionExists(bytes32 partition) internal view returns (bool) {
        for (uint i = 0; i < partitions.length; i++) {
            if (partitions[i] == partition) {
                return true;
            }
        }
        return false;
    }
    
    function getPartitions() external view returns (bytes32[] memory) {
        return partitions;
    }
}
