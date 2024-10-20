// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "../library/WordCodec.sol";

library Samples {
    using WordCodec for int256;
    using WordCodec for uint256;
    using WordCodec for bytes32;

    uint256 internal constant _TIMESTAMP_OFFSET = 0;
    uint256 internal constant _INST_LOG_PAIR_PRICE_OFFSET = 31;

    function update(bytes32 sample, int256 instLogPairPrice, uint256 currentTimestamp) internal pure returns (bytes32) {
        return pack(instLogPairPrice, currentTimestamp);
    }

    function timestamp(bytes32 sample) internal pure returns (uint256) {
        return sample.decodeUint31(_TIMESTAMP_OFFSET);
    }

    function _instLogPairPrice(bytes32 sample) private pure returns (int256) {
        return sample.decodeInt22(_INST_LOG_PAIR_PRICE_OFFSET);
    }

    function pack(int256 instLogPairPrice, uint256 _timestamp) internal pure returns (bytes32) {
        return instLogPairPrice.encodeInt22(_INST_LOG_PAIR_PRICE_OFFSET) | _timestamp.encodeUint31(_TIMESTAMP_OFFSET);
    }

    function unpack(bytes32 sample) internal pure returns (int256 logPairPrice, uint256 _timestamp) {
        logPairPrice = _instLogPairPrice(sample);
        _timestamp = timestamp(sample);
    }
}
