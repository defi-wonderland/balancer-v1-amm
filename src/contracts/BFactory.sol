// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.25;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import './BPool.sol';
import 'interfaces/IBFactory.sol';

contract BFactory is IBFactory, BBronze {
  mapping(address => bool) internal _isBPool;

  function isBPool(address b) external view returns (bool) {
    return _isBPool[b];
  }

  function newBPool() external returns (BPool) {
    BPool bPool = new BPool();
    _isBPool[address(bPool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(bPool));
    bPool.setController(msg.sender);
    return bPool;
  }

  address internal _bLabs;
  address internal _cowSwap;

  constructor(address cowSwap) {
    _bLabs = msg.sender;
    _cowSwap = cowSwap;
  }

  function getBLabs() external view returns (address) {
    return _bLabs;
  }

  function getCowSwap() external view returns (address) {
    return _cowSwap;
  }

  function setBLabs(address b) external {
    require(msg.sender == _bLabs, 'ERR_NOT_BLABS');
    emit LOG_BLABS(msg.sender, b);
    _bLabs = b;
  }

  function collect(BPool pool) external {
    require(msg.sender == _bLabs, 'ERR_NOT_BLABS');
    uint256 collected = IERC20(pool).balanceOf(address(this));
    bool xfer = pool.transfer(_bLabs, collected);
    require(xfer, 'ERR_ERC20_FAILED');
  }
}
