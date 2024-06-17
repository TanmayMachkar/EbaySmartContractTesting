const Ebay = artifacts.require('Ebay');
const {expectRevert} = require('@openzeppelin/test-helpers');

contract('Ebay', (accounts) => {
	let ebay;
	beforeEach(async() => {
		ebay = await Ebay.new() //another way of creating instance of contract
		console.log(ebay.address);
	})

	it('Accounts printing', async() => {
		//console.log(accounts);
	})
	it('Accounts hello', async() => {
		
	})
})