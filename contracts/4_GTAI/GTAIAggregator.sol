pragma solidity ^0.5.10;

import '../1_gelato_standards/3_GTAI_standards/IGTAIFull.sol';
import '../1_gelato_standards/3_GTAI_standards/GTAIStandardOwnable.sol';

contract GTAIAggregator is IGTAIFull,
                           GTAIStandardOwnable
{

    constructor(address payable _gelatoCore,
                uint256 _gtaiGasPrice
    )
        GTAIStandardOwnable(_gelatoCore, _gtaiGasPrice)
        public
    {}


    // _______________ API FOR DAPP TRIGGER ACTION MINTING____________________
    event LogActivation(uint256 executionClaimId,
                        address indexed executionClaimOwner,
                        address indexed trigger,
                        address indexed action
    );

    function activateTA(address _trigger,
                        bytes calldata _specificTriggerParams,
                        address _action,
                        bytes calldata _specificActionParams,
                        uint256 _executionClaimLifespan
    )
        onlyRegisteredTriggers(_trigger)
        onlyRegisteredActions(_action, _executionClaimLifespan)
        external
        payable
        returns(bool)
    {
        /// @dev Calculations for charging the msg.sender/user
        uint256 prepaidExecutionFee = _getExecutionClaimPrice(_action);
        require(msg.value == prepaidExecutionFee,
            "GTAIAggregator.activateTA: prepaidExecutionFee failed"
        );
        // _________________Minting_____________________________________________
        // Trigger-Action Payloads
        bytes memory triggerPayload
            = abi.encodeWithSelector(_getTriggerSelector(_trigger),
                                     _specificTriggerParams
        );
        // Standard action conditions check before minting
        require(_actionConditionsFulfilled(_action, msg.sender, _specificActionParams),
            "GTAIAggregator.activateTA._actionConditionsFulfilled: failed"
        );
        require(_mintExecutionClaim(msg.sender,  // executionClaimOwner
                                    _trigger,
                                    triggerPayload,
                                    _action,
                                    _specificActionParams,
                                    _executionClaimLifespan),
            "IcedOut._mintExecutionClaim: failed"
        );
        emit LogActivation(_getCurrentExecutionClaimId(),
                           msg.sender,
                           _trigger,
                           _action
        );
        return true;
        // =========================
    }

    //___________________ Chained Execution Claim Minting _____________________
    event LogChainedActivation(uint256 indexed executionClaimId,
                               address indexed chainedTrigger,
                               address indexed chainedAction,
                               address minter
    );

    function activateChainedTA(address _executionClaimOwner,
                               address _chainedTrigger,
                               bytes calldata _chainedTriggerPayload,
                               address _chainedAction,
                               bytes calldata _chainedActionPayload,
                               uint256 _chainedExecutionClaimLifespan
    )
        msgSenderIsRegisteredAction()
        onlyRegisteredTriggers(_chainedTrigger)
        onlyRegisteredActions(_chainedAction, _chainedExecutionClaimLifespan)
        actionConditionsFulfilled(_chainedAction,
                                  _executionClaimOwner,
                                  _chainedActionPayload
        )
        external
    {
        _mintExecutionClaim(_executionClaimOwner,
                            _chainedTrigger,
                            _chainedTriggerPayload,
                            _chainedAction,
                            _chainedActionPayload,
                            _chainedExecutionClaimLifespan
        );
        emit LogChainedActivation(_getCurrentExecutionClaimId(),
                                  _chainedTrigger,
                                  _chainedAction,
                                  msg.sender
        );
    }
    // ================
}