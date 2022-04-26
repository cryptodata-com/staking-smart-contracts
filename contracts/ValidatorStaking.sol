// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract ValidatorStaking {
    struct Validator {
        address validatorNodeAddress;
        uint256 amount;
        string machineId;
        bytes signature;
    }

    mapping(address => uint256) internal stakes;
    mapping(address => Validator) internal validators;
    mapping(string => uint256) internal allowedMachineIds;
    uint256 internal totalEntries = 1;

    /// @notice Calculates a hash composed by nodeAddress and machine id
    /// @dev Make sure only the signer of this message can call the _removeStake method
    /// @param validatorNodeAddress the node validator address
    /// @param message license of the machine added in the whitelist
    /// @return bytes32 keccak256 hash signature
    function getMessageHash(address validatorNodeAddress, string memory message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(validatorNodeAddress, message));
    }

    /// @notice Add new machine id to the whitelist of allowed validators
    function _addNewMachineId(string memory machineId) internal {
        uint256 index = allowedMachineIds[machineId];
        require(index == 0, "The machine id is already assigned as validator!");
        allowedMachineIds[machineId] = totalEntries;
        totalEntries++;
    }

    /// @notice Set a node address to the list of staking validators
    function _setNewStake(
        address validatorNodeAddress,
        uint256 amount,
        string memory machineId,
        bytes memory signature
    ) internal {
        uint256 index = allowedMachineIds[machineId];
        uint256 stakedAmount = stakes[msg.sender];

        require(
            validatorNodeAddress != address(0),
            "Can not stake to Zero Address"
        );
        require(
            validatorNodeAddress != msg.sender,
            "You can not set your self as staker"
        );
        require(index != 0, "This license is not whitelisted!");
        require(stakedAmount == 0, "This node node is already a validator ");

        stakes[msg.sender] += amount;
        validators[msg.sender] = Validator({
            validatorNodeAddress: validatorNodeAddress,
            amount: amount,
            machineId: machineId,
            signature: signature
        });
    }

    /// @notice Remove a node address from the list of staking validators
    function _removeStake(address validatorNodeAddress, string memory machineId)
        internal
    {
        uint256 stakedAmount = stakes[msg.sender];
        require(stakedAmount > 0, "You are not in the validators list");

        require(
            verify(
                msg.sender,
                validatorNodeAddress,
                machineId,
                validators[msg.sender].signature
            ),
            "invalid signature match"
        );

        stakes[msg.sender] = 0;
        delete validators[msg.sender];
    }

    /// @notice Extracts r, s, v from a signature
    /// @dev First 32 bytes stores the length of the signature
    /// @dev Skip first 32 bytes of signature add(sig, 32) = pointer of sig + 32
    /// @dev mload(p) loads next 32 bytes starting at the memory address p into memory
    /// @dev add(sig, 32) = pointer of sig + 3
    /// @dev add(sig, 32) = pointer of sig + 3
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function verify(
        address signer,
        address validatorNodeAddress,
        string memory message,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(validatorNodeAddress, message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return recover(ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /// @dev Signature is produced by signing a keccak256 hash with the following format:
    /// @dev "\x19Ethereum Signed Message\n" + len(msg) + msg
    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }
}
