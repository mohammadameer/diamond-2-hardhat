/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

// abis
const MRHBTokenABI = require("../artifacts/contracts/facets/MRHBTokenFacet.sol/MRHBTokenFacet.json")
const { ethers } = require('hardhat')

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
  await diamond.deployed()
  console.log('Diamond deployed:', diamond.address)

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet',
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // upgrade diamond with facets
  console.log('')
  // console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }

  // testing adding/replacing/removing functions

  // deploy mrhb token contract
  const MRHBTokenFactory = await ethers.getContractFactory('MRHBTokenFacet')
  const mrhbToken = await MRHBTokenFactory.deploy()
  await mrhbToken.deployed()

  console.log(`MRHB Token deployed: ${mrhbToken.address}`)

  // add mrhb token state & functions to diamond
  tx = await diamondCut.diamondCut([{
    facetAddress: mrhbToken.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(mrhbToken)
  }], diamondInit.address, functionCall)

  // initialize diamond with mrhb token abis
  const diamondMRHBToken = new ethers.Contract(diamond.address, MRHBTokenABI.abi, contractOwner);

  tx = await diamondMRHBToken.initialize(0, "MRHB Network", "MRHB")

  // test getting and increasing mrhb token supply
  tx = await diamondMRHBToken.totalSupply()
  console.log("total supply: ", ethers.utils.formatUnits(tx))
  
  tx = await diamondMRHBToken.mint(contractOwner.address, ethers.utils.parseUnits("100"));

  tx = await diamondMRHBToken.totalSupply()
  console.log("total supply: ", ethers.utils.formatUnits(tx))
  
  // remove total Supply function
  tx = await diamondCut.diamondCut([{
    facetAddress: ethers.constants.AddressZero,
    action: FacetCutAction.Remove,
    functionSelectors: [mrhbToken.interface.getSighash("totalSupply()")]
  }], diamondInit.address, functionCall);

  // console.log("funcs: ", diamondMRHBToken.interface.functions)

  tx = await diamondMRHBToken.name()
  console.log("name: ", tx)


  try {
    tx = await diamondMRHBToken.totalSupply()
    console.log("total supply: ", ethers.utils.formatUnits(tx))
  } catch {
    console.log("Diamond: Function does not exist")
  }


  
  console.log('Completed diamond cut')
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
