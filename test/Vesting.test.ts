/* eslint-disable camelcase */
import { expect } from 'chai';
import { BigNumber, Signer } from 'ethers';
import { ethers } from 'hardhat';
import keccak256 from 'keccak256';
import { MerkleTree } from 'merkletreejs';

import {
  Vesting__factory,
  ERC20Token__factory,
  ERC20Token,
  Vesting,
} from '../typechain-types';

describe('SignatureVesting', function () {
  let erc20: ERC20Token;
  let vesting: Vesting;
  let defaultVestingBalance: BigNumber;

  beforeEach(async () => {
    const [owner] = await ethers.getSigners();
    erc20 = await new ERC20Token__factory(owner).deploy();
    vesting = await new Vesting__factory(owner).deploy(erc20.address);
    defaultVestingBalance = await erc20.balanceOf(await owner.getAddress());
    await erc20.transfer(vesting.address, defaultVestingBalance);
  });

  it('Should emit Vest event with correct data when vesting tokens', async function () {
    const claimer = await ethers.provider.getSigner(2);
    const claimerAddress = await claimer.getAddress();

    const message = ethers.utils.solidityPack(
      ['address', 'uint256', 'uint256', 'address'],
      [claimerAddress, defaultVestingBalance.div(10), 1, vesting.address],
    );

    const signature = await ethers.provider
      .getSigner(0)
      .signMessage(keccak256(message));

    const claimingTx = await vesting
      .connect(claimer)
      .claimWithSignature(defaultVestingBalance.div(10), 1, signature);
    claimingTx.wait();
  });
});

type Leaf = {
  address: string;
  amount: BigNumber;
};

export function getRandomInt(max: number) {
  return Math.floor(Math.random() * max);
}

describe('MerkleVesting', function () {
  let erc20: ERC20Token;
  let vesting: Vesting;
  let merkleVestingBalance: BigNumber;

  beforeEach(async () => {
    const [signer] = await ethers.getSigners();
    erc20 = await new ERC20Token__factory(signer).deploy();
    vesting = await new Vesting__factory(signer).deploy(erc20.address);
    merkleVestingBalance = (
      await erc20.balanceOf(await signer.getAddress())
    ).div(2);

    await erc20.transfer(vesting.address, merkleVestingBalance);
  });

  it('Should emit Vest event with correct data when vesting tokens', async function () {
    const address2 = await ethers.provider.getSigner(1).getAddress();
    const address3 = await ethers.provider.getSigner(2).getAddress();

    const vestData1 = ethers.utils.solidityPack(
      ['address', 'uint256'],
      [address2, merkleVestingBalance.div(2)],
    );
    const vestData2 = ethers.utils.solidityPack(
      ['address', 'uint256'],
      [address3, merkleVestingBalance.div(3)],
    );

    const merkleTree = new MerkleTree([vestData1, vestData2], keccak256, {
      hashLeaves: true,
      sortPairs: true,
    });

    console.log(ethers.utils.keccak256(vestData1));

    const vestTx = await vesting
      .changeMerkleRoot(merkleTree.getHexRoot())
      .then((i) => i.wait());

    const claimTx2 = await vesting
      .connect(ethers.provider.getSigner(1))
      .claim(
        merkleVestingBalance.div(2),
        merkleTree.getHexProof(keccak256(vestData1)),
      )
      .then((i) => i.wait());
    const claimTx3 = await vesting
      .connect(ethers.provider.getSigner(2))
      .claim(
        merkleVestingBalance.div(3),
        merkleTree.getHexProof(keccak256(vestData2)),
      )
      .then((i) => i.wait());

    const balance2 = await erc20.balanceOf(address2);
    const balance3 = await erc20.balanceOf(address3);
    const vestingBalance = await erc20.balanceOf(vesting.address);

    expect(vestingBalance).to.be.equal(
      merkleVestingBalance.sub(balance2).sub(balance3),
    );
    expect(balance2).to.be.equal(merkleVestingBalance.div(2));
    expect(balance3).to.be.equal(merkleVestingBalance.div(3));
  });
});
