// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./AppStorage.sol";

library LibERC20 {
  using SafeMath for uint256;

  // Need to include events locally because `emit Interface.Event(params)` does not work
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function mint(AppStorage storage state, address _to, uint256 _amount) internal {
    require(_to != address(0), "INVALID_TO_ADDRESS");

    state.balances[_to] = state.balances[_to].add(_amount);
    state.totalSupply = state.totalSupply.add(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function burn(AppStorage storage state, address _from, uint256 _amount) internal {

    state.balances[_from] = state.balances[_from].sub(_amount);
    state.totalSupply = state.totalSupply.sub(_amount);
    emit Transfer(_from, address(0), _amount);
  }
}
