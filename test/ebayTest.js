const Ebay = artifacts.require('Ebay');
const {expectRevert} = require('@openzeppelin/test-helpers');

contract('Ebay', (accounts) => {
	let ebay;
	beforeEach(async() => {
		ebay = await Ebay.new() //another way of creating instance of contract
		//console.log(ebay.address);
	})

	//dummy data
	const auction = {
		name: 'auction1',
		description: 'Selling item1',
		min: 10
	}

	const [seller, buyer1, buyer2] = [accounts[0], accounts[1], accounts[2]];

	it('Should create an auction', async() => {
		let auctions;
		await ebay.createAuction(auction.name, auction.description, auction.min);
		auctions = await ebay.getAuctions();

		assert(auctions.length === 1);
		assert(auctions[0].name === auction.name);
		assert(auctions[0].description === auction.description);
		//console.log(typeof auctions[0].min);
		//assert(auctions[0].min.toNumber() === auction.min); //gives error since auctions[0].min is not a big number and it is a string
		assert(parseInt(auctions[0].min) === auction.min); //converting big number obj to normal number
	})

	it('Should not create an offer if auction does not exist', async() => {
		await expectRevert(
			ebay.createOffer(1, {from: buyer1, value: auction.min + 10}),
			'Auction does not exist' //should be exactly as given in modifier block of smart contract
		)
	})

	it('Should not create an offer if price is too low', async() => {
		await ebay.createAuction(auction.name, auction.description, auction.min);
		await expectRevert(
			ebay.createOffer(1, {from: buyer1, value: auction.min - 1}),
			'msg.value must be greater than the minimum and the best offer'
		)
	})

	it('Should create an offer', async() => {
		await ebay.createAuction(auction.name, auction.description, auction.min);
		await ebay.createOffer(1, {from: buyer1, value: auction.min});
	
		const userOffers = await ebay.getUserOffers(buyer1);
		assert(userOffers.length === 1);
		assert(parseInt(userOffers[0].id) === 1);
		assert(userOffers[0].buyer === buyer1);
		assert(parseInt(userOffers[0].price) === auction.min);
	})

	it('Should not transact if auction does not exist', async() => {
		await expectRevert(ebay.transaction(1), 'Auction does not exist');
	})

	it('Should do transaction', async() => {
		const bestPrice = web3.utils.toBN(auction.min + 10); //convert to Big number obj
		await ebay.createAuction(auction.name, auction.description, auction.min);
		await ebay.createOffer(1, {from: buyer1, value: auction.min});
		await ebay.createOffer(1, {from: buyer2, value: bestPrice}); //this offer will be accepted since 10+10=20 eth
		const balanceBefore = web3.utils.toBN(await web3.eth.getBalance(seller)); //will amount to around 98~100 eth
		console.log(await web3.eth.getBalance(seller));

		await ebay.transaction(1, {from: accounts[3]});

		const balanceAfter = web3.utils.toBN(await web3.eth.getBalance(seller)); //will amount to around 118~120 eth
		console.log(await web3.eth.getBalance(seller));
		assert(balanceAfter.sub(balanceBefore).eq(bestPrice)); //will give true
	})
})