pragma solidity ^0.5.10;

contract SplitFunctionSelector {
    // This contract should not be deployed
    constructor() internal {}

    function _splitFunctionSelector(bytes memory _payloadWithSelector)
        internal
        pure
        returns(bytes4 functionSelector, bytes memory payloadWithoutSelector)
    {
        assembly {
            // first 32bytes=0x20 stores length of bytes array - we take first 4 bytes
            functionSelector := mload(add(0x20, _payloadWithSelector))
            mstore(
                add(_payloadWithSelector, 4),  // p
                sub(mload(_payloadWithSelector), 4)  // length of payload - 4
            )
            payloadWithoutSelector := add(_payloadWithSelector, 4)
        }
    }
}
