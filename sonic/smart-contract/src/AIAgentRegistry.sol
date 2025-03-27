// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Adjust path for Foundry: lib/openzeppelin-contracts/contracts/access/Ownable.sol
import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title AIAgentRegistry
 * @notice A registry for AI Agents operating within Confidential Compute VMs.
 * Allows agents to register, submit attestation hashes, and log interaction/guess hashes.
 * Designed for an architecture where the agent interacts directly with the chain,
 * and clients verify attestation off-chain using the submitted hash/timestamp.
 * @dev Uses keccak256 hashes to represent messages, saving significant gas costs.
 * Assumes off-chain storage holds the full message content mapped to these hashes.
 */
contract AIAgentRegistry is Ownable {

    // --- Structs ---

    struct AgentInfo {
        address agentWallet; // The wallet agent uses to interact with this contract
        string endpointUrl; // Public API endpoint (optional, primarily for off-chain discovery)
        bytes32 currentAttestationReportHash; // Hash of the latest submitted report (e.g., keccak256 of the report data)
        uint256 lastAttestationTimestamp; // Timestamp of the last successful attestation submission
        bool isActive; // Whether the agent is currently considered active/registered
    }

    struct InteractionLog {
        uint256 timestamp; // Timestamp of the interaction log
        address user; // User wallet address involved in the interaction
        bytes32 promptHash; // keccak256 hash of the user's prompt
        bytes32 responseHash; // keccak256 hash of the AI agent's response
    }

    struct GuessLog {
         uint256 timestamp; // Timestamp of the guess log
         address user; // User wallet address making the guess
         bool wasCorrect; // Whether the guess was correct
    }

    // --- State Variables ---

    mapping(address => AgentInfo) public agents; // agentWallet => AgentInfo
    // Key for logs: keccak256(abi.encodePacked(agentAddress, sessionId))
    // Where sessionId is an off-chain generated identifier for a user's session with an agent
    mapping(bytes32 => InteractionLog[]) public interactionLogs;
    mapping(bytes32 => GuessLog[]) public guessLogs;

    // --- Events ---

    event AgentRegistered(address indexed agentWallet, string endpointUrl);
    event AgentDeactivated(address indexed agentWallet);
    event AgentEndpointUpdated(address indexed agentWallet, string newEndpointUrl);
    event AttestationSubmitted(address indexed agentWallet, bytes32 reportHash, uint256 timestamp);
    event InteractionRecorded(bytes32 indexed logKey, address indexed user, bytes32 promptHash, bytes32 responseHash);
    event GuessRecorded(bytes32 indexed logKey, address indexed user, bool wasCorrect);

    // --- Constructor ---

    /**
     * @dev Sets the contract deployer as the initial owner.
     */
    constructor() Ownable(msg.sender) {} // Using OZ Ownable constructor

    // --- Agent Management (by Owner) ---

    /**
     * @notice Registers a new AI Agent.
     * @param _agentWallet The address of the wallet the agent will use to submit transactions.
     * @param _endpointUrl The public API endpoint where the agent can be reached (optional).
     */
    function registerAgent(address _agentWallet, string memory _endpointUrl) external onlyOwner {
        require(_agentWallet != address(0), "Invalid agent address");
        require(!agents[_agentWallet].isActive, "Agent already registered");

        agents[_agentWallet] = AgentInfo({
            agentWallet: _agentWallet,
            endpointUrl: _endpointUrl,
            currentAttestationReportHash: bytes32(0), // Initially no attestation
            lastAttestationTimestamp: 0,
            isActive: true
        });
        emit AgentRegistered(_agentWallet, _endpointUrl);
    }

    /**
     * @notice Deactivates a registered AI Agent.
     * @param _agentWallet The wallet address of the agent to deactivate.
     */
    function deactivateAgent(address _agentWallet) external onlyOwner {
        require(agents[_agentWallet].isActive, "Agent not active or not registered");
        agents[_agentWallet].isActive = false;
        emit AgentDeactivated(_agentWallet);
    }

    /**
     * @notice Updates the endpoint URL for a registered AI Agent.
     * @param _agentWallet The wallet address of the agent.
     * @param _newEndpointUrl The new public API endpoint URL.
     */
    function updateAgentEndpoint(address _agentWallet, string memory _newEndpointUrl) external onlyOwner {
         require(agents[_agentWallet].isActive, "Agent not active or not registered");
         agents[_agentWallet].endpointUrl = _newEndpointUrl;
         emit AgentEndpointUpdated(_agentWallet, _newEndpointUrl);
    }


    // --- Agent Actions (Callable only by registered Agent Wallet) ---

    modifier onlyActiveAgent() {
        require(agents[msg.sender].isActive, "Caller is not an active registered agent");
        _;
    }

    /**
     * @notice Allows an active agent to submit a hash of its latest attestation report.
     * @dev Clients are expected to verify the actual report off-chain using this hash and timestamp.
     * @param _reportHash keccak256 hash (or similar) of the attestation report data.
     */
    function submitAttestationHash(bytes32 _reportHash) external onlyActiveAgent {
        require(_reportHash != bytes32(0), "Report hash cannot be empty"); // Basic validation
        agents[msg.sender].currentAttestationReportHash = _reportHash;
        agents[msg.sender].lastAttestationTimestamp = block.timestamp;
        emit AttestationSubmitted(msg.sender, _reportHash, block.timestamp);
    }

    /**
     * @notice Allows an active agent to record the hashes of a user interaction.
     * @param _logKey A key unique to the agent and session, e.g., keccak256(abi.encodePacked(agentAddress, sessionId)).
     * @param _user The address of the user involved.
     * @param _promptHash keccak256 hash of the user's prompt.
     * @param _responseHash keccak256 hash of the agent's response.
     */
    function recordInteraction(bytes32 _logKey, address _user, bytes32 _promptHash, bytes32 _responseHash) external onlyActiveAgent {
        require(_user != address(0), "Invalid user address");
        require(_promptHash != bytes32(0), "Prompt hash cannot be empty");
        require(_responseHash != bytes32(0), "Response hash cannot be empty");

        interactionLogs[_logKey].push(InteractionLog({
            timestamp: block.timestamp,
            user: _user,
            promptHash: _promptHash,
            responseHash: _responseHash
        }));
        emit InteractionRecorded(_logKey, _user, _promptHash, _responseHash);
    }

    /**
     * @notice Allows an active agent to record the result of a user's guess.
     * @param _logKey A key unique to the agent and session, e.g., keccak256(abi.encodePacked(agentAddress, sessionId)).
     * @param _user The address of the user who made the guess.
     * @param _wasCorrect Whether the guess was correct according to the agent.
     */
     function recordGuessResult(bytes32 _logKey, address _user, bool _wasCorrect) external onlyActiveAgent {
        require(_user != address(0), "Invalid user address");

        guessLogs[_logKey].push(GuessLog({
            timestamp: block.timestamp,
            user: _user,
            wasCorrect: _wasCorrect
        }));
        emit GuessRecorded(_logKey, _user, _wasCorrect);
     }

     // --- View Functions ---

     /**
      * @notice Retrieves the stored information for a given agent wallet address.
      * @param _agentWallet The wallet address of the agent.
      * @return AgentInfo struct containing the agent's details.
      */
     function getAgentInfo(address _agentWallet) external view returns (AgentInfo memory) {
         // require(agents[_agentWallet].agentWallet != address(0), "Agent not registered"); // Check if needed
         return agents[_agentWallet];
     }

     /**
      * @notice Retrieves the interaction logs for a specific agent and session key.
      * @param _logKey The key for the logs, derived from agent address and session ID.
      * @return An array of InteractionLog structs.
      */
     function getInteractionLogs(bytes32 _logKey) public view returns (InteractionLog[] memory) {
         return interactionLogs[_logKey];
     }

     /**
      * @notice Retrieves the guess logs for a specific agent and session key.
      * @param _logKey The key for the logs, derived from agent address and session ID.
      * @return An array of GuessLog structs.
      */
      function getGuessLogs(bytes32 _logKey) public view returns (GuessLog[] memory) {
         return guessLogs[_logKey];
     }
}