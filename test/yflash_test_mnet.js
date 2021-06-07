const mLegos = require("@studydefi/money-legos");

const CompFlash = artifacts.require("CompoundFlash");
const IERC20 = artifacts.require("IERC20");
const CTokenInterface = artifacts.require("CTokenInterface");
const CompAdaptor = artifacts.require("CompAdaptor");

contract("CompFlash", async () => {
    const soloAddr = mLegos.legos.dydx.soloMargin.address;
    const cCtrlrAddr = mLegos.legos.compound.comptroller.address;
    const daiAddr = mLegos.legos.erc20.dai.address;
    const cDaiAddr = mLegos.legos.compound.cDAI.address;

    const whale = "0x43EAEAC4bED50cc56a9074D7EBe87EFB7232bD94";

    // ERC20 balance getter
    const getBalance = async (token, address) => {
        const bal = await token.balanceOf(address);
        return web3.utils.fromWei(bal);
    };

    const fromWeiDigit = (number, digits) => {
        const bal = parseFloat(web3.utils.fromWei(number));
        return bal * Math.pow(10, 18 - digits);
    };

    let compFlash, dai, cDai;
    beforeEach(async () => {
        compFlash = await CompFlash.new(cCtrlrAddr);
        compAdaptor = await CompAdaptor.new(cCtrlrAddr);
        dai = await IERC20.at(daiAddr);
        cDai = await CTokenInterface.at(cDaiAddr);
    });

    it("should deposit funds to compound", async () => {
        console.log(compFlash.address);
        await dai.transfer(compFlash.address, web3.utils.toWei("1000"), { from: whale });
        console.log("DAI balance of contract: ", await getBalance(dai, compFlash.address));

        await compFlash.startFlashLoan(soloAddr, daiAddr, cDaiAddr, web3.utils.toWei("100"), web3.utils.toWei("200"));
        console.log("DAI balance of contract: ", await getBalance(dai, compFlash.address));
        console.log();

        // let [error, cTknBal, borrowBal, exchRate] = await cDai.getAccountSnapshot(compAdaptor.address);
        let res = await cDai.getAccountSnapshot(compFlash.address);
        console.log("cDAI balance of contract: ", fromWeiDigit(res[3], 8));
        console.log("cDAI exchange rate      : ", web3.utils.fromWei(res[1]));
        let daiDeposits = parseFloat(web3.utils.fromWei(res[1])) * parseFloat(web3.utils.fromWei(res[3]));
        console.log("DAI deposits (total)    : ", daiDeposits);
        console.log("DAI owed to Compound    : ", web3.utils.fromWei(res[2]));
    });
});
