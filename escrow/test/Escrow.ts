import { loadFixture, time } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'
import { parseEther, parseUnits } from 'ethers'
import { ethers } from 'hardhat'

describe('Escrow', function () {
  async function deployOneYearLockFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60

    const [owner, depositor, recipient] = await ethers.getSigners()

    const tokenFactory = await ethers.getContractFactory('Token')
    const token = await tokenFactory.deploy('Key', 'KEY')

    const contractFactory = await ethers.getContractFactory('Escrow')
    const contract = await contractFactory.deploy()

    await token.transfer(depositor.address, parseEther('100'))

    return { owner, depositor, recipient, token, contract, ONE_YEAR_IN_SECS }
  }

  describe('Deployment', function () {
    it('check token information', async function () {
      const { token, owner } = await loadFixture(deployOneYearLockFixture)

      expect(await token.name()).to.equal('Key')
      expect(await token.symbol()).to.equal('KEY')
      expect(await token.decimals()).to.equal(18)
      expect(await token.owner()).to.equal(owner.address)
    })

    it('shoul successful after deposited', async function () {
      const { depositor, token, contract, recipient, ONE_YEAR_IN_SECS } = await loadFixture(deployOneYearLockFixture)
      token.connect(depositor).approve(await contract.getAddress(), parseEther('80'))
      await contract.connect(depositor).deposit(token, await recipient.getAddress(), parseEther('50'), ONE_YEAR_IN_SECS)

      // get all information of contract
      expect(await contract.depositor()).to.equal(await depositor.getAddress())
      expect(await contract.recipient()).to.equal(await recipient.getAddress())
      expect(await contract.balance()).to.equal(parseEther('50'))
      const withdrawTime = (await time.latest()) + ONE_YEAR_IN_SECS
      expect(await contract.withdrawTime()).to.equal(withdrawTime)

      // check depositor balance after depositting
      expect(await token.balanceOf(await depositor.getAddress())).to.equal(parseEther('50'))
    })

    it('should fail if withdraw time is expired', async () => {
      const { depositor, token, contract, recipient, ONE_YEAR_IN_SECS } = await loadFixture(deployOneYearLockFixture)
      token.connect(depositor).approve(await contract.getAddress(), parseEther('80'))
      await contract.connect(depositor).deposit(token, await recipient.getAddress(), parseEther('50'), ONE_YEAR_IN_SECS)

      //
      const withdrawTime = (await time.latest()) + ONE_YEAR_IN_SECS - 1
      await time.increaseTo(withdrawTime + 1000)
      await expect(contract.connect(recipient).withdraw()).to.be.revertedWith('withdraw time is expired')
    })

    it("should successful if withdraw time isn't expired yet", async () => {
      const { depositor, token, contract, recipient, ONE_YEAR_IN_SECS } = await loadFixture(deployOneYearLockFixture)
      token.connect(depositor).approve(await contract.getAddress(), parseEther('80'))
      await contract.connect(depositor).deposit(token, await recipient.getAddress(), parseEther('50'), ONE_YEAR_IN_SECS)
      //
      await contract.connect(recipient).withdraw()
      expect(await token.balanceOf(await recipient.getAddress())).to.equal(parseEther('50'))
    })
  })
})
