// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IERC20} from "../../external/IERC20.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {IConditionalTokens, IERC1155, IFixedProductMarketMaker} from "../../dapp_interfaces/conditional_tokens/IConditionalTokens.sol";

/// @title ActionWithdrawLiquidity
/// @author Hilmar Orth
/// @notice Gelato Action that
///  1) withdraws conditional tokens from FPMM
///  2) merges position on conditional tokens contract
///  3) transfers merged tokens back to user
contract ActionWithdrawLiquidity {

    using SafeERC20 for IERC20;

    constructor() public {}

    // ======= ACTION IMPLEMENTATION DETAILS =========
    function action(
        IConditionalTokens _conditionalTokens,
        IFixedProductMarketMaker _fixedProductMarketMaker,
        uint256[] memory _positionIds,
        bytes32 _conditionId,
        bytes32 _parentCollectionId,
        address _collateralToken,
        address _receiver
    )
        public
        virtual
    {
        // 1. Fetch the balance of liquidity pool tokens
        uint256 lpTokensToWithdraw = IERC20(address(_fixedProductMarketMaker)).balanceOf(address(this));

        if (lpTokensToWithdraw > 0) {

            // 2. Remove funding from fixedProductMarketMaker
            _fixedProductMarketMaker.removeFunding(lpTokensToWithdraw);

            // 3. Check balances of conditional tokens
            address[] memory proxyAddresses = new address[](_positionIds.length);
            for (uint256 i; i < _positionIds.length; i++) {
                proxyAddresses[i] = address(this);
            }

            uint256[] memory outcomeTokenBalances = IERC1155(address(_conditionalTokens)).balanceOfBatch(proxyAddresses, _positionIds);

            // 4. Find the lowest balance of all outcome tokens
            uint256 amountToMerge;
            for (uint256 i; i < outcomeTokenBalances.length; i++) {
                uint256 outcomeTokenBalance = outcomeTokenBalances[i];
                if (i == 0) amountToMerge = outcomeTokenBalance;
                else if (outcomeTokenBalance < amountToMerge) amountToMerge = outcomeTokenBalance;
            }

            if (amountToMerge > 0 ) {

                uint256[] memory partition = new uint256[](_positionIds.length);
                for (uint256 i; i < partition.length; i++) {
                    partition[i] = 1 << i;
                }

                // 5. Merge outcome tokens
                _conditionalTokens.mergePositions(IERC20(_collateralToken), _parentCollectionId, _conditionId, partition, amountToMerge);

                // 6. Transfer collateral back to user
                IERC20(_collateralToken).safeTransfer(_receiver, amountToMerge, "Transfer Collateral to receiver failed");
            }
        }

    }


}