// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**

 * 1. Usage of CREATE2 instead of CREATE3. This makes cheaper to use but more expensive to deploy.
 * 2. No burn limits, tokens do not have burn limits and as a result, the burn arguments are not needed.
 * 3. Ability to deploy a token on behalf of another account.
 */
contract CatERC20Factory is IXERC20Factory {

  /**
   * @notice Deploys an CatERC20 contract using CREATE2.
   * @dev limits and minters must be the same length.
   * @param name The name of the token.
   * @param symbol The symbol of the token.
   * @param owner The owner of the token.
   * @return caterc20 The address of the xerc20.
   */
  function deployXERC20(
    string calldata name,
    string calldata symbol,
    address owner,
    bytes12 salt
  ) external returns (address caterc20) {
    caterc20 = _deployXERC20(name, symbol, owner, salt);

    CatERC20(caterc20).transferOwnership(owner);

    emit XERC20Deployed(caterc20);
  }

  /**
   * @notice Deploys contract using CREATE2.
   * @dev limits and minters must be the same length.
   * @param name The name of the token.
   * @param symbol The symbol of the token.
   * @param minterLimits The array of limits that you are adding (optional, can be an empty array).
   * @param bridges The array of bridges that you are adding (optional, can be an empty array).
   * @return caterc20 The address of the xerc20.
   */
  function deployXERC20(
    string calldata name,
    string calldata symbol,
    uint256[] calldata minterLimits,
    address[] calldata bridges
  ) external returns (address caterc20) {

    caterc20 = _deployXERC20(name, symbol, msg.sender, bytes12(0));

    _setBridgeLimits(caterc20, minterLimits, bridges);

    CatERC20(caterc20).transferOwnership(msg.sender);

    emit XERC20Deployed(caterc20);
  }

  
  function deployLockbox(
    address caterc20,
    address baseToken,
    bool isNative
  ) external returns (address payable lockbox) {
    if ((baseToken == address(0) && !isNative) || (isNative && baseToken != address(0))) {
      revert IXERC20Factory_BadTokenAddress();
    }

    lockbox = _deployLockbox(caterc20, baseToken, isNative);

    emit LockboxDeployed(lockbox);
  }

  function deployXERC20WithLockbox(
    string calldata name,
    string calldata symbol,
    uint256[] calldata minterLimits,
    address[] calldata bridges,
    address baseToken,
    bool isNative
  ) external returns (address caterc20, address payable lockbox) {
    if ((baseToken == address(0) && !isNative) || (isNative && baseToken != address(0))) {
      revert IXERC20Factory_BadTokenAddress();
    }
    caterc20 = _deployXERC20(name, symbol, msg.sender, bytes12(0));

    _setBridgeLimits(caterc20, minterLimits, bridges);

    emit XERC20Deployed(caterc20);

    lockbox = _deployLockbox(caterc20, baseToken, isNative);

    CatERC20(caterc20).setLockbox(lockbox);

    emit LockboxDeployed(lockbox);

    CatERC20(caterc20).transferOwnership(msg.sender);
  }

  
  function _deployXERC20(
    string calldata name,
    string calldata symbol,
    address owner,
    bytes12 salt
  ) internal returns (address caterc20) {
    // concat owner and salt. Owner is in first 20 bytes of the salt
    // where salt is in the last 12.
    bytes32 fullySalt = bytes32(uint256(bytes32(bytes20(owner))) + uint256(uint96(salt)));

    caterc20 = address(new CatERC20{salt: fullySalt}(name, symbol, address(this)));
  }

  
  function _deployLockbox(
    address caterc20,
    address baseToken,
    bool isNative
  ) internal returns (address payable lockbox) {
    bytes32 salt = keccak256(abi.encodePacked(caterc20, baseToken, isNative)); // We technically don't have to include isNative in the salt since the baseToken does that. But for simplicity we do it anyway.

    lockbox = payable(new CatLockbox{salt: salt}(caterc20, baseToken, isNative));

    return lockbox;
  }

 
  function _setBridgeLimits(
    address caterc20,
    uint256[] calldata minterLimits,
    address[] calldata bridges
  ) internal {
    uint256 _bridgesLength = bridges.length;
    if (minterLimits.length != _bridgesLength) {
      revert IXERC20Factory_InvalidLength();
    }

    for (uint256 i; i < _bridgesLength; ++i) {
      CatERC20(caterc20).setLimits(bridges[i], minterLimits[i], 0);
    }
  }
}
