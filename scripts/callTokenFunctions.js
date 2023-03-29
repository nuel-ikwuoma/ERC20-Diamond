const fs = require('fs')
const path = require('path')

async function main() {
    const network = hre.network.name
    const file = path.join(__dirname, 'deploymentAddresses.json')
    const diamondAddress = JSON.parse(fs.readFileSync(file))[network]

    const token = await hre.ethers.getContractAt("DiamondTokenFacet", diamondAddress);
    
    const name = await token.name();
    const symbol = await token.symbol();
    const totalSupply = await token.totalSupply();

    console.log("Token name:", name);
    console.log("Token symbol:", symbol);
    console.log("Token total supply:", totalSupply);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });