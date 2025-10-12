// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleAMM
 * @notice A simple constant product AMM (x * y = k) for WBTC/USDT
 * @dev This contract can be deployed on any EVM chain to receive liquidity from BitVM3 vault
 */
contract SimpleAMM {
    // Token addresses (would be actual ERC20 in production)
    address public immutable tokenA; // WBTC
    address public immutable tokenB; // USDT
    
    // Reserves
    uint256 public reserveA;
    uint256 public reserveB;
    
    // LP token tracking
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    // Events
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event Swap(address indexed trader, uint256 amountIn, uint256 amountOut, bool isAToB);
    
    // Constants
    uint256 private constant FEE_NUMERATOR = 997; // 0.3% fee
    uint256 private constant FEE_DENOMINATOR = 1000;
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
    
    /**
     * @notice Initialize the pool with first liquidity
     * @param amountA Amount of token A
     * @param amountB Amount of token B
     * @return shares LP tokens minted
     */
    function initializePool(uint256 amountA, uint256 amountB) external returns (uint256 shares) {
        require(totalSupply == 0, "Pool already initialized");
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        
        // Transfer tokens (simplified - would use safeTransferFrom in production)
        // IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        // IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        
        reserveA = amountA;
        reserveB = amountB;
        
        // Initial shares = sqrt(amountA * amountB)
        shares = sqrt(amountA * amountB);
        totalSupply = shares;
        balanceOf[msg.sender] = shares;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
        return shares;
    }
    
    /**
     * @notice Add liquidity maintaining current ratio
     * @param amountA Amount of token A to add
     * @return amountB Required amount of token B
     * @return shares LP tokens minted
     */
    function addLiquidity(uint256 amountA) external returns (uint256 amountB, uint256 shares) {
        require(totalSupply > 0, "Pool not initialized");
        require(amountA > 0, "Invalid amount");
        
        // Calculate required amountB to maintain ratio
        amountB = (amountA * reserveB) / reserveA;
        
        // Calculate LP shares to mint
        shares = (amountA * totalSupply) / reserveA;
        
        // Transfer tokens (simplified)
        // IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        // IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        
        // Update state
        reserveA += amountA;
        reserveB += amountB;
        totalSupply += shares;
        balanceOf[msg.sender] += shares;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
        return (amountB, shares);
    }
    
    /**
     * @notice Remove liquidity
     * @param shares Amount of LP tokens to burn
     * @return amountA Token A returned
     * @return amountB Token B returned
     */
    function removeLiquidity(uint256 shares) external returns (uint256 amountA, uint256 amountB) {
        require(shares > 0 && shares <= balanceOf[msg.sender], "Invalid shares");
        
        // Calculate token amounts proportional to shares
        amountA = (shares * reserveA) / totalSupply;
        amountB = (shares * reserveB) / totalSupply;
        
        // Update state
        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transfer tokens back (simplified)
        // IERC20(tokenA).transfer(msg.sender, amountA);
        // IERC20(tokenB).transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, shares);
        return (amountA, amountB);
    }
    
    /**
     * @notice Swap token A for token B
     * @param amountAIn Amount of token A to swap
     * @return amountBOut Amount of token B received
     */
    function swapAForB(uint256 amountAIn) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "Invalid amount");
        
        // Calculate output with fee
        uint256 amountAInWithFee = amountAIn * FEE_NUMERATOR;
        uint256 numerator = amountAInWithFee * reserveB;
        uint256 denominator = (reserveA * FEE_DENOMINATOR) + amountAInWithFee;
        amountBOut = numerator / denominator;
        
        require(amountBOut > 0, "Insufficient output");
        
        // Transfer tokens (simplified)
        // IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        // IERC20(tokenB).transfer(msg.sender, amountBOut);
        
        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;
        
        emit Swap(msg.sender, amountAIn, amountBOut, true);
        return amountBOut;
    }
    
    /**
     * @notice Swap token B for token A
     * @param amountBIn Amount of token B to swap
     * @return amountAOut Amount of token A received
     */
    function swapBForA(uint256 amountBIn) external returns (uint256 amountAOut) {
        require(amountBIn > 0, "Invalid amount");
        
        // Calculate output with fee
        uint256 amountBInWithFee = amountBIn * FEE_NUMERATOR;
        uint256 numerator = amountBInWithFee * reserveA;
        uint256 denominator = (reserveB * FEE_DENOMINATOR) + amountBInWithFee;
        amountAOut = numerator / denominator;
        
        require(amountAOut > 0, "Insufficient output");
        
        // Transfer tokens (simplified)
        // IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        // IERC20(tokenA).transfer(msg.sender, amountAOut);
        
        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOut;
        
        emit Swap(msg.sender, amountBIn, amountAOut, false);
        return amountAOut;
    }
    
    /**
     * @notice Get current price
     * @return priceAInB Price of token A in terms of token B
     * @return priceBInA Price of token B in terms of token A
     */
    function getPrice() external view returns (uint256 priceAInB, uint256 priceBInA) {
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        priceAInB = (reserveB * 1e18) / reserveA;
        priceBInA = (reserveA * 1e18) / reserveB;
    }
    
    /**
     * @notice Get pool state
     */
    function getPoolState() external view returns (
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _totalSupply,
        uint256 _k
    ) {
        return (reserveA, reserveB, totalSupply, reserveA * reserveB);
    }
    
    /**
     * @notice Calculate output amount for a swap
     * @param amountIn Input amount
     * @param reserveIn Input reserve
     * @param reserveOut Output reserve
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountIn > 0, "Invalid input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        
        return numerator / denominator;
    }
    
    /**
     * @notice Square root function for initial liquidity calculation
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}