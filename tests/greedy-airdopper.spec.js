const Airdropper = artifacts.require('./greedy-airdropper.sol');
const TestToken = artifacts.require('./popular-shitcoin-token.sol');
const {signAirdropERC20, web1SignAdapterFactory, sign} = require('../utils/signer.js');

const signFn = web1SignAdapterFactory(web3);

let tokenToClaimInstance;
let sender;
let recipient;
let airdropperInstance;

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should allow user to claim the tokens', async function () {
        const nTokens = 31337;
        const nonce = 0;
        const parms = await signAirdropERC20(tokenToClaimInstance.address, sender, recipient, nTokens, nonce, signFn);

        const balanceSenderPre = await tokenToClaimInstance.balanceOf(sender);
        const balanceRecipientPre = await tokenToClaimInstance.balanceOf(recipient);

        await tokenToClaimInstance.approve(airdropperInstance.address, nTokens);
        await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, sender, recipient, nTokens, nonce, parms.v, parms.r, parms.s);

        const balanceSenderPost = await tokenToClaimInstance.balanceOf(sender);
        const balanceRecipientPost = await tokenToClaimInstance.balanceOf(recipient);

        assert.equal(balanceSenderPost.toNumber(), balanceSenderPre.toNumber() - nTokens);
        assert.equal(balanceRecipientPost.toNumber(), balanceRecipientPre.toNumber() + nTokens);
    });
});

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should only allow user to claim token once unless given another signature', async function () {
        const nTokens = 31337;
        const nonce = 0;
        const parms = await signAirdropERC20(tokenToClaimInstance.address, sender, recipient, nTokens, nonce, signFn);

        const balanceSenderPre = await tokenToClaimInstance.balanceOf(sender);
        const balanceRecipientPre = await tokenToClaimInstance.balanceOf(recipient);

        await tokenToClaimInstance.approve(airdropperInstance.address, nTokens);
        await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, sender, recipient, nTokens, nonce, parms.v, parms.r, parms.s);

        const balanceSenderPost = await tokenToClaimInstance.balanceOf(sender);
        const balanceRecipientPost = await tokenToClaimInstance.balanceOf(recipient);

        assert.equal(balanceSenderPost.toNumber(), balanceSenderPre.toNumber() - nTokens);
        assert.equal(balanceRecipientPost.toNumber(), balanceRecipientPre.toNumber() + nTokens);

        try {
            await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, sender, recipient, nTokens, nonce, parms.v, parms.r, parms.s);
        } catch ({reason}) {
            assert.equal(reason, "re-use detected");
        }

        const newNonce = 2
        const parms2 = await signAirdropERC20(tokenToClaimInstance.address, sender, recipient, nTokens, newNonce, signFn);
        await tokenToClaimInstance.approve(airdropperInstance.address, nTokens);
        await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, sender, recipient, nTokens, newNonce, parms2.v, parms2.r, parms2.s);
    });
});

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should not allow claim when signed by non-sender and message sender is different', async function () {
        const nTokens = 31337;
        const nonce = 0;
        const parms = await signAirdropERC20(tokenToClaimInstance.address, accounts[1], recipient, nTokens, nonce, signFn);

        await tokenToClaimInstance.approve(airdropperInstance.address, nTokens);
        try {
            await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], recipient, nTokens, nonce, parms.v, parms.r, parms.s);
        } catch ({reason}) {
            assert.equal(reason, "invalid claim");
        }
    });
});

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should not allow claim when signed by non-sender but message sender is the same', async function () {
        const nTokens = 31337;
        const nonce = 0;
        // create a data saying the sender is accounts[0]
        const h = await web3.utils.soliditySha3(tokenToClaimInstance.address, accounts[0], recipient, nTokens, nonce);
        // sign it using their account instead, accounts[1], since they don't have access to accounts[0]
        const parms = await sign(accounts[1], h, signFn)

        await tokenToClaimInstance.approve(airdropperInstance.address, nTokens);

        try {
            await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], recipient, nTokens, nonce, parms.v, parms.r, parms.s);
        } catch ({reason}) {
            assert.equal(reason, "invalid claim");
        }
    });
});

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should not allow the transfer of tokens past the approved amount', async function () {
        const totalTokensApproved = 1000;
        const nonce = 0;

        await tokenToClaimInstance.approve(airdropperInstance.address, totalTokensApproved);

        const parmsA = await signAirdropERC20(tokenToClaimInstance.address, accounts[0], accounts[1], totalTokensApproved / 2, nonce, signFn);
        const parmsB = await signAirdropERC20(tokenToClaimInstance.address, accounts[0], accounts[2], (totalTokensApproved / 2) + 1, nonce, signFn);
        const parmsC = await signAirdropERC20(tokenToClaimInstance.address, accounts[0], accounts[3], totalTokensApproved / 2, nonce, signFn);
        const parmsD = await signAirdropERC20(tokenToClaimInstance.address, accounts[0], accounts[4], 1, nonce, signFn);

        await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], accounts[1], totalTokensApproved / 2, nonce, parmsA.v, parmsA.r, parmsA.s);
        try {
            await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], accounts[2], (totalTokensApproved / 2) + 1, nonce, parmsB.v, parmsB.r, parmsB.s);
        } catch ({reason}) {
            assert.equal(reason, "allowance too low");
        }
        await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], accounts[3], totalTokensApproved / 2, nonce, parmsC.v, parmsC.r, parmsC.s);
        try {
            await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], accounts[4], 1, nonce, parmsD.v, parmsD.r, parmsD.s);
        } catch ({reason}) {
            assert.equal(reason, "allowance too low");
        }
    });
});

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should not allow claim when recipient is different', async function () {
        const nTokens = 31337;
        const nonce = 0;
        const parms = await signAirdropERC20(tokenToClaimInstance.address, accounts[0], accounts[0], nTokens, nonce, signFn);

        await tokenToClaimInstance.approve(airdropperInstance.address, nTokens);
        try {
            await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, accounts[0], accounts[1], nTokens, nonce, parms.v, parms.r, parms.s);
        } catch ({reason}) {
            assert.equal(reason, "invalid claim");
        }
    });
});

contract('Airdropper', function (accounts) {
    beforeEach(async function () {
        sender = accounts[0];
        recipient = accounts[1];
        tokenToClaimInstance = await TestToken.new();
        airdropperInstance = await Airdropper.new(tokenToClaimInstance.address);
    });

    it('should consume less than 100k gas per claim', async function () {
        const parms = await signAirdropERC20(tokenToClaimInstance.address, sender, recipient, 14, 0, signFn);

        await tokenToClaimInstance.approve(airdropperInstance.address, 14);
        const r = await airdropperInstance.claimTokensBEP20(tokenToClaimInstance.address, sender, recipient, 14, 0, parms.v, parms.r, parms.s);

        assert.isBelow(r.receipt.gasUsed, 100000);
    });
});