import { time } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';

describe('Votable', () => {
  const deployContract = async () => {
    const [owner, address1, address2] = await ethers.getSigners();
    const Votable = await ethers.getContractFactory('VotingContract');

    const votable = await Votable.deploy(2);
    await votable.deployed();
    return { votable, owner, address1, address2 };
  };

  describe('Time to vote fellas :)', () => {
    it('Should return empty price list', async () => {
      const { votable, address1 } = await deployContract();

      expect(await votable.connect(address1).getPricesList()).to.deep.equal([
        [],
        [],
      ]);
      // bcs it's initially empty, just testng the function itself
    });

    it('Should buy tokens', async () => {
      const { votable, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);
    });

    it('Should sell tokens', async () => {
      const { votable, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        BigInt(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);
      await votable
        .connect(address1)
        .sellTokens(
          BigInt(await votable.balanceOf(address1.address)),
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
        );
      expect(BigInt(await votable.balanceOf(address1.address))).to.be.equal(0);
    });

    it('Should not sell more tokens as user has', async () => {
      const { votable, address1 } = await deployContract();

      const selling = async () => {
        await votable
          .connect(address1)
          .sellTokens(
            BigInt((await votable.balanceOf(address1.address)) + 1),
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
          );
      };

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        BigInt(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);
      expect(selling()).to.be.revertedWith('Insufficient balance');
    });

    it('Should vote for tokens price', async () => {
      const { votable, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      await votable
        .connect(address1)
        .vote(2, ethers.constants.AddressZero, ethers.constants.AddressZero);

      expect(Number(await votable.totalVotesCounted())).to.be.greaterThan(0);
      expect(await votable._voters(address1.address)).to.equal(
        ethers.constants.AddressZero,
      );
      // bcs he is the first in proposedVotes
      const pricesList = await votable.connect(address1).getPricesList();
      assert.isNotEmpty(pricesList);
    });

    it('Should set token price', async () => {
      const { votable, owner, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      await votable
        .connect(address1)
        .vote(2, ethers.constants.AddressZero, ethers.constants.AddressZero);

      expect(Number(await votable.totalVotesCounted())).to.be.greaterThan(0);
      expect(await votable._voters(address1.address)).to.equal(
        ethers.constants.AddressZero,
      );
      // bcs he is the first in proposedVotes
      const pricesList = await votable.connect(address1).getPricesList();
      assert.isNotEmpty(pricesList);

      await time.increase(60 * 60 * 24 * 7);
      await votable.connect(owner).endVote();
      expect(await votable.tokenPrice()).to.be.equal(2);
    });

    it('Should sort properly', async () => {
      const { votable, address1, address2 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      await votable
        .connect(address1)
        .vote(2, ethers.constants.AddressZero, ethers.constants.AddressZero);

      await votable
        .connect(address2)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.2') },
        );
      expect(
        Number(await votable.balanceOf(address2.address)),
      ).to.be.greaterThan(0);

      await votable
        .connect(address2)
        .vote(4, ethers.constants.AddressZero, address1.address);
    });

    it('Should burn fee', async () => {
      const { votable, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      await time.increase(60 * 60 * 24 * 7);
      expect(Number(await votable.balanceOf(votable.owner()))).not.to.be.equal(
        50000,
      ); // since we got the fee
      await votable.burnFee();
      expect(Number(await votable.balanceOf(votable.owner()))).to.be.equal(
        50000,
      ); // back to his default 50k
      expect(Number(await votable.amountToBurn())).to.be.equal(0);
    });

    it('Should not allow to burn fee twice', async () => {
      const { votable, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      await time.increase(60 * 60 * 24 * 7);
      expect(Number(await votable.balanceOf(votable.owner()))).not.to.be.equal(
        50000,
      ); // since we got the fee
      await votable.burnFee();
      expect(Number(await votable.balanceOf(votable.owner()))).to.be.equal(
        50000,
      ); // back to his default 50k
      expect(Number(await votable.amountToBurn())).to.be.equal(0);

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(await votable.burnFee()).to.be.revertedWith('Already executed');
    });

    it('Should not allow to burn fee if a week not elapsed', async () => {
      const { votable, address1 } = await deployContract();

      await votable
        .connect(address1)
        .buyTokens(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther('0.1') },
        );
      expect(
        Number(await votable.balanceOf(address1.address)),
      ).to.be.greaterThan(0);

      expect(await votable.burnFee()).to.be.revertedWith('Only once a week');
    });
  });
});
