pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import { Action, Task, ExecClaim } from "../../../gelato_core/interfaces/IGelatoCore.sol";

interface IGelatoUserProxy {
    function mintExecClaim(Task calldata _task) external;
    function multiMintExecClaims(Task[] calldata _tasks) external;

    function cancelExecClaim(ExecClaim calldata _ec) external;
    function batchCancelExecClaims(ExecClaim[] calldata _ecs) external;

    function execAction(Action calldata _action) external payable;
    function multiExecActions(Action[] calldata _actions) external payable;

    // Does not work due to `immutable override` InternalCompilerError: Assembly exception for bytecode
    function user() external view returns(address);
    function gelatoCore() external view returns(address);
}
