import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Vulnerable', () => {
    // replace with modern tools of hardhat
    const deployContract = async () => {
        const [owner, address1, address2] = await ethers.getSigners();
        const Attack = await ethers.getContractFactory(
            'Attack',
        );
        const BohdanERC20Token = await ethers.getContractFactory('Vulnerable');
        const bohdanERC20Token = await BohdanERC20Token.deploy();
        await bohdanERC20Token.deployed();

        const attack = await Attack.deploy(bohdanERC20Token.address);
        await attack.deployed();
        return { attack, bohdanERC20Token, owner, address1, address2 };
    };

    describe('The action part', () => {
        it('Should attack the contract and steal the money', async () => {
            const { bohdanERC20Token, owner, attack, address1 } = await deployContract();

            await bohdanERC20Token.connect(owner).buy({ value: ethers.utils.parseEther("2") });

            expect(Number(await ethers.provider.getBalance(bohdanERC20Token.address))).to.be.equal(2000000000000000000);
            await attack.connect(address1).drainMoney({ value: ethers.utils.parseEther("2") });
            expect(Number(await ethers.provider.getBalance(bohdanERC20Token.address))).to.be.equal(0);
        });

        it('Should revert if money sent < 1 ether', async () => {
            const { bohdanERC20Token, owner, attack, address1 } = await deployContract();

            await bohdanERC20Token.connect(owner).buy({ value: ethers.utils.parseEther("2") });
            await expect(attack.connect(address1).drainMoney({ value: ethers.utils.parseEther("0.5") })).to.be.revertedWith('Not enough ether');
        });
    });
});
