import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { parseUnits } from 'ethers'
import { ethers } from 'hardhat'

describe('Swap', function () {
  async function deployTokenAndContract() {
    const [owner, account1, account2] = await ethers.getSigners()

    const bnbFactory = await ethers.getContractFactory('Token')
    const bnb = await bnbFactory.deploy('BNB', 'BNB', 8)

    const usdtFactory = await ethers.getContractFactory('Token')
    const usdt = await usdtFactory.deploy('USDT', 'USDT', 12)

    const swapFactory = await ethers.getContractFactory('Swap')
    const contract = await swapFactory.deploy()

    bnb.transfer(account1, parseUnits('200', 8))
    usdt.transfer(account1, parseUnits('30000', 12))

    bnb.transfer(account2, parseUnits('200', 8))
    usdt.transfer(account2, parseUnits('10000', 12))

    bnb.approve(await contract.getAddress(), parseUnits('200', 8))
    usdt.approve(await contract.getAddress(), parseUnits('30000', 12))

    await contract.initialize(await bnb.getAddress(), await usdt.getAddress(), parseUnits('200', 8), parseUnits('30000', 12))
    return { contract, bnb, usdt, owner, account1, account2 }
  }

  it('init contract', async function () {
    const { contract } = await loadFixture(deployTokenAndContract)

    expect(await contract.bnbAmount()).to.equal(parseUnits('200', 8))
    expect(await contract.usdtAmount()).to.equal(parseUnits('30000', 12))
    expect(await contract.k()).to.equal(parseUnits('200', 8) * parseUnits('30000', 12))
  })

  it('should not enough bnb', async function () {
    const { contract, account1 } = await loadFixture(deployTokenAndContract)
    await expect(contract.connect(account1).buy(parseUnits('201', 8))).to.be.revertedWith('not enough bnb')
  })

  it('should enough bnb', async function () {
    const { bnb, owner, usdt, contract, account1 } = await loadFixture(deployTokenAndContract)
    await contract.connect(account1).buy(parseUnits('1', 8))
    expect(await bnb.balanceOf(account1.address)).to.equal(parseUnits('202', 8))
  })
})
