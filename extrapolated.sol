// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0

import {WadRayMath} from "./dependencies/WadRayMath.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SwapLibrary {
  function exactInput(
    SwapConfig calldata swapConfig,
    address tokenIn,
    address tokenOut,
    uint256 amount,
    uint256 price
  ) external returns (uint256) {
    if (swapConfig.protocol == SwapProtocol.uniswap) {
      return _exactInputUniswap(swapConfig, tokenIn, tokenOut, amount, price);
    }
    return 0;
  }
function _swapExactOutputMultihop(
    SwapConfig calldata swapConfig,
    address[] calldata tokens,
    uint256 amountOut,
    uint256 amountInMaximum
) internal returns (uint256) {
    require(tokens.length >= 2, "SwapLibrary: invalid tokens array length");

    UniswapCustomParams memory cp = abi.decode(swapConfig.customParams, (UniswapCustomParams));
    address tokenIn = tokens[0];
    address tokenOut = tokens[tokens.length - 1];

    TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
    TransferHelper.safeApprove(tokenIn, address(cp.router), amountInMaximum);

    bytes memory path;

    path=_constructPath(tokens, cp.feeTier)

    ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
        path: path,
        recipient: address(this),
        deadline: block.timestamp,
        amountOut: amountOut,
        amountInMaximum: amountInMaximum
    });

    uint256 amountIn = cp.router.exactOutput(params);

    if (amountIn < amountInMaximum) {
        TransferHelper.safeApprove(tokenIn, address(cp.router), 0);
        TransferHelper.safeTransferFrom(tokenIn, address(this), msg.sender, amountInMaximum - amountIn);
    }

    // Sanity check
    require(amountIn <= amountInMaximum, "SwapLibrary: slippage greater than maxSlippage");
    return amountIn;
} 
    function _constructPath(address[] memory tokens, uint24 poolFee) internal pure returns (bytes memory) {
        require(tokens.length > 0, "Tokens array must not be empty");
        
        bytes memory path;
        
        for (uint i = 0; i < tokens.length; i++) {
            path = abi.encodePacked(path, tokens[i]);
            
            if (i < tokens.length - 1) {
                path = abi.encodePacked(path, poolFee);
            }
        }
        
        return path;
    }


}