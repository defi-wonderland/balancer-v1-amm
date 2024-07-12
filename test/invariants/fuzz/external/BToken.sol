pragma solidity 0.8.23;

import {CryticERC20ExternalBasicProperties} from
  '@crytic/properties/contracts/ERC20/external/properties/ERC20ExternalBasicProperties.sol';
import {ITokenMock} from '@crytic/properties/contracts/ERC20/external/util/ITokenMock.sol';
import {PropertiesConstants} from '@crytic/properties/contracts/util/PropertiesConstants.sol';
import 'contracts/BToken.sol';

contract EchidnaBToken is CryticERC20ExternalBasicProperties {
  constructor() {
    // Deploy ERC20
    token = ITokenMock(address(new CryticTokenMock()));
  }

  /// @custom:property-id 8
  /// @custom:property  BToken increaseApproval should increase the approval of the address by the amount
  function fuzz_increaseApproval() public {
    // Precondition
  }
  /// @custom:property-id 9
  /// @custom:property BToken decreaseApproval should decrease the approval to max(old-amount, 0)
  function fuzz_decreaseApproval() public {}
}

contract CryticTokenMock is BToken, PropertiesConstants {
  bool public isMintableOrBurnable;
  uint256 public initialSupply;

  constructor() {
    _mint(USER1, INITIAL_BALANCE);
    _mint(USER2, INITIAL_BALANCE);
    _mint(USER3, INITIAL_BALANCE);
    _mint(msg.sender, INITIAL_BALANCE);

    initialSupply = totalSupply();
    isMintableOrBurnable = true;
  }
}
