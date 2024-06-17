//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Ebay {
	struct Auction{
		uint id;
		address payable seller;
		string name;
		string description;
		uint min;
		uint bestOfferId;
		uint[] offerIds;
	}

	struct Offer {
		uint id;
		uint auctionId;
		address payable buyer;
		uint price;
	}

	mapping(uint => Auction) private auctions;
	mapping(uint => Offer) private offers;
	mapping(address => uint[]) private auctionList;
	mapping(address => uint[]) private offerList;

	uint private newAuctionId = 1;
	uint private newOfferId = 1;

	function createAuction(string calldata _name, string calldata _description, uint _min) external{ //calldata used when variables are declared as immutable(read only) whereas memory is used when variables are mutable(read and write)
		require(_min>0, "minimum must be greater than 0");
		uint[] memory offerIds = new uint[](0);
		
		auctions[newAuctionId] = Auction(newAuctionId, payable(msg.sender), _name, _description, _min, 0, offerIds);
		auctionList[msg.sender].push(newAuctionId);
		newAuctionId++;
	}

	function createOffer(uint _auctionId) external payable auctionExists(_auctionId){
		Auction storage auction = auctions[_auctionId];
		Offer storage bestOffer = offers[auction.bestOfferId];
		require(msg.value >= auction.min && msg.value > bestOffer.price, "msg.value must be greater than the minimum and the best offer");
		auction.bestOfferId = newOfferId;
		auction.offerIds.push(newOfferId);

		offers[newOfferId] = Offer(newOfferId, _auctionId, payable(msg.sender), msg.value);
		offerList[msg.sender].push(newOfferId);
		newOfferId++;
	}

	function transaction(uint _auctionId) external auctionExists(_auctionId){
		Auction storage auction = auctions[_auctionId];
		Offer storage bestOffer = offers[auction.bestOfferId];

		for(uint i = 0; i<auction.offerIds.length; i++)
		{
			uint offerId = auction.offerIds[i];

			if(offerId != auction.bestOfferId){
				Offer storage offer = offers[offerId];
				offer.buyer.transfer(offer.price); //transfer money back to bidder with less bidding than highest bidding
			}
		}
		auction.seller.transfer(bestOffer.price); //transfer money from highest bidder to seller of item
	}

	function getAuctions() external view returns(Auction[] memory){
		Auction[] memory _auctions = new Auction[](newAuctionId - 1);

		for(uint i = 1; i < newAuctionId; i++)
		{
			_auctions[i-1] = auctions[i];
		}
		return _auctions;
	}

	function getUserAuctions(address _user) external view returns(Auction[] memory){
		uint[] storage userAuctionIds = auctionList[_user];
		Auction[] memory _auctions = new Auction[](userAuctionIds.length);
		for(uint i = 0; i < userAuctionIds.length; i++)
		{
			uint auctionId = userAuctionIds[i];
			_auctions[i] = auctions[auctionId];
		}
		return _auctions;
	}

	function getUserOffers(address _user) external view returns(Offer[] memory){
		uint[] storage userOfferIds = offerList[_user];
		Offer[] memory _offers = new Offer[](userOfferIds.length);

		for(uint i = 0; i<userOfferIds.length; i++)
		{
			uint offerId = userOfferIds[i];
			_offers[i] = offers[offerId];
		}
		return _offers;
	}

	modifier auctionExists(uint _auctionId){
		require(_auctionId > 0 && _auctionId < newAuctionId, "Auction does not exist");
		_;
	}
}