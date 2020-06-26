// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoCore, TaskReceipt} from "../gelato_core/interfaces/IGelatoCore.sol";
import {IGelatoExecutors} from "../gelato_core/interfaces/IGelatoExecutors.sol";
import {IGelatoProviders} from "../gelato_core/interfaces/IGelatoProviders.sol";
import {IGelatoSysAdmin} from "../gelato_core/interfaces/IGelatoSysAdmin.sol";
import {Address} from  "../external/Address.sol";
import {EnumerableSet} from "../external/EnumerableSet.sol";
import {GelatoString} from "../libraries/GelatoString.sol";
import {GelatoTaskReceipt} from "../libraries/GelatoTaskReceipt.sol";
import {Math} from "../external/Math.sol";
import {SafeMath} from "../external/SafeMath.sol";

/// @title BlockCoordinatedExecutor
/// @author Luis Schliesske & Hilmar Orth
/// @notice A module that Executors can use to coordinate shared Task execution
/// @dev This is a prototype only and a work in progress
contract BlockCoordinatedExecutor is IGelatoExecutors {

    using Address for address payable;  /// for sendValue method
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using GelatoString for string;
    using GelatoTaskReceipt for TaskReceipt;
    using SafeMath for uint256;

    event LogExecutorUnstakingRequested(
        address indexed executor,
        uint256 validFromBlock
    );
    event LogExecutorChallenged(
        address indexed challenger,
        address indexed executor,
        uint256 indexed taskReceiptId
    );
    event LogChallengesRemoved(address indexed executor, uint256 indexed taskReceiptId);
    event LogChallengesCompleted(
        address indexed challenger,
        address indexed executor,
        uint256 slashingRewards
    );
    event LogExecutorRemoved(address indexed executor);

    struct Response { uint256 taskReceiptId; string response; }
    struct Slot { address executor; uint256 start; }

    uint256 public constant slotLength = 30;  // block => ~ 6 minutes
    uint256 public constant minExecutorStake = 1 ether;
    uint256 public constant challengeRewardNum = 500;  // 5 % challenge reward
    uint256 public constant challengeRewardDen = 10000;  // 5 % challenge reward

    address public immutable gelatoCore;

    Slot public slot;
    mapping(address => uint256) public executorStake;
    mapping(address => uint256) public unstakingRequestBlock;
    EnumerableSet.AddressSet internal _activeExecutors;
    mapping(address => mapping(uint256 => bool)) public challenged;
    mapping(address => mapping(address => uint256[])) public challengeEnds;

    bytes32 internal constant InvalidExecutor = keccak256(abi.encodePacked("InvalidExecutor"));

    constructor(address _gelatoCore) public { gelatoCore = _gelatoCore; }

    receive() external payable virtual {
        require(msg.sender == gelatoCore, "BlockCoordinatedExecutor.receive:onlyGelatoCore");
    }

    // ======= ENTRY & EXIT APIs ========
    function stakeExecutor() public payable virtual override {
        require(
            unstakingRequestBlock[msg.sender] == 0,
            "BlockCoordinatedExecutor.stakeExecutor:open unstakingRequestBlock"
        );
        try IGelatoExecutors(gelatoCore).stakeExecutor{value: msg.value}() {
            uint256 currentStake = executorStake[msg.sender];
            uint256 newStake = currentStake + msg.value;
            require(
                newStake >= minExecutorStake,
                "BlockCoordinatedExecutor.stakeExecutor: below minStake"
            );
            executorStake[msg.sender] = newStake;
            _activeExecutors.add(msg.sender);  // containment check done by lib
            emit LogExecutorStaked(msg.sender, currentStake, newStake);
        } catch Error(string memory error) {
            error.revertWithInfo("BlockCoordinatedExecutor.stakeExecutor:");
        } catch {
            revert("BlockCoordinatedExecutor.stakeExecutor:unknown error");
        }
    }

    /// @dev Unstaking can only be requested from block.number + slotLength, to reduce
    ///  the likelihood of challenged Executors prematurely escaping with their stake.
    function requestUnstaking() public virtual {
        require(
            unstakingRequestBlock[msg.sender] == 0,
            "BlockCoordinatedExecutor.requestUnstaking: redundant"
        );
        _activeExecutors.remove(msg.sender);
        uint256 requestValidFromBlock = block.number + slotLength;
        unstakingRequestBlock[msg.sender] = requestValidFromBlock;
        emit LogExecutorUnstakingRequested(msg.sender, requestValidFromBlock);
    }

    /// @dev The last active Executor to unstake must call this beforehand
    function multiReassignProviders(address[] calldata _providers, address _newExecutor)
        public
        virtual
        override
    {
        require(
            _activeExecutors.length() == 1,
            "BlockCoordinatedExecutor.multiReassignProviders-1: Must be last Executor"
        );
        require(
            _activeExecutors.contains(msg.sender),
            "BlockCoordinatedExecutor.multiReassignProviders-2: Must be last Executor"
        );
        for (uint i; i < _providers.length; i++)
            IGelatoProviders(gelatoCore).executorAssignsExecutor(_providers[i], _newExecutor);
    }

    /// @dev Call this before unstaking and make sure it returned "OK"
    function canUnstake() public virtual view returns (string memory, uint256 stake) {
        if (block.number < unstakingRequestBlock[msg.sender])
            return ("PendingUnstakingRequestBlock", stake);
        stake = executorStake[msg.sender];
        if (stake == 0) return ("Already unstaked", stake);
        if (_activeExecutors.length() == 1) {
            if (IGelatoProviders(gelatoCore).isExecutorAssigned(address(this)))
                return ("LastExecutor:AssignedByProvider", stake);

            uint256 coreBalance = IGelatoProviders(gelatoCore).executorStake(address(this));
            if (coreBalance > stake)
                return ("LastExecutor:CoreBalance mismatch", stake);
        }
        return ("OK", stake);
    }

    /// @dev Challengers need to withdraw their rewards before the executor unstakes
    function unstakeExecutor() public virtual override {
        // Checks
        (string memory res, uint256 stake) = canUnstake();
        require(res.startsWithOK(), res);

        // Effects
        delete unstakingRequestBlock[msg.sender];
        delete executorStake[msg.sender];

        // Interactions
        if (_activeExecutors.length() == 1) {
            try IGelatoExecutors(gelatoCore).unstakeExecutor() {
            } catch Error(string memory error) {
                error.revertWithInfo("BlockCoordinatedExecutor.unstakeExecutor-1:");
            } catch {
                revert("BlockCoordinatedExecutor.unstakeExecutor-1:unknown error");
            }
        } else {
            try IGelatoExecutors(gelatoCore).withdrawExcessExecutorStake(stake) {
            } catch Error(string memory error) {
                error.revertWithInfo("BlockCoordinatedExecutor.unstakeExecutor-2:");
            } catch {
                revert("BlockCoordinatedExecutor.unstakeExecutor-2:unknown error");
            }
        }
        msg.sender.sendValue(stake);
        emit LogExecutorUnstaked(msg.sender);
    }

    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        public
        virtual
        override
        returns (uint256 realWithdrawAmount)
    {
        require(
            isExecutorMinStaked(msg.sender),
            "BlockCoordinatedExecutor.withdrawExcessExecutorStake: not minStaked"
        );
        uint256 currentExecutorStake = executorStake[msg.sender];
        uint256 excessExecutorStake = currentExecutorStake - minExecutorStake;
        realWithdrawAmount = Math.min(_withdrawAmount, excessExecutorStake);
        uint256 newExecutorStake = currentExecutorStake - realWithdrawAmount;

        // Effects
        executorStake[msg.sender] = newExecutorStake;

        // Interaction
        msg.sender.sendValue(realWithdrawAmount);
        emit LogExecutorBalanceWithdrawn(msg.sender, realWithdrawAmount);
    }

    function isExecutorMinStaked(address _executor) public view returns(bool) {
        return executorStake[_executor] >= minExecutorStake;
    }

    // ======= SLOT ALLOCATION APIs ========
    function getExecutorIndex(address _executor) public view virtual returns (uint256) {
        return _activeExecutors._inner._indexes[bytes32(uint256(_executor))] - 1;
    }
    function currentExecutor()
        public
        view
        virtual
        returns (address executor, uint256 start, uint256 end)
    {
        executor = slot.executor;
        start = slot.start;
        end = start.add(slotLength);
        if (block.number < end) return (executor, start, slotLength);
        return nextExecutor(executor, end);
    }
    function nextExecutor(address _slotExecutor, uint256 _end)
        public
        view
        virtual
        returns (address executor, uint256 start, uint256 end)
    {
        uint256 nextExecutorIndex = getExecutorIndex(_slotExecutor);

        // For each started slot we point to the next Executor
        for (end = _end; block.number < end; end += slotLength) {
            if (nextExecutorIndex == _activeExecutors.length() - 1)
                nextExecutorIndex = 0;
            else nextExecutorIndex += 1;
        }
        executor = _activeExecutors.at(nextExecutorIndex);
        start = end - slotLength;
    }

    // ======= EXECUTION & CHALLENGE APIs  ========
    /// @dev Call this to get the _TR(s) you want to use in exec
    function multiCanExec(
        TaskReceipt[] memory _TRs,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice,
        uint256 _buffer
    )
        public
        view
        virtual
        returns (uint256 blockNumber, Response[] memory responses, string memory error)
    {
        blockNumber = block.number;

        if (!isExecutorMinStaked(msg.sender))
            return (blockNumber, responses, "NotMinStaked");

        (address executor,, uint256 end) = currentExecutor();

        if (block.number.add(_buffer) >= end)
            return (blockNumber, responses, "SlotClosing");

        responses = new Response[](_TRs.length);
        for(uint256 i = 0; i < _TRs.length; i++) {
            try IGelatoCore(gelatoCore).canExec(
                _TRs[i],
                _TRs[i].selfProvider() ? _TRs[i].task().selfProviderGasLimit : _gelatoMaxGas,
                _gelatoGasPrice
            )
                returns(string memory response)
            {
                responses[i] = Response({taskReceiptId: _TRs[i].id, response: response});
            } catch {
                responses[i] = Response({
                    taskReceiptId: _TRs[i].id,
                    response: "BlockCoordinatedExecutor.multiCanExec: failed"
                });
            }
        }

        // This is done last so challengers can use this API too
        if (msg.sender != executor)
            return (blockNumber, responses, "NotYourSlot");
    }

    /// @dev Can be used to execute TaskReceipts OR to challenge executors!
    function exec(TaskReceipt memory _TR) public virtual {
        // Require that current slot belongs to Executor
        (address executor, uint256 start, uint256 end) = currentExecutor();
        require(msg.sender == executor, "NotYourSlot");

        if (!isExecutorMinStaked(msg.sender)) {
            _activeExecutors.remove(msg.sender);
            emit LogExecutorRemoved(msg.sender);
            return;
        }

        if (slot.executor != executor) {
            slot.executor = executor;
            slot.start = start;
        } else if (slot.start < start) {
            slot.start = start;
        }

        try IGelatoCore(gelatoCore).exec(_TR) returns (uint256 compensation) {
            executorStake[msg.sender] += compensation;
            if (challenged[msg.sender][_TR.id]) {
                delete challenged[msg.sender][_TR.id];
                emit LogChallengesRemoved(msg.sender, _TR.id);
            }
        } catch Error(string memory error) {
            if (keccak256(abi.encodePacked(error)) == InvalidExecutor) {
                if (!challenged[executor][_TR.id])
                    challenged[executor][_TR.id] = true;
                challengeEnds[msg.sender][executor].push(end);
                emit LogExecutorChallenged(msg.sender, executor, _TR.id);
            }
        } catch {
            revert("BlockCoordinatedExecutor.exec:");
        }
    }

    /// @dev Call this before calling withdrawChallengeRewards
    function canWithdrawChallengeRewards(address _executor, uint256 _taskReceiptId)
        public
        view
        virtual
        returns (bool, uint256)
    {
        uint256 challengeeStake = executorStake[_executor];
        return (
            challenged[_executor][_taskReceiptId] && challengeeStake != 0,
            challengeeStake
        );
    }

    /// @notice Withdraws all withdrawable rewards from successful challengeEnds.
    /// @dev Caution: This fn uses a loop and could result in out of gas reverts.
    ///  This function might also leave
    function withdrawChallengeRewards(
        address _executor,
        uint256 _taskReceiptId,
        uint256[] calldata _indices // empty means withdraw all withdrawable
    )
        public
        virtual
    {
        // Checks
        (bool ok, uint256 challengeeStake) = canWithdrawChallengeRewards(
            _executor,
            _taskReceiptId
        );
        require(ok, "BlockCoordinatedExecutor.withdrawChallengeRewards: not possible");

        // Copy storage array to memory to avoid multiple storage reads
        //uint256[] memory challengeEndsMem = challengeEnds[msg.sender][_executor];

        uint256 slashingReward = 0;
        uint256 i = 0;
        if (_indices.length == 0) {
            for (i; i < challengeEnds[msg.sender][_executor].length; i++) {
                // Check: has the challenge period concluded
                if (challengeEnds[msg.sender][_executor][i] <= block.number) {
                    // Check: Skip over challenge ends that we already withdrew
                    if (challengeEnds[msg.sender][_executor][i] == 0)
                        continue;
                    // Effects: remove this challenge and add slashingReward
                    delete challengeEnds[msg.sender][_executor][i];
                    slashingReward += (
                        challengeeStake.mul(challengeRewardNum).sub(1) / challengeRewardDen + 1
                    );
                } else {
                    // All challengeEnds that come after will be im the future
                    break;
                }
            }
        } else {
            for (i; i < _indices.length; i++) {
                // Check: has the challenge period concluded
                if (challengeEnds[msg.sender][_executor][_indices[i]] <= block.number) {
                    // Effects
                    delete challengeEnds[msg.sender][_executor][_indices[i]];
                    slashingReward += (
                        challengeeStake.mul(challengeRewardNum).sub(1) / challengeRewardDen + 1
                    );
                }
            }
        }

        // Effects: If we cleared all challengeEnds, we delete the whole Array
        if (i == challengeEnds[msg.sender][_executor].length - 1)
            delete challengeEnds[msg.sender][_executor];

        // Effects: remove challenged Executor from activeExecutors
        _activeExecutors.remove(_executor);

        // Effects: challenged Executors gets stake slashed
        executorStake[_executor] = challengeeStake.sub(
            slashingReward,
            "BlockCoordinatedExecutor.withdrawChallengeRewards: stake underflow"
        );

        // Interactions
        msg.sender.sendValue(slashingReward);

        emit LogChallengesCompleted(msg.sender, _executor, slashingReward);
    }
}
