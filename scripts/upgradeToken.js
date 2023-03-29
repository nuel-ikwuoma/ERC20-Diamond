const fs = require('fs')
const path = require('path')
const { getSelectors, FacetCutAction } = require("./libraries/diamond")
const { ethers } = require('hardhat')

async function upgradeToken() {
    const zeroAddress = ethers.constants.AddressZero
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]

    const network = hre.network.name
    const file = path.join(__dirname, 'deploymentAddresses.json')
    const diamondAddress = JSON.parse(fs.readFileSync(file))[network]
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondCutFacet.connect(contractOwner)

    const facetName = 'NameFacet'
    const NameFacet = await ethers.getContractFactory(facetName)
    const nameFacet = await NameFacet.deploy()
    await nameFacet.deployed()

    console.log(`${facetName} deployed at: ${nameFacet.address}`)

    const cut = [{
        facetAddress: nameFacet.address,
        action: FacetCutAction.Replace,
        functionSelectors: getSelectors(nameFacet),
    }]


    let tx = await diamondCutFacet.diamondCut(cut, zeroAddress, [])
    let receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
    console.log('Completed diamond upgrade')
}

if (require.main === module) {
    upgradeToken()
      .then(() => process.exit(0))
      .catch((error) => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.upgradeToken = upgradeToken