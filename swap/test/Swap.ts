import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { parseUnits } from 'ethers'
import { ethers } from 'hardhat'
import { Swap, Token } from '../typechain-types'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { before } from 'mocha'

const BNB_DECIMALS: bigint = BigInt(5)
const USDT_DECIMALS: bigint = BigInt(8)

describe('Swap', function () {
  let contract: Swap
  let usdt: Token
  let bnb: Token

  let owner: HardhatEthersSigner
  let account1: HardhatEthersSigner
  let account2: HardhatEthersSigner

  before(async function () {
    ;[owner, account1, account2] = await ethers.getSigners()

    const bnbFactory = await ethers.getContractFactory('Token')
    bnb = await bnbFactory.deploy('BNB', 'BNB', BNB_DECIMALS)

    const usdtFactory = await ethers.getContractFactory('Token')
    usdt = await usdtFactory.deploy('USDT', 'USDT', USDT_DECIMALS)

    const swapFactory = await ethers.getContractFactory('Swap')
    contract = await swapFactory.deploy(await bnb.getAddress(), await usdt.getAddress())

    await bnb.connect(owner).approve(await contract.getAddress(), parseUnits('200', BNB_DECIMALS))
    await usdt.connect(owner).approve(await contract.getAddress(), parseUnits('30000', USDT_DECIMALS))

    await contract.connect(owner).fund(parseUnits('200', BNB_DECIMALS), parseUnits('30000', USDT_DECIMALS))

    return { contract, bnb, usdt, owner, account1, account2 }
  })

  it('should initialize contract with correct balances', async function () {
    expect(await contract.bnbAmount()).to.equal(parseUnits('200', BNB_DECIMALS))
    expect(await contract.usdtAmount()).to.equal(parseUnits('30000', USDT_DECIMALS))
    expect(await contract.k()).to.equal(parseUnits('200', BNB_DECIMALS) * parseUnits('30000', USDT_DECIMALS))
  })

  it('should transfer tokens to another account', async function () {
    await bnb.connect(owner).transfer(account1.address, parseUnits('200', BNB_DECIMALS))
    await usdt.connect(owner).transfer(account1.address, parseUnits('30000', USDT_DECIMALS))

    expect(await bnb.balanceOf(account1.address)).to.equal(parseUnits('200', BNB_DECIMALS))
    expect(await usdt.balanceOf(account1.address)).to.equal(parseUnits('30000', USDT_DECIMALS))
  })

  it('should revert when buying with not enough BNB', async function () {
    await expect(contract.connect(account1).buy(parseUnits('201', BNB_DECIMALS))).to.be.revertedWith('Not enough BNB')
  })

  it('should revert when buying with not enough USDT', async function () {
    await expect(contract.connect(account1).buy(parseUnits('199', BNB_DECIMALS))).to.be.revertedWith(
      'Your USDT balance is not enough'
    )
  })

  it('should successfully execute a buy transaction', async function () {
    await contract.connect(account1).buy(parseUnits('1', BNB_DECIMALS))
    expect(await contract.bnbAmount()).to.equal(parseUnits('199', BNB_DECIMALS))
    expect(await bnb.balanceOf(account1.address)).to.equal(parseUnits('201', BNB_DECIMALS))
  })
})
