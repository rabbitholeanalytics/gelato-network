// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoCore, TaskReceipt} from "../gelato_core/interfaces/IGelatoCore.sol";
import {GelatoTaskReceipt} from "../libraries/GelatoTaskReceipt.sol";

/// @title GelatoMultiCall - Aggregate results from multiple read-only function calls on GelatoCore
/// @author Hilmar X (inspired by Maker's Multicall)
contract GelatoMultiCall {

    using GelatoTaskReceipt for TaskReceipt;

    IGelatoCore public immutable gelatoCore;

    constructor(IGelatoCore _gelatoCore) public { gelatoCore = _gelatoCore; }

    struct Response { uint256 taskReceiptId; string response; }

    function multiCanExec(
        TaskReceipt[] memory _TRs,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        public
        view
        returns (uint256 blockNumber, Response[] memory responses)
    {
        blockNumber = block.number;
        responses = new Response[](_TRs.length);
        for(uint256 i = 0; i < _TRs.length; i++) {
            try gelatoCore.canExec(_TRs[i], getGasLimit(_TRs[i], _gelatoMaxGas), _gelatoGasPrice)
                returns(string memory response)
            {
                responses[i] = Response({taskReceiptId: _TRs[i].id, response: response});
            } catch {
                responses[i] = Response({
                    taskReceiptId: _TRs[i].id,
                    response: "GelatoMultiCall.multiCanExec: failed"
                });
            }
        }
    }

    function getGasLimit(TaskReceipt memory _TRs, uint256 _gelatoMaxGas)
        private
        pure
        returns(uint256 gasLimit)
    {
        gasLimit = _TRs.selfProvider() ? _TRs.task().selfProviderGasLimit : _gelatoMaxGas;
    }

}