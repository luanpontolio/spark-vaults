// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.21;

import { MockERC20 } from "./MockERC20.sol";
import { MockRateProvider } from "./MockRateProvider.sol";

contract MockPSM {

    address public owner;
    address public usdc;
    address public susds;
    address public rateProvider;

    modifier onlyOwner() {
        require(msg.sender == owner, "MockPSM/not-owner");
        _;
    }

    constructor(address _usdc, address _susds, address _rateProvider) {
        owner        = msg.sender;
        usdc         = _usdc;
        susds        = _susds;
        rateProvider = _rateProvider;
    }

    function pocket() external view returns (address) {
        return address(this);
    }

    // Mint tokens directly into the PSM pocket (this contract).
    function fund(address token, uint256 amount) external onlyOwner {
        MockERC20(token).mint(address(this), amount);
    }

    // --- Preview helpers ---

    function previewSwapExactIn(address assetIn, address assetOut, uint256 amountIn)
        external view returns (uint256 amountOut)
    {
        return _calcExactIn(assetIn, assetOut, amountIn);
    }

    function previewSwapExactOut(address assetIn, address assetOut, uint256 amountOut)
        external view returns (uint256 amountIn)
    {
        return _calcExactOut(assetIn, assetOut, amountOut);
    }

    // --- Swap functions ---

    function swapExactIn(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint256 /* referralCode */
    ) external returns (uint256 amountOut) {
        amountOut = _calcExactIn(assetIn, assetOut, amountIn);
        require(amountOut >= minAmountOut, "MockPSM/insufficient-amount-out");
        require(MockERC20(assetIn).transferFrom(msg.sender, address(this), amountIn),  "MockPSM/transfer-in-failed");
        require(MockERC20(assetOut).transfer(receiver, amountOut),                     "MockPSM/transfer-out-failed");
    }

    function swapExactOut(
        address assetIn,
        address assetOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        address receiver,
        uint256 /* referralCode */
    ) external returns (uint256 amountIn) {
        amountIn = _calcExactOut(assetIn, assetOut, amountOut);
        require(amountIn <= maxAmountIn, "MockPSM/exceeded-max-amount-in");
        require(MockERC20(assetIn).transferFrom(msg.sender, address(this), amountIn),  "MockPSM/transfer-in-failed");
        require(MockERC20(assetOut).transfer(receiver, amountOut),                     "MockPSM/transfer-out-failed");
    }

    // --- Internal math ---

    function _calcExactIn(address assetIn, address assetOut, uint256 amountIn)
        internal view returns (uint256 amountOut)
    {
        uint256 rate = MockRateProvider(rateProvider).getConversionRate();
        if (assetIn == usdc && assetOut == susds) {
            // USDC (6 dec) → sUSDS (18 dec): scale up by 1e12, then convert at rate
            amountOut = amountIn * 1e12 * 1e27 / rate;
        } else if (assetIn == susds && assetOut == usdc) {
            // sUSDS (18 dec) → USDC (6 dec): convert at rate, then scale down by 1e12
            amountOut = amountIn * rate / 1e27 / 1e12;
        } else {
            revert("MockPSM/unsupported-swap");
        }
    }

    function _calcExactOut(address assetIn, address assetOut, uint256 amountOut)
        internal view returns (uint256 amountIn)
    {
        uint256 rate = MockRateProvider(rateProvider).getConversionRate();
        if (assetIn == usdc && assetOut == susds) {
            // Inverse of USDC → sUSDS
            amountIn = amountOut * rate / 1e27 / 1e12;
        } else if (assetIn == susds && assetOut == usdc) {
            // Inverse of sUSDS → USDC
            amountIn = amountOut * 1e12 * 1e27 / rate;
        } else {
            revert("MockPSM/unsupported-swap");
        }
    }
}
