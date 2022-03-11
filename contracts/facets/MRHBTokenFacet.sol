// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IERC20Facet.sol";

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibERC20 } from "../libraries/LibERC20.sol";

import "../libraries/AppStorage.sol";

contract MRHBTokenFacet is IERC20, IERC20Facet {
    using SafeMath for uint256;

    AppStorage internal state;

    modifier onlyOwner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.contractOwner == msg.sender, "only owner can call this function");
        _;
    }

    function initialize(
    uint256 _initialSupply,
    string memory _name,
    string memory _symbol
  ) external override {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    require(
      bytes(state.name).length == 0 &&
      bytes(state.symbol).length == 0,
      "ALREADY_INITIALIZED"
    );

    require(
      bytes(_name).length != 0 &&
      bytes(_symbol).length != 0,
      "INVALID_PARAMS"
    );

    require(msg.sender == ds.contractOwner, "Must own the contract.");

    LibERC20.mint(state, msg.sender, _initialSupply);

    state.name = _name;
    state.symbol = _symbol;
  }

    function name() external override view returns (string memory) {
    return state.name;
    }

  function setName(string calldata _name) external override onlyOwner {
    state.name = _name;
  }

  function symbol() external override view returns (string memory) {
    return state.symbol;
  }

  function setSymbol(string calldata _symbol) external override onlyOwner {
    state.symbol = _symbol;
  }

  function decimals() external override pure returns (uint8) {
    return 18;
  }

  function mint(address _to, uint256 _amount) external override {
    require(_to != address(0), "INVALID_TO_ADDRESS");

    state.balances[_to] = state.balances[_to].add(_amount);
    state.totalSupply = state.totalSupply.add(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function burn(address _from, uint256 _amount) external override {

    state.balances[_from] = state.balances[_from].sub(_amount);
    state.totalSupply = state.totalSupply.sub(_amount);
    emit Transfer(_from, address(0), _amount);
  }

  function approve(address _spender, uint256 _amount)
    external
    override
    returns (bool)
  {
    require(_spender != address(0), "SPENDER_INVALID");
    state.allowances[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  function increaseApproval(address _spender, uint256 _amount) external override returns (bool) {
    require(_spender != address(0), "SPENDER_INVALID");

    state.allowances[msg.sender][_spender] = state.allowances[msg.sender][_spender].add(_amount);
    emit Approval(msg.sender, _spender, state.allowances[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _amount) external override returns (bool) {
    require(_spender != address(0), "SPENDER_INVALID");

    uint256 oldValue = state.allowances[msg.sender][_spender];
    if (_amount > oldValue) {
      state.allowances[msg.sender][_spender] = 0;
    } else {
      state.allowances[msg.sender][_spender] = oldValue.sub(_amount);
    }
    emit Approval(msg.sender, _spender, state.allowances[msg.sender][_spender]);
    return true;
  }

  function transfer(address _to, uint256 _amount)
    external
    override
    returns (bool)
  {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external override returns (bool) {

    require(_from != address(0), "FROM_INVALID");

    // Update approval if not set to max uint256
    if (state.allowances[_from][msg.sender] != type(uint256).max) {
      uint256 newApproval = state.allowances[_from][msg.sender].sub(_amount);
      state.allowances[_from][msg.sender] = newApproval;
      emit Approval(_from, msg.sender, newApproval);
    }

    _transfer(_from, _to, _amount);
    return true;
  }

  function allowance(address _owner, address _spender)
    external
    view
    override
    returns (uint256)
  {
    return state.allowances[_owner][_spender];
  }

  function balanceOf(address _of) external view override returns (uint256) {
    return state.balances[_of];
  }

  function totalSupply() external view override returns (uint256) {
    return state.totalSupply;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
      
    state.balances[_from] = state.balances[_from].sub(_amount);
    state.balances[_to] = state.balances[_to].add(_amount);

    emit Transfer(_from, _to, _amount);
  }
}