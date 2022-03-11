// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
    string name;
    string symbol;
    uint totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
}