import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('BohdanERC20Token', () => {
  // replace with modern tools of hardhat
  const deployContract = async () => {
    const [owner, address1, address2, address3] = await ethers.getSigners();
    const BohdanERC20Token = await ethers.getContractFactory(
      'BohdanERC20Token',
    );
    const bohdanERC20Token = await BohdanERC20Token.deploy();
    await bohdanERC20Token.deployed();
    return { bohdanERC20Token, owner, address1, address2, address3 };
  };

  describe('Constructor part', () => {
    it('Should give owner 50000 tokens', async () => {
      const { bohdanERC20Token, owner } = await deployContract();

      expect(await bohdanERC20Token.balanceOf(owner.address)).to.be.equal(
        50000,
      );
    });

    it('Should have increased totalSupply by 50000', async () => {
      const { bohdanERC20Token } = await deployContract();

      expect(await bohdanERC20Token.totalSupply()).to.be.equal(50000);
    });
  });

  describe('Transaction', () => {
    it('Should be able to transfer tokens', async () => {
      const { bohdanERC20Token, owner, address1, address2 } =
        await deployContract();

      await bohdanERC20Token.connect(owner).transfer(address1.address, 50);
      await bohdanERC20Token.connect(owner).transfer(address2.address, 2);

      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(
        50,
      );
      expect(await bohdanERC20Token.balanceOf(address2.address)).to.be.equal(2);

      await bohdanERC20Token.connect(address1).transfer(address2.address, 50);

      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(0);
      expect(await bohdanERC20Token.balanceOf(address2.address)).to.be.equal(
        52,
      );
    });
  });

  describe('Buying and selling', () => {
    it('Should buy tokens', async () => {
      const { bohdanERC20Token, address1 } = await deployContract();

      await bohdanERC20Token.connect(address1).buy({ value: 5 });
      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(5);
    });

    it('Should sell tokens', async () => {
      const { bohdanERC20Token, address1 } = await deployContract();

      await bohdanERC20Token.connect(address1).buy({ value: 5 });
      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(5);
      await bohdanERC20Token.connect(address1).sell(5);
      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(0);
    });

    it('Should not allow buying zero tokens', async () => {
      const { bohdanERC20Token, address1 } = await deployContract();

      await expect(
        bohdanERC20Token.connect(address1).buy({ value: 0 }),
      ).to.be.revertedWith('Cannot deposit zero tokens');
    });

    it('Should not allow withdrawing zero tokens', async () => {
      const { bohdanERC20Token, address1 } = await deployContract();

      await bohdanERC20Token.connect(address1).buy({ value: 5 });
      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(5);

      await expect(
        bohdanERC20Token.connect(address1).sell(0),
      ).to.be.revertedWith('Cannot withdraw zero tokens');
    });

    it('Should not allow withdrawing way too much tokens', async () => {
      const { bohdanERC20Token, address1 } = await deployContract();

      await bohdanERC20Token.connect(address1).buy({ value: 5 });
      expect(await bohdanERC20Token.balanceOf(address1.address)).to.be.equal(5);

      await expect(
        bohdanERC20Token.connect(address1).sell(6),
      ).to.be.revertedWith('Withdrawing way too much');
    });
  });
});
