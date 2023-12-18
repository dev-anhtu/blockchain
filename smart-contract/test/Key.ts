import { ethers } from 'hardhat'
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'

describe('Token contract', function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners()
    const keyToken = await ethers.deployContract('Key')
    await keyToken.waitForDeployment()
    return { keyToken, owner, addr1, addr2 }
  }

  describe('Deployment', function () {
    it('deposit amount', async function () {
      const { keyToken, addr1, addr2 } = await loadFixture(deployTokenFixture)
      await keyToken.deposit(addr1.address, 100)
      await keyToken.deposit(addr2.address, 200)
      expect(await keyToken.balanceOf(addr1.address)).to.equal(100)
      expect(await keyToken.balanceOf(addr2.address)).to.equal(200)
      expect(await keyToken.getTotalSupply()).to.equal(300)
    })

    it('withdraw', async function () {
      const { keyToken, addr1, addr2 } = await loadFixture(deployTokenFixture)
      await keyToken.deposit(addr1.address, 100)
      await keyToken.deposit(addr2.address, 200)
      expect(await keyToken.getTotalSupply()).to.equal(300)

      await keyToken.withdraw(addr1.address, 50)
      expect(await keyToken.balanceOf(addr1.address)).to.equal(50)
      expect(await keyToken.balanceOf(addr2.address)).to.equal(200)
      expect(await keyToken.getTotalSupply()).to.equal(250)

      await keyToken.withdraw(addr2.address, 100)
      expect(await keyToken.balanceOf(addr1.address)).to.equal(50)
      expect(await keyToken.balanceOf(addr2.address)).to.equal(100)
      expect(await keyToken.getTotalSupply()).to.equal(150)

      await keyToken.withdraw(addr1.address, 50)
      expect(await keyToken.balanceOf(addr1.address)).to.equal(0)
    })
  })
})
