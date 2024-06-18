// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BConst, BMath, BNum} from '../../src/contracts/BMath.sol';
import {Test} from 'forge-std/Test.sol';

contract MockBMath is BMath, Test {
  function mock_call_calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee,
    uint256 spotPrice
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcSpotPrice(uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceIn,
        tokenWeightIn,
        tokenBalanceOut,
        tokenWeightOut,
        swapFee
      ),
      abi.encode(spotPrice)
    );
  }

  function mock_call_calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee,
    uint256 tokenAmountOut
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcOutGivenIn(uint256,uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceIn,
        tokenWeightIn,
        tokenBalanceOut,
        tokenWeightOut,
        tokenAmountIn,
        swapFee
      ),
      abi.encode(tokenAmountOut)
    );
  }

  function mock_call_calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee,
    uint256 tokenAmountIn
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcInGivenOut(uint256,uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceIn,
        tokenWeightIn,
        tokenBalanceOut,
        tokenWeightOut,
        tokenAmountOut,
        swapFee
      ),
      abi.encode(tokenAmountIn)
    );
  }

  function mock_call_calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee,
    uint256 poolAmountOut
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcPoolOutGivenSingleIn(uint256,uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceIn,
        tokenWeightIn,
        poolSupply,
        totalWeight,
        tokenAmountIn,
        swapFee
      ),
      abi.encode(poolAmountOut)
    );
  }

  function mock_call_calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee,
    uint256 tokenAmountIn
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcSingleInGivenPoolOut(uint256,uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceIn,
        tokenWeightIn,
        poolSupply,
        totalWeight,
        poolAmountOut,
        swapFee
      ),
      abi.encode(tokenAmountIn)
    );
  }

  function mock_call_calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee,
    uint256 tokenAmountOut
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcSingleOutGivenPoolIn(uint256,uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceOut,
        tokenWeightOut,
        poolSupply,
        totalWeight,
        poolAmountIn,
        swapFee
      ),
      abi.encode(tokenAmountOut)
    );
  }

  function mock_call_calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee,
    uint256 poolAmountIn
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'calcPoolInGivenSingleOut(uint256,uint256,uint256,uint256,uint256,uint256)',
        tokenBalanceOut,
        tokenWeightOut,
        poolSupply,
        totalWeight,
        tokenAmountOut,
        swapFee
      ),
      abi.encode(poolAmountIn)
    );
  }
}
